package Hypersonic::Event::IOUring;

use strict;
use warnings;
use 5.010;

use parent 'Hypersonic::Event::Role';

our $VERSION = '0.19';

sub name { 'io_uring' }

sub available {
    return 0 unless $^O eq 'linux';

    # Check kernel version >= 5.13.
    #
    # We need kernel 5.13+ (not just 5.1+) because the readiness-only
    # backend in 0.19+ uses io_uring_prep_poll_multishot() which was
    # added in Linux 5.13 / liburing 2.1 (Aug 2021). Multi-shot poll
    # is essential: with one-shot poll_add the userspace re-arm in
    # gen_get_fd races against the main loop's recv() in a way that
    # makes the freshly re-armed (level-triggered) poll fire while
    # the buffer still has unread data, then fire AGAIN with an
    # empty buffer after recv() drains, causing the next iteration
    # to recv() and get EAGAIN, which the main loop treats as a
    # disconnect. This bug killed all sequential-keep-alive tests
    # (t/2100..t/2102, t/0035 WebSocket echo) the first time we
    # tried readiness-only mode. Multi-shot lets the kernel manage
    # the re-arm atomically with the readiness check, avoiding the
    # race entirely.
    #
    # Kernels < 5.13 fall back to epoll automatically via
    # Hypersonic::Event::best_backend's priority list. cpansmoker
    # hosts on Debian 12 (kernel 6.1+) and Fedora 43 (kernel 6.x)
    # all satisfy this; Debian 11 (5.10) and older fall back.
    my $ver = `uname -r 2>/dev/null` || '';
    my ($major, $minor) = $ver =~ /^(\d+)\.(\d+)/;
    return 0 unless $major && ($major > 5 || ($major == 5 && $minor >= 13));

    # Check for liburing headers
    my $has_header = -f '/usr/include/liburing.h'
        || -f '/usr/local/include/liburing.h'
        || -f '/usr/include/x86_64-linux-gnu/liburing.h';
    return 0 unless $has_header;

    # io_uring may be disabled at the kernel level. RHEL9 ships with
    # kernel.io_uring_disabled=2 by default; a value of 1 or 2 means
    # the syscall returns EINVAL/EPERM regardless of liburing being
    # linkable. Bail before we sink time into a compile+link probe.
    if (open my $fh, '<', '/proc/sys/kernel/io_uring_disabled') {
        my $disabled = <$fh>;
        close $fh;
        chomp $disabled if defined $disabled;
        return 0 if defined $disabled && $disabled ne '0';
    }

    # Compile-link-and-RUN probe. A pure link check passes on systems
    # that have liburing installed but where io_uring_setup() will
    # nevertheless fail at runtime (kernel disabled, sandboxing, missing
    # liburing.so at exec time). Also probe for io_uring_prep_poll_multishot
    # symbol availability - the symbol was added in liburing 2.1, and
    # the actual multishot poll operation requires kernel 5.13+. If
    # either is missing we want to fall back to epoll silently.
    require Hypersonic::JIT::Util;
    return Hypersonic::JIT::Util->can_run(
        '',
        '-luring',
        'struct io_uring ring; int rc = io_uring_queue_init(8, &ring, 0); '
            . 'if (rc < 0) return 1; '
            . 'struct io_uring_sqe* sqe = io_uring_get_sqe(&ring); '
            . 'if (!sqe) { io_uring_queue_exit(&ring); return 2; } '
            . 'io_uring_prep_poll_multishot(sqe, 0, POLLIN); '
            . 'io_uring_sqe_set_data(sqe, (void*)0); '
            . 'io_uring_queue_exit(&ring); return 0;',
        "#include <liburing.h>\n#include <poll.h>",
    );
}

sub includes {
    # liburing.h for the server loop.
    # <poll.h> for POLLIN (the readiness mask we pass to prep_poll_add).
    # <sys/epoll.h> is needed for the UA::Async slot-tracking helpers
    # (gen_create_loop / _add_with_slot / _get_slot) - io_uring is
    # Linux 5.1+ which always has epoll.
    return "#include <liburing.h>\n#include <poll.h>\n#include <sys/epoll.h>";
}

