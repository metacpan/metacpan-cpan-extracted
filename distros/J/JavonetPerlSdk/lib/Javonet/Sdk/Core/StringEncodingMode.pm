package Javonet::Sdk::Core::StringEncodingMode;
use strict;
use warnings;
use Moose;
use Exporter qw(import);
our @EXPORT = qw(get_string_encoding_mode);

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