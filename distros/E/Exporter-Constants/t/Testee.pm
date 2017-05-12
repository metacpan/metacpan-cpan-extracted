package t::Testee;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

our @EXPORT;
our @EXPORT_OK;

use Exporter::Constants (
    \@EXPORT => {
        TYPE_A => 4649,
        TYPE_B => 5963,
    },
    \@EXPORT_OK => {
        TYPE_C => 1919,
        TYPE_D => 0721,
    },
);

1;

