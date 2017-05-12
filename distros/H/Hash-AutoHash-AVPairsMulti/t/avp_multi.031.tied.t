use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsMulti qw(autohash_tied autohash_alias);
use Test::More;
use Test::Deep;
use autohashUtil;

#################################################################################
# test tied. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $avp_multi=new Hash::AutoHash::AVPairsMulti;
is(ref $avp_multi,'Hash::AutoHash::AVPairsMulti',
   "class is Hash::AutoHash::AVPairsMulti - sanity check");

my $tied=autohash_tied($avp_multi);
is(ref $tied,'Hash::AutoHash::AVPairsMulti::tie','autohash_tied type (avp_multi form)');
is($tied,tied %$avp_multi,'autohash_tied (avp_multi form)');

my %hash;
autohash_alias($avp_multi,%hash);
my $tied=autohash_tied(%hash);
is(ref $tied,'Hash::AutoHash::AVPairsMulti::tie','autohash_tied type (hash form)');
is($tied,tied %$avp_multi,'autohash_tied (hash form)');

done_testing();
