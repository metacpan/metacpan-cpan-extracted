
package Lab::Instrument::LabViewHeater;
our $VERSION = "3.542";

use strict;
use warnings;
use Lab::Instrument;
use IO::File;
use Time::HiRes qw/usleep/;
use Time::HiRes qw/sleep/;

our @ISA = ("Lab::Instrument");

our %fields = ( supported_connections => ['Socket'], );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub set_T {
    my $self    = shift;
    my $set_T   = shift;
    my $command = sprintf( "SET_T %f", $set_T );
    my $result  = $self->query($command);
    return $result;
}

sub get_T0 {
    my $self   = shift;
    my $result = $self->query("GET_T0");
    return $result;
}

sub get_T {
    my $self   = shift;
    my $result = $self->query("GET_T");
    return $result;
}

sub get_mean_T {
    my $self   = shift;
    my $result = $self->query("GET_MEAN_T");
    return $result;
}

sub get_sigma_T {
    my $self   = shift;
    my $result = $self->query("GET_SIGMA_T");
    return $result;
}

sub get_max_dT {
    my $self   = shift;
    my $result = $self->query("GET_MAX_dT");
    return $result;
}

# returns two boolean bits: first bit is SETPOINT_REMOTE, second bit is PID_ON
sub get_mode {
    my $self   = shift;
    my $result = $self->query("GET_MODE");
    return $result;
}

sub set_mode {
    my $self   = shift;
    my $remote = shift;
    my $pid    = shift;
    my $result = $self->query("SET_MODE $remote,$pid");
    return $result;
}

1;