sub defines {
    # 0.19+ uses io_uring purely as a readiness notifier via
    # io_uring_prep_poll_multishot. Two subtle bugs would otherwise
    # bite us; both are fixed here:
    #
    # BUG 1 - CQE pointer staleness. The previous gen_wait cached
    # `struct io_uring_cqe*` pointers into a static array and called
    # io_uring_cqe_seen() per-event from gen_get_fd. Each cqe_seen
    # advances the user-side consumer cursor by one slot, freeing
    # that slot for the kernel to overwrite with a new CQE. So by
    # the time gen_get_fd dereferences cqes[i+1] for i+1 > 0, the
    # kernel may have rewritten cqes[1..n-1]'s targets. The new
    # design copies (user_data, res) VALUES out of each CQE inside
    # the for_each_cqe loop, then calls io_uring_cq_advance(&ring,
    # count) once to release all consumed slots at once. The
    # downstream gen_get_fd reads from our private value array, never
    # from the ring buffer.
    #
    # BUG 2 - fd reuse race. Suppose connection A is on fd 7 with a
    # multi-shot poll registration whose CQEs carry user_data=7. The
    # kernel may queue a CQE for fd 7 just before A is closed. The
    # main loop closes fd 7. The next accept() returns fd 7 for a
    # new connection B; the main loop calls gen_add(7) which arms a
    # new multi-shot poll. The queued CQE from A arrives -- it
    # carries user_data=7, looks valid, gen_get_fd returns fd=7, and
    # the main loop calls recv(7) thinking it's data for B but B
    # hasn't sent anything yet so recv returns EAGAIN and the main
    # loop closes B as if it had disconnected. The fix is a per-fd
    # generation counter, bumped on every gen_add and gen_del, with
    # the current generation packed into the high 32 bits of
    # user_data. gen_get_fd compares the CQE's generation to the
    # current one and discards stale CQEs.
    #
    # CQEs from cancel SQEs (gen_del) carry user_data=0 by design
    # so they can be cheaply distinguished from real poll completions
    # in gen_get_fd.
    return <<'C';
#define EV_BACKEND_IO_URING 1
#ifndef URING_ENTRIES
#define URING_ENTRIES 256
#endif
#ifndef MAX_EVENTS
#define MAX_EVENTS 1024
#endif

/* MAX_FD is set by Hypersonic core to 65536, but its #define is
 * emitted AFTER the backend's defines() block. Guard ours so the
 * array declaration below has a valid size; the later core #define
 * will be a redefinition to the same value, which gcc accepts. */
#ifndef MAX_FD
#define MAX_FD 65536
#endif

/* Value-copied CQE for the readiness-only design. See BUG 1 above. */
typedef struct {
    uint64_t ud;
    int32_t  res;
} hs_iouring_event_t;

/* Per-fd generation counter. See BUG 2 above. Starts at 0; the very
 * first gen_add() bumps to 1, so a user_data of 0 unambiguously means
 * "this CQE is from a cancel SQE, not a real poll completion". */
static uint32_t g_iouring_fd_gen[MAX_FD];

/* Pack (generation, fd) into a uintptr_t for io_uring_sqe_set_data.
 * Generation is in the high 32 bits so that incrementing it cannot
 * collide with any valid fd value (which is at most MAX_FD-1).
 * Cast to void* at the call site because that's what
 * io_uring_sqe_set_data expects. */
#define HS_IOURING_UD(fd)  ( ((uint64_t)g_iouring_fd_gen[(fd)] << 32) | (uint32_t)(fd) )
C
}

sub event_struct { 'io_uring_cqe' }

# UA::Async slot-tracking helpers below use a private epoll instance
# (io_uring's own slot tracking would mean weaving user_data through
# the shared submission ring, which is a lot more invasive). So when
# UA::Async asks for a buffer to pass to gen_wait_once it must be
# struct epoll_event[], NOT io_uring_cqe[]. See the Fedora 43 / perl
# 5.38.5 smoker report (5ce1e632) for what happens when the wrong
# type is declared - epoll_wait() argument-type mismatch + a missing
# `data` member access.
sub slot_event_struct { 'epoll_event' }

sub extra_cflags  { '' }
sub extra_ldflags { '-luring' }

