#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Guards for Fugu::Signer
#
# The parent class drives a command, and every real command of a
# subclass is optional on a host. The test therefore writes its own
# command: a shell script that plays the three verbs, records each run
# in a log beside itself, and fails on demand. Four stub subclasses
# hold the hooks over it.
#
# The stub command reports what only it can see: the mode of the
# private directory at the moment it writes the secret half, and the
# key of each run of the walk. The assertions of the private directory
# and of the trust order rest on that log.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Basename qw(basename dirname);
use File::Temp     qw(tempdir);
use FindBin        qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Fugu::Signer');

my $WORK = tempdir( 'fugu-signer-XXXXXXXX', TMPDIR => 1, CLEANUP => 1 );

# The stub subclass under test. It names a command that no host holds,
# and each hook writes one command line over the verbs of the stub
# command.
package Stub::Signer {
	our @ISA = ('Fugu::Signer');

	sub _command_label ($)
	{
		return 'stub';
	}

	sub _command_defaults ($)
	{
		return ('fugu-stub-signer');
	}

	sub _generate ( $self, %args )
	{
		$self->_run( [ 'generate', $args{public}, $args{secret} ],
			"cannot generate $args{public}" )
		    or return;

		return 1;
	}

	sub _sign ( $self, %args )
	{
		$self->_run(
			[
				'sign',        $args{secret},
				$args{file},   $args{signature}
			],
			"cannot sign $args{file}"
		) or return;

		return 1;
	}

	sub _verify ( $self, $key, %args )
	{
		$self->_command or return $self->error;

		$self->_run(
			[ 'verify', $key, $args{file}, $args{signature} ] )
		    or return $self->error;

		return;
	}
}

# A second subclass, for the helper lifecycle alone. It records the
# state of the directory at the moment the parent stops the helpers,
# so the order of the two steps is visible.
package Stub::Helper {
	our @ISA = ('Stub::Signer');
	our @STOPPED;

	sub _stop_helpers ( $, $dir )
	{
		push @STOPPED, ( -d $dir ? "live $dir" : "gone $dir" );
		return;
	}
}

# A third subclass, for a start failure that is no failed execve(2).
# The signer hook and the verifier hook each run the command in a
# directory that does not exist. Fugu::Process then stops in the child
# before the execve(2), and it answers the reason in error.
package Stub::Cwd {
	our @ISA = ('Stub::Signer');

	sub _sign ( $self, %args )
	{
		$self->_run(
			[ 'sign', $args{secret}, $args{file},
				$args{signature}
			],
			"cannot sign $args{file}",
			cwd => "$args{file}.absent"
		) or return;

		return 1;
	}

	sub _verify ( $self, $key, %args )
	{
		$self->_command or return $self->error;

		$self->_run(
			[ 'verify', $key, $args{file}, $args{signature} ],
			undef, cwd => "$args{file}.absent"
		) or return $self->error;

		return;
	}
}

# A fourth subclass, for a temporary directory that the module cannot
# make. The verifier hook runs the command under a private directory,
# as Fugu::OpenPGP runs each key under a temporary home. The parent of
# that directory does not exist, so mkdir fails and no run starts.
package Stub::Temp {
	our @ISA = ('Stub::Signer');

	sub _verify ( $self, $key, %args )
	{
		$self->_command or return $self->error;

		my $verified = $self->_with_temp_dir(
			"$args{file}.absent",
			sub ($) {
				return $self->_run(
					[
						'verify', $key,
						$args{file},
						$args{signature}
					] );
			} );

		return if $verified;

		return $self->error;
	}
}

# The command of the test. It plays one verb of a signing command.
# generate reports the mode of the directory that holds the secret
# half, because no other caller sees that directory. verify passes for
# a key file that holds the word good, and fails with the diagnostic
# of signify(1) for every other key.
my $STUB = <<'SH';
#!/bin/sh
log="$0.log"
verb="$1"
shift
case "$verb" in
generate)
	printf 'public\n' > "$1" || exit 1
	printf 'secret\n' > "$2" || exit 1
	mode=$(ls -ld "$(dirname "$2")" | cut -d' ' -f1)
	printf 'generate %s %s\n' "$mode" "$2" >> "$log"
	;;
