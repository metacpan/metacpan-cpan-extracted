use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 9;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;

require File::Spec->catfile($Bin, '_common.pl');

my $subtlex;
my $val;

eval {$subtlex = Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples NL_all.with-pos.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'NL_all');};
ok(!$@, $@);

$val = $subtlex->get_lang();
ok($val eq 'NL_all', "get_lang(): wrong value: $val");

my $canned_data = get_canned_data('NL');

while (my($str, $val) = each %{$canned_data}) {
    my $test_opm = $subtlex->frq_opm(string => $str);
    ok ($test_opm == $val->{'freq'}, "'$str' returned wrong opm frequency: $test_opm");
    my $test_pos = $subtlex->pos_dom(string => $str);
    ok ($test_pos eq $val->{'pos'}, "'$str' returned wrong POS: $test_pos");
}

$val = $subtlex->get_index(measure => 'frq_zipf');
ok( defined $val, 'Returned true for unindexed variable: ' . $val);

1;