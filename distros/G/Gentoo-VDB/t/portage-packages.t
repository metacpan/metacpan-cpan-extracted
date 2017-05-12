use strict;
use warnings;

BEGIN {
    local @INC = @INC;
    unshift @INC, 't/lib';
    require KENTNL::IsVDB;
    KENTNL::IsVDB::check_isvdb('/var/db/pkg');
}

use Test::More;

use Gentoo::VDB;
my $vdb = Gentoo::VDB->new();

my ( $cat, ) = $vdb->categories;
if ( not defined $cat ) {
    plan skip_all => 'This test requires at least one category in /var/db/pkg';
    exit;
}
diag "Testing vs $cat";
for my $pkg ( $vdb->packages( { in => $cat } ) ) {
    like( $pkg, qr{\A\Q$cat\E/[^/]+\z},
        "Package $pkg has one slash and starts with category" );
}

done_testing;
