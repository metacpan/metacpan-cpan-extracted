#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
my %filenames;
$filenames{$_}++ foreach $ebug->filenames;
ok($filenames{'t/calc_oo.pl'});
ok($filenames{'t/Calc.pm'});
