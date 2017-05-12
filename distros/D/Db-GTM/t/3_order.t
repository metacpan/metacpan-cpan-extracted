# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 7;
BEGIN { use_ok('Db::GTM') };
$ENV{'GTMCI'}="/usr/local/gtm/xc/calltab.ci" unless $ENV{'GTMCI'};

#########################

my $db = new GTMDB('SPZ');

is(&create_subscripts($db->sub("TEST_ORDER")),"passed","Creating subscripts");
is(&test_children($db->sub("TEST_ORDER")),"passed", 
   "\$O,CHILDREN,Correct M Collating Order");

is(
  join(",",scalar($db->order("TEST_ORDER",""))),
  "-10",
  "scalar context - find first subscript"
);

is(
  join(",",$db->order("TEST_ORDER","")),
  "TEST_ORDER,-10",
  "list context - find first subscript"
);

is(
  $db->order("TEST_ORDER","A"),
  "ALPHA",
  "Getting first value from undefined"
);

is(
  $db->order("TEST_ORDER",1),
  "1.1",
  "Numeric collating order"
);

$db->kill("TEST_ORDER");
system("stty sane"); # gtm_init() screws up the terminal 

sub create_subscripts {
  my($db,$i) = @_;
  foreach $i (qw(A 1 2 100 -5 -10 -5.5 1.1 ALPHA B)) {
    return "failed" if $db->set($i,"FOO$i");
  } 
  return "passed";
}

sub test_children {
  my($db) = @_;
  my($ch) = join(":",$db->children());
  return ($ch eq "-10:-5.5:-5:1:1.1:2:100:A:ALPHA:B") ? "passed" : "failed";
}