sign)
	printf 'signature\n' > "$3" || exit 1
	printf 'sign %s\n' "$3" >> "$log"
	;;
verify)
	printf 'verify %s\n' "$1" >> "$log"
	grep -q good "$1" 2>/dev/null || {
		printf 'stub: checked against wrong key\n' >&2
		exit 1
	}
	;;
esac
exit 0
SH

my $stubs = 0;

# stub($body):
#	Write an executable stub command in a directory of its own, and
#	answer its path. Each stub takes one directory, so a test that
#	puts the directory on PATH resolves that stub alone.
sub stub ( $body = $STUB )
{
	my $bin = "$WORK/bin" . ++$stubs;
	mkdir $bin or die "Cannot create $bin: $!";
	my $path = "$bin/fugu-stub-signer";
	write_file( $path, $body );
	chmod 0755, $path or die "Cannot chmod $path: $!";

	return $path;
}

# write_file($path, $bytes):
#	Write a fixture file, and answer the path.
sub write_file ( $path, $bytes )
{
	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $bytes;
	close $fh or die "Cannot close $path: $!";

	return $path;
}

# runs($command):
#	The log lines of one stub command, in order. An absent log means
#	that the command never ran.
sub runs ($command)
{
	open my $fh, '<', "$command.log" or return ();
	my @lines = <$fh>;
	close $fh;
	chomp @lines;

	return @lines;
}

# mode($path):
#	The permission bits of a path.
sub mode ($path)
{
	return ( stat $path )[2] & 07777;
}

# entries($dir):
#	Every name in a directory, except the two that every directory
#	holds. A private directory that a call left behind shows here.
sub entries ($dir)
{
	opendir my $dh, $dir or die "Cannot read $dir: $!";
	my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	return @names;
}

# work($name):
#	A fresh working directory of one subtest.
sub work ($name)
{
	my $dir = "$WORK/$name";
	mkdir $dir or die "Cannot create $dir: $!";

	return $dir;
}

subtest 'new resolves the command once' => sub {
	my $command = stub();
	my $signer  = Stub::Signer->new( command => $command );

	is( $signer->is_available,   1,        'is_available returns 1' );
	is( $signer->command,        $command, 'command returns the path' );
	is( $signer->error,          undef,    'error is undef' );
	is( $signer->command_absent, 0,        'command_absent returns 0' );
	my @started = runs($command);
	is( scalar @started, 0, 'and new runs no process' );

	# The search list of the subclass reaches find_command, so a
	# caller that names no command takes the default name.
	local $ENV{PATH} = dirname($command);
	my $found = Stub::Signer->new;
	is( $found->command, $command, 'the default list resolves a command' );
};

subtest 'new must not die for an absent command' => sub {
	my $named =
	    eval { Stub::Signer->new( command => "$WORK/no-such-command" ) };
	is( $@, '', 'new does not die' );
	ok( defined $named, 'and it answers an object' );

	is( $named->is_available,   0,     'is_available returns 0' );
	is( $named->command,        undef, 'command returns undef' );
	is( $named->command_absent, 1,     'command_absent returns 1' );
	like( $named->error, qr{\Qno executable stub command: $WORK\E},
		'error names the command that resolved nothing' );

	# With no name the reason names the search list of the subclass.
	local $ENV{PATH} = '';
	my $bare = Stub::Signer->new;
	is( $bare->error, 'no executable stub command: fugu-stub-signer',
		'and with no name it names the search list' );
};

subtest 'new takes the timeout of the caller' => sub {
	my $command = stub();

	my $default = Stub::Signer->new( command => $command );
	is( $default->{timeout}, 30, 'the default timeout is 30 seconds' );

	my $named = Stub::Signer->new( command => $command, timeout => 5 );
	is( $named->{timeout}, 5, 'and the caller names its own' );

	for my $bad ( 0, -1, 'soon', '' ) {
		eval {
			Stub::Signer->new(
				command => $command,
				timeout => $bad
			);
		};
		like( $@, qr/timeout must be a positive number/,
			"the timeout $bad dies" );
	}
};