# io_uring is used here as a *readiness* notifier rather than for
# completion-based I/O. The main event loop's accept() and recv()
# calls do the actual I/O - identical to the epoll/kqueue path.
# See the comment on `defines` above for the two subtle bugs
# (CQE pointer staleness, fd reuse race) that this design fixes.
sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;

    $builder->comment('io_uring backend - readiness-only multi-shot poll')
      ->line('static struct io_uring ring;')
      ->line('static int ring_initialized = 0;')
      ->blank
      ->if('!ring_initialized')
        ->if('io_uring_queue_init(URING_ENTRIES, &ring, 0) < 0')
          # gen_create is inlined into hypersonic_run_event_loop, which
          # is a void XS function. `return <value>;` triggers GCC 14+
          # -Wreturn-mismatch (now an error). croak from XS instead -
          # it longjmps out cleanly and surfaces a Perl-level error.
          ->line('croak("io_uring_queue_init() failed: %s", strerror(errno));')
        ->endif
        ->line('ring_initialized = 1;')
      ->endif
      ->blank
      ->comment('Arm MULTI-SHOT poll for listen socket. The kernel')
      ->comment('re-arms automatically after each event (no userspace')
      ->comment('re-arm race). Generation counter is bumped first so')
      ->comment('any stale CQEs from a previous lifetime of this fd are')
      ->comment('discarded as stale by gen_get_fd.')
      ->line('{')
      ->line("    g_iouring_fd_gen[$listen_fd_var]++;")
      ->line('    struct io_uring_sqe* _csqe = io_uring_get_sqe(&ring);')
      ->line('    if (!_csqe) croak("io_uring_get_sqe() returned NULL during gen_create");')
      ->line("    io_uring_prep_poll_multishot(_csqe, $listen_fd_var, POLLIN);")
      ->line("    io_uring_sqe_set_data(_csqe, (void*)(uintptr_t)HS_IOURING_UD($listen_fd_var));")
      ->line('    if (io_uring_submit(&ring) < 0) croak("io_uring_submit() failed: %s", strerror(errno));')
      ->line('}')
      ->line('int ev_fd = 0;')  # Dummy - io_uring uses the static ring
      ->blank;
}

# Arm a MULTI-SHOT POLLIN poll for $fd_var. Kernel re-arms after each
# completion automatically (kernel 5.13+ / liburing 2.1+, validated by
# available()). Generation counter is bumped first so the new poll's
# CQEs cannot be confused with stale CQEs from an earlier registration
# on the same fd value (see BUG 2 in defines() comment).
sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line('{')
      ->line("    if ($fd_var >= 0 && $fd_var < MAX_FD) {")
      ->line("        g_iouring_fd_gen[$fd_var]++;")
      ->line('        struct io_uring_sqe* _asqe = io_uring_get_sqe(&ring);')
      ->line('        if (_asqe) {')
      ->line("            io_uring_prep_poll_multishot(_asqe, $fd_var, POLLIN);")
      ->line("            io_uring_sqe_set_data(_asqe, (void*)(uintptr_t)HS_IOURING_UD($fd_var));")
      ->line('            io_uring_submit(&ring);')
      ->line('        }')
      ->line('    }')
      ->line('}');
}

