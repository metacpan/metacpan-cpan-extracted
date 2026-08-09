#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use EreshkigalTest qw( test_dir );

use Ereshkigal::Kur;

my $dir = test_dir();

my %common = (
	'backend'        => 'dummy',
	'ports'          => ['22'],
	'protocols'      => ['tcp'],
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);

# hide the Error::Helper warn noise
local *STDERR;
open( STDERR, '>', \my $stderr_capture );

#
# name validation
#

throws_ok { Ereshkigal::Kur->new(%common) } qr/name is undef/, 'dies when name is undef';

foreach my $bad_name ( 'bad.name', 'bad name', 'bad/name', '' ) {
	throws_ok { Ereshkigal::Kur->new( %common, 'name' => $bad_name ) }
	( $bad_name eq '' ? qr/name is undef|does not match/ : qr/does not match/ ),
		'dies on invalid name "' . $bad_name . '"';
}

#
# backend validation
#

throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'backend' => undef ) }
qr/Failed to init the backend/, 'dies when backend is undef';

throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'backend' => 'nosuchbackend' ) }
qr/Failed to init the backend/, 'dies on a bogus backend';

#
# dir validation
#

open( my $block_fh, '>', $dir . '/blockfile' ) || die($!);
close($block_fh);
throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'run_base_dir' => $dir . '/blockfile' ) }
qr/does not exist or is not a directory/, 'dies when run_base_dir is a file';

throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'cache_base_dir' => $dir . '/blockfile' ) }
qr/does not exist or is not a directory/, 'dies when cache_base_dir is a file';

SKIP: {
	skip 'perms are meaningless when running as root', 2 if $> == 0;

	mkdir( $dir . '/ro-run' );
	chmod( 0500, $dir . '/ro-run' );
	throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'run_base_dir' => $dir . '/ro-run' ) }
	qr/not writable or readable/, 'dies when run_base_dir is not writable';

	mkdir( $dir . '/ro-cache' );
	chmod( 0500, $dir . '/ro-cache' );
	throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'cache_base_dir' => $dir . '/ro-cache' ) }
	qr/not writable or readable/, 'dies when cache_base_dir is not writable';

	chmod( 0700, $dir . '/ro-run' );
	chmod( 0700, $dir . '/ro-cache' );
} ## end SKIP:

#
# happy path
#

my $kur;
lives_ok {
	$kur = Ereshkigal::Kur->new( %common, 'name' => 'testy', 'prefix' => 'foo9', 'self_heal' => 0 );
}
'new lives with sane options';

is( $kur->socket_path, $dir . '/run/kur/testy.sock', 'socket_path' );
is( $kur->pid_path,    $dir . '/run/kur/testy.pid',  'pid_path' );
ok( -d $dir . '/run/kur', 'the kur dir under run_base_dir was created' );
ok( -d $dir . '/cache',   'the cache dir was created' );
is( $kur->{name},      'testy', 'name merged' );
is( $kur->{backend},   'dummy', 'backend merged' );
is( $kur->{prefix},    'foo9',  'prefix merged' );
is( $kur->{self_heal}, 0,       'self_heal merged' );
is_deeply( $kur->{ports},     ['22'],  'ports merged' );
is_deeply( $kur->{protocols}, ['tcp'], 'protocols merged' );
is_deeply(
	$kur->{stats},
	{
		'bans'         => 0,
		'unbans'       => 0,
		'cidr_bans'    => 0,
		'cidr_unbans'  => 0,
		'errors'       => 0,
		'expired'      => 0,
		'cidr_expired' => 0,
	},
	'stats initialized to zeros'
);
isa_ok( $kur->{backend_obj}, 'Net::Firewall::BlockerHelper', 'backend_obj' );

done_testing;
