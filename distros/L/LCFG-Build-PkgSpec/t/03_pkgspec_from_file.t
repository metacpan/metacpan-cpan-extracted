use strict; # -*-cperl-*-*
use warnings;

use Test::More tests => 22;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my $spec = LCFG::Build::PkgSpec->new_from_metafile('./t/lcfg.yml');

isa_ok( $spec, 'LCFG::Build::PkgSpec' );

is( $spec->name(), 'foo', 'name Accessor' );

is( $spec->version(), '1.0.0', 'version Accessor' );

is( $spec->release(), '1', 'release Accessor' );

is( $spec->schema(), '1', 'schema Accessor' );

is( $spec->base(), 'lcfg', 'base Accessor' );

is( $spec->abstract(), 'An lcfg component to manage the foo daemon', 'abstract accessor' );

is( $spec->group(), 'LCFG/System', 'group accessor' );

is( $spec->license(), 'GPL', 'license accessor' );

is( $spec->vendor(), 'University of Edinburgh', 'vendor accessor' );

is( $spec->date(), '02/20/08 12:12:27', 'date accessor' );

is ( $spec->fullname(), 'lcfg-foo', 'fullname method' );

# author, platforms

is_deeply( [$spec->author()], ['Stephen Quinney <squinney@inf.ed.ac.uk>'], 'author accessor' );

is_deeply( [$spec->platforms()], [qw/Fedora5 Fedora6 ScientificLinux5/], 'platforms accessor' );

my @keys = sort $spec->ids_in_vcsinfo;

is_deeply( \@keys, [qw/checkcommitted genchangelog type/] );

is( $spec->exists_in_vcsinfo('type'), 1, 'VCS type is specified' );

is ( $spec->get_vcsinfo('type'), 'CVS', 'VCS type is correct' );


is( $spec->exists_in_vcsinfo('checkcommitted'), 1, 'VCS checkcommitted is specified' );

is ( $spec->get_vcsinfo('checkcommitted'), 1, 'VCS checkcommitted is correct' );


is( $spec->exists_in_vcsinfo('genchangelog'), 1, 'VCS genchangelog specified' );

is ( $spec->get_vcsinfo('genchangelog'), 0, 'VCS genchangelog is correct' );
