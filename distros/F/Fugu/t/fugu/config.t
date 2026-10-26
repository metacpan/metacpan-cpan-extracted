#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use Cwd        qw(getcwd);
use File::Temp qw(tempdir);

use_ok('Fugu::Config');

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

# fixture($text): write a configuration file and return a loaded object
sub fixture ($text)
{
	my $path = sprintf '%s/fixture-%d.conf', $dir, ++$n;
	open my $fh, '>', $path or die "open $path: $!";
	print {$fh} $text;
	close $fh;

	return Fugu::Config->new( file => $path );
}

subtest 'both assignment forms parse' => sub {
	my $config = fixture(<<'CONF')->load;
log_level debug
hap_port = 51827
hap_name = "Home Bridge"
cache_dir ~/.cache/fuguvm
hap_pin  =  1995-1018
CONF

	ok( $config, 'the file loaded' );
	is( $config->get('log_level'), 'debug',        'key value' );
	is( $config->get('hap_port'),  '51827',        'key = value' );
	is( $config->get('hap_name'),  'Home Bridge',  'quotes are stripped' );
	is( $config->get('cache_dir'), '~/.cache/fuguvm', 'a tilde is kept' );
	is( $config->get('hap_pin'),   '1995-1018',    'spacing does not matter' );

	is( $config->get('absent'),          undef,  'an absent key is undef' );
	is( $config->get( 'absent', 'dflt' ), 'dflt', 'with a default' );

	is_deeply(
		[ $config->setting_names ],
		[qw(cache_dir hap_name hap_pin hap_port log_level)],
		'setting_names lists them sorted'
	);
};

subtest 'comments and blank lines' => sub {
	my $config = fixture(<<'CONF')->load;
# A leading comment

	# An indented comment
key value	# a trailing comment

CONF

	ok( $config, 'the file loaded' );
	is( $config->get('key'), 'value', 'the setting survived' );
	is_deeply( [ $config->setting_names ], ['key'],
		'a comment is not a setting' );
};

# A device-list grammar: repeated blocks of one type, where the order is
# the order the accessories appear in the bridge.
subtest 'a device list of repeated blocks' => sub {
	my $config = fixture(<<'CONF')->load;
hap_name = "Home Bridge"
db_path = /var/db/openhapd

device tasmota thermostat bedroom {
	name = "Bedroom Thermostat"
	topic = tasmota_AABBCC
}

device tasmota lightbulb kitchen {
	name = "Kitchen Light"
	topic = tasmota_LIGHT1
}

device tasmota sensor outdoor {
	name = "Outdoor Sensor"
	topic = tasmota_SENS01
}
CONF

	ok( $config, 'the file loaded' );
	is( $config->get('hap_name'), 'Home Bridge', 'a top-level setting' );

	my @devices = $config->blocks('device');
	is( scalar @devices, 3, 'three devices' );

	is_deeply(
		[ map { $_->{name} } @devices ],
		[qw(bedroom kitchen outdoor)],
		'in file order'
	);
	is_deeply(
		$devices[0]{args},
		[qw(tasmota thermostat bedroom)],
		'the header arguments are the type, subtype and id'
	);
	is( $devices[0]{settings}{name}, 'Bedroom Thermostat',
		'a block setting, unquoted' );
	is( $devices[1]{settings}{topic}, 'tasmota_LIGHT1',
		'a block setting of the second device' );

	is_deeply( [ $config->blocks('vm') ], [], 'an unused type is empty' );
};

# Each block carries its position in the file. blocks() answers for one
# type, so a caller that reads two types has nothing else to sort on.
subtest 'a block knows where in the file it is' => sub {
	my $config = fixture(<<'CONF')->load;
manuals "First" {
	dir = man/one
}

modules "Second" {
	dir = lib/two
}

manuals "Third" {
	dir = man/three
}
CONF

	ok( $config, 'the file loaded' );

	my @blocks = sort { $a->{order} <=> $b->{order} }
	    ( $config->blocks('manuals'), $config->blocks('modules') );

	is_deeply(
		[ map { $_->{name} } @blocks ],
		[qw(First Second Third)],
		'two types interleave as the file wrote them'
	);
	is( $blocks[0]{order}, 0, 'the count starts at zero' );
};

