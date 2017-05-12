#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Touch;

use File::Find::Rule;
use File::Find::Rule::DirCompare;

use Test::More tests => 8;

my $searchdir = File::Spec->catdir( $FindBin::Bin, 'samples', 'search' );
my $cmpdir = File::Spec->catdir( $FindBin::Bin, 'samples', 'compare' );

touch( File::Spec->catfile( $searchdir, 'newer_in_search' ) );
touch( File::Spec->catfile( $cmpdir, 'newer_in_compare' ) );

my @only_in_searchdir = find( file => not_exists_in => $cmpdir, in => $searchdir );
cmp_ok( scalar(@only_in_searchdir), '==', 1, 'only in searchdir' );
my @in_both_dirs = find( file => exists_in => $cmpdir, in => $searchdir );
cmp_ok( scalar(@in_both_dirs), '==', 3, 'in both dirs' );
my @newer_in_cmpdir = find( file => newer_in => $cmpdir, in => $searchdir );
cmp_ok( scalar(@newer_in_cmpdir), '==', 1, 'newer in cmpdir' );
my @older_in_cmpdir = find( file => older_in => $cmpdir, in => $searchdir );
cmp_ok( scalar(@older_in_cmpdir), '==', 1, 'older in cmpdir' );

my @ois = find( file => not_exists_in => [ $cmpdir ], in => $searchdir );
cmp_ok( scalar(@ois), '==', 1, 'only in searchdir (array ref)' );
my @ibd = find( file => exists_in => [ $cmpdir ], in => $searchdir );
cmp_ok( scalar(@ibd), '==', 3, 'in both dirs (array ref)' );
my @nic = find( file => newer_in => [ $cmpdir ], in => $searchdir );
cmp_ok( scalar(@nic), '==', 1, 'newer in cmpdir (array ref)' );
my @oic = find( file => older_in => [ $cmpdir ], in => $searchdir );
cmp_ok( scalar(@oic), '==', 1, 'older in cmpdir (array ref)' );
