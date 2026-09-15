#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use POSIX ();
use Time::HiRes qw(sleep);

use_ok('Fugu::REPL');

# The module must stand alone: no other Fugu module, because FuguTTX
# HRN-REPL-2 depends on it. This file loads only Fugu::REPL, so %INC
# holds every module that it pulled in.
subtest 'the module loads no other Fugu module' => sub {
	my @loaded = sort grep {m{^Fugu/}} keys %INC;
	is_deeply( \@loaded, ['Fugu/REPL.pm'],
		'only Fugu::REPL itself is loaded' );
};

# repl(%args):
#	A REPL over a fresh pipe pair, plus the pipe's write end and a
#	read end for the output.
sub repl (%args)
{
	pipe my $in_r,  my $in_w  or die "pipe: $!";
	pipe my $out_r, my $out_w or die "pipe: $!";

	my $repl =
	    Fugu::REPL->new( in => $in_r, out => $out_w, %args );

	return ( $repl, $in_w, $out_r );
}

# output($fh):
#	Every byte that the output pipe holds right now.
sub output ($fh)
{
	my $bytes = '';
	my $rin   = '';
	vec( $rin, fileno $fh, 1 ) = 1;
	while ( select( my $ready = $rin, undef, undef, 0 ) ) {
		last unless sysread $fh, $bytes, 4096, length $bytes;
	}
	return $bytes;
}

# guarded($code):
#	Run $code under an alarm, so a read that never returns fails
#	the test instead of hanging it.
sub guarded ($code)
{
	my $result;
	local $SIG{ALRM} = sub { die "test timeout\n" };
	alarm 15;
	$result = $code->();
	alarm 0;
	return $result;
}

subtest 'new dies on a programming error' => sub {
	ok( !eval { Fugu::REPL->new( complete => 'not code' ); 1 },
		'a complete argument that is not code dies' );
	like( $@, qr/code reference/, 'with the reason' );

	ok( !eval { Fugu::REPL->new( watch => ['no handle'] ); 1 },
		'a watch entry without a descriptor dies' );
	like( $@, qr/descriptor/, 'with the reason' );

	my ( $repl, $in_w, $out_r ) = repl();
	ok( !eval { $repl->watch( ['no handle'] ); 1 },
		'the watch accessor checks the same invariant' );
};

subtest 'the plain mode reads whole lines' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	is( $repl->is_interactive, 0, 'a pipe is not interactive' );

	syswrite $in_w, "first\nsecond\n";
	is( guarded( sub { $repl->read_line } ), 'first', 'line one' );
	is( $repl->event, 'line', 'with the event line' );
	is( guarded( sub { $repl->read_line } ), 'second', 'line two' );

	is( output($out_r), '', 'and the plain mode writes no prompt' );
};

subtest 'the plain mode reads a line that arrives in pieces' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		syswrite $in_w, 'first';
		sleep 0.2;
		syswrite $in_w, " half\n";
		POSIX::_exit(0);
	}

	is( guarded( sub { $repl->read_line } ),
		'first half', 'the pieces join into one line' );
	waitpid $pid, 0;
};

subtest 'the plain mode reports eof' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	syswrite $in_w, "tail without a newline";
	close $in_w;

	is( guarded( sub { $repl->read_line } ),
		'tail without a newline',
		'an end of file still ends the last line' );
	is( guarded( sub { $repl->read_line } ),
		undef, 'then the input is empty' );
	is( $repl->event, 'eof', 'with the event eof' );
};

subtest 'a watched handle that becomes readable ends the read' => sub {
	pipe my $watch_r, my $watch_w or die "pipe: $!";
	my ( $repl, $in_w, $out_r ) = repl( watch => [$watch_r] );

	syswrite $watch_w, 'wake';
	is( guarded( sub { $repl->read_line } ),
		undef, 'the read ends without a line' );
	is( $repl->event, 'watch', 'with the event watch' );
	ok( $repl->ready_handle == $watch_r,
		'and ready_handle names the handle' );
};

subtest 'a watched handle that closes ends the read' => sub {
	pipe my $watch_r, my $watch_w or die "pipe: $!";
	my ( $repl, $in_w, $out_r ) = repl( watch => [$watch_r] );

	close $watch_w;
	is( guarded( sub { $repl->read_line } ),
		undef, 'the closed peer ends the read' );
	is( $repl->event, 'watch', 'with the event watch' );
	ok( $repl->ready_handle == $watch_r,
		'and ready_handle names the handle' );

	syswrite $in_w, "still alive\n";
	is( guarded( sub { $repl->read_line } ),
		undef, 'a closed handle stays readable' );
	is( $repl->event, 'watch', 'so watch outranks the input' );
};

