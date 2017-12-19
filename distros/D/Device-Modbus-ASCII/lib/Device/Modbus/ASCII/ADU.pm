package Device::Modbus::ASCII::ADU;

use parent 'Device::Modbus::ADU';
use Carp;
use strict;
use warnings;

sub lrc {
    my ($self, $lrc) = @_;
    if (defined $lrc) {
        $self->{lrc} = $lrc;
    }
    croak "LRC has not been declared"
        unless exists $self->{lrc};
    return $self->{lrc};
}

sub binary_message {
    my $self = shift;
    my $head = $self->build_header;
    my $pdu  = $self->message->pdu();
    my $lrc  = $self->lrc_for($head . $pdu);
    return ':' . unpack('H*', $head . $pdu . pack('C', $lrc)) . "\r\n";
}

sub build_header {
    my $self = shift;
    croak "Please include a unit number in the ADU"
        unless $self->{unit};
    my $header = pack 'C', $self->{unit};
    return $header;
}

# Returns the LRC as a number
sub lrc_for {
    my ($self, $str) = @_;
    my $lrc = 0;
    $lrc += unpack('C', $_) foreach split //, $str;
    no warnings 'pack';
    return unpack 'C', pack 'c', -$lrc;
}

1;
