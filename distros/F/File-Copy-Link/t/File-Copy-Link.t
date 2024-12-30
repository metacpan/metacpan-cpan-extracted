# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl File-Copy-Link.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('File::Copy::Link') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dist_ver = File::Copy::Link->VERSION;
ok( defined $dist_ver, 'has dist version' );
$dist_ver = eval $dist_ver;

for my $pack (qw(File::Spec::Link)) {
    require_ok($pack);
    my $pack_ver = $pack->VERSION;
    ok( defined $pack_ver, "package $pack has version" );
    cmp_ok( $pack_ver, "<=", $dist_ver, "package version <= dist version" );
}
