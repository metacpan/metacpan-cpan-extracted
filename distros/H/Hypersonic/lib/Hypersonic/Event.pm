package Hypersonic::Event;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

# Hypersonic::Event - Event backend registry and selection
#
# This module provides a central registry for event loop backends and
# automatic detection of the best available backend for the platform.
# All event loop implementations are JIT-compiled via XS::JIT::Builder.

# Backend registry - maps name to module
my %BACKENDS = (
    io_uring    => 'Hypersonic::Event::IOUring',     # Linux 5.1+ (fastest)
    epoll       => 'Hypersonic::Event::Epoll',       # Linux (fast)
    kqueue      => 'Hypersonic::Event::Kqueue',      # BSD/macOS (fast)
    iocp        => 'Hypersonic::Event::IOCP',        # Windows (fast, completion-based)
    event_ports => 'Hypersonic::Event::EventPorts',  # Solaris/illumos (fast)
    poll        => 'Hypersonic::Event::Poll',        # POSIX fallback
    select      => 'Hypersonic::Event::Select',      # Universal (Windows support)
);

# Priority order for auto-selection (first available wins)
my @PRIORITY = qw(io_uring epoll kqueue iocp event_ports poll select);

# Check if io_uring is available (Linux 5.1+ with liburing)
sub _has_io_uring {
    return 0 unless $^O eq 'linux';

    # Check kernel version >= 5.1
    my $ver = `uname -r 2>/dev/null` || '';
    my ($major, $minor) = $ver =~ /^(\d+)\.(\d+)/;
    return 0 unless $major && ($major > 5 || ($major == 5 && $minor >= 1));

    # Check for liburing.h in common locations
    for my $path (
        '/usr/include/liburing.h',
        '/usr/local/include/liburing.h',
        '/usr/include/x86_64-linux-gnu/liburing.h',
    ) {
        return 1 if -f $path;
    }

    return 0;
}

# Select best available backend for this platform
sub best_backend {
    my $class = shift;

    # Windows prefers IOCP (falls back to select if unavailable)
    if ($^O eq 'MSWin32') {
        my $mod = $BACKENDS{iocp};
        eval "require $mod";
        return 'iocp' if !$@ && $mod->available;
        return 'select';
    }

    for my $name (@PRIORITY) {
        my $mod = $BACKENDS{$name} or next;

        # Try to load the module
        eval "require $mod";
        next if $@;

        # Check if it's available on this platform
        next unless $mod->available;

        return $name;
    }

    die "No event backend available for platform: $^O";
}

# Get backend module by name (loads if needed)
sub backend {
    my ($class, $name) = @_;
    $name //= $class->best_backend;

    my $mod = $BACKENDS{$name}
        or die "Unknown event backend: $name (available: " . join(', ', sort keys %BACKENDS) . ")";

    eval "require $mod" or die "Cannot load $mod: $@";

    die "$mod is not available on this platform"
        unless $mod->available;

    return $mod;
}

# List all backends that work on this system
sub available_backends {
    my $class = shift;
    my @available;

    for my $name (@PRIORITY) {
        my $mod = $BACKENDS{$name} or next;

        eval "require $mod";
        next if $@;

        push @available, $name if $mod->available;
    }

    return @available;
}

# Return the backend priority order
sub backend_priority {
    return @PRIORITY;
}

# List all registered backends (whether available or not)
sub all_backends {
    return sort keys %BACKENDS;
}

# Register a custom backend
sub register_backend {
    my ($class, $name, $module) = @_;

    die "Backend name required" unless $name;
    die "Module name required" unless $module;

    $BACKENDS{$name} = $module;

    return 1;
}

# Unregister a backend
sub unregister_backend {
    my ($class, $name) = @_;
    delete $BACKENDS{$name};
}

1;

__END__

=head1 NAME

Hypersonic::Event - Event backend registry and selection

