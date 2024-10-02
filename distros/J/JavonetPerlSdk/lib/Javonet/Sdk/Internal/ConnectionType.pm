package Javonet::Sdk::Internal::ConnectionType;
use strict;
use warnings FATAL => 'all';
use Moose;

my %connection_type = (
    'InMemory'       => 0,
    'Tcp'    => 1,
    'WithConfig' => 2,
);

sub get_connection_type {
    my $type = shift;
    return $connection_type{$type};
}


no Moose;
1;