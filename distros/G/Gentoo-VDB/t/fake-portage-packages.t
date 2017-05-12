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

done_testing;
