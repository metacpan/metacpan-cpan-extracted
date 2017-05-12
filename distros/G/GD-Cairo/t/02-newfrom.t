# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GD-Cairo.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use GD;
use GD::Cairo qw();
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $img = GD::Image->new( 400, 300 );

my $black = $img->colorAllocate(0, 0, 0);

my $gdc = GD::Cairo->newFromPngData( $img->png );

ok(1);
