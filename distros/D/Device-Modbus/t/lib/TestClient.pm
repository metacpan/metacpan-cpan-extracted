package TestClient;

use Carp;
use strict;
use warnings;

use parent 'Device::Modbus::Client';

sub new {
    my $class    = shift;
    my @messages = @_;
    my $self     = {
        index    => 0,
        messages => \@messages,
    };
    return bless $self, $class;
}

sub set_index {
    my ($self, $index) = @_;
    $self->{index} = $index;
}

sub read_port {
    my $self = shift;
    my $str  = $self->{messages}[$self->{index}];
    die "Timeout error" unless length($str);
    $self->{buffer} = $str;
    return $str;        
}

sub parse_buffer {
    my ($self, $bytes, $pattern) = @_;
    die "Timeout error" unless length($self->{buffer}) >= $bytes;    
    return unpack $pattern, substr $self->{buffer},0,$bytes,'';
}

1;