# A caller that accepts a fixed set of types reads the types of the
# parse, and refuses each type outside that set.
subtest 'block_types lists each type once, sorted' => sub {
	my $config = fixture(<<'CONF')->load;
log_level debug

modules "First" {
	dir = lib/one
}

manuals "Second" {
	dir = man/two
}

modules "Third" {
	dir = lib/three
}
CONF

	ok( $config, 'the file loaded' );
	is_deeply( [ $config->block_types ], [qw(manuals modules)],
		'two types, sorted, each one time' );
};

subtest 'a file with no block has no block type' => sub {
	my $config = fixture(<<'CONF')->load;
log_level debug
hap_port = 51827
CONF

	ok( $config, 'the file loaded' );
	is_deeply( [ $config->block_types ], [], 'the list is empty' );
};

# The FuguVM grammar: blocks addressed by name, and settings with no
# equals sign.
subtest 'a FuguVM named-VM file' => sub {
	my $config = fixture(<<'CONF')->load;
cache_dir ~/.cache/fuguvm
state_dir .fuguvm/state
default_vm default

vm "default" {
	version      7.8
	arch         arm64
	memory       2048
	disk_size    8G
}

vm builder {
	version 7.7
	memory  8192
}
CONF

	ok( $config, 'the file loaded' );
	is( $config->get('default_vm'), 'default', 'a top-level setting' );

	my $default = $config->block( 'vm', 'default' );
	ok( $default, 'the quoted block is addressable by name' );
	is( $default->{settings}{version}, '7.8', 'a bare key-value setting' );
	is( $default->{settings}{arch},    'arm64', 'and another' );

	my $builder = $config->block( 'vm', 'builder' );
	ok( $builder, 'the unquoted block is addressable too' );
	is( $builder->{settings}{memory}, '8192', 'with its own settings' );

	is( $config->block( 'vm', 'nonesuch' ), undef, 'an unknown name' );

	is( scalar $config->blocks('vm'), 2, 'both blocks are in the list' );
};

subtest 'a block name may hold a space' => sub {
	my $config = fixture(<<'CONF')->load;
vm "my machine" {
	memory 512
}
CONF

	ok( $config, 'the file loaded' );
	my $vm = $config->block( 'vm', 'my machine' );
	ok( $vm, 'the quoted name kept its space' );
	is( $vm->{settings}{memory}, '512', 'and its settings parsed' );
};

# The parser reads bytes. A UTF-8 character can hold 0x85 or 0xA0, and
# neither byte is white space here.
subtest 'a value keeps each byte of the file' => sub {
	my $config = fixture( "grave = voil\xc3\xa0\n"
		  . "han = \xe4\xb8\x85\n"
		  . "nbsp = a\xc2\xa0b\xc2\xa0\n" )->load;

	ok( $config, 'the file loaded' );
	is( unpack( 'H*', $config->get('grave') ),
		'766f696cc3a0', 'a value that ends in U+00E0' );
	is( unpack( 'H*', $config->get('han') ),
		'e4b885', 'a value that ends in U+4E05' );
	is( unpack( 'H*', $config->get('nbsp') ),
		'61c2a062c2a0', 'a value that holds U+00A0' );
};

subtest 'a block argument keeps each byte, quoted or not' => sub {
	my $config = fixture( "device \"voil\xc3\xa0\" \xe4\xb8\x85 {\n}\n"
		  . "device light a\xc2\xa0b {\n}\n"
		  . "device light voil\xc3\xa0{\n}\n" )->load;

	ok( $config, 'the file loaded' );
	my @args = map {
		[ map { unpack 'H*', $_ } @{ $_->{args} } ]
	} $config->blocks('device');
	is_deeply( $args[0], [ '766f696cc3a0', 'e4b885' ],
		'a quoted and a bare argument' );
	is_deeply( $args[1], [ '6c69676874', '61c2a062' ],
		'a bare argument that holds U+00A0' );
	is_deeply( $args[2], [ '6c69676874', '766f696cc3a0' ],
		'a bare argument against the brace' );
};

subtest 'only ASCII is white space or a word character' => sub {
	my $config = fixture("a = yes\n")->load;

	is( $config->parse_bool("yes\xa0"), 0, 'a 0xA0 byte is not a blank' );
	like( $config->error, qr/not a yes\/no value/, 'and records why' );

	my $key = fixture("cl\xc3\xa9 = 1\n");
	is( $key->load, undef, 'a key that holds U+00E9 fails' );
	like( $key->error, qr/:1: cannot parse/, 'and says where' );

	my $micro = fixture("\xc2\xb5 = 1\n");
	is( $micro->load, undef, 'a key of Latin-1 word bytes fails' );

	my $type = fixture("\xc2\xb5 name {\n}\n");
	is( $type->load, undef, 'a block type of Latin-1 word bytes fails' );
	like( $type->error, qr/not a block type/, 'and says why' );
};

