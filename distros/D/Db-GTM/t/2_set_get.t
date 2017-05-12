# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################


use Test::More tests => 14; use Db::GTM;

#########################

my $db = new GTMDB('SPZ');

&test_set($db->sub("TEST_SG"));
&is( &test_subscript_create($db->sub("TEST_SG")), "passed", 
     "Create lots of subscripts" );
&is( &test_subscript_fetch($db->sub("TEST_SG")),  "passed",
     "Retrieve lots of subscripts" );

$db->kill("TEST_SG");

sub test_set {
  my($db) = @_;
  my(@testvals,$var,$val,$i) = (
    [ 41 ],                       "X", 
    [ 41, "B" ],                  41,
    [ "Foo", "Bar", "Baz" ],      -5,
    [ "Foo", 59, -0.0001, 6 ],    "BAR",
    [ -42, "Foo", 'BaRR!#$$$' ],  "Foooooooooooooooooooooooooooooooooooooooo",
    [ "^SPZ(45,\"FOO\")" ],       $$
  );
  for($i=0;$i<@testvals;$i+=2) {
    my($var,$val) = @testvals[$i,$i+1];
    ok( ! $db->set( @$var, $val ), "Basic store");
  } 
  for($i=0;$i<@testvals;$i+=2) {
    my($var,$val) = @testvals[$i,$i+1];
    is( $db->get( @$var ) , $val , "Basic fetch");
  } 
}

sub test_subscript_create {
  my($db) = @_;
  my($i); foreach $i ( -100 .. 100, "AA" .. "ZZ" ) {
    if( $db->set("SUBS",$i) ) { return "failed on [$i]\n"; }
  }
  return "passed";
}

sub test_subscript_fetch {
  my($db) = @_;
  my(@setlist,$i) = reverse (-100 .. 100, "AA" .. "ZZ");
  for($i=0;$i<@setlist;$i++) { 
    if( $db->get("SUBS",$setlist[$i] != (@setlist - $i)) ) { 
      return "failed on [$i] = [",$db->get("SUBS",$setlist[$i]),"]\n"; 
    }
  }
  return "passed";
}

system("stty sane"); # gtm_init() screws up the terminal 
