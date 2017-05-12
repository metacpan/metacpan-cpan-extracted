package Device::Modbus::RTU::ADU;

use parent 'Device::Modbus::ADU';
use Carp;
use strict;
use warnings;

sub crc {
    my ($self, $crc) = @_;
    if (defined $crc) {
        $self->{crc} = $crc;
    }
    croak "CRC has not been declared"
        unless exists $self->{crc};
    return $self->{crc};
}

sub binary_message {
    my $self = shift;
    croak "Please include a unit number in the ADU."
        unless $self->{unit};
    my $header = $self->build_header;
    my $pdu    = $self->message->pdu();
    my $footer = $self->build_footer($header, $pdu);
    return $header . $pdu . $footer;
}

sub build_header {
    my $self = shift;
    my $header = pack 'C', $self->{unit};
    return $header;
}

sub build_footer {
    my ($self, $header, $pdu) = @_;
    return $self->crc_for($header . $pdu);
}

# Taken from MBClient (and verified against Modbus docs)
sub crc_for {
    my ($self, $str) = @_;
    my $crc = 0xFFFF;
    my ($chr, $lsb);
    for my $i (0..length($str)-1) {
        $chr  = ord(substr($str, $i, 1));
        $crc ^= $chr;
        for (1..8) {
            $lsb = $crc & 1;
            $crc >>= 1;
            $crc ^= 0xA001	if $lsb;
        }
	}
    return pack 'v', $crc;
}

1;
