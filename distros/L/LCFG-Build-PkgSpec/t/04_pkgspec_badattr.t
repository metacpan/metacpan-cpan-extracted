use strict; # -*-cperl-*-*
use warnings;

use Test::More tests => 5;
use Test::Exception;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

throws_ok { LCFG::Build::PkgSpec->new( version => '0.0.1' ) } qr/^Attribute \(name\) is required/, 'missing attribute';

throws_ok { LCFG::Build::PkgSpec->new_from_metafile() } qr/^Error: You need to specify the LCFG meta-data file name/, 'missing metafile name';

throws_ok { LCFG::Build::PkgSpec->new_from_metafile('') } qr/^Error: You need to specify the LCFG meta-data file name/, 'empty metafile name';

throws_ok { LCFG::Build::PkgSpec->new_from_metafile('t/missingfile.yml') } qr/^Error: Cannot find LCFG meta-data file \'t\/missingfile.yml\'/, 'missing metafile';

