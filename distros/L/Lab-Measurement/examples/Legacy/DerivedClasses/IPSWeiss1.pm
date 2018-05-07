#$Id: IPSWeiss1.pm 2012-11-10 Geissler/Butschkow $

package Lab::Instrument::IPSWeiss1;
our $version = '3.10';

use strict;
use Lab::Instrument::IPS;
our @ISA = ('Lab::Instrument::IPS');

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

    },

    device_settings => {
        has_switchheater => 1
    },

    device_cache => {}

);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    $self->{LIMITS} = {
        'magneticfield'          => 14,
        'field_intervall_limits' => [ 0, 9, 11.5, 13, 14 ],
        'rate_intervall_limits'  => [ 1.98, 0.66, 0.36, 0.18, 0.18 ]
    };

    $self->connection()->Clear();
    $self->check_magnet();
    $self->_init_magnet();

    return $self;
}

sub check_magnet {
    my $self = shift;

    my $version = $self->get_version();
    if ( not( $version =~ /Version\s3\.06/ ) ) {
        Lab::Exception::CorruptParameter->throw( error =>
"This Instrument driver is supposed to be used ONLY with LS Weiss Kryo1 !\n"
        );
    }
}

1;