=head1 SYNOPSIS

    use Hypersonic::Event;

    # Auto-detect best backend for this platform
    my $backend_name = Hypersonic::Event->best_backend;
    # Returns: 'kqueue' on macOS, 'epoll' on Linux, etc.

    # Get the backend module
    my $backend = Hypersonic::Event->backend;           # Auto-detect
    my $backend = Hypersonic::Event->backend('epoll');  # Specific

    # List available backends on this system
    my @available = Hypersonic::Event->available_backends;
    # e.g., ('epoll', 'poll', 'select') on Linux

    # Register a custom backend
    Hypersonic::Event->register_backend('mybackend', 'My::Event::Backend');

=head1 DESCRIPTION

C<Hypersonic::Event> is the central registry for event loop backends
in Hypersonic. It provides automatic detection of the best available
backend for the current platform and lazy-loading of backend modules.

=head2 Backend Priority

When auto-detecting, backends are tried in this order:

=over 4

=item 1. C<io_uring> - Linux 5.1+ with liburing (fastest)

=item 2. C<epoll> - Linux (fast, edge-triggered)

=item 3. C<kqueue> - BSD/macOS (fast)

=item 4. C<iocp> - Windows I/O Completion Ports (fast, completion-based)

=item 5. C<event_ports> - Solaris/illumos (fast, one-shot)

=item 6. C<poll> - POSIX systems (O(n) but portable)

=item 7. C<select> - Universal including Windows (slowest, FD_SETSIZE limit)

=back

=head1 CLASS METHODS

=head2 best_backend

    my $name = Hypersonic::Event->best_backend;

Returns the name of the best available backend for the current platform.
Dies if no backend is available.

=head2 backend

    my $module = Hypersonic::Event->backend;
    my $module = Hypersonic::Event->backend($name);

Returns the backend module (class name) for the given backend name.
If no name is provided, uses C<best_backend()>.

The module is loaded via C<require> if not already loaded.
Dies if the backend is unknown or not available on this platform.

=head2 available_backends

    my @names = Hypersonic::Event->available_backends;

Returns a list of backend names that are available on the current system.
Backends are returned in priority order.

=head2 all_backends

    my @names = Hypersonic::Event->all_backends;

Returns a list of all registered backend names (whether available or not).

=head2 register_backend

    Hypersonic::Event->register_backend($name, $module);

Register a custom backend. The module must implement the backend interface
(see L<Hypersonic::Event::Epoll> for an example).

=head2 unregister_backend

    Hypersonic::Event->unregister_backend($name);

Remove a backend from the registry.

=head1 BACKEND INTERFACE

Each backend module must implement these methods:

=over 4

=item * C<name()> - Return the backend name string

=item * C<available()> - Return true if usable on this platform

=item * C<includes()> - Return C #include directives

=item * C<defines()> - Return C #define directives

=item * C<event_struct()> - Return the C struct name for events

=item * C<gen_create($builder, $listen_fd_var)> - Generate event loop creation

=item * C<gen_add($builder, $loop_var, $fd_var)> - Generate fd add

=item * C<gen_del($builder, $loop_var, $fd_var)> - Generate fd remove

=item * C<gen_wait($builder, $loop_var, $events_var, $count_var, $timeout_var)> - Generate wait

=item * C<gen_get_fd($builder, $events_var, $index_var, $fd_var)> - Generate fd extraction

=back

Optional methods:

=over 4

=item * C<extra_cflags()> - Additional compiler flags

=item * C<extra_ldflags()> - Additional linker flags

=back

=head1 SEE ALSO

L<Hypersonic>, L<Hypersonic::Event::Epoll>, L<Hypersonic::Event::Kqueue>,
L<Hypersonic::Event::Poll>, L<Hypersonic::Event::Select>,
L<Hypersonic::Event::IOUring>, L<Hypersonic::Event::IOCP>,
L<Hypersonic::Event::EventPorts>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