# Cancel any pending poll for $fd_var. MUST be called BEFORE close()
# by the main loop.
#
# THE CRITICAL BIT: io_uring's multishot poll registration holds a
# kernel-level `struct file` reference to the fd. The caller's
# subsequent close(fd) only removes the fd from the process's fd
# table; the underlying socket stays open (and the peer never sees a
# TCP FIN) until io_uring drops its file reference. Since
# io_uring_prep_cancel is async, that drop happens at an unspecified
# later time -- the client can wait indefinitely for the EOF that
# tells it "the response is complete".
#
# Symptom: short-lived `Connection: close` HTTP requests appear to
# succeed on the server (response is fully sent) but the client's
# blocking recv() loop never returns 0. Tests like t/2100 hang at
# the first POST.
#
# Fix: call shutdown(fd, SHUT_RDWR) here BEFORE submitting the
# cancel. shutdown operates on the socket directly and unconditionally
# sends FIN to the peer regardless of any reference counts.
# io_uring's struct file ref is irrelevant to whether TCP FIN goes
# out. The caller's close() afterwards still does the right thing
# (marks the fd unused in our process); io_uring will eventually
# release its own ref when the cancel completes async.
#
# Bumping the generation counter (still done) is what closes the
# fd-reuse race: from this moment on, any pending CQE that still
# carries the old generation is silently discarded by gen_get_fd,
# even if accept() reuses the fd number before the cancel completes.
#
# We use io_uring_prep_cancel (not io_uring_prep_poll_remove) because
# poll_remove's signature flipped from void* to __u64 around liburing
# 2.0 whereas prep_cancel's void* user_data is stable from 0.7+.
#
# The cancel SQE carries user_data=0 so its own CQE is cheaply
# distinguishable from real poll CQEs (which always have non-zero
# user_data thanks to the generation in the high 32 bits).
sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;

    $builder->line('{')
      ->line("    if ($fd_var >= 0 && $fd_var < MAX_FD) {")
      ->line("        g_iouring_fd_gen[$fd_var]++;")
      ->line('    }')
      ->comment('Force-send TCP FIN regardless of io_uring file refs')
      ->line("    shutdown($fd_var, SHUT_RDWR);")
      ->line('    struct io_uring_sqe* _dsqe = io_uring_get_sqe(&ring);')
      ->line('    if (_dsqe) {')
      ->line("        io_uring_prep_cancel(_dsqe, (void*)(uintptr_t)$fd_var, 0);")
      ->line('        io_uring_sqe_set_data(_dsqe, NULL);')
      ->line('        io_uring_submit(&ring);')
      ->line('    }')
      ->line('}');
}

# Copy CQEs out of the ring buffer into our private value array, then
# release all consumed ring slots at once with io_uring_cq_advance.
# This avoids BUG 1 (pointer staleness) - we never reference ring
# slots after they've been released. We also lose nothing functionally
# because the only fields we ever need from a CQE are user_data and
# res.
#
# CRUCIAL: do NOT `continue;` on -ETIME or -EINTR. The main loop's
# shutdown-drain branch (which force-closes all connections when
# g_shutdown is set) lives AFTER gen_wait but BEFORE the event-
# processing loop. If we `continue;` here, we never reach that branch,
# and a server with idle keep-alive connections that gets SIGTERMed
# will spin in gen_wait forever (no CQEs arriving means perpetual
# -ETIME). Instead, set count=0 and fall through so the shutdown
# branch runs and the cleanup pass drains the connections. This is
# the same shape as epoll_wait()=0 in the Epoll backend.
sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;

    $builder->line('struct io_uring_cqe* cqe;')
      ->line('struct __kernel_timespec ts;')
      ->line("ts.tv_sec = $timeout_var / 1000;")
      ->line("ts.tv_nsec = ($timeout_var % 1000) * 1000000;")
      ->blank
      ->line("int $count_var = 0;")
      ->line('static hs_iouring_event_t events_buf[MAX_EVENTS];')
      ->line("$events_var = events_buf;")
      ->blank
      ->comment('Block until at least one completion is ready')
      ->line('int wait_result = io_uring_wait_cqe_timeout(&ring, &cqe, &ts);')
      ->if('wait_result == 0')
        ->comment('Drain all currently available CQEs (BUG 1 fix: copy values)')
        ->line('unsigned head;')
        ->line('io_uring_for_each_cqe(&ring, head, cqe) {')
        ->line("    if ($count_var < MAX_EVENTS) {")
        ->line("        events_buf[$count_var].ud  = (uint64_t)(uintptr_t)io_uring_cqe_get_data(cqe);")
        ->line("        events_buf[$count_var].res = cqe->res;")
        ->line("        $count_var++;")
        ->line('    }')
        ->line('}')
        ->line("io_uring_cq_advance(&ring, (unsigned)$count_var);")
      ->elsif('wait_result == -ETIME || wait_result == -EINTR')
        ->comment('Timeout / signal: fall through with count=0 so the')
        ->comment('cleanup-on-shutdown branch can run. Do NOT continue;')
      ->else
        ->line('break;')
      ->endif;
}