subtest 'ready_handle answers only after a watch event' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	syswrite $in_w, "a line\n";
	guarded( sub { $repl->read_line } );
	is( $repl->ready_handle, undef, 'a line event names no handle' );
};

subtest 'display_filter keeps the safe bytes' => sub {
	is( Fugu::REPL::display_filter("plain text 09AZ~"),
		'plain text 09AZ~', 'printable ASCII survives' );
	is( Fugu::REPL::display_filter("one\ttab\nand a line feed\n"),
		"one\ttab\nand a line feed\n",
		'the tab and the line feed survive' );
};

subtest 'display_filter removes DEL and every C1 byte' => sub {
	is( Fugu::REPL::display_filter("a\x7Fb"), 'ab', 'DEL disappears' );
	is( Fugu::REPL::display_filter( 'a' . join( '', map {chr}
					0x80 .. 0x9F ) . 'b' ),
		'ab', 'every raw C1 byte disappears' );
	is( Fugu::REPL::display_filter("a\xC2\x9Bb"),
		'ab', 'a C1 control as a UTF-8 sequence disappears' );
};

subtest 'display_filter keeps a valid UTF-8 sequence whole' => sub {
	is( Fugu::REPL::display_filter("h\xC3\xA9llo"),
		"h\xC3\xA9llo", 'a two-byte sequence survives' );
	is( Fugu::REPL::display_filter("cost \xE2\x82\xAC5"),
		"cost \xE2\x82\xAC5", 'a three-byte sequence survives' );
	is( Fugu::REPL::display_filter("\xF0\x9F\x90\xA1 fugu"),
		"\xF0\x9F\x90\xA1 fugu", 'a four-byte sequence survives' );
};

subtest 'display_filter replaces an invalid byte with one mark' => sub {
	is( Fugu::REPL::display_filter("a\xFFb"), 'a?b',
		'a stray byte becomes one question mark' );
	is( Fugu::REPL::display_filter("tail\xC3"),
		'tail?', 'a cut sequence becomes one question mark' );
	is( Fugu::REPL::display_filter("a\eb\rc"), 'a?b?c',
		'an escape and a carriage return become marks' );
	is( Fugu::REPL::display_filter("\xC3\xA9\xA9"),
		"\xC3\xA9?", 'a lone continuation byte becomes a mark' );
};

subtest 'show writes the filtered bytes' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	is( $repl->show("safe\x1B[31m"), $repl, 'show returns the object' );
	is( output($out_r), 'safe?[31m', 'and the output is filtered' );
};

subtest 'confirm answers no by default' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	syswrite $in_w, "\nn\nno\nmaybe\n";
	is( guarded( sub { $repl->confirm('Sure?') } ),
		0, 'an empty answer is no' );
	is( guarded( sub { $repl->confirm('Sure?') } ), 0, 'n is no' );
	is( guarded( sub { $repl->confirm('Sure?') } ), 0, 'no is no' );
	is( guarded( sub { $repl->confirm('Sure?') } ),
		0, 'every other answer is no' );
	like( output($out_r), qr/\ASure\? \[y\/N\] /,
		'the question shows, with the default no' );

	close $in_w;
	is( guarded( sub { $repl->confirm('Sure?') } ),
		0, 'an end of file is no' );
	is( $repl->event, 'eof', 'with the event eof' );
};

subtest 'confirm answers yes for y and yes' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	syswrite $in_w, "y\nY\nyes\nYES\nYes\n";
	is( guarded( sub { $repl->confirm('Sure?') } ), 1, 'y' );
	is( guarded( sub { $repl->confirm('Sure?') } ), 1, 'Y' );
	is( guarded( sub { $repl->confirm('Sure?') } ), 1, 'yes' );
	is( guarded( sub { $repl->confirm('Sure?') } ), 1, 'YES' );
	is( guarded( sub { $repl->confirm('Sure?') } ), 1, 'Yes' );
};

