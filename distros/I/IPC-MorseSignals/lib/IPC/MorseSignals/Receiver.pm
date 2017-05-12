package IPC::MorseSignals::Receiver;

use strict;
use warnings;

use Carp qw/croak/;

use Bit::MorseSignals::Receiver;
use base qw/Bit::MorseSignals::Receiver/;

=head1 NAME

IPC::MorseSignals::Receiver - Base class for IPC::MorseSignals receivers.

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

    use IPC::MorseSignals::Receiver;

    local %SIG;
    my $pants = IPC::MorseSignals::Receiver->new(\%SIG, done => sub {
     print STDERR "GOT $_[1]\n";
    });

=head1 DESCRIPTION

This module installs C<$SIG{qw/USR1 USR2/}> handlers and forwards the bits received to an underlying L<Bit::MorseSignals> receiver.

=head1 METHODS

=head2 C<new>

Creates a new receiver object. Its arguments are passed to L<Bit::MorseSignals::Receiver/new>, in particular the C<done> callback.

=cut

sub new {
 my $class = shift;
 my $sig   = shift;
 $class = ref $class || $class || return;
 croak 'The first argument must be a hash reference to the %SIG hash'
  unless $sig and ref $sig eq 'HASH';
 my $self = bless $class->SUPER::new(@_), $class;
 @{$sig}{qw/USR1 USR2/} = (sub { $self->push(0) }, sub { $self->push(1) });
 return $self;
}

=pod

IPC::MorseSignals::Receiver objects also inherit methods from L<Bit::MorseSignals::Receiver>.

=head1 EXPORT

An object module shouldn't export any function, and so does this one.

=head1 DEPENDENCIES

L<Bit::MorseSignals::Receiver>.

L<Carp> (standard since perl 5) is also required.

=head1 SEE ALSO

L<IPC::MorseSignals>, L<IPC::MorseSignals::Emitter>.

L<Bit::MorseSignals>, L<Bit::MorseSignals::Emitter>, L<Bit::MorseSignals::Receiver>.

L<perlipc> for information about signals in perl.

For truly useful IPC, search for shared memory, pipes and semaphores.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-morsesignals-receiver at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-MorseSignals>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::MorseSignals::Receiver

=head1 COPYRIGHT & LICENSE

Copyright 2007,2008,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IPC::MorseSignals::Receiver
