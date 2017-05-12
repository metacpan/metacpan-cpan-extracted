#$Id: IPSStrunkDillFridge.pm 2013-10-15 Dirnaichner $

package Lab::Instrument::IPSStrunkDillFridge;
our $version = '3.10';

use strict;
use Lab::Instrument::IPS;
our @ISA = ('Lab::Instrument::IPS');

my $default_config = {
    use_persistentmode       => 0,
    can_reverse              => 1,
    can_use_negative_current => 1,
};

our %fields = (
    supported_connections =>
      [ 'VISA', 'VISA_GPIB', 'GPIB', 'VISA_RS232', 'RS232', 'IsoBus', 'DEBUG' ],

    # default settings for the supported connections
    connection_settings => {
        gpib_board   => 0,
        gpib_address => undef,
        baudrate     => 9600,
        databits     => 8,
        stopbits     => 2,
        parity       => 'none',
        handshake    => 'none',
        termchar     => "\r",
        timeout      => 2,

    },

    device_settings => {
        has_switchheater => 1
    },

    device_cache => {
        id => "Strunk Dilution Fridge"
      }

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->{LIMITS} = {
        'magneticfield'          => 8,
        'field_intervall_limits' => [ 0, 8 ],
        'rate_intervall_limits'  => [ 0.6, 0.6 ]
    };

    $self->connection()->Clear();
    $self->check_magnet();
    $self->_init_magnet();

    return $self;
}

sub check_magnet {
    my $self = shift;
    print "Initializing magnet at the Strunk Dilution system.\n";
}

1;