# Extract fd from our private value-array CQE. NO io_uring_cqe_seen
# call here - gen_wait already advanced the ring cursor once for the
# whole batch.
#
# Filters applied (any failure -> continue, skip this event):
#   * ud == 0           -> CQE is from a cancel SQE
#   * res < 0           -> poll cancelled/errored (-ECANCELED, -EBADF, ...)
#   * fd out of range   -> defensive guard against corruption
#   * stale generation  -> fd was closed and reused, this CQE is for the
#                          old lifetime (see BUG 2 in defines() comment)
sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;

    $builder->line("uint64_t _ud  = ${events_var}[$index_var].ud;")
      ->line("int      _res = ${events_var}[$index_var].res;")
      ->if('_ud == 0')
        ->line('continue;')  # cancel-SQE completion
      ->endif
      ->if('_res < 0')
        ->line('continue;')  # poll cancelled / errored
      ->endif
      ->line('uint32_t _ud_gen = (uint32_t)(_ud >> 32);')
      ->line("int $fd_var    = (int)(_ud & 0xFFFFFFFFu);")
      ->if("$fd_var < 0 || $fd_var >= MAX_FD")
        ->line('continue;')  # defensive: corrupted user_data
      ->endif
      ->if("_ud_gen != g_iouring_fd_gen[$fd_var]")
        ->line('continue;')  # stale CQE from a previous fd lifetime
      ->endif;
}

# Cleanup io_uring resources
sub gen_cleanup {
    my ($class, $builder) = @_;

    $builder->if('ring_initialized')
      ->line('io_uring_queue_exit(&ring);')
      ->line('ring_initialized = 0;')
    ->endif;
}

# ============================================================
# Async Slot Integration Methods (UA Async)
#
# UA::Async tracks per-slot fd readiness independently of the server
# loop's io_uring ring. We use epoll under the hood since io_uring
# requires Linux 5.1+ which always has epoll, and a separate epoll
# instance is much simpler than weaving slot tracking through the
# server's submission ring.
# ============================================================

sub gen_wait_once {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_ms) = @_;

    $builder->line("$count_var = epoll_wait($loop_var, $events_var, MAX_EVENTS, $timeout_ms);")
      ->line("if ($count_var < 0 && errno == EINTR) $count_var = 0;");
}

sub gen_create_loop {
    my ($class, $builder, $loop_var) = @_;

    $builder->line("$loop_var = epoll_create1(0);")
      ->if("$loop_var < 0")
        ->line('croak("epoll_create1() failed");')
      ->endif;
}

sub gen_add_with_slot {
    my ($class, $builder, $loop_var, $fd_var, $slot_var, $events) = @_;

    my $ev_flags = $events eq 'read' ? 'EPOLLIN | EPOLLET | EPOLLONESHOT'
                 : $events eq 'write' ? 'EPOLLOUT | EPOLLET | EPOLLONESHOT'
                 : 'EPOLLIN | EPOLLET | EPOLLONESHOT';

    $builder->line('{')
      ->line('    struct epoll_event _ev;')
      ->line("    _ev.events = $ev_flags;")
      ->line("    _ev.data.u32 = (uint32_t)$slot_var;")
      ->line("    epoll_ctl($loop_var, EPOLL_CTL_ADD, $fd_var, &_ev);")
      ->line('}');
}

sub gen_get_slot {
    my ($class, $builder, $events_var, $index_var, $slot_var) = @_;

    $builder->line("int $slot_var;")
      ->line("$slot_var = (int)${events_var}[$index_var].data.u32;");
}

# When async-slot helpers above are emitted, the io_uring includes
# already pull in <sys/epoll.h> via the generated Hypersonic includes.
# We don't need to add it here.

# Future/Pool integration: pool_notify_fd is added via the same
# gen_add path as any client fd (just an arm-poll-add on the fd, with
# user_data = fd). We rely on Hypersonic::Event::Role's default
# gen_add_pool_notify which delegates to gen_add. The pre-0.19
# override here used a UD_READ|fd encoding which broke alongside the
# main accept-handoff bug.

1;

__END__

=head1 NAME

Hypersonic::Event::IOUring - io_uring event backend for Linux 5.1+

=head1 SYNOPSIS

    use Hypersonic::Event;

    my $backend = Hypersonic::Event->backend('io_uring');
    # $backend is 'Hypersonic::Event::IOUring'

