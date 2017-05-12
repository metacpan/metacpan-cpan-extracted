use lib qw(t);
use Carp;
use Hash::AutoHash::MultiValued qw(autohash_tied autohash_alias);
use Test::More;
use Test::Deep;
use mvhashUtil;

#################################################################################
# test tied. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $mvhash=new Hash::AutoHash::MultiValued;
is(ref $mvhash,'Hash::AutoHash::MultiValued',
   "class is Hash::AutoHash::MultiValued - sanity check");

my $tied=autohash_tied($mvhash);
is(ref $tied,'Hash::AutoHash::MultiValued::tie','autohash_tied type (mvhash form)');
is($tied,tied %$mvhash,'autohash_tied (mvhash form)');

my %hash;
autohash_alias($mvhash,%hash);
my $tied=autohash_tied(%hash);
is(ref $tied,'Hash::AutoHash::MultiValued::tie','autohash_tied type (hash form)');
is($tied,tied %$mvhash,'autohash_tied (hash form)');

done_testing();
