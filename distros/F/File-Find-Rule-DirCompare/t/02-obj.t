#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Touch;

use File::Find::Rule::DirCompare;

use Test::More tests => 5;

my $searchdir = File::Spec->catdir( $FindBin::Bin, 'samples', 'search' );
my $comparedir = File::Spec->catdir( $FindBin::Bin, 'samples', 'compare' );

touch( File::Spec->catfile( $searchdir, 'newer_in_search' ) );
touch( File::Spec->catfile( $comparedir, 'newer_in_compare' ) );

my $FindNE = File::Find::Rule->file()
                             ->not_exists_in( $comparedir );
my @foo = $FindNE->in( $searchdir );
cmp_ok( scalar(@foo), '==', 1, 'not exist in' );


my $FindE = File::Find::Rule->file()
                            ->exists_in( $comparedir );
my @bar = $FindE->in( $searchdir );
cmp_ok( scalar(@bar), '==', 3, 'exists in' );

my $FindN = File::Find::Rule->file()
                            ->newer_in( $comparedir );
my @newer = $FindN->in( $searchdir );
cmp_ok( scalar(@newer), '==', 1, 'newer in' );

my $FindO = File::Find::Rule->file()
                            ->older_in( $comparedir );
my @older = $FindO->in( $searchdir );
cmp_ok( scalar(@older), '==', 1, 'older in' );

my $FindNON = File::Find::Rule->file()
                              ->or(
				    File::Find::Rule->new->not_exists_in( $comparedir ),
				    File::Find::Rule->new->newer_in( $comparedir ),
				);
my @newerOrNewly = $FindNON->in( $searchdir );
cmp_ok( scalar(@newerOrNewly), '==', 2, 'Newer or newly created' );
