use strict; # -*-cperl-*-*
use warnings;

use Test::More tests => 8;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my $spec = LCFG::Build::PkgSpec->new( name    => 'foo',
                                      version => '0.0.1' );

isa_ok( $spec, 'LCFG::Build::PkgSpec' );

is( $spec->name(), 'foo', 'Name Accessor' );

is( $spec->version(), '0.0.1', 'Version Accessor' );

is( $spec->release(), '1', 'Release Accessor' );

is( $spec->schema(), '1', 'Schema Accessor' );

is ( $spec->fullname(), 'foo', 'fullname method' );

is ( $spec->tarname(), 'foo-0.0.1.tar.gz', 'tarname method' );
