#!perl
use strict;
use warnings;
use Test::More tests => 1;
use Lingua::Boolean;

my @langs = Lingua::Boolean::languages();
is_deeply [sort @langs], [sort 'English', "Fran\x{e7}ais"]
    or diag explain [sort @langs];
