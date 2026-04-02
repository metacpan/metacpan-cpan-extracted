package Hypersonic::Event::Role;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

# Hypersonic::Event::Role - Base class for event backends
#
# This module defines the interface that all event backends must implement.
# Backends should inherit from this class to get default implementations
# of optional methods and clear error messages for missing required methods.

# ============================================================
# Required Methods - backends MUST override these
# ============================================================

sub name {
    my $class = shift;
    die "$class must implement name()";
}

sub available {
    my $class = shift;
    die "$class must implement available()";
}

sub includes {
    my $class = shift;
    die "$class must implement includes()";
}

sub defines {
    my $class = shift;
    die "$class must implement defines()";
}

sub event_struct {
    my $class = shift;
    die "$class must implement event_struct()";
}

sub gen_create {
    my ($class, $builder, $listen_fd_var) = @_;
    die "$class must implement gen_create(\$builder, \$listen_fd_var)";
}

sub gen_add {
    my ($class, $builder, $loop_var, $fd_var) = @_;
    die "$class must implement gen_add(\$builder, \$loop_var, \$fd_var)";
}

sub gen_del {
    my ($class, $builder, $loop_var, $fd_var) = @_;
    die "$class must implement gen_del(\$builder, \$loop_var, \$fd_var)";
}

sub gen_wait {
    my ($class, $builder, $loop_var, $events_var, $count_var, $timeout_var) = @_;
    die "$class must implement gen_wait(\$builder, \$loop_var, \$events_var, \$count_var, \$timeout_var)";
}

sub gen_get_fd {
    my ($class, $builder, $events_var, $index_var, $fd_var) = @_;
    die "$class must implement gen_get_fd(\$builder, \$events_var, \$index_var, \$fd_var)";
}

# ============================================================
# Optional Methods - backends MAY override these
# ============================================================

# Additional compiler flags (e.g., -I/path/to/headers)
sub extra_cflags { '' }

# Additional linker flags (e.g., -luring)
sub extra_ldflags { '' }

# One-time initialization code (called once at start)
sub gen_init {
    my ($class, $builder) = @_;
    # Default: no-op
}

# Cleanup code (called on shutdown)
sub gen_cleanup {
    my ($class, $builder) = @_;
    # Default: no-op
}

# ============================================================
# Async Slot Integration Methods (UA Async)
# ============================================================

# Generate: add fd with slot as user data
# slot_var is an integer slot ID that will be stored with the fd
# events: 'read', 'write', or 'both'
sub gen_add_with_slot {
    my ($class, $builder, $loop_var, $fd_var, $slot_var, $events) = @_;
    # Default implementation - subclasses should override
    die "$class must implement gen_add_with_slot(\$builder, \$loop_var, \$fd_var, \$slot_var, \$events)";
}

# Generate: extract slot from event (returns the user data)
sub gen_get_slot {
    my ($class, $builder, $events_var, $index_var, $slot_var) = @_;
    die "$class must implement gen_get_slot(\$builder, \$events_var, \$index_var, \$slot_var)";
}

# Generate: create event loop (without listen socket)
sub gen_create_loop {
    my ($class, $builder, $loop_var) = @_;
    # Default - call gen_create with dummy fd
    die "$class must implement gen_create_loop(\$builder, \$loop_var)";
}

# ============================================================
# Future/Pool Integration Methods (Single Pool - Legacy)
# ============================================================

# Generate code to add the Future pool notify fd to the event loop
# Called during event loop setup when pool is available
sub gen_add_pool_notify {
    my ($class, $builder, $loop_var, $notify_fd_var) = @_;
    # Default: use gen_add
    $class->gen_add($builder, $loop_var, $notify_fd_var);
}

# Generate code to check if the current fd is the pool notify fd
# Should set a variable indicating this is a pool notification
sub gen_check_pool_notify {
    my ($class, $builder, $fd_var, $notify_fd_var, $is_pool_var) = @_;
    $builder->line("int $is_pool_var = ($fd_var == $notify_fd_var);");
}

# Generate code to process pool notifications (call pool_process_ready)
sub gen_process_pool_ready {
    my ($class, $builder) = @_;
    $builder->line('/* Process completed async operations */')
            ->line('extern int xs_pool_process_ready(pTHX_ CV *cv);')
            ->line('xs_pool_process_ready(aTHX_ NULL);');
}

# ============================================================
# Multi-Pool Integration Methods (OO API)
# ============================================================

# Generate code to add multiple pool notify fds to the event loop
# pool_slots is an array variable, pool_count is the count
sub gen_add_multi_pool_notify {
    my ($class, $builder, $loop_var, $pool_slots_var, $pool_count_var) = @_;

    $builder->line("/* Add all pool notify fds to event loop */")
            ->line("{ int _pi; int _pool_notify_fd;")
            ->line("for (_pi = 0; _pi < $pool_count_var; _pi++) {")
            ->line("    _pool_notify_fd = pool_get_notify_fd_slot($pool_slots_var\[_pi]);")
            ->line("    if (_pool_notify_fd >= 0) {");

    # Use the backend's gen_add method - inline the generated code
    $class->gen_add($builder, $loop_var, '_pool_notify_fd');

    $builder->line("    }")
            ->line("} }");
}