subtest 'a method that needs an absent command reports it' => sub {
	my $dir    = work('absent');
	my $signer = Stub::Signer->new( command => "$WORK/no-such-command" );
	my $file   = write_file( "$dir/file", "payload\n" );
	my $key    = write_file( "$dir/key",  "good\n" );
	my $sig    = write_file( "$dir/file.sig", "signature\n" );

	is(
		$signer->generate(
			public => "$dir/made.pub",
			secret => "$dir/made.sec"
		),
		undef,
		'generate returns undef'
	);
	is( $signer->command_absent, 1, 'command_absent returns 1' );
	ok( !-e "$dir/made.sec", 'and it wrote no secret half' );

	is(
		$signer->sign(
			secret    => $key,
			file      => $file,
			signature => "$dir/out.sig"
		),
		undef,
		'sign returns undef'
	);
	is( $signer->command_absent, 1, 'command_absent returns 1' );

	is(
		$signer->verify(
			keys      => [$key],
			file      => $file,
			signature => $sig
		),
		undef,
		'verify returns undef'
	);
	is( $signer->command_absent, 1, 'command_absent returns 1' );
	like( $signer->error, qr/\Ano executable stub command/,
		'and the reason of the walk stands alone' );
};

subtest 'a failed execve reports an absent command' => sub {
	my $dir     = work('execve');
	my $command = stub();
	my $signer  = Stub::Signer->new( command => $command );
	my $file    = write_file( "$dir/file", "payload\n" );
	my $key     = write_file( "$dir/key",  "secret\n" );

	# new resolved the command, and the command goes before the
	# run. The child then fails to execve(2), and that failure is
	# an install problem like an unresolved command.
	unlink $command or die "Cannot remove $command: $!";

	is(
		$signer->sign(
			secret    => $key,
			file      => $file,
			signature => "$dir/out.sig"
		),
		undef,
		'sign returns undef'
	);
	is( $signer->command_absent, 1, 'command_absent returns 1' );
	like( $signer->error, qr/Cannot exec/, 'and the reason names the exec' );
};

subtest 'a start failure is no absent command' => sub {
	my $dir     = work('start');
	my $command = stub();
	my $signer  = Stub::Cwd->new( command => $command );
	my $file    = write_file( "$dir/file", "payload\n" );
	my $key     = write_file( "$dir/key",  "secret\n" );

	# The run reports a reason of its own, and the command never
	# execs. Such a failure is no install problem, so the flag
	# stays at 0.
	is(
		$signer->sign(
			secret    => $key,
			file      => $file,
			signature => "$dir/out.sig"
		),
		undef,
		'sign returns undef'
	);
	like(
		$signer->error,
		qr/\Acannot sign \Q$file\E: Cannot chdir to /,
		'the reason names the act and the directory'
	);
	is( $signer->command_absent, 0, 'command_absent returns 0' );
	my @none = runs($command);
	is( scalar @none, 0, 'and the command never ran' );
};

subtest 'a run that failed is no absent command' => sub {
	my $dir     = work('failed');
	my $command = stub(<<'SH');
#!/bin/sh
printf 'stub: the key is no key\n' >&2
exit 1
SH
	my $signer = Stub::Signer->new( command => $command );
	my $file   = write_file( "$dir/file", "payload\n" );
	my $key    = write_file( "$dir/key",  "secret\n" );

	is(
		$signer->sign(
			secret    => $key,
			file      => $file,
			signature => "$dir/out.sig"
		),
		undef,
		'sign returns undef'
	);
	is(
		$signer->error,
		"cannot sign $file: stub: the key is no key",
		'the reason names the act and the diagnostic'
	);
	is( $signer->command_absent, 0, 'command_absent returns 0' );

	# A command that writes no diagnostic leaves the exit code.
	my $quiet = Stub::Signer->new( command => stub("#!/bin/sh\nexit 3\n") );
	is(
		$quiet->sign(
			secret    => $key,
			file      => $file,
			signature => "$dir/out.sig"
		),
		undef,
		'a quiet failure returns undef'
	);
	is( $quiet->error, "cannot sign $file: exit code 3",
		'and the reason names the exit code' );
};

