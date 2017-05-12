use strict; # -*-cperl-*-*
use warnings;

use Test::More tests => 7;
use Test::Differences;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my $spec = LCFG::Build::PkgSpec->new_from_metafile('./t/lcfg.yml');

isa_ok( $spec, 'LCFG::Build::PkgSpec' );

my $clone = $spec->clone;

isnt( $spec, $clone, "needs to be a different reference" );

is_deeply( $spec, $clone, "A clone should be the same data as the original" );

$clone->update_release;

isnt( $spec->release, $clone->release, "release field should have changed" );

$clone->set_vcsinfo("genchangelog", 1);

is( $clone->get_vcsinfo("genchangelog"), 1, "correctly set vcsinfo");

isnt( $spec->get_vcsinfo("genchangelog"), $clone->get_vcsinfo("genchangelog"), "vcsinfo should have changed" );
