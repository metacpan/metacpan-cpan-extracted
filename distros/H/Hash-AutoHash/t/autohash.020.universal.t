# test methods inheritted from UNIVERSAL: 'can', 'isa', 'DOES', and 'VERSION'
use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
require 'autohash.TieMV.pm';	# example tied hash class
use Hash::AutoHash qw(autohash_new autohash_tie);

# Test DOES in perls > 5.10. 
# Note: $^V returns real string in perls > 5.10, and v-string in earlier perls
#   regexp below fails in earlier perls. this is okay
my($perl_main,$perl_minor)=$^V=~/^v(\d+)\.(\d+)/; # perl version


my $case='not tied';
my $autohash=autohash_new;
ok($autohash->can('new'),"$case. can");
ok(!$autohash->can('foo'),"$case. can not");
test_bad_usage($autohash,$case,'can');
ok($autohash->isa('Hash::AutoHash'),"$case. isa");
ok(!$autohash->isa('Foo'),"$case. isa not");
test_bad_usage($autohash,$case,'isa');
if ($perl_main==5 && $perl_minor>=10) {
  ok($autohash->DOES('Hash::AutoHash'),"$case. DOES");
  ok(!$autohash->DOES('Foo'),"$case. DOES not");
  test_bad_usage($autohash,$case,'DOES');
}
is($autohash->VERSION,$Hash::AutoHash::VERSION,"$case. VERSION");
test_bad_usage($autohash,$case,'VERSION');

my $case='tied';
my $autohash=autohash_tie TieMV;
ok($autohash->can('new'),"$case. can");
ok(!$autohash->can('foo'),"$case. can not");
test_bad_usage($autohash,$case,'can');
ok($autohash->isa('Hash::AutoHash'),"$case. isa");
ok(!$autohash->isa('Foo'),"$case. isa not");
test_bad_usage($autohash,$case,'isa');
if ($perl_main==5 && $perl_minor>=10) {
  ok($autohash->DOES('Hash::AutoHash'),"$case. DOES");
  ok(!$autohash->DOES('Foo'),"$case. DOES not");
  test_bad_usage($autohash,$case,'DOES');
}
is($autohash->VERSION,$Hash::AutoHash::VERSION,"$case. VERSION");
test_bad_usage($autohash,$case,'VERSION');

done_testing();

sub test_bad_usage {
  my($autohash,$case,$key)=@_;
  if ($key ne 'VERSION')  {
    eval {$autohash->$key};
  } else {
    eval {$autohash->$key(9999)};
  }
  ok($@,"$case. $key bad usage");
}