subtest 'one run ends within the timeout' => sub {
	my $dir     = work('timeout');
	my $command = stub("#!/bin/sh\nsleep 30\n");
	my $signer  = Stub::Signer->new( command => $command, timeout => 1 );
	my $file    = write_file( "$dir/file", "payload\n" );
	my $key     = write_file( "$dir/key",  "secret\n" );

	my $start = time;
	is(
		$signer->sign(
			secret    => $key,
			file      => $file,
			signature => "$dir/out.sig"
		),
		undef,
		'sign returns undef'
	);
	my $elapsed = time - $start;

	is( $signer->error, "cannot sign $file: timeout after 1 seconds",
		'the reason names the timeout' );
	is( $signer->command_absent, 0, 'a timeout is no absent command' );
	ok( $elapsed < 15, "and the run ended near the deadline ($elapsed s)" );
};

subtest 'a command method refuses an input that is no plain file' => sub {
	my $dir     = work('input');
	my $command = stub();
	my $signer  = Stub::Signer->new( command => $command );
	my $file    = write_file( "$dir/file", "payload\n" );
	my $key     = write_file( "$dir/key",  "good\n" );
	my $sig     = write_file( "$dir/file.sig", "signature\n" );

	is(
		$signer->sign(
			secret    => "$dir/no-such-key",
			file      => $file,
			signature => "$dir/out.sig"
		),
		undef,
		'sign returns undef for an absent private half'
	);
	is( $signer->error, "not a plain file: $dir/no-such-key",
		'the reason names the path' );
	is( $signer->command_absent, 0, 'a bad path is no absent command' );

	is(
		$signer->sign(
			secret    => $key,
			file      => $dir,
			signature => "$dir/out.sig"
		),
		undef,
		'and undef for a directory'
	);
	is( $signer->error, "not a plain file: $dir", 'the reason names it' );

	is(
		$signer->verify(
			keys      => [$key],
			file      => $file,
			signature => "$dir/no-such-signature"
		),
		undef,
		'verify returns undef for an absent signature'
	);
	is(
		$signer->error,
		"not a plain file: $dir/no-such-signature",
		'the reason names the path'
	);

	my @none = runs($command);
	is( scalar @none, 0, 'and no call ran the command' );

	# A key that does not read is the exception: it is one reason
	# of the walk, and not a refusal.
	is(
		$signer->verify(
			keys      => ["$dir/no-such-key"],
			file      => $file,
			signature => $sig
		),
		undef,
		'an absent key file reaches the walk'
	);
	like( $signer->error, qr/no key verified the signature/,
		'and it answers one reason of the walk' );

	my @walked = runs($command);
	is( scalar @walked, 1, 'so the command ran for that key alone' );
};

subtest 'generate publishes the secret half from a private directory' =>
    sub {
	my $dir     = work('generate');
	my $command = stub();
	my $signer  = Stub::Signer->new( command => $command );
	my ( $public, $secret ) = ( "$dir/made.pub", "$dir/made.sec" );

	is( $signer->generate( public => $public, secret => $secret ),
		1, 'generate returns 1' )
	    or diag( $signer->error );
	is( $signer->error,          undef, 'error is undef' );
	is( $signer->command_absent, 0,     'command_absent returns 0' );

	my ($line) = runs($command);
	my ( $written, $temp ) = $line =~ /\Agenerate (\S+) (\S+)\z/;

	like( $written, qr/\Adrwx------/,
		'the command wrote into an owner-only directory' );
	isnt( $temp, $secret, 'the command never wrote the destination' );
	is( dirname( dirname($temp) ), $dir,
		'the private directory sits beside the destination' );
	is( basename($temp), basename($secret), 'and it holds one name' );
	my $private = dirname($temp);
	ok( !-e $private, 'the private directory is gone' );

	is( mode($secret), 0600, 'the secret half is owner-only' );
	ok( -f $public, 'and the public half is in place' );

	# A second call must not overwrite a half, and it must refuse
	# before the command runs.
	for my $exists ( $public, $secret ) {
		my ( $new_public, $new_secret ) =
		    ( "$dir/next.pub", "$dir/next.sec" );
		$new_public = $exists if $exists eq $public;
		$new_secret = $exists if $exists eq $secret;

		is(
			$signer->generate(
				public => $new_public,
				secret => $new_secret
			),
			undef,
			"generate refuses the path $exists"
		);
		is( $signer->error, "the path exists: $exists",
			'the reason names the path' );
		ok( !-e "$dir/next.pub" && !-e "$dir/next.sec",
			'and it wrote no half' );
	}
	my @made = runs($command);
	is( scalar @made, 1, 'so the command ran once' );
    };

