# test methods inherited from UNIVERSAL: 'can', 'isa', 'DOES', and 'VERSION'
use lib qw(t);
use strict;
use Carp;
use Test::More;
use autohashUtil;
use Hash::AutoHash::Record;

# Test DOES in perls > 5.10. 
# Note: $^V returns real string in perls > 5.10, and v-string in earlier perls
#   regexp below fails in earlier perls. this is okay
my($perl_main,$perl_minor)=$^V=~/^v(\d+)\.(\d+)/; # perl version

my $class='Hash::AutoHash::Record';
my $autohash=new $class;
ok($autohash->can('new'),"can");
ok(!$autohash->can('foo'),"can not");
test_bad_usage($autohash,'can');
ok($autohash->isa('Hash::AutoHash'),"isa");
ok(!$autohash->isa('Foo'),"isa not");
test_bad_usage($autohash,'isa');
if ($perl_main==5 && $perl_minor>=10) {
  ok($autohash->DOES('Hash::AutoHash'),"DOES");
  ok(!$autohash->DOES('Foo'),"DOES not");
  test_bad_usage($autohash,'DOES');
}
is($autohash->VERSION,eval "\$${class}::VERSION","VERSION");
test_bad_usage($autohash,'VERSION');

done_testing();

sub test_bad_usage {
  my($autohash,$key)=@_;
  if ($key ne 'VERSION')  {
    eval {$autohash->$key};
  } else {
    eval {$autohash->$key(9999)};
  }
  ok($@,"$key bad usage");
}
