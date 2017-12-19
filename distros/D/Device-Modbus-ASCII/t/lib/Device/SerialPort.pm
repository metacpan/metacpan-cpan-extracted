package Device::SerialPort;

use strict;
use warnings;
use v5.10;

our $AUTOLOAD;
my @rx_buffer = ();
my @wx_buffer = ();

sub new {
    my ($class, $port) = @_;
    my $self = bless {}, $class;
    return $self;
}

my %is_mocked = (
    baudrate        => 1,
    databits        => 1,
    stopbits        => 1,
    parity          => 'even',
    timeout         => 10,
    handshake       => 1,
    read_char_time  => 1,
    read_const_time => 1,
    write_settings  => 1,
    purge_all       => 1,
    close           => 1,
);

sub read {
    my ($self, $chars) = @_;
    my $string = shift @rx_buffer;
    $string //= '';
#    say STDERR "# Reading from serial port: ",
#        join '-', unpack 'H*', $string
#        if $string;
    return length $string, $string;
}

sub write {
    my ($self, $string) = @_;
    push @wx_buffer, $string;
    return length $string;
}

sub add_test_strings {
    my ($class, @strings) = @_;
    push @rx_buffer, @strings;
}

sub get_test_string {
    my $class = shift;
    return shift @wx_buffer;
}

sub write_buffer {
    my $self = shift;
    return $self->{wx_buffer};
}

sub AUTOLOAD {
    my @args = @_;
    my ($sub) = $AUTOLOAD =~ /Device::SerialPort::(\w+)/;

    die "Undeclared subroutine: $sub" unless $is_mocked{$sub};
    return $is_mocked{$sub};
}

sub DESTROY { }

1;
