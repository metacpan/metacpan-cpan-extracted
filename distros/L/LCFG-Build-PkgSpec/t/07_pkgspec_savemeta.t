use strict; # -*-cperl-*-*
use warnings;

use Test::More tests => 5;
use Test::Differences;
use Test::Exception;
use File::Temp ();
use IO::File;

BEGIN { use_ok( 'LCFG::Build::PkgSpec' ); }

my $spec = LCFG::Build::PkgSpec->new_from_metafile('./t/lcfg.yml');

isa_ok( $spec, 'LCFG::Build::PkgSpec' );

my $tmp = File::Temp->new( UNLINK => 1 );

$spec->save_metafile($tmp->filename);

my $expfh = IO::File->new( 't/expected.yml', 'r' );

my @exp = <$expfh>;

my @got = <$tmp>;

eq_or_diff \@got, \@exp, 'saved metafile', { context => 2 };

throws_ok { $spec->save_metafile() } qr/^Error: You need to specify the LCFG config file name/, 'Missing filename';

throws_ok { $spec->save_metafile('') } qr/^Error: You need to specify the LCFG config file name/, 'Missing filename';

