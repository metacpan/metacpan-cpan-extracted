#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::Log;

use_ok('Fugu::CLI');

my $quiet = Fugu::Log->new( mode => 'quiet' );

# capture($code): run $code and return (stdout, stderr, return value)
sub capture ($code)
{
	my ( $out, $err ) = ( '', '' );
	my $result;
	{
		local *STDOUT;
		local *STDERR;
		open STDOUT, '>', \$out or die "capture stdout: $!";
		open STDERR, '>', \$err or die "capture stderr: $!";
		$result = $code->();
	}

	return ( $out, $err, $result );
}

# tool(%args): a CLI with a recording command table
my @calls;

sub tool (%args)
{
	@calls = ();

	return Fugu::CLI->new(
		name  => 'mytool',
		log   => $quiet,
		usage => '[-v] <command>',
		options  => {
			'verbose|v' => 'be noisy',
			'config|c=s' => 'the configuration file',
			'help|h'     => 'show the help',
		},
		commands => {
			status => {
				summary => 'report the state',
				run     => sub ( $cli, @argv ) {
					push @calls, [ 'status', @argv ];
					return Fugu::CLI::EXIT_SUCCESS();
				},
			},
			list => {
				summary => 'list the things',
				usage   => '[--names]',
				options => { 'names' => 'names only' },
				run     => sub ( $cli, @argv ) {
					push @calls,
					    [ 'list', $cli->option('names') // 0,
						@argv ];
					print "thing\n";
					return Fugu::CLI::EXIT_SUCCESS();
				},
			},
			fail => {
				summary => 'always fails',
				run     => sub ( $, @ ) {
					return Fugu::CLI::EXIT_ERROR();
				},
			},
		},
		%args,
	);
}

subtest 'exit codes are shared constants' => sub {
	is( Fugu::CLI::EXIT_SUCCESS(),      0, 'EXIT_SUCCESS' );
	is( Fugu::CLI::EXIT_ERROR(),        1, 'EXIT_ERROR' );
	is( Fugu::CLI::EXIT_INVALID_ARGS(), 2, 'EXIT_INVALID_ARGS' );
	is( Fugu::CLI::EXIT_CONFIG_ERROR(), 3, 'EXIT_CONFIG_ERROR' );
	is( Fugu::CLI::EXIT_TIMEOUT(),      7, 'EXIT_TIMEOUT' );
};

subtest 'dispatch' => sub {
	my $cli = tool();

	my ( $out, $err, $code ) = capture( sub { $cli->run('status') } );
	is( $code, 0, 'the command returned its exit code' );
	is_deeply( \@calls, [ ['status'] ], 'the body ran' );
	is( $cli->command, 'status', 'the CLI knows what ran' );

	$cli = tool();
	( $out, $err, $code ) =
	    capture( sub { $cli->run( 'status', 'extra', 'args' ) } );
	is_deeply( \@calls, [ [ 'status', 'extra', 'args' ] ],
		'the remaining arguments reach the body' );

	$cli = tool();
	( $out, $err, $code ) = capture( sub { $cli->run('fail') } );
	is( $code, 1, 'a failing command returns its own code' );
};

subtest 'global options are parsed once' => sub {
	my $cli = tool();

	my ( $out, $err, $code ) = capture(
		sub { $cli->run( '-v', '-c', '/etc/mytool.conf', 'status' ) } );

	is( $code, 0, 'the command ran' );
	is( $cli->option('verbose'), 1, 'a flag' );
	is( $cli->option('config'), '/etc/mytool.conf', 'a value option' );
	is( $cli->option('names'),  undef, 'an option of another command' );

	is_deeply(
		$cli->options,
		{ verbose => 1, config => '/etc/mytool.conf' },
		'options returns what was parsed'
	);
};

subtest 'a command parses its own options' => sub {
	my $cli = tool();

	my ( $out, $err, $code ) =
	    capture( sub { $cli->run( 'list', '--names', 'rest' ) } );

	is( $code, 0, 'the command ran' );
	is_deeply( \@calls, [ [ 'list', 1, 'rest' ] ],
		'the body saw its own option' );

	# The option belongs to the command, and not to the tool
	$cli = tool();
	( $out, $err, $code ) = capture( sub { $cli->run( '--names', 'list' ) } );
	is( $code, 2, 'a command option before the command is invalid' );
};

# Data that a script reads goes to standard output. A diagnostic goes
# to the logger, which writes to standard error. A tool that mixes the
# two breaks every pipeline that reads it.
subtest 'data and diagnostics use separate channels' => sub {
	my $cli = tool();

	my ( $out, $err, $code ) =
	    capture( sub { $cli->run( 'list', '--names' ) } );

	is( $out, "thing\n", 'the command data is on stdout' );
	is( $err, '',        'and nothing else came with it' );

	$cli = tool();
	( $out, $err, $code ) = capture( sub { $cli->run('nonesuch') } );
	is( $code, 2,  'an unknown command is invalid' );
	is( $out,  '', 'no data on stdout' );
	like( $err, qr/^usage: mytool/, 'the usage line is on stderr' );
};

subtest 'help' => sub {
	my $cli = tool();

	my ( $out, $err, $code ) = capture( sub { $cli->run('help') } );
	is( $code, 0, 'asking for help is not a failure' );
	like( $out, qr/^usage: mytool \[-v\] <command>/m, 'the usage line' );
	like( $out, qr/^\s+status\s+report the state$/m, 'a command summary' );
	like( $out, qr/^\s+list\s+list the things$/m,    'and another' );
	is( $err, '', 'help goes to stdout, because the user asked' );

	$cli = tool();
	( $out, $err, $code ) = capture( sub { $cli->run } );
	is( $code, 0, 'no arguments prints the help' );
	like( $out, qr/^usage: mytool/m, 'the same help' );

	$cli = tool();
	( $out, $err, $code ) = capture( sub { $cli->run( 'help', 'list' ) } );
	like( $out, qr/^usage: mytool list \[--names\]$/m,
		'help for one command shows its usage' );

	$cli = tool();
	( $out, $err, $code ) = capture( sub { $cli->run( 'list', '--help' ) } );
	is( $code, 0, '--help after a command is not a failure' );
	like( $out, qr/^usage: mytool list/m, 'and shows that command' );
	is_deeply( \@calls, [], 'the body did not run' );
};

subtest 'a bad option is invalid, not a crash' => sub {
	my $cli = tool();

	my ( $out, $err, $code ) =
	    capture( sub { $cli->run( '--nonesuch', 'status' ) } );
	is( $code, 2, 'an unknown global option is invalid' );
	like( $err, qr/usage: mytool/, 'with the usage line' );

	$cli = tool();
	( $out, $err, $code ) =
	    capture( sub { $cli->run( 'list', '--nonesuch' ) } );
	is( $code, 2, 'an unknown command option is invalid' );
	like( $err, qr/usage: mytool list/, 'with that command usage' );
	is_deeply( \@calls, [], 'and the body did not run' );
};

subtest 'the table must be usable' => sub {
	ok( !eval { Fugu::CLI->new; 1 }, 'new needs a command table' );
	ok(
		!eval {
			Fugu::CLI->new( commands => { x => {} } );
			1;
		},
		'a command needs a run code reference'
	);

	my $cli = Fugu::CLI->new(
		commands => { x => { run => sub ( $, @ ) { 0 } } } );
	is( $cli->name, 'cli', 'the name has a default' );
	ok( defined $cli->log, 'and the logger falls back to the default' );
};

done_testing();
