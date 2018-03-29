use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 8;
use FindBin qw/$Bin/;
use File::Spec;
use constant EPS => 1e-3;
use Lingua::Norms::SUBTLEX;

# try non-default languages:

my $subtlex;
my $val;

my %testlist = (
    niet => {freq => 18323.9788, pos_dom => 'BW'},
    van => { freq => 10410.2451, pos_dom => 'VZ'},
    maar => { freq => 8385.7271, pos_dom => 'VG'}
);

eval {$subtlex = Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, 'samples', 'NL_all.with-pos.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'NL_all');};
ok(!$@, $@);

$val = $subtlex->get_lang();
ok($val eq 'NL_all', "get_lang(): wrong value: $val");

while (my($key, $val) = each %testlist) {
    my $test_aref = $subtlex->values_list(string => $key, values => [qw/frq_opm pos_dom/]);
    ok ($test_aref->[0] == $val->{'freq'}, "'$key' returned wrong opm frequency: $test_aref->[0]");
    ok ($test_aref->[1] eq $val->{'pos_dom'}, "'$key' returned wrong POS: $test_aref->[1]");
}

#$val = $subtlex->all_vals(measure => 'frq_opm');
#diag(join(q{,}, @{$val}));

1;