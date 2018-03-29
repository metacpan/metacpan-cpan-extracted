use 5.12.0;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 2;
use FindBin qw/$Bin/;
use File::Spec;
use Lingua::Norms::SUBTLEX;
require File::Spec->catfile($Bin, '_common.pl');

my $subtlex;
my $val;

eval {$subtlex = Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($Bin, qw'samples DE.txt'), fieldpath =>  File::Spec->catfile($FindBin::Bin, qw'.. lib Lingua Norms SUBTLEX specs.csv'), lang => 'DE');};
ok(!$@, $@);

$val = $subtlex->get_lang();
ok($val eq 'DE', "get_lang(): wrong value: $val");
exit;

# ensure got tab not comma as delimiter:
ok ($subtlex->{'_DELIM'} eq "\t", "Returned wrong delimiter for lang DE");

my $canned_data = get_canned_data('DE');

my $ret;

while (my($str, $val) = each %{$canned_data}) {
    $ret = $subtlex->frq_opm(string => $str);
    ok ($ret == $val->{'freq'}, "'$str' returned wrong opm frequency: $ret");
    $ret = $subtlex->frq_log(string => $str);
    ok ($ret eq $val->{'frq_log'}, "'$str' returned wrong log frequency: $ret");
}

# and stats?
my $mean = $subtlex->frq_mean(strings => [qw/Genaui Brez Selbstzweifel/], scale => 'log');
ok (about_equal($mean, 0.660666667), "returned wrong mean frequency for DE: $mean");

1;