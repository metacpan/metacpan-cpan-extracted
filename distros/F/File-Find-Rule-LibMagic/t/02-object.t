#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;

use File::Find::Rule::LibMagic;

use Test::More tests => 3;

sub get_finder
{
    my $finder;
    eval {
	$finder = File::Find::Rule->ignore_vcs()
				  ->file();
    };
    $finder = File::Find::Rule->file() unless( defined( $finder ) );

    return $finder;
}

eval {
    require File::Find::Rule::VCS;
} if( $ENV{RELEASE_TESTING} );

my $searchdir = File::Spec->catdir( $FindBin::Bin, 'samples' );
my @executables = get_finder()->magic( '*script text executable' )
                              ->in( $searchdir );
cmp_ok( scalar(@executables), '==', 2, 'find by magic' );

my @xfiles_all = get_finder()->mime( 'text/x-*' )
                        ->in( $searchdir );
cmp_ok( scalar( @xfiles_all ), '==', 4, 'find by MIME types (single)' );

my @xfiles_selected = get_finder()->mime( 'text/x-perl*', 'text/x-shellscript*' )
                             ->in( $searchdir );
cmp_ok( scalar( @xfiles_selected ), '==', 2, 'find by MIME types (multiple)' );
