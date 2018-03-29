use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 13;
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

while (my($str, $val) = each %{$canned_data}) {
    ok ($subtlex->frq_count(string => $str) == $val->{'frq_count'}, "'$str' returned wrong frq_count");
    ok ($subtlex->frq_zipf(string => $str) == $val->{'frq_zipf'}, "'$str' returned wrong frq_zipf");

    $ret = $subtlex->pos_dom(string => $str);
    ok ($ret eq $val->{'pos_dom'}, "'$str' returned wrong pos_dom: $ret");
    
    $ret = $subtlex->pos_all( string => $str );
    ok(ref $ret, 'Not a reference returned from pos_all');
    for my $expected_pos_i(0 .. ((scalar @{$val->{'pos_all'}}) - 1 )) {
        my $expected = $val->{'pos_all'}->[$expected_pos_i];
        my $observed = $ret->[$expected_pos_i];
        ok( $observed eq $expected, "<$str> returned wrong pos_all:\n\tobserved\t$observed\n\texpected\t$expected" );
    }
}

$val = $subtlex->get_index(measure => 'frq_opm');
ok( defined $val, 'Returned true for unindexed variable: ' . $val);

$val = $subtlex->get_index(measure => 'frq_zipf');
ok($val == 5, 'Returned wrong index for variable: ' . $val);

1;