#use Test::More tests => 23;
use Test::More qw(no_plan);

BEGIN { use_ok( 'Language::Farnsworth' ); use_ok('Language::Farnsworth::Value'); use_ok('Language::Farnsworth::Output');}
require_ok( 'Language::Farnsworth' );
require_ok( 'Language::Farnsworth::Value' );
require_ok( 'Language::Farnsworth::Output' );

my $new = Language::Farnsworth->new(); #will attempt to load everything, doesn't die if it fails though, need a way to check that!.

my $expected; 
my $result = $new->runString("2+2");

is("4 ", $result, "Simple addition");

$result = $new->runString("sqrt[C[-17.15]]");

is("16.0 K^(1/2)", $result, "Simple check for sqrt[] and C[]"); #they happen to be at the END of the files (or near) they come from, meaning that they'll only be there if things didn't bomb out earlier
