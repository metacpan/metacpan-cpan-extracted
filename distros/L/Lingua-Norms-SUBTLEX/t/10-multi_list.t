use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 10;
use FindBin qw/$Bin/;
use File::Spec;
use constant EPS => 1e-2;
use Lingua::Norms::SUBTLEX;
require File::Spec->catfile($Bin, '_common.pl');

# try non-default languages:

my $subtlex;
my $val;

my %testlist = (
    colour => { frq_count => 22651, frq_zipf => 5.05, pos_dom => 'noun'},
    favourite => {frq_count => 27052, frq_zipf => 5.13, pos_dom => 'adjective'},
);

eval {$subtlex = Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples UK.csv'), fieldpath =>  File::Spec->catfile($Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'UK');};
ok(!$@, $@);

$val = $subtlex->get_lang();
ok($val eq 'UK', "get_lang(): wrong value: $val"); # strings => $key, values => [qw/frq_opm pos/]

my $test_href = $subtlex->multi_list(strings => [qw/colour favourite/], measures => [qw/frq_count frq_zipf pos_dom/]);

while (my($key, $val) = each %{$test_href}) {
    ok(ref $val, "No reference of measure-values returned for $key");
    #diag($key, "\n");
    while (my($key2, $val2) = each %{$val}) {
        #diag("\t$key2\t$val2\n");
        ok( about_equal($val2, $testlist{$key}->{$key2}), "Incorrect value of $key2 for $key of $val2; expected $testlist{$key}->{$key2}" );
    }
}

1;