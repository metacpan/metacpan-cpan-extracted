#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;

use File::Find::Rule::LibMagic;

use Test::More tests => 3;

my $searchdir = File::Spec->catdir( $FindBin::Bin, 'samples' );
my @executables = grep { ! /\.svn/ } find( file => magic => '*script text executable', in => $searchdir );
cmp_ok( scalar(@executables), '==', 2, 'find by magic' );

my @xfiles_all = grep { ! /\.svn/ } find( file => mime => 'text/x-*', in => $searchdir );
cmp_ok( scalar( @xfiles_all ), '==', 4, 'find by one MIME type' );

my @xfiles_selected = grep { ! /\.svn/ } find( file => mime => [ 'text/x-perl*', 'text/x-shellscript*' ], in => $searchdir );
cmp_ok( scalar( @xfiles_selected ), '==', 2, 'find by multiple MIME types' );
