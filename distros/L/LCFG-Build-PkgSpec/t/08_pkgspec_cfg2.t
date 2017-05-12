use strict; # -*-cperl-*-*
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my $spec = LCFG::Build::PkgSpec->new( name    => 'foobar',
                                      version => '0.0.1' );

isa_ok( $spec, 'LCFG::Build::PkgSpec' );

is( $spec->name, 'foobar', 'check name is correctly set' );

$spec->new_from_cfgmk( 't/config.mk' );

isa_ok( $spec, 'LCFG::Build::PkgSpec' );

is( $spec->name, 'foo', 'check name has changed' );

is( $spec->date, '02/10/07 17:37', 'correctly imported date' );

throws_ok { LCFG::Build::PkgSpec::new_from_cfgmk( 'ook', 't/config.mk' ) } qr/^Can\'t locate object method \"new\" via package \"ook\"/, 'dies properly when called improperly';

throws_ok { LCFG::Build::PkgSpec::new_from_cfgmk( {}, 't/config.mk' ) } qr/^Error: new_from_cfgmk method called on wrong class or object/, 'dies properly when called improperly';

my $ref = bless {}, 'FooBar';

throws_ok { LCFG::Build::PkgSpec::new_from_cfgmk( $ref, 't/config.mk' ) } qr/^Error: new_from_cfgmk method called on wrong class or object/, 'dies properly when given a wrong class or object';
