package IPC::MorseSignals::Emitter;

use strict;
use warnings;

use Carp qw/croak/;
use POSIX qw/SIGUSR1 SIGUSR2/;
use Time::HiRes qw/usleep/;

use Bit::MorseSignals::Emitter;
use base qw/Bit::MorseSignals::Emitter/;

=head1 NAME

IPC::MorseSignals::Emitter - Base class for IPC::MorseSignals emitters.

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

=head1 SYNOPSIS

    use IPC::MorseSignals::Emitter;

    my $deuce = IPC::MorseSignals::Emitter->new(speed => 1024);
    $deuce->post('HLAGH') for 1 .. 3;
    $deuce->send($pid);

=head1 DESCRIPTION

This module sends messages processed by an underlying L<Bit::MorseSignal> emitter to another process as a sequence of C<SIGUSR1> (for bits 0) and C<SIGUSR2> (for 1) signals.

=cut

sub _check_self {
 croak 'First argument isn\'t a valid ' . __PACKAGE__ . ' object'
  unless ref $_[0] and $_[0]->isa(__PACKAGE__);
}

=head1 METHODS

=head2 C<< new < delay => $seconds, speed => $bauds, %bme_options > >>

Creates a new emitter object. C<delay> specifies the delay between two sends, in seconds, while C<speed> is the number of bits sent per second. The delay value has priority over the speed. Default delay is 1 second. Extra arguments are passed to L<Bit::MorseSignals::Emitter/new>.

=cut

sub new {
 my $class = shift;
 $class = ref $class || $class || return;
 croak 'Optional arguments must be passed as key => value pairs' if @_ % 2;
 my %opts = @_;
 # delay supersedes speed
 my $delay = delete $opts{delay};       # fractional seconds
 if (!defined $delay) {
  my $speed = delete $opts{speed} || 0; # bauds
  $speed = int $speed;
  $delay = abs(1 / $speed) if $speed;
 }
 my $self = $class->SUPER::new(%opts);
 $self->{delay} = abs($delay || 1 + 0.0);
 bless $self, $class;
}

=head2 C<send $pid>

Sends messages enqueued with L<Bit::MorseSignals::Emitter/post> to the process C<$pid> (or to all the C<@$pid> if C<$pid> is an array reference, in which case duplicated targets are stripped off).

=cut

sub send {
 my ($self, $dest) = @_;
 _check_self($self);
 return unless defined $dest;
 my %count;
 my @dests = grep $_ > 0 && !$count{$_}++, # Remove duplicates.
              ref $dest eq 'ARRAY' ? map int, grep defined, @$dest
                                   : int $dest;
 return unless @dests;
 while (defined(my $bit = $self->pop)) {
  my @sigs = (SIGUSR1, SIGUSR2);
  my $d = $self->{delay} * 1_000_000;
  $d -= usleep $d while $d > 0;
  kill $sigs[$bit] => @dests;
 }
}

=head2 C<< delay < $seconds > >>

Returns the current delay in seconds, or set it if an argument is provided.

=cut

sub delay {
 my ($self, $delay) = @_;
 _check_self($self);
 $self->{delay} = abs $delay if $delay and $delay += 0.0;
 return $self->{delay};
}

=head2 C<< speed < $bauds > >>

Returns the current speed in bauds, or set it if an argument is provided.

=cut

sub speed {
 my ($self, $speed) = @_;
 _check_self($self);
 $self->{delay} = 1 / (abs $speed) if $speed and $speed = int $speed;
 return int(1 / $self->{delay});
}

=pod

IPC::MorseSignals::Emitter objects also inherit methods from L<Bit::MorseSignals::Emitter>.

=head1 EXPORT

An object module shouldn't export any function, and so does this one.

=head1 DEPENDENCIES

L<Bit::MorseSignals::Emitter>.

L<Carp> (standard since perl 5), L<POSIX> (idem) and L<Time::HiRes> (since perl 5.7.3) are required.

=head1 SEE ALSO

L<IPC::MorseSignals>, L<IPC::MorseSignals::Receiver>.

L<Bit::MorseSignals>, L<Bit::MorseSignals::Emitter>, L<Bit::MorseSignals::Receiver>.

L<perlipc> for information about signals in perl.

For truly useful IPC, search for shared memory, pipes and semaphores.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-morsesignals-emitter at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-MorseSignals>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::MorseSignals::Emitter

=head1 COPYRIGHT & LICENSE

Copyright 2007,2008,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IPC::MorseSignals::Emitter
