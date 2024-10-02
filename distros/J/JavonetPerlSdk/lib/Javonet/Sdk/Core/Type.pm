package Javonet::Sdk::Core::Type;
use strict;
use warnings FATAL => 'all';
use Moose;

my %my_type = (
    'Command' => 0,
    'JavonetString' => 1,
    'JavonetInteger' => 2,
    'JavonetBool' => 3,
    'JavonetFloat' => 4,
    'JavonetByte' => 5,
    'JavonetChar' => 6,
    'JavonetLongLong' => 7,
    'JavonetDouble' => 8,
    'JavonetUnsignedLongLong' => 9,
    'JavonetUnsignedInteger' => 10,
    'JavonetNull' => 11,
);

sub get_type {
    my ($self, $type) = @_;
    return $my_type{$type};
}

no Moose;

1;