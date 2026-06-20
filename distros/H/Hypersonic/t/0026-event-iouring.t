use strict;
use warnings;
use Test::More;


# Test Hypersonic::Event::IOUring backend
use_ok('Hypersonic::Event::IOUring');

# Test basic properties (even if not available)
subtest 'Basic properties' => sub {
    is(Hypersonic::Event::IOUring->name, 'io_uring', 'name() returns io_uring');
};

# Test platform availability
subtest 'Platform availability' => sub {
    if ($^O ne 'linux') {
        ok(!Hypersonic::Event::IOUring->available, "Not available on $^O (Linux only)");
        note('io_uring is Linux-specific, skipping detailed tests');
    } else {
        # On Linux, check kernel version and liburing
        my $available = Hypersonic::Event::IOUring->available;
        if ($available) {
            pass('io_uring available on this Linux system');
        } else {
            note('io_uring not available (requires Linux 5.13+, liburing 2.1+, and io_uring_prep_poll_multishot)');
            pass('io_uring correctly reports unavailable');
        }
    }
};

# Skip remaining tests if not available
if (!Hypersonic::Event::IOUring->available) {
    done_testing();
    exit;
}

# Test includes
subtest 'C includes' => sub {
    my $includes = Hypersonic::Event::IOUring->includes;
    ok($includes, 'includes() returns value');
    like($includes, qr/liburing\.h/, 'Includes liburing.h');
    like($includes, qr/poll\.h/, 'Includes poll.h for POLLIN');
};

# Test defines
subtest 'C defines' => sub {
    my $defines = Hypersonic::Event::IOUring->defines;
    ok($defines, 'defines() returns value');
    like($defines, qr/EV_BACKEND_IO_URING/, 'Defines EV_BACKEND_IO_URING');
    like($defines, qr/URING_ENTRIES/, 'Defines URING_ENTRIES');

    # 0.19+ uses readiness-only with per-fd generation counter, not
    # the old completion-based UD_* encoding which was removed.
    like($defines, qr/hs_iouring_event_t/, 'Declares value-copy event struct');
    like($defines, qr/g_iouring_fd_gen/, 'Declares per-fd generation counter');
    like($defines, qr/HS_IOURING_UD/, 'Defines user_data packing macro');
    unlike($defines, qr/UD_ACCEPT|UD_READ|UD_WRITE|UD_FD_MASK/,
           'Old completion-based UD_* encoding is GONE (was unfixable)');
};

# Test event_struct
subtest 'Event struct' => sub {
    is(Hypersonic::Event::IOUring->event_struct, 'io_uring_cqe',
       'event_struct is still io_uring_cqe (informational only - actual storage is hs_iouring_event_t)');
};

# Test extra flags
subtest 'Extra compiler flags' => sub {
    my $cflags = Hypersonic::Event::IOUring->extra_cflags;
    my $ldflags = Hypersonic::Event::IOUring->extra_ldflags;

    is($cflags, '', 'No extra cflags needed');
    like($ldflags, qr/-luring/, 'Requires -luring linker flag');
};

