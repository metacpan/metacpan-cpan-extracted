use strict; # -*-perl-*-*
use warnings;

use Test::More tests => 34;
use Test::Exception;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my @files = qw/config.mk config2.mk/;

for my $file (@files) {

    my $spec = LCFG::Build::PkgSpec->new_from_cfgmk('./t/' . $file );

    isa_ok( $spec, 'LCFG::Build::PkgSpec' );

    is( $spec->name(), 'foo', 'name Accessor' );

    is( $spec->version(), '1.0.0', 'version Accessor' );

    is( $spec->release(), '1', 'release Accessor' );

    is( $spec->schema(), '1', 'schema Accessor' );

    is( $spec->base(), 'lcfg', 'base Accessor' );

    is( $spec->abstract(), 'An lcfg component to manage the foo daemon', 'abstract accessor' );

    is( $spec->group(), 'LCFG/System', 'group accessor' );

    is( $spec->license(), 'GPLv2', 'license accessor' );

    is( $spec->vendor(), 'University of Edinburgh', 'vendor accessor' );

    is( $spec->date, '02/10/07 17:37', 'correctly imported date' );

    is ( $spec->fullname(), 'lcfg-foo', 'fullname method' );

    # author, platforms

    is_deeply( [$spec->author()], ['"Stephen Quinney" <squinney@inf.ed.ac.uk>'], 'author accessor' );

    is_deeply( [$spec->platforms()], [qw/Fedora5 Fedora6 ScientificLinux5/], 'platforms accessor' );

    my @keys = sort $spec->ids_in_vcsinfo;

    is_deeply( \@keys, [qw/logname/], 'vcs info contains the correct keys' );

}

throws_ok { LCFG::Build::PkgSpec->new_from_cfgmk() } qr/^Error: You need to specify the LCFG config file name/, 'missing filename';

throws_ok { LCFG::Build::PkgSpec->new_from_cfgmk('') } qr/^Error: You need to specify the LCFG config file name/, 'missing filename';

throws_ok { LCFG::Build::PkgSpec->new_from_cfgmk('t/missingfile.mk') } qr/Error: Cannot find LCFG config file \'t\/missingfile.mk\'/, 'missing config file';