subtest 'a failed generate leaves no private directory' => sub {
	my $dir     = work('generate-fail');
	my $command = stub(<<'SH');
#!/bin/sh
printf 'stub: cannot make a key\n' >&2
exit 1
SH
	my $signer = Stub::Signer->new( command => $command );

	is(
		$signer->generate(
			public => "$dir/made.pub",
			secret => "$dir/made.sec"
		),
		undef,
		'generate returns undef'
	);
	is(
		$signer->error,
		"cannot generate $dir/made.pub: stub: cannot make a key",
		'the reason names the act'
	);
	ok( !-e "$dir/made.sec", 'no secret half is in place' );
	is_deeply( [ entries($dir) ], [], 'and no private directory is left' );

	# A generator that writes no secret half fails on the publish,
	# and it leaves nothing behind either.
	my $half = Stub::Signer->new( command => stub(<<'SH') );
#!/bin/sh
printf 'public\n' > "$2"
exit 0
SH
	is(
		$half->generate(
			public => "$dir/half.pub",
			secret => "$dir/half.sec"
		),
		undef,
		'a generator that writes no secret half returns undef'
	);
	like( $half->error, qr{\Qcannot set the mode of $dir/half.sec\E},
		'the reason names the secret half' );
	ok( !-e "$dir/half.sec", 'no secret half is in place' );
	is_deeply( [ entries($dir) ], ['half.pub'],
		'and no private directory is left' );
};

subtest 'verify walks the keys in trust order' => sub {
	my $dir     = work('verify');
	my $command = stub();
	my $signer  = Stub::Signer->new( command => $command );
	my $file    = write_file( "$dir/file",     "payload\n" );
	my $sig     = write_file( "$dir/file.sig", "signature\n" );

	my $wrong = write_file( "$dir/wrong.pub", "wrong\n" );
	my $right = write_file( "$dir/right.pub", "good\n" );
	my $third = write_file( "$dir/third.pub", "good\n" );

	is(
		$signer->verify(
			keys      => [ $wrong, $right, $third ],
			file      => $file,
			signature => $sig
		),
		$right,
		'verify answers the key that verified'
	);
	is( $signer->error, undef, 'error is undef after a success' );
	is_deeply( [ runs($command) ], [ "verify $wrong", "verify $right" ],
		'and the walk stopped at that key' );

	# No key verifies: the reason names the file, and then one
	# reason for each key of the set, in one shape.
	my $none = Stub::Signer->new( command => stub() );
	is(
		$none->verify(
			keys      => [ $wrong, $wrong ],
			file      => $file,
			signature => $sig
		),
		undef,
		'verify returns undef when no key verified'
	);
	is(
		$none->error,
		"$file: no key verified the signature:\n"
		    . "    $wrong: stub: checked against wrong key;\n"
		    . "    $wrong: stub: checked against wrong key",
		'the reason holds the file and one reason for each key'
	);
	is( $none->command_absent, 0, 'a wrong key is no absent command' );
};

subtest 'the key walk stops at a start failure' => sub {
	my $dir     = work('walk');
	my $command = stub();
	my $signer  = Stub::Cwd->new( command => $command );
	my $file    = write_file( "$dir/file",     "payload\n" );
	my $sig     = write_file( "$dir/file.sig", "signature\n" );

	my $first  = write_file( "$dir/first.pub",  "good\n" );
	my $second = write_file( "$dir/second.pub", "good\n" );

	# The chdir of the child fails before the execve(2), so the
	# command never ran. The second key would fail the same way,
	# and a failure of the machinery is no integrity failure.
	is(
		$signer->verify(
			keys      => [ $first, $second ],
			file      => $file,
			signature => $sig
		),
		undef,
		'verify returns undef'
	);
	like( $signer->error, qr/\ACannot chdir to /,
		'the reason of the start failure stands alone' );
	is( $signer->command_absent, 0, 'a chdir failure is no absent command' );
	my @none = runs($command);
	is( scalar @none, 0, 'and the command never ran' );
};