=head1 DESCRIPTION

C<Hypersonic::Event::IOUring> is the io_uring-based event backend for
Hypersonic on Linux 5.1+. It uses io_uring as a B<readiness
notification> mechanism via C<io_uring_prep_poll_add> (one-shot,
level-triggered C<POLLIN>) and lets the main event loop's userspace
C<accept(2)> and C<recv(2)> calls do the actual I/O - the same model
as the epoll and kqueue backends, but with submissions batched
through the io_uring submission queue.

=head2 Why readiness-only, not completion-based?

Hypersonic versions before 0.19 attempted to use io_uring's
B<completion-based> I/O model (C<io_uring_prep_accept> +
C<io_uring_prep_recv>) where the kernel performs the I/O and returns
the result via C<cqe-E<gt>res>. That design had two unfixable bugs
that produced empty HTTP responses and 5000s+ test hangs on CPAN
smoker hosts:

=over 4

=item *

The C<UD_ACCEPT> completion's C<cqe-E<gt>res> (the new client fd)
was discarded by C<gen_get_fd> and control fell through to the
shared accept loop which called C<accept(listen_fd)> - getting
C<EAGAIN> because the kernel had already handed the connection to
io_uring. The connection was leaked.

=item *

C<UD_READ> used C<io_uring_prep_recv> into a B<single global>
C<recv_buf>, so multiple concurrent clients would corrupt each
other's request data.

=back

The readiness-only design is simpler, correct, and still benefits
from io_uring's batched submission queue (one syscall to arm many
polls). Native completion-based I/O could be added in a future
release with per-fd buffers and a redesigned accept loop, but is
out of scope for the 0.19 fix.

=head1 METHODS

=head2 name

    my $name = Hypersonic::Event::IOUring->name;  # 'io_uring'

Returns the backend name.

=head2 available

    if (Hypersonic::Event::IOUring->available) { ... }

Returns true if this backend is available. Requires:

=over 4

=item * Linux kernel 5.1 or later

=item * liburing library installed (liburing-dev package)

=back

=head2 includes

Returns the C #include directives needed for io_uring.

=head2 defines

Returns the C #define directives for io_uring configuration,
including user data encoding macros.

=head2 event_struct

    my $struct = Hypersonic::Event::IOUring->event_struct;  # 'io_uring_cqe'

Returns the C struct name used for completion queue entries.

=head2 extra_ldflags

    my $flags = Hypersonic::Event::IOUring->extra_ldflags;  # '-luring'

Returns linker flags needed for liburing.

=head2 gen_create($builder, $listen_fd_var)

Generates C code to initialize the io_uring and submit the first accept.

=head2 gen_add($builder, $loop_var, $fd_var)

Generates C code to submit a recv operation for a file descriptor.

=head2 gen_del($builder, $loop_var, $fd_var)

Generates C code to close a file descriptor (pending operations
will complete with an error).

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generates C code to wait for completions with a timeout.

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generates C code to extract the operation type and file descriptor
from a completion queue entry.

=head2 gen_cleanup($builder)

Generates C code to clean up io_uring resources on shutdown.

=head1 USER DATA ENCODING

As of 0.19, user_data is just the file descriptor cast to C<void*>.
The old high-bit-operation-type encoding (UD_ACCEPT / UD_READ /
UD_WRITE / UD_FD_MASK) was removed when the backend was rewritten
in readiness-only mode. Cancel submissions get NULL user_data so
the completion handler can filter them out cheaply.

=head1 PERFORMANCE

io_uring can achieve 1.5-2x the throughput of epoll for high-concurrency
workloads due to:

=over 4

=item * Batched submissions (fewer syscalls)

=item * Zero-copy I/O paths

=item * Optional kernel-side polling (IORING_SETUP_SQPOLL)

=back

=head1 REQUIREMENTS

=over 4

=item * Linux kernel 5.1 or later

=item * liburing library: C<apt install liburing-dev> (Debian/Ubuntu)
or C<dnf install liburing-devel> (Fedora/RHEL)

=back

=head1 AVAILABILITY

Linux 5.1+ with liburing installed.

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Role>, L<Hypersonic::Event::Epoll>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
