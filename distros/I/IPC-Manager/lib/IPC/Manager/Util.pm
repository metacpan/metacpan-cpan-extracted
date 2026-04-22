package IPC::Manager::Util;
use strict;
use warnings;

our $VERSION = '0.000029';

use Carp qw/croak/;
use Errno qw/ESRCH/;

BEGIN {
    if (eval { require IO::Select; 1 }) {
        *USE_IO_SELECT = sub() { 1 };
    }
    else {
        *USE_IO_SELECT = sub() { 0 };
    }

    if (eval { require Linux::Inotify2; Linux::Inotify2->can('fh') ? 1 : 0 }) {
        *USE_INOTIFY = sub() { 1 };
    }
    else {
        *USE_INOTIFY = sub() { 0 };
    }
}

use Importer Importer => 'import';

our @EXPORT_OK = qw{
    USE_INOTIFY
    USE_IO_SELECT
    require_mod
    pid_is_running
    clone_io
    tinysleep
};

# Sub-second sleep that returns early when interrupted by a signal.
# Time::HiRes::sleep restarts on EINTR, which delays signal-driven loops by
# up to a full cycle. select() with a timeout returns immediately on EINTR.
sub tinysleep {
    my ($secs) = @_;
    return unless defined($secs) && $secs > 0;
    select(undef, undef, undef, $secs);
    return;
}

sub require_mod {
    my $mod = shift;

    my $file = $mod;
    $file =~ s{::}{/}g;
    $file .= ".pm";

    require($file);

    return $mod;
}

sub pid_is_running {
    my $pid = pop;

    croak "A pid is required" unless $pid;

    local $!;

    return 1 if kill(0, $pid);    # Running and we have perms
    return 0 if $! == ESRCH;      # Does not exist (not running)
    return -1;                    # Running, but not ours
}

sub clone_io {
    my ($mode, $orig) = @_;
    croak "No mode provided" unless $mode;
    croak "No handle provided" unless $orig;
    open(my $fh, $mode, $orig) or die "Could not clone filehandle: $!";
    return $fh;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Util - Utility functions for IPC::Manager

=head1 DESCRIPTION

This module provides utility functions used throughout the IPC::Manager
distribution.

=head1 EXPORTS

The following functions are available via C<use IPC::Manager::Util qw(...)>:

=over 4

=item $bool = USE_INOTIFY()

Returns true if the L<Linux::Inotify2> module is available and supports the
C<fh> method.

This can be used as a constant.

=item $bool = USE_IO_SELECT()

Returns true if the L<IO::Select> module is available.

=item $mod = require_mod($module)

Loads a module by name. Converts C<::> to C</> and appends C<.pm>.

Returns the original input.

=item $val = pid_is_running($pid)

Checks if a PID is running.

returns 1 if the process is running and we have permissions.

returns 0 if the process does not exist.

return -1 if the process is running but we don't have permissions to do
anything with it.

=item $fh = clone_io($mode, $orig)

Clones a filehandle. C<$mode> is the open mode (e.g. C<< '<' >>, C<< '>' >>,
C<< '+<' >>), and C<$orig> is the filehandle to clone.

Returns the filehandle clone.

=item tinysleep($seconds)

Sleeps for up to C<$seconds> seconds (sub-second resolution allowed) using a
4-arg C<select()> under the hood.  Unlike L<Time::HiRes/sleep>, which restarts
on C<EINTR>, this returns immediately when a signal handler fires.  Use this
in polling loops whose progress depends on signals (C<SIGCHLD>, C<SIGTERM>,
user-installed handlers, etc).

Returns nothing.  Like C<Time::HiRes::sleep>, the actual time slept may be
shorter than requested when a signal interrupts it; callers that require a
minimum elapsed time should use a deadline loop.

C<$seconds> values that are undefined or non-positive are treated as a no-op.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