# The editor path needs a terminal, and CI has none. The cycle logic
# does not, so these subtests drive _complete on a character array.
subtest 'completion cycles when no extension remains' => sub {
	my ( $repl, $in_w, $out_r ) = repl(
		commands => { show => 'reveal one entry' },
		complete => sub ( $, $ ) { return qw(github.com gitlab.com) },
	);

	my @chars = split //, 'show gi';
	my $pos   = scalar @chars;
	my $cycle;

	( $pos, $cycle ) = $repl->_complete( \@chars, $pos, $cycle, 1, '> ' );
	is( join( '', @chars ), 'show git', 'the common prefix extends' );
	is( $cycle, undef, 'and no cycle starts yet' );

	( $pos, $cycle ) = $repl->_complete( \@chars, $pos, $cycle, 1, '> ' );
	is( join( '', @chars ), 'show github.com',
		'the next tab selects the first candidate' );
	ok( defined $cycle, 'and the cycle is active' );

	( $pos, $cycle ) = $repl->_complete( \@chars, $pos, $cycle, 1, '> ' );
	is( join( '', @chars ), 'show gitlab.com',
		'the next tab selects the next candidate' );

	( $pos, $cycle ) = $repl->_complete( \@chars, $pos, $cycle, 1, '> ' );
	is( join( '', @chars ), 'show github.com', 'the cycle wraps' );

	( $pos, $cycle ) =
	    $repl->_complete( \@chars, $pos, $cycle, -1, '> ' );
	is( join( '', @chars ), 'show gitlab.com',
		'a back-tab steps back' );
	is( $pos, length 'show gitlab.com', 'the cursor sits at the end' );

	my $stream = output($out_r);
	my $lists  = () = $stream =~ /gitlab\.com\r\n/g;
	is( $lists, 1, 'the list shows once, at the cycle start' );
};

subtest 'a backward completion starts at the last candidate' => sub {
	my ( $repl, $in_w, $out_r ) = repl(
		complete => sub ( $, $ ) { return qw(alpha alps) } );

	my @chars = split //, 'x alp';
	my $pos   = scalar @chars;
	my $cycle;

	( $pos, $cycle ) =
	    $repl->_complete( \@chars, $pos, $cycle, -1, '> ' );
	is( join( '', @chars ), 'x alps',
		'a back-tab starts at the last candidate' );
	ok( defined $cycle, 'and the cycle is active' );
};

subtest 'help_text lists every command, sorted, with the prefix' => sub {
	my ( $repl, $in_w, $out_r ) = repl(
		commands => {
			quit => 'end the session',
			help => 'show this help',
			ls   => 'list the entries',
		},
		prefix => '/',
	);

	is( $repl->help_text,
		    "/help  show this help\n"
		  . "/ls    list the entries\n"
		  . "/quit  end the session\n",
		'one aligned line per command' );

	my ( $bare, $bare_w, $bare_r ) =
	    repl( commands => { go => 'run' } );
	is( $bare->help_text, "go  run\n", 'an empty prefix adds nothing' );
};

subtest 'the history keeps no empty line and no repeat' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	syswrite $in_w, "one\n\none\ntwo\n";
	guarded( sub { $repl->read_line } ) for 1 .. 4;

	is_deeply( [ $repl->history ],
		[ 'one', 'two' ],
		'the empty line and the repeat stay out' );
};

subtest 'the history drops the oldest line above history_size' => sub {
	my ( $repl, $in_w, $out_r ) = repl( history_size => 3 );

	$repl->add_history($_) for qw(a b c d);
	is_deeply( [ $repl->history ], [qw(b c d)],
		'the oldest line is gone' );
};

subtest 'the accessors set and read' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	is( $repl->prompt, '> ', 'the default prompt' );
	is( $repl->prompt('fugu> '), 'fugu> ', 'the prompt changes' );

	my $table = { quit => 'end the session' };
	is( $repl->commands($table), $table, 'the command table changes' );
	is( $repl->commands,         $table, 'and reads back' );

	pipe my $watch_r, my $watch_w or die "pipe: $!";
	is_deeply( $repl->watch( [$watch_r] ),
		[$watch_r], 'the watch list changes' );
};

subtest 'restore is safe to call two times' => sub {
	my ( $repl, $in_w, $out_r ) = repl();

	is( $repl->restore, $repl, 'the first call returns the object' );
	is( $repl->restore, $repl, 'and so does the second' );
};

subtest 'the editor mode needs a terminal' => sub {
	plan skip_all => 'standard input is not a terminal'
	    unless -t STDIN;

	my $repl = Fugu::REPL->new;
	is( $repl->is_interactive, 1, 'a terminal is interactive' );
};

done_testing();
