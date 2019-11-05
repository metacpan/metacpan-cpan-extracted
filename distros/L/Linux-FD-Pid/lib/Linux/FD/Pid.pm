package Linux::FD::Pid;
$Linux::FD::Pid::VERSION = '0.001';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: PID file descriptors

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::FD::Pid - PID file descriptors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Linux::FD::Pid
 
 my $fh = Linux::FD::Pid($pid)

=head1 METHODS

=head2 new($pid)

This creates a pidfd file descriptor that can be used to await the termination of a process. This provides an alternative to using C<SIGCHLD>, and has the advantage that the file descriptor may be monitored by select, poll, and epoll.

Note that it doesn't (and for now can't) do the actual waiting, one still needs C<waitpid> for that.

=head2 send($signo)

This sends a signal to the process.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
