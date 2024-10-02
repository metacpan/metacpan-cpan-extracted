package Javonet::Sdk::Core::StringEncodingMode;
use strict;
use warnings;
use Moose;

my %string_encoding_mode = (
    'ASCII'             => 0,
    'UTF8'              => 1,
    'UTF16'             => 2,
    'UTF32'             => 3
);

sub get_string_encoding_mode {
    my ($self, $mode) = @_;
    return $string_encoding_mode{$mode};
}

no Moose;

1;