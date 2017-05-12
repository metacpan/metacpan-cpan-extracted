# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::Simple tests => 3 ;
use IBM::LoadLeveler;

my $c_version="";
my $p_version="";

 ok( open(CTEST,"ct/version |"), "C Reference case");
 
 while ( <CTEST> )
 {
 	chomp;
 	$c_version=$1 if (/VERSION=(.*)/);
 }
 close CTEST;

$p_version=ll_version();

ok( defined ll_version(), "ll_version returns a value?" );
ok( $c_version eq $p_version, "Compare Perl with C" );
