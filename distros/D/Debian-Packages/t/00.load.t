#!perl -T

use Test::More tests => 2;

BEGIN { use_ok( 'Debian::Packages' ); }
require_ok( 'Debian::Packages' ) or die "Cannot load Debian::Packages. $!\n";
use Debian::Packages;

diag( "Testing Debian::Packages $Debian::Packages::VERSION, Perl $], $^X" );
