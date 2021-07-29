#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("corpus/calc_oo.pl");
$ebug->load;
my %filenames;
$filenames{$_}++ foreach $ebug->filenames;
ok($filenames{'corpus/calc_oo.pl'});
ok($filenames{'corpus/lib/Calc.pm'});