subtest 'the key walk stops when no private directory is made' => sub {
	my $dir     = work('tempdir');
	my $command = stub();
	my $signer  = Stub::Temp->new( command => $command );
	my $file    = write_file( "$dir/file",     "payload\n" );
	my $sig     = write_file( "$dir/file.sig", "signature\n" );

	my $first  = write_file( "$dir/first.pub",  "good\n" );
	my $second = write_file( "$dir/second.pub", "good\n" );

	# The parent of the private directory does not exist, so mkdir
	# fails and the run of the first key never starts. The second
	# key gives the same answer, so the walk stops at the first one.
	is(
		$signer->verify(
			keys      => [ $first, $second ],
			file      => $file,
			signature => $sig
		),
		undef,
		'verify returns undef'
	);
	like(
		$signer->error,
		qr{\Acannot make a private directory in \Q$file.absent\E},
		'the reason of the start failure stands alone'
	);
	is( $signer->command_absent, 0,
		'a directory that failed is no absent command' );
	my @none = runs($command);
	is( scalar @none, 0, 'and the command never ran' );
};

subtest 'verify needs a key set' => sub {
	my $dir     = work('keys');
	my $signer  = Stub::Signer->new( command => stub() );
	my $file    = write_file( "$dir/file",     "payload\n" );
	my $sig     = write_file( "$dir/file.sig", "signature\n" );
	my %args    = ( file => $file, signature => $sig );

	eval { $signer->verify( %args, keys => [] ) };
	like( $@, qr/a verification needs a non-empty keys list/,
		'an empty key set dies' );

	eval { $signer->verify( %args, keys => "$dir/key" ) };
	like( $@, qr/keys must be an array reference/,
		'a key set that is no array reference dies' );

	eval { $signer->verify(%args) };
	like( $@, qr/keys, file and signature are necessary arguments/,
		'and an absent key set dies' );
};

subtest 'the temporary directory of a subclass' => sub {
	my $dir    = work('temp');
	my $signer = Stub::Helper->new( command => stub() );

	local @Stub::Helper::STOPPED = ();

	my ( $seen, $seen_mode );
	my $answer = $signer->_with_temp_dir(
		$dir,
		sub ($temp) {
			$seen      = $temp;
			$seen_mode = mode($temp);
			write_file( "$temp/home", "state\n" );

			return 'done';
		} );

	is( $answer, 'done', 'the method answers the body' );
	is( dirname($seen), $dir, 'the directory sits under the parent' );
	is( $seen_mode,     0700, 'and it is owner-only' );
	ok( !-e $seen, 'the tree is gone after the call' );
	is_deeply( \@Stub::Helper::STOPPED, ["live $seen"],
		'and the helpers stopped before the removal' );

	# With no parent the directory sits under the temporary
	# directory of the system.
	my $system;
	$signer->_with_temp_dir( undef, sub ($temp) { $system = $temp } );
	isnt( dirname($system), $dir, 'an undef parent names another parent' );
	ok( !-e $system, 'and that tree is gone too' );

	# A die of the body removes the tree, and the reason reaches
	# the caller.
	my $died;
	eval {
		$signer->_with_temp_dir(
			$dir,
			sub ($temp) {
				$died = $temp;
				die "the body failed\n";
			} );
	};
	is( $@, "the body failed\n", 'a die of the body reaches the caller' );
	ok( !-e $died, 'and the tree is gone' );
};

subtest 'the readers of a subclass' => sub {
	my $dir    = work('readers');
	my $signer = Stub::Signer->new( command => stub() );
	my $file   = write_file( "$dir/file", "0123456789" );

	is( $signer->_read_bounded( $file, 10 ), '0123456789',
		'a file at the bound reads' );
	is( $signer->_read_bounded( $file, 9 ),
		undef, 'a file above the bound reads nothing' );
	is( $signer->_read_bounded( "$dir/absent", 10 ),
		undef, 'an absent file reads nothing' );

	is( $signer->_wide("\x{100}"), 1, 'a code point above 255 is wide' );
	is( $signer->_wide("\xFF"),    0, 'and a byte is not' );
};

done_testing();
