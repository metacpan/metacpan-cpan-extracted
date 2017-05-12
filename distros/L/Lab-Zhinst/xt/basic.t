#!perl -T
use warnings;
use strict;

use Test::More;

BEGIN { use_ok('Lab::Zhinst') };

my $conn = Lab::Zhinst->new('localhost', 8004);
isa_ok($conn, 'Lab::Zhinst');


my $implementations = ListImplementations();
is($implementations, "ziAPI_Core\nziAPI_AsyncSocket\nziAPI_ziServer1",
    "ListImplementations");


is($conn->GetConnectionAPILevel(), 1, "GetConnectionAPILevel");


my $nodes = $conn->ListNodes("/", ZI_LIST_NODES_ABSOLUTE
                             | ZI_LIST_NODES_RECURSIVE);
like($nodes, qr{/zi/about/version}i, "ListNodes");

for my $getter (qw/GetValueD GetValueI/) {
    is($conn->$getter('/zi/config/port'), 8004, $getter);
}

like($conn->GetValueB('/zi/about/copyright'), qr/Zurich Instruments/,
    "GetValueB");




done_testing();
