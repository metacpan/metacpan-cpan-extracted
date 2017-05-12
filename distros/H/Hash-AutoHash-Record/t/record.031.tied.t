use lib qw(t);
use Carp;
use Hash::AutoHash::Record qw(autohash_tied autohash_alias);
use Test::More;
use Test::Deep;
use recordUtil;

#################################################################################
# test tied. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $record=new Hash::AutoHash::Record;
is(ref $record,'Hash::AutoHash::Record',
   "class is Hash::AutoHash::Record - sanity check");

my $tied=autohash_tied($record);
is(ref $tied,'Hash::AutoHash::Record::tie','autohash_tied type (record form)');
is($tied,tied %$record,'autohash_tied (record form)');

my %hash;
autohash_alias($record,%hash);
my $tied=autohash_tied(%hash);
is(ref $tied,'Hash::AutoHash::Record::tie','autohash_tied type (hash form)');
is($tied,tied %$record,'autohash_tied (hash form)');

done_testing();
