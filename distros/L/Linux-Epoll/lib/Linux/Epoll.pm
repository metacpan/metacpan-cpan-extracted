package Linux::Epoll;
$Linux::Epoll::VERSION = '0.012';
use 5.010;
use strict;
use warnings FATAL => 'all';

use parent 'IO::Handle';

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: O(1) multiplexing for Linux

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Epoll - O(1) multiplexing for Linux

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 use Linux::Epoll;

 my $epoll = Linux::Epoll->new();
 $epoll->add($fh, 'in', sub {
     my $events = shift;
     do_something($fh) if $events->{in};
 });
 $epoll->wait while 1;

=head1 DESCRIPTION

Epoll is a multiplexing mechanism that scales up O(1) with number of watched files. Linux::Epoll is a callback style epoll module, unlike other epoll modules available on CPAN.

=head2 Types of events

=over 4

=item * in

The associated filehandle is availible for reading.

=item * out

The associated filehandle is availible for writing.

=item * err

An error condition has happened on the associated filehandle. C<wait> will always wait on this event, it is not necessary to set this with C<add> or C<modify>.

=item * prio

There is urgent data available for reading.

=item * et

Set edge triggered behavior for the associated filehandle. The default behavior is level triggered. See you L<epoll(7)> documentation for more information on what this means.

=item * hup

A hang-up has happened on the associated filehandle. C<wait> will always wait on this event, it is not necessary to set this with C<add> or C<modify>.

=item * rdhup

Stream socket peer closed the connection, or shut down the writing half of connection. This flag is especially useful for writing simple code to detect peer shutdown when using Edge Triggered monitoring.

=item * oneshot

Sets the one-shot behavior for the associated file descriptor. This means that after an event is pulled out with C<wait> the associated file descriptor is internally disabled and no other events will be reported by the epoll interface. The user must call C<modify> to rearm the file descriptor with a new event mask.

=back

=head1 METHODS

=head2 new()

Create a new epoll instance.

=head2 add($fh, $events, $callback)

Register the filehandle with the epoll instance and associate events C<$events> and callback C<$callback> with it. C<$events> may be either a string (e.g. C<'in'>) or an arrayref (e.g. C<[qw/in out hup/]>). If a filehandle already exists in the set and C<add> is called in non-void context, it returns undef and sets C<$!> to C<EEXIST>; if the file can't be waited upon it sets C<$!> to C<EPERM> instead. On all other error conditions an exception is thrown. The callback gets a single argument, a hashref whose keys are the triggered events.

=head2 modify($fh, $events, $callback)

Change the events and callback associated on this epoll instance with filehandle $fh. The arguments work the same as with C<add>. If a filehandle doesn't exist in the set and C<modify> is called in non-void context, it returns undef and sets C<$!> to C<ENOENT>. On all other error conditions an exception is thrown.

=head2 delete($fh)

Remove a filehandle from the epoll instance. If a filehandle doesn't exist in the set and C<delete> is called in non-void context, it returns undef and sets C<$!> to C<ENOENT>. On all other error conditions an exception is thrown.

=head2 wait($number = 1, $timeout = undef, $sigmask = undef)

Wait for up to C<$number> events, where C<$number> must be greater than zero. C<$timeout> is the maximal time C<wait> will wait for events in fractional seconds. If it is undefined it may wait indefinitely. C<$sigmask> is the signal mask during the call. If it is not defined the signal mask will be untouched. If interrupted by a signal it returns undef/an empty list and sets C<$!> to C<EINTR>. On all other error conditions an exception is thrown.

=head1 REQUIREMENTS

This module requires at least Perl 5.10 and Linux 2.6.19 to function correctly.

=head1 SEE ALSO

=over 4

=item * L<IO::Epoll>

=item * L<Sys::Syscall>

=item * L<IO::Poll>

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
