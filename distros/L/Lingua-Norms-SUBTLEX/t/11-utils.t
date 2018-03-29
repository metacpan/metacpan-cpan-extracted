use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 5;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;
require File::Spec->catfile($Bin, '_common.pl');

my $subtlex;
my $val;

eval {$subtlex = Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples UK.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'UK');};
ok(!$@, $@);

$val = $subtlex->get_lang();
ok($val eq 'UK', "get_lang(): wrong value: $val");

my $canned_data = get_canned_data('UK');
my $ret;

$val = $subtlex->get_index(measure => 'frq_opm');
ok( defined $val, 'Returned true for unindexed variable (s/be undef): ' . $val);

$val = $subtlex->get_index(measure => 'frq_zipf');
ok($val == 5, 'Returned wrong index for variable: ' . $val);

$val = $subtlex->pct_alpha();
ok($val == 100, 'Returned wrong pct_alpha: ' . $val);

1;