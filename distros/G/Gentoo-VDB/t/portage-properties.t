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
my ( $pkg, ) = $vdb->packages( { in => $cat } );
diag "Testing vs $pkg";
for my $pkg ( $vdb->properties( { for => $pkg } ) ) {
    my $all_ok = ok( exists $pkg->{property}, 'property exists for record' );

    undef $all_ok
      unless ok( exists $pkg->{label},
        'label exists for record ' . $pkg->{property} );
    undef $all_ok
      unless ok( exists $pkg->{for},
        'for exists for record ' . $pkg->{property} );
    undef $all_ok
      unless ok( exists $pkg->{type},
        'type id exists for record ' . $pkg->{property} );
    diag explain $pkg unless $all_ok;
    next unless $all_ok;
    next if $pkg->{type} eq 'flag-file' or $pkg->{type} eq 'file';
    my $content = $vdb->get_property($pkg);
    ok( defined $content, 'record has content ' . $pkg->{property} );

}

done_testing;
