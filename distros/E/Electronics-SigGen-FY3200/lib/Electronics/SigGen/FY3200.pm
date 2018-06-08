package Electronics::SigGen::FY3200;

use strict;
use warnings;

use Carp;
use Fcntl qw( O_NOCTTY O_NDELAY );
use Future;
use IO::Termios;
use Time::HiRes qw( time sleep );

use constant MIN_DELAY => 0.05;

# See also:
#   https://www.eevblog.com/forum/testgear/feeltech-fy3224s-24mhz-2-channel-dds-aw-function-signal-generator/msg708434/#msg708434

=head1 NAME

C<Electronics::SigGen::FY3200> - control a F<FeelTech> F<FY32xx> signal generator

=head1 SYNOPSIS

   use Electronics::SigGen::FY3200;

   my $fy3200 = Electronics::SigGen::FY3200->new( dev => "/dev/ttyUSB0" );

   my $ch1 = $fy3200->channel(1);

   $ch1->set_wave( 'sine' )->get;
   $ch1->set_frequency( 1E3 )->get; # in Hz
   $ch->set_amplitude( 2 )->get;    # in Volts peak

=head1 DESCRIPTION

This module allows control of a F<FeelTech> F<FY32xx> series signal generator,
such as the F<FY3224S>, when connected over USB.

=head2 Interface Design

The interface is currently an ad-hoc collection of whatever seems to work
here, but my hope is to find a more generic shareable interface that multiple
different modules can use, to provide standard interfaces to various kinds of
electronics test equipment.

The intention is that it should eventually be possible to write a script for
performing automated electronics testing or experimentation, and easily swap
out modules to suit the equipment available. Similar concepts apply in fields
like L<DBI>, or L<Device::Chip>, so there should be plenty of ideas to borrow.

=cut

sub new
{
   my $class = shift;
   my %opts = @_;

   my $fh = IO::Termios->open( $opts{dev}, "9600,8,n,1", O_NOCTTY, O_NDELAY ) or
      croak "Cannot open $opts{dev} - $!";

   $fh->setflag_clocal( 1 );
   $fh->blocking( 1 );
   $fh->autoflush;

   return bless {
      fh => $fh,
      lasttime => time(),
   }, $class;
}

sub _command
{
   my $self = shift;
   my ( $cmd ) = @_;

   my $fh = $self->{fh};

   my $delay = time() - $self->{lasttime};
   if( $delay < MIN_DELAY ) {
      sleep MIN_DELAY - $delay;
   }

   $fh->print( "$cmd\x0a" );

   $self->{lasttime} = time();

   return Future->done;
}

sub _commandresponse
{
   my $self = shift;
   my ( $cmd ) = @_;

   my $fh = $self->{fh};

   my $delay = time() - $self->{lasttime};
   if( $delay < MIN_DELAY ) {
      sleep MIN_DELAY - $delay;
   }

   $fh->print( "$cmd\x0a" );

   my $ret = <$fh>;
   chomp $ret;

   $self->{lasttime} = time();

   return Future->done( $ret );
}

=head1 METHODS

=cut

=head2 identify

   $str = $fy3200->identify->get

=cut

sub identify
{
   my $self = shift;
   return $self->_commandresponse( "a" );
}

=head2 channel

   $ch = $fy3200->channel( $n )

Returns a Channel object representing the main (if I<$n> is 1) or secondary
(if I<$n> is 2) channel.

=cut

sub channel
{
   my $self = shift;
   my ( $idx ) = @_;

   croak "Bad channel index" unless $idx == 1 or $idx == 2;

   return Electronics::SigGen::FY3200::_Channel->new( $self,
      $idx == 1 ? "c" : "",
      $idx == 1 ? "b" : "d",
   );
}

package
   Electronics::SigGen::FY3200::_Channel;

use Carp;

sub new
{
   my $class = shift;
   my ( $fy, $getcmd, $setcmd ) = @_;
   return bless [ $fy, $getcmd, $setcmd ], $class;
}

sub _set
{
   my $self = shift;
   my ( $cmd ) = @_;
   return $self->[0]->_command( $self->[2] . $cmd );
}

=head1 CHANNEL METHODS

=cut

=head2 set_wave

   $ch->set_wave( $type )->get

Sets the basic wave shape - one of C<sine>, C<square>, C<triangle>, etc... or
one of the direct numbers from 0 to 16 recognised by the device.

=cut

my %WAVES = (
   sine        => 0,
   square      => 1,
   triangle    => 2,
   arb1        => 3,
   arb2        => 4,
   arb3        => 5,
   arb4        => 6,
   lorentz     => 7,
   multitone   => 8,
   noise       => 9,
   ecg         => 10,
   trapezoidal => 11,
   sinc        => 12,
   narrow      => 13,
   gaussnoise  => 14,
   am          => 15,
   fm          => 16,
);

sub set_wave
{
   my $self = shift;
   my ( $wave ) = @_;

   $wave = $WAVES{$wave} if exists $WAVES{$wave};
   $wave =~ m/^\d+$/ or croak "Unrecognised wave type $wave";

   $self->_set( sprintf "w%d", $wave );
}

=head2 set_frequency

   $ch->set_frequency( $hz )->get

Sets the frequency in Hz.

=cut

sub set_frequency
{
   my $self = shift;
   my ( $hz ) = @_;

   # Frequency is in cHz
   $self->_set( sprintf "f%d", $hz * 100 );
}

=head2 set_amplitude

   $ch->set_amplitude( $vpk )->get

Sets the amplitude in Volts peak.

=cut

sub set_amplitude
{
   my $self = shift;
   my ( $vpk ) = @_;

   $self->_set( sprintf "a%.2f", $vpk );
}

=head2 set_offset

   $ch->set_offset( $v )->get

Sets the offset in Volts.

=cut

sub set_offset
{
   my $self = shift;
   my ( $v ) = @_;

   $self->_set( sprintf "o%.2f", $v );
}

=head2 set_duty

   $ch->set_duty( $duty )->get

Sets the duty cycle as a fraction from 0 to 1.

=cut

sub set_duty
{
   my $self = shift;
   my ( $duty ) = @_;

   $self->_set( sprintf "d%d", $duty * 1000 );
}

=head2 set_phase

   $ch->set_phase( $phase )->get

Sets the phase offset as a fraction from 0 to 1.

Note that due to hardware limitations this only takes effect on the secondary
channel; the primary channel will ignore it.

=cut

sub set_phase
{
   my $self = shift;
   my ( $phase ) = @_;

   $self->_set( sprintf "p%d", $phase * 360 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
