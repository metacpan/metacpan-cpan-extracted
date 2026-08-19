#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use Fugu::Log;

use_ok('Fugu::File');

# The module reports recoverable failures through the default logger.
# A quiet default keeps the expected failures out of the TAP stream.
Fugu::Log->set_default( Fugu::Log->new( mode => 'quiet' ) );

my $dir = tempdir( CLEANUP => 1 );

# mode_of($path): the permission bits of a file
sub mode_of ($path)
{
	return ( stat $path )[2] & 07777;
}

subtest 'read and write round-trip' => sub {
	my $path = "$dir/plain.txt";

	ok( Fugu::File->write( $path, "hello\n" ), 'write reports success' );
	is( Fugu::File->read($path), "hello\n", 'read returns the bytes' );

	ok( Fugu::File->write( $path, '' ), 'an empty write succeeds' );
	is( Fugu::File->read($path), '', 'and reads back empty' );

	is( Fugu::File->read("$dir/absent.txt"),
		undef, 'an absent file reads as undef' );
	is( Fugu::File->write( "$dir/no-such-dir/x", 'x' ),
		undef, 'an unwritable path returns undef' );
};

subtest 'binary content survives' => sub {
	my $path = "$dir/binary.bin";
	my $data = join '', map { chr } 0 .. 255;

	Fugu::File->write( $path, $data );
	is( Fugu::File->read($path), $data, 'every byte round-trips' );
	is( -s $path, 256, 'and the file is the right length' );
};

subtest 'the mode is set before the content' => sub {
	my $path = "$dir/secret.txt";

	Fugu::File->write( $path, 'a secret', mode => 0600 );
	is( mode_of($path), 0600, 'write applies the mode' );

	# An existing file must not keep a wider mode
	Fugu::File->write( $path, 'a secret again', mode => 0600 );
	is( mode_of($path), 0600, 'a rewrite keeps the mode' );

	my $atomic = "$dir/secret-atomic.txt";
	Fugu::File->write_atomic( $atomic, 'a secret', mode => 0600 );
	is( mode_of($atomic), 0600, 'write_atomic applies the mode' );
};

subtest 'write_atomic publishes by rename' => sub {
	my $path = "$dir/atomic.txt";

	Fugu::File->write( $path, "old\n" );
	ok( Fugu::File->write_atomic( $path, "new\n" ), 'atomic write' );
	is( Fugu::File->read($path), "new\n", 'the content replaced' );

	# No temporary file is left behind
	opendir my $dh, $dir or die "opendir $dir: $!";
	my @temps = grep { /^\.atomic\.txt\./ } readdir $dh;
	closedir $dh;
	is_deeply( \@temps, [], 'no temporary file remains' );

	is( Fugu::File->write_atomic( "$dir/no-such-dir/x", 'x' ),
		undef, 'an unwritable directory returns undef' );
};

subtest 'JSON files' => sub {
	my $path = "$dir/state.json";
	my $data = { count => 3, name => 'bridge', list => [ 1, 2 ] };

	ok( Fugu::File->write_json( $path, $data ), 'write_json' );
	is_deeply( Fugu::File->read_json($path), $data, 'read_json' );

	# Canonical encoding: the same data always gives the same bytes
	my $first = Fugu::File->read($path);
	Fugu::File->write_json( $path, $data );
	is( Fugu::File->read($path), $first, 'the encoding is stable' );

	is( Fugu::File->read_json("$dir/absent.json"),
		undef, 'an absent JSON file reads as undef' );

	Fugu::File->write( "$dir/broken.json", '{not json' );
	is( Fugu::File->read_json("$dir/broken.json"),
		undef, 'a corrupt JSON file reads as undef' );

	Fugu::File->write( "$dir/empty.json", '' );
	is( Fugu::File->read_json("$dir/empty.json"),
		undef, 'an empty JSON file reads as undef' );
};

