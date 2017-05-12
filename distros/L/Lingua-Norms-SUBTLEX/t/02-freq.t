use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 16;
use File::Spec;
use FindBin;
use Lingua::Norms::SUBTLEX;

my $subtlex = Lingua::Norms::SUBTLEX->new(path => File::Spec->catfile($FindBin::Bin, 'US_sample.csv'), fieldpath =>  File::Spec->catfile($FindBin::Bin, '..', 'lib', 'Lingua', 'Norms', 'SUBTLEX', 'fields.csv'));
my $val;
my %testlist = (
    the       => { freq => 29449.18, log => 6.1766, zipf => 7.468477762, cd_pct => 100, cd_log => 3.9237 },
    Detective => { freq => 61.12, log => 3.4939, zipf => 4.785710253, cd_pct => 11.78, cd_log => 2.9952 }
);

while (my($key, $val) = each %testlist) {
    ok ($subtlex->freq(string => $key) == $val->{'freq'}, "'$key' returned wrong frequency");
    ok ($subtlex->lfreq(string => $key) == $val->{'log'}, "'$key' returned wrong log frequency");
    ok ($subtlex->zipf(string => $key) == $val->{'zipf'}, "'$key' returned wrong zipf frequency");
    ok ($subtlex->cd_pct(string => $key) == $val->{'cd_pct'}, "'$key' returned wrong cd_pct");
    ok ($subtlex->cd_log(string => $key) == $val->{'cd_log'}, "'$key' returned wrong cd_log");
}

my $href = $subtlex->freqhash(strings => [keys %testlist]);
while (my($key, $val) = each %testlist) {
    ok ($href->{$key} == $val->{'freq'}, "'$key' returned wrong frequency");
}
$href = $subtlex->freqhash(strings => [keys %testlist], scale => 'log');
while (my($key, $val) = each %testlist) {
    ok ($href->{$key} == $val->{'log'}, "'$key' returned wrong log frequency");
}
$href = $subtlex->freqhash(strings => [keys %testlist], scale => 'zipf');
while (my($key, $val) = each %testlist) {
    ok ($href->{$key} == $val->{'zipf'}, "'$key' returned wrong zip frequency");
}
#, scale => raw|log|zipf

1;