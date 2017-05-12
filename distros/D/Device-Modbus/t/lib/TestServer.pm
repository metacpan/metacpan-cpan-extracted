package TestServer;

use Device::Modbus::ADU;
use strict;
use warnings;

use parent 'Device::Modbus::Server';

sub new {
    my $class    = shift;
    my @messages = @_;
    my %args     = (
        index    => 0,
        messages => \@messages,
        units    => {},
        buffer   => '',
    );
    return bless {%args, %{$class->proto}}, $class;
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
    return unpack $pattern, substr $self->{buffer},0,$bytes,'';
}

sub new_adu { return Device::Modbus::ADU->new(); }
sub parse_header { }
sub parse_footer { }
sub log { }

1;