# Generate code to check if fd matches any pool's notify_fd
# Sets matched_slot_var to the pool slot if matched, -1 otherwise
sub gen_check_multi_pool_notify {
    my ($class, $builder, $fd_var, $pool_slots_var, $pool_count_var, $matched_slot_var) = @_;

    $builder->line("int $matched_slot_var = -1;")
            ->line("{ int _pi; int _pslot;")
            ->line("for (_pi = 0; _pi < $pool_count_var; _pi++) {")
            ->line("    _pslot = $pool_slots_var\[_pi];")
            ->line("    if ($fd_var == pool_get_notify_fd_slot(_pslot)) {")
            ->line("        $matched_slot_var = _pslot;")
            ->line("        break;")
            ->line("    }")
            ->line("} }");
}

# Generate code to process a specific pool's completed operations
sub gen_process_pool_slot {
    my ($class, $builder, $slot_var) = @_;
    $builder->line("/* Process completed async operations for pool slot */")
            ->line("pool_process_ready_slot($slot_var);");
}

# ============================================================
# Utility Methods for Backends
# ============================================================

# Check if a header file exists
sub _has_header {
    my ($class, @paths) = @_;
    for my $path (@paths) {
        return 1 if -f $path;
    }
    return 0;
}

# Check if a library exists (file check only - use _can_link for full verification)
sub _has_library {
    my ($class, $lib) = @_;
    # Check common library paths
    for my $dir (qw(/usr/lib /usr/local/lib /lib /lib64 /usr/lib64)) {
        return 1 if -f "$dir/lib$lib.so" || -f "$dir/lib$lib.a" || -f "$dir/lib$lib.dylib";
    }
    return 0;
}

# Check if a library can actually be linked (compile+link test)
# Delegates to centralized Hypersonic::JIT::Util
sub _can_link {
    my ($class, $lib_flag, $test_symbol, $extra_includes) = @_;
    require Hypersonic::JIT::Util;
    return Hypersonic::JIT::Util->can_link('', $lib_flag, $test_symbol, $extra_includes);
}

1;

__END__

=head1 NAME

Hypersonic::Event::Role - Base class for event backends

=head1 SYNOPSIS

    package Hypersonic::Event::MyBackend;
    use parent 'Hypersonic::Event::Role';

    sub name { 'mybackend' }

    sub available {
        # Return true if this backend works on current platform
        return $^O eq 'myos';
    }

    sub includes {
        return '#include <mybackend.h>';
    }

    sub defines {
        return '#define USE_MYBACKEND 1';
    }

    sub event_struct { 'mybackend_event' }

    sub gen_create {
        my ($class, $builder, $listen_fd_var) = @_;
        $builder->line("int ev_fd = mybackend_create();");
        # ... more code generation
    }

    # ... implement other gen_* methods

    1;

=head1 DESCRIPTION

C<Hypersonic::Event::Role> is the base class for all event loop backends
in Hypersonic. It defines the interface contract and provides default
implementations for optional methods.

Backends should inherit from this class using C<use parent>.

=head1 REQUIRED METHODS

These methods MUST be implemented by every backend:

=head2 name

    sub name { 'epoll' }

Return the backend name as a string.

=head2 available

    sub available { $^O eq 'linux' }

Return true if this backend is available on the current platform.

=head2 includes

    sub includes { '#include <sys/epoll.h>' }

Return C preprocessor #include directives needed by this backend.

=head2 defines

    sub defines { '#define USE_EPOLL 1' }

Return C preprocessor #define directives.

=head2 event_struct

    sub event_struct { 'epoll_event' }

Return the C struct name used for the events array.

=head2 gen_create($builder, $listen_fd_var)

Generate C code to create the event loop and register the listen socket.

    sub gen_create {
        my ($class, $builder, $listen_fd_var) = @_;
        $builder->line("int ev_fd = epoll_create1(0);")
          ->line("/* ... */");
    }

=head2 gen_add($builder, $loop_var, $fd_var)

Generate C code to add a file descriptor to the event loop.

=head2 gen_del($builder, $loop_var, $fd_var)

Generate C code to remove a file descriptor from the event loop.

=head2 gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)

Generate C code to wait for events with a timeout.

=head2 gen_get_fd($builder, $events_var, $index_var, $fd_var)

Generate C code to extract the file descriptor from an event.

=head1 OPTIONAL METHODS

These methods have default implementations but MAY be overridden:

=head2 extra_cflags

    sub extra_cflags { '-I/opt/mylib/include' }

Return additional compiler flags. Default: empty string.

=head2 extra_ldflags

    sub extra_ldflags { '-luring' }

Return additional linker flags. Default: empty string.

=head2 gen_init($builder)

Generate one-time initialization code. Default: no-op.

=head2 gen_cleanup($builder)

Generate cleanup code for shutdown. Default: no-op.

=head1 UTILITY METHODS

=head2 _has_header(@paths)

    if ($class->_has_header('/usr/include/foo.h')) { ... }

Check if any of the given header files exist.

=head2 _has_library($name)

    if ($class->_has_library('uring')) { ... }

Check if a library exists in common library paths.

=head1 VARIABLE NAMING CONVENTION

When generating C code, use these variable names for consistency:

    ev_fd       - Event loop file descriptor
    listen_fd   - Server listen socket
    client_fd   - Accepted client socket
    events      - Array of event structures
    n           - Number of ready events
    i           - Loop index
    fd          - Current file descriptor being processed

=head1 SEE ALSO

L<Hypersonic::Event>, L<Hypersonic::Event::Epoll>, L<Hypersonic::Event::Kqueue>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
