use strict;
use warnings;

BEGIN {
    local @INC = @INC;
    unshift @INC, 't/lib';
    require KENTNL::FakeVDB;
    KENTNL::FakeVDB->check_requires;
}

use Test::More;
use Gentoo::VDB;

my $tdir = KENTNL::FakeVDB::mkvdb(
    {
        dirs     => [ 'dev-lang/empty_pkg', 'empty-cat' ],
        packages => ['dev-lang/perl-5.24.1_rc3'],
    }
);

my $vdb = Gentoo::VDB->new( path => $tdir );

cmp_ok( scalar $vdb->categories, '==', 1, "Exactly one category found" )
  or diag explain [ $vdb->categories ];

cmp_ok( [ $vdb->categories ]->[0], 'eq', 'dev-lang',
    'dev-lang category found' );

cmp_ok( scalar $vdb->packages( { in => 'dev-lang' } ),
    '==', 1, "One package in dev-lang" );
cmp_ok( scalar $vdb->packages( { in => 'empty-cat' } ),
    '==', 0, "No packages in empty category" );

cmp_ok( scalar $vdb->packages( { in => 'missing-cat' } ),
    '==', 0, "No packages in missing category" );

cmp_ok( [ $vdb->packages( { in => 'dev-lang' } ) ]->[0],
    'eq', 'dev-lang/perl-5.24.1_rc3',
    "One package in dev-lang is dev-lang/perl-*" );

for my $pkg ( $vdb->properties( { for => 'dev-lang/perl-5.24.1_rc3' } ) ) {
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