# The window that this closes: the old code opened the file, wrote the
# content, and chmodded afterwards. A metadata file that carries a
# guest root password was therefore world-readable while it held the
# password.
#
# To observe the window, the payload is an object whose stringify
# overload runs inside the write. At that moment the file exists and
# holds nothing, so the mode it has then is the mode it will have when
# the first byte lands.
{

	package SecretProbe;
	use overload
	    '""'     => \&reveal,
	    fallback => 1;

	our $dir;
	our $prefix;
	our $mode_when_written;

	sub reveal ( $self, @ )
	{
		opendir my $dh, $dir or return 'the secret';
		my @found = grep { index( $_, $prefix ) == 0 } readdir $dh;
		closedir $dh;

		for my $name (@found) {
			$mode_when_written = ( stat "$dir/$name" )[2] & 07777;
		}

		return 'the secret';
	}
}

subtest 'a write never exposes a secret' => sub {
	local $SecretProbe::dir               = $dir;
	local $SecretProbe::prefix            = '.probe.txt.';
	local $SecretProbe::mode_when_written = undef;

	my $path = "$dir/probe.txt";
	ok(
		Fugu::File->write_atomic(
			$path, ( bless {}, 'SecretProbe' ), mode => 0600
		),
		'wrote through the probe'
	);

	is( $SecretProbe::mode_when_written, 0600,
		'the file had its final mode before it had content' );
	is( mode_of($path), 0600, 'and the published file is 0600' );

	# The end-to-end path a caller uses
	my $json = "$dir/password.json";
	Fugu::File->write_json( $json, { password => 'hunter2' },
		mode => 0600 );
	is( mode_of($json), 0600, 'write_json publishes at 0600' );
	is( Fugu::File->read_json($json)->{password},
		'hunter2', 'and the content arrived' );
};

subtest 'ensure_dir' => sub {
	my $path = "$dir/a/b/c";

	ok( Fugu::File->ensure_dir($path), 'creates a nested directory' );
	ok( -d $path,                         'the directory exists' );
	ok( Fugu::File->ensure_dir($path), 'a second call succeeds' );

	# A path that is a file is not a directory to write through
	my $file = "$dir/not-a-dir";
	Fugu::File->write( $file, 'x' );
	is( Fugu::File->ensure_dir($file), undef, 'refuses a plain file' );

	SKIP: {
		skip 'symlinks unavailable', 1
		    unless eval { symlink '', ''; 1 };

		my $link = "$dir/linked";
		symlink $path, $link or skip 'cannot create a symlink', 1;
		is( Fugu::File->ensure_dir($link),
			undef, 'refuses a symlink' );
	}
};

subtest 'expand_tilde' => sub {
	local $ENV{HOME} = '/home/tester';

	is( Fugu::File->expand_tilde('~/.cache/x'),
		'/home/tester/.cache/x', 'a leading ~ expands' );
	is( Fugu::File->expand_tilde('~'), '/home/tester', 'a bare ~ expands' );
	is( Fugu::File->expand_tilde('/absolute/path'),
		'/absolute/path', 'an absolute path is unchanged' );
	is( Fugu::File->expand_tilde('relative/~/path'),
		'relative/~/path', 'a ~ in the middle is unchanged' );
	is( Fugu::File->expand_tilde('~other/path'),
		'~other/path', 'another user is left alone' );
	is( Fugu::File->expand_tilde(undef), undef, 'undef stays undef' );
};

