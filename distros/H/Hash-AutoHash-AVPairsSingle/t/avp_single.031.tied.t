use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsSingle qw(autohash_tied autohash_alias);
use Test::More;

#################################################################################
# test tied. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $avp=new Hash::AutoHash::AVPairsSingle;
is(ref $avp,'Hash::AutoHash::AVPairsSingle',
   "class is Hash::AutoHash::AVPairsSingle - sanity check");

my $tied=autohash_tied($avp);
is(ref $tied,'Hash::AutoHash::AVPairsSingle::tie','autohash_tied type (avp form)');
is($tied,tied %$avp,'autohash_tied (avp form)');

my %hash;
autohash_alias($avp,%hash);
my $tied=autohash_tied(%hash);
is(ref $tied,'Hash::AutoHash::AVPairsSingle::tie','autohash_tied type (hash form)');
is($tied,tied %$avp,'autohash_tied (hash form)');

done_testing();