# Test code generation methods with mock builder
subtest 'Code generation methods' => sub {
    # Create a simple mock builder
    my @code;
    my $mock_builder = bless {}, 'MockBuilder';

    {
        no strict 'refs';
        for my $method (qw(line comment blank if endif else elsif while endwhile)) {
            *{"MockBuilder::$method"} = sub {
                my ($self, $code) = @_;
                push @code, $code if defined $code;
                return $self;
            };
        }
    }

    # Test gen_create - uses multi-shot poll on the listen fd
    @code = ();
    Hypersonic::Event::IOUring->gen_create($mock_builder, 'listen_fd');
    ok(scalar @code > 0, 'gen_create generates code');
    ok(grep(/io_uring_queue_init/, @code), 'gen_create initializes the ring');
    ok(grep(/io_uring_get_sqe/, @code), 'gen_create gets an SQE');
    ok(grep(/io_uring_prep_poll_multishot/, @code),
       'gen_create arms multi-shot poll (not prep_accept - readiness-only design)');
    ok(grep(/g_iouring_fd_gen\[listen_fd\]\+\+/, @code),
       'gen_create bumps generation for fd-reuse race safety');
    ok(!grep(/io_uring_prep_accept/, @code),
       'gen_create does NOT use prep_accept (broken pre-0.19 API)');

    # Test gen_add - arms multi-shot poll on a client fd
    @code = ();
    Hypersonic::Event::IOUring->gen_add($mock_builder, 'ev_fd', 'client_fd');
    ok(scalar @code > 0, 'gen_add generates code');
    ok(grep(/io_uring_prep_poll_multishot/, @code), 'gen_add arms multi-shot poll');
    ok(grep(/g_iouring_fd_gen\[client_fd\]\+\+/, @code),
       'gen_add bumps generation');
    ok(grep(/io_uring_submit/, @code), 'gen_add submits');
    ok(!grep(/io_uring_prep_recv/, @code),
       'gen_add does NOT use prep_recv (broken pre-0.19 - shared global recv_buf)');

    # Test gen_del - cancels poll via prep_cancel (NOT close)
    @code = ();
    Hypersonic::Event::IOUring->gen_del($mock_builder, 'ev_fd', 'client_fd');
    ok(scalar @code > 0, 'gen_del generates code');
    ok(grep(/io_uring_prep_cancel/, @code),
       'gen_del uses prep_cancel (stable void* user_data signature)');
    ok(grep(/g_iouring_fd_gen\[client_fd\]\+\+/, @code),
       'gen_del bumps generation - this is what actually closes the fd-reuse race');
    ok(!grep(/^close\(|\sclose\(/, @code),
       'gen_del does NOT close fd (caller owns the close - prevents double-close bug)');

    # Test gen_wait - drains the ring into a value array
    @code = ();
    Hypersonic::Event::IOUring->gen_wait($mock_builder, 'ev_fd', 'events', 'n', '1000');
    ok(scalar @code > 0, 'gen_wait generates code');
    ok(grep(/io_uring_wait_cqe_timeout/, @code), 'gen_wait blocks with timeout');
    ok(grep(/io_uring_for_each_cqe/, @code), 'gen_wait iterates available CQEs');
    ok(grep(/io_uring_cq_advance/, @code),
       'gen_wait advances ring cursor ONCE for the whole batch (BUG 1 fix)');
    ok(grep(/hs_iouring_event_t/, @code),
       'gen_wait copies values into a private array (not cached pointers - BUG 1 fix)');
    ok(grep(/kernel_timespec|__kernel_timespec/, @code), 'gen_wait uses kernel timespec');

    # Test gen_get_fd - reads from value array, checks generation
    @code = ();
    Hypersonic::Event::IOUring->gen_get_fd($mock_builder, 'events', 'i', 'fd');
    ok(scalar @code > 0, 'gen_get_fd generates code');
    ok(grep(/g_iouring_fd_gen/, @code),
       'gen_get_fd checks generation counter for stale-CQE filtering (BUG 2 fix)');
    ok(!grep(/io_uring_cqe_seen/, @code),
       'gen_get_fd does NOT call cqe_seen - gen_wait already advanced the cursor');
    ok(!grep(/io_uring_cqe_get_data/, @code),
       'gen_get_fd reads from the value-copy array, not the live ring');
};

# Test cleanup method if present
subtest 'Cleanup' => sub {
    if (Hypersonic::Event::IOUring->can('gen_cleanup')) {
        my @code;
        my $mock_builder = bless {}, 'MockBuilder2';

        {
            no strict 'refs';
            for my $method (qw(line comment blank if endif else elsif while endwhile)) {
                *{"MockBuilder2::$method"} = sub {
                    my ($self, $code) = @_;
                    push @code, $code if defined $code;
                    return $self;
                };
            }
        }

        Hypersonic::Event::IOUring->gen_cleanup($mock_builder);
        ok(grep(/io_uring_queue_exit/, @code), 'Cleanup calls io_uring_queue_exit');
    } else {
        pass('gen_cleanup not implemented (optional)');
    }
};

# Test inheritance
subtest 'Inheritance' => sub {
    require Hypersonic::Event::Role;
    ok(Hypersonic::Event::IOUring->isa('Hypersonic::Event::Role'),
       'IOUring inherits from Role');
};

done_testing();
