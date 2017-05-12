# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;
use FindBin;
use lib "$FindBin::Bin/../lib";
BEGIN { use_ok( 'Finance::Bank::DE::NetBank' ); }

my $object = Finance::Bank::DE::NetBank->new ();
isa_ok ($object, 'Finance::Bank::DE::NetBank');