subtest 'share_path finds a shipped file' => sub {
	# The caller passes its own module file, so a file that the
	# checkout ships resolves from any working directory.
	my $found = Fugu::File->share_path( 'Makefile',
		from => "$RealBin/../../lib/Fugu/File.pm" );
	ok( defined $found, 'a shipped file resolves' );
	ok( -f $found,      'and the path exists' );

	is( Fugu::File->share_path('no/such/file/anywhere'),
		undef, 'a missing file resolves to undef' );

	my $root = tempdir( CLEANUP => 1 );
	mkdir "$root/share";
	Fugu::File->write( "$root/share/thing", 'x' );
	is( Fugu::File->share_path( 'share/thing', root => $root ),
		"$root/share/thing", 'an explicit root wins' );

	# from names a checkout: the directory above the deepest lib
	# component is the root of the tree that ships the data.
	is( Fugu::File->share_path(
			'share/thing', from => "$root/lib/App/Thing/Deep.pm"
		),
		"$root/share/thing",
		'from anchors the checkout root'
	);

	# dist names the installed layout under @INC. The leading
	# share/ component never appears in an installed tree.
	my $inc = tempdir( CLEANUP => 1 );
	Fugu::File->ensure_dir("$inc/auto/share/dist/App-Thing");
	Fugu::File->write( "$inc/auto/share/dist/App-Thing/data", 'x' );
	local @INC = ( @INC, $inc );
	is( Fugu::File->share_path( 'share/data', dist => 'App-Thing' ),
		"$inc/auto/share/dist/App-Thing/data",
		'dist resolves the installed share tree'
	);
};

subtest 'atomic_dir publishes or leaves nothing' => sub {
	my $target = "$dir/tree/entry";

	my $built = Fugu::File->atomic_dir(
		$target,
		sub ($tmp) {
			Fugu::File->write( "$tmp/base", 'content' );
			return 1;
		} );

	is( $built, $target, 'atomic_dir returns the target' );
	ok( -d $target, 'the directory is published' );
	is( Fugu::File->read("$target/base"), 'content', 'with its content' );

	# A build that fails leaves no partial tree
	my $failed = "$dir/tree/failed";
	is(
		Fugu::File->atomic_dir(
			$failed,
			sub ($tmp) {
				Fugu::File->write( "$tmp/half", 'x' );
				return 0;
			} ),
		undef,
		'a false return discards the build'
	);
	ok( !-e $failed, 'and nothing is published' );

	# A build that dies is the same
	my $died = "$dir/tree/died";
	is(
		Fugu::File->atomic_dir( $died, sub ($) { die "nope\n" } ),
		undef, 'a die discards the build' );
	ok( !-e $died, 'and nothing is published' );

	# No leftovers in the parent
	is( Fugu::File->sweep_temp("$dir/tree"),
		0, 'no build directories are left behind' );

	# A target that exists is not overwritten
	is( Fugu::File->atomic_dir( $target, sub ($) { 1 } ),
		undef, 'an existing target is refused' );
	is( Fugu::File->read("$target/base"),
		'content', 'and its content is intact' );
};

subtest 'sweep_temp removes an orphan build directory' => sub {
	my $parent = "$dir/sweep";
	Fugu::File->ensure_dir($parent);

	mkdir "$parent/.tmp.99999.1" or die "mkdir: $!";
	mkdir "$parent/keep"         or die "mkdir: $!";

	is( Fugu::File->sweep_temp($parent), 1, 'one orphan removed' );
	ok( !-e "$parent/.tmp.99999.1", 'the orphan is gone' );
	ok( -d "$parent/keep",          'a real entry stays' );

	is( Fugu::File->sweep_temp("$dir/no-such-parent"),
		0, 'an absent parent sweeps nothing' );
};

subtest 'valid_name refuses what escapes a directory' => sub {
	ok( Fugu::File->valid_name('default'),   'a plain name' );
	ok( Fugu::File->valid_name('a-b_c.1'),   'punctuation that is safe' );
	ok( Fugu::File->valid_name('x' x 255),   'the longest allowed name' );

	ok( !Fugu::File->valid_name(undef),      'undef' );
	ok( !Fugu::File->valid_name(''),         'the empty string' );
	ok( !Fugu::File->valid_name('x' x 256),  'a name that is too long' );
	ok( !Fugu::File->valid_name('a/b'),      'a path separator' );
	ok( !Fugu::File->valid_name('../etc'),   'a traversal' );
	ok( !Fugu::File->valid_name('.'),        'the current directory' );
	ok( !Fugu::File->valid_name('..'),       'the parent directory' );
	ok( !Fugu::File->valid_name("a\x00b"),   'an embedded NUL' );
};

done_testing();