subtest 'parse_bool' => sub {
	my $config = fixture(<<'CONF')->load;
a = yes
CONF

	ok( $config, 'the file loaded' );
	ok( $config->parse_bool($_), "$_ is true" )
	    for qw(yes true on 1);
	ok( !$config->parse_bool($_), "$_ is false" )
	    for qw(NO False off 0);

	is( $config->parse_bool( undef, 1 ),
		1, 'an absent value takes the default' );
	is( $config->parse_bool(undef), 0, 'and 0 without one' );

	is( $config->parse_bool( 'maybe', 1 ),
		1, 'an unreadable value takes the default' );
	like( $config->error, qr/not a yes\/no value: maybe/,
		'and records why' );
};

subtest 'a malformed line fails with its position' => sub {
	my $config = fixture(<<'CONF');
good = 1
!!! this is not a setting
CONF

	is( $config->load, undef, 'load reports the failure' );
	like( $config->error, qr/:2: cannot parse/,
		'the error names the line number' );
	like( $config->error, qr/\Q$dir\E/, 'and the file' );
};

subtest 'brace errors' => sub {
	my $unterminated = fixture(<<'CONF');
device a b c {
	name = x
CONF
	is( $unterminated->load, undef, 'an unterminated block fails' );
	like( $unterminated->error, qr/unterminated device block/,
		'and says so' );

	my $stray = fixture(<<'CONF');
key = value
}
CONF
	is( $stray->load, undef, 'a stray closing brace fails' );
	like( $stray->error, qr/:2: closing brace outside a block/,
		'and says where' );

	my $nested = fixture(<<'CONF');
outer a {
	inner b {
	}
}
CONF
	is( $nested->load, undef, 'a nested block fails' );
	like( $nested->error, qr/a block cannot hold a block/, 'and says why' );

	my $headless = fixture(<<'CONF');
lonely {
}
CONF
	is( $headless->load, undef, 'a block with no name fails' );
	like( $headless->error, qr/a block needs a type and a name/,
		'and says why' );
};

subtest 'an unreadable file is an error, not empty defaults' => sub {
	my $config = Fugu::Config->new( file => "$dir/no-such-file.conf" );

	is( $config->load, undef, 'load returns undef' );
	like( $config->error, qr/Cannot open/, 'and says why' );

	ok( !eval { Fugu::Config->new; 1 }, 'new needs a file' );
};

subtest 'load starts over' => sub {
	my $path = "$dir/reload.conf";

	open my $fh, '>', $path or die "open $path: $!";
	print {$fh} "a = 1\nb = 2\n";
	close $fh;

	my $config = Fugu::Config->new( file => $path );
	$config->load;
	is_deeply( [ $config->setting_names ], [qw(a b)], 'both settings' );

	open $fh, '>', $path or die "open $path: $!";
	print {$fh} "a = 9\n";
	close $fh;

	$config->load;
	is_deeply( [ $config->setting_names ], ['a'],
		'a removed setting is gone after a reload' );
	is( $config->get('a'), '9', 'and the value is the new one' );
};

subtest 'find_project_root walks up to the marker' => sub {
	my $root = tempdir( CLEANUP => 1 );
	mkdir "$root/a"   or die "mkdir: $!";
	mkdir "$root/a/b" or die "mkdir: $!";

	open my $fh, '>', "$root/.marker" or die "open: $!";
	close $fh;

	my $cwd = getcwd();
	chdir "$root/a/b" or die "chdir: $!";
	my $found = Fugu::Config->find_project_root('.marker');
	my $none  = Fugu::Config->find_project_root('.no-such-marker');
	chdir $cwd or die "chdir: $!";

	# The temporary directory can sit behind a symlink, so compare
	# what the filesystem resolves rather than the two strings.
	ok( defined $found, 'the walk found a root' );
	ok( defined $found && ( stat $found )[1] == ( stat $root )[1],
		'and it is the directory that holds the marker' );
	is( $none, undef, 'a marker that does not exist gives undef' );

	ok( !eval { Fugu::Config->find_project_root; 1 },
		'find_project_root needs a marker' );
};

done_testing();
