#!/usr/bin/perl -w

# Destructive, boundary and security tests for Lingua::EN::NameCase.
#
# What this module is, so the tests make sense: a pure string function.  It
# opens no files, talks to no database or network, and reads no clock.  So
# the filesystem, upstream-outage and time-travel scenarios have nothing to
# act on; instead this file (a) proves that by auditing the source and by
# feeding it path-like and shell-like text, and (b) attacks what it does
# have: its arguments, its error messages, its regular expressions, its
# memory use and the caller's global state.
#
# Slow or dangerous work (regex stress, huge strings) runs in a forked child
# with an alarm.  A regex cannot be interrupted by a Perl signal handler, so
# the child is killed by the default SIGALRM action and the parent reports it.

use strict;
use warnings;

use Cwd ();
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();
use Readonly;
use Scalar::Util qw(tainted);
use Test::Needs 'Test::Mockingbird';    # needs a recent Perl; skip the file without it
use Test::Mockingbird;
use Test::Most;

# Sub::Private is optional.  Declare its variables so Perl does not warn that they
# are "used only once" when the module is not installed.
# Naming each variable twice is what makes Perl treat it as intentional.
BEGIN { my @known = ( \%Sub::Private::config, \$Sub::Private::BYPASS ); }
use Test::Needs;
use lib 't/lib';
use ReturnsOk;

use Lingua::EN::NameCase qw( NameCase nc );

Readonly my $PKG               => 'Lingua::EN::NameCase';
Readonly my $SENTINEL          => 'SENTINEL';
Readonly my $STRESS_SIZE       => 100_000;      # characters in one pathological string
Readonly my $STRESS_SECONDS    => 1;            # strict: each stress case must finish in this time
Readonly my $HUGE_STRING       => 10_000_000;   # one 10 MB name
Readonly my $HUGE_SECONDS      => 20;
Readonly my $MANY_ELEMENTS     => 100_000;
Readonly my $DEEP_NESTING      => 10_000;
Readonly my $LONG_CLASS_NAME   => 1_000_000;
Readonly my $TYPE_NAME_LIMIT   => 64;           # as in the module
Readonly my $FD_LIMIT          => 64;           # lowered OS limit for the descriptor test
Readonly my $FD_SAFETY_CAP     => 5_000;        # never open more than this
Readonly my $LENGTH_LIMIT      => 10;

# Directory that holds the module under test, for child perls.
my ($LIB_DIR) = $INC{'Lingua/EN/NameCase.pm'} =~ m{^(.*)/Lingua/EN/NameCase\.pm$};
$LIB_DIR = File::Spec->rel2abs($LIB_DIR) if defined $LIB_DIR;

my $CAN_FORK = $^O ne 'MSWin32';

# Switch the Sub::Private guard off for white-box helpers; one subtest turns it on.
$Sub::Private::BYPASS = 1;

sub dbg {
	diag(@_) if $ENV{TEST_VERBOSE};
	return;
}

# Return the warnings a block produced (and any death), for "stays quiet" checks.
sub quiet(&) {
	my $code = shift;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	eval { $code->() };
	return [ @warnings, ( $@ ? "DIED: $@" : () ) ];
}

# Run a block in a child that the OS kills after $seconds.  Returns
# { ok => 1 } if the block finished and returned true in time,
# { timeout => 1 } if it was killed, { failed => 1 } if it returned false or died.
sub bounded {
	my ( $seconds, $code ) = @_;
	my $pid = fork();
	die "fork failed: $!" unless defined $pid;
	if ( !$pid ) {
		$SIG{ALRM} = 'DEFAULT';
		alarm $seconds;
		my $good = eval { $code->() };
		POSIX::_exit( $good ? 0 : 3 );
	}
	waitpid( $pid, 0 );
	my $signal = $? & 127;
	return { timeout => 1, signal => $signal } if $signal == POSIX::SIGALRM();
	return { ok => 1 } if $? == 0;
	return { failed => 1, status => $? };
}

# ---------------------------------------------------------------- hostile scalars
# Purpose: odd but legal scalar values: zero, empty, whitespace, huge and
# special numbers.  None may die or warn; false values come back unchanged.
subtest 'hostile scalar values' => sub {
	my %unchanged = ( 'undef' => undef, 'empty' => '', 'zero' => 0, 'string zero' => '0' );
	for my $label ( sort keys %unchanged ) {
		my $r;
		is_deeply( quiet { $r = nc( $unchanged{$label} ) }, [], "$label: quiet" );
		is( $r, $unchanged{$label}, "$label: unchanged" );
	}

	my %exact = (
		'0.0'          => '0.0',
		'00'           => '00',
		'0 but true'   => '0 But True',
		' '            => ' ',
		"\n"           => "\n",
		"\0"           => "\0",
		"\t \r\n"      => "\t \r\n",
		'1e21'         => '1e21',
		'-1'           => '-1',
		'.'            => '.',
		"'"            => "'",
	);
	for my $in ( sort keys %exact ) {
		is( nc($in), $exact{$in}, sprintf( 'nc(%s)', join '', map { /[[:print:]]/ ? $_ : sprintf '\\x%02x', ord } split //, $in ) );
	}

	# Numbers: extreme values are stringified, then treated as text.
	for my $number ( 1e308, -1e308, 9**9**9, -9**9**9, 9**9**9 / 9**9**9, 2**63, -2**63, 0.1 + 0.2 ) {
		my $w = quiet { my $r = nc($number); die "undef result\n" unless defined $r };
		is_deeply( $w, [], "number $number: no warning, defined result" );
	}
	is( nc(1e308), '1e+308', 'large number is text' );
};

# ---------------------------------------------------------------- reference types
# Purpose: every kind of reference Perl has, other than a plain scalar ref,
# must be refused with the documented message, and nothing else.
subtest 'unexpected reference types are refused' => sub {
	my $text = 'abc';
	my %bad = (
		'REF'     => \\'x',
		'CODE'    => sub { 1 },
		'GLOB'    => \*STDOUT,
		'LVALUE'  => \substr( $text, 0, 1 ),
		'VSTRING' => \v1.2.3,
		'Regexp'  => qr/x/,
		'HASH'    => {},
		'ARRAY'   => [],
		'IO::File' => *STDOUT{IO},
		'Obj'     => bless( {}, 'Obj' ),
		'Obj::Scalar' => bless( \my $s, 'Obj::Scalar' ),
	);
	for my $type ( sort keys %bad ) {
		throws_ok { nc( $bad{$type} ) } qr/^Usage: nc \[\[\\\]\$SCALAR\] \(got \Q$type\E\) at /, "nc rejects $type";
		throws_ok { NameCase( $bad{$type} ) } qr/^(?:Usage: .*NameCase.*\(got \Q$type\E\)|Usage: nc .*\(got \Q$type\E\)) at /, "NameCase rejects $type"
			unless $type eq 'ARRAY';
	}
};

# Purpose: a typeglob passed by value is not a reference and not in the API;
# it must not crash, and must not damage the handle it names.
subtest 'typeglobs by value do not damage the handle' => sub {
	my $before = fileno(STDOUT);
	my $w = quiet { my $r = nc(*STDOUT); die "no result\n" unless defined $r };
	is_deeply( $w, [], 'a glob is treated as text, quietly' );
	is( fileno(STDOUT), $before, 'STDOUT still open on the same descriptor' );
	ok( defined( *STDOUT{IO} ), 'STDOUT still has its IO slot' );
};

# ---------------------------------------------------------------- circular and deep structures
# Purpose: self-referencing and deeply nested data must be refused without
# recursion, without hanging and without half-changing the caller's array.
subtest 'circular and deeply nested references' => sub {
	my $loop;
	$loop = \$loop;
	throws_ok { nc($loop) } qr/\(got REF\)/, 'scalar that refers to itself';

	my @cycle = ('ANNE JONES');
	push @cycle, \@cycle;
	throws_ok { NameCase( \@cycle ) } qr/^Usage: nc .*\(got ARRAY\)/, 'array that contains itself';
	is( $cycle[0], 'ANNE JONES', 'array left unchanged' );

	my ( @one, @two );
	@one = ( 'A B', \@two );
	@two = ( 'C D', \@one );
	throws_ok { NameCase( \@one ) } qr/\(got ARRAY\)/, 'two arrays that contain each other';
	is_deeply( [ $one[0], $two[0] ], [ 'A B', 'C D' ], 'both unchanged' );

	my $deep = ['LEAF NAME'];
	$deep = [$deep] for 1 .. $DEEP_NESTING;
	throws_ok { NameCase($deep) } qr/\(got ARRAY\)/, "nested $DEEP_NESTING deep: refused, no recursion";
	my $hash_loop = {};
	$hash_loop->{self} = $hash_loop;
	throws_ok { nc($hash_loop) } qr/\(got HASH\)/, 'self-referencing hash';

	# Break the cycles so the test itself leaks nothing.
	@cycle = ();
	@one = @two = ();
	%{$hash_loop} = ();
	undef $loop;
};

# ---------------------------------------------------------------- invalid text
# Purpose: bytes that are not valid UTF-8, lone surrogates and code points
# outside Unicode must pass through without a crash or a warning.
subtest 'invalid UTF-8 and unusual code points' => sub {
	my @bytes = ( "\xff\xfe", "\xc3\x28", "\xc0\xaf", "\xe2\x82", "\x80", "\xf8\x88\x80\x80\x80", "JOHN \xff SMITH", "\xef\xbb\xbfBOM NAME" );
	for my $bad (@bytes) {
		my $before = $bad;
		my $r;
		is_deeply( quiet { $r = nc($bad) }, [], sprintf( 'bytes %vX: quiet', $bad ) );
		is( length $r, length $before, '... length kept' );
		is( $bad, $before, '... argument untouched' );
	}

	# Decoded text with characters that are not valid Unicode scalars.
	no warnings 'utf8', 'non_unicode', 'surrogate', 'nonchar';
	for my $cp ( 0xD800, 0xDFFF, 0xFFFE, 0xFFFF, 0x10FFFF, 0x110000, 0x7FFFFFFF ) {
		my $text = "john " . chr($cp) . " smith";
		my $r;
		my $w = quiet { $r = nc($text) };
		is_deeply( $w, [], sprintf( 'U+%X: quiet', $cp ) );
		is( $r, "John " . chr($cp) . " Smith", sprintf( 'U+%X: kept, words fixed', $cp ) );
	}

	# Strings whose case change changes their length.
	for my $odd ( "\x{130}STANBUL", "STRA\x{df}E", "\x{1c6}ELENA", "\x{fb01}LE" ) {
		my $w = quiet { my $r = nc($odd); die "undef\n" unless defined $r };
		is_deeply( $w, [], sprintf( '%vX: handled', $odd ) );
	}

	# A decode that substitutes U+FFFD still gives a usable string.
	require Encode;
	my $decoded = Encode::decode( 'UTF-8', "caf\xc3\xa9 \xff NAME" );
	is_deeply( quiet { nc($decoded) }, [], 'decoded with replacement characters' );
};

# ---------------------------------------------------------------- context abuse
# Purpose: the same call in list, scalar and void context, and wrappers that
# forward their caller's context, must behave exactly as documented.
subtest 'list versus scalar context' => sub {
	my @one = nc(undef);
	is( scalar @one, 1, 'nc(undef) in list context is a list of one' );
	my ( $first, $second ) = nc('JOHN SMITH');
	is( $first, 'John Smith', 'first value' );
	is( $second, undef, 'there is no second value' );

	my $count = () = NameCase( 'a', 'b', 'c' );
	is( $count, 3, 'three names, three results' );
	$count = () = NameCase( [ 'a', 'b' ] );
	is( $count, 2, 'array ref in list context' );
	ok( scalar NameCase( [] ), 'in place on an empty array is true (a reference)' );
	my ($head) = NameCase( 'ANNE JONES', 'BOB MCVEY' );
	is( $head, 'Anne Jones', 'list assignment takes the first' );

	# A wrapper forwards its own context.
	my $wrap = sub { return NameCase(@_) };
	my @list = $wrap->( 'A B', 'C D' );
	is_deeply( \@list, [ 'A B', 'C D' ], 'wrapper in list context' );
	throws_ok { my $s = $wrap->( 'A B', 'C D' ) } qr/^NameCase only accepts a single scalar/, 'wrapper in scalar context';
	throws_ok { my @e = NameCase( () ) } qr/^NameCase only accepts a single scalar/, 'empty list';
	throws_ok { nc( 'Lingua::EN::NameCase', 'x' ) } qr/\(got list\)/, 'nc as a method call passes an extra argument';

	# &nc; reuses the caller's @_.
	my $forward = sub { &nc };
	is( $forward->('JOHN SMITH'), 'John Smith', '&nc; uses the current @_' );
};

# ---------------------------------------------------------------- caller's global state
# Purpose: the caller's special variables must come out as they went in.
subtest 'caller state is never disturbed' => sub {
	"abc" =~ /(b)/;
	nc('JOHN MCVEY');
	is( $1, 'b', 'capture groups of the caller survive' );
	is( $&, 'b', '$& survives' );

	my $text = 'aaa';
	$text =~ /a/g;
	my $position = pos $text;
	nc( \$text );
	is( pos $text, $position, 'pos() of a referenced scalar is kept' );

	{
		local ( $/, $,, $\, $", $; ) = ( undef, 'X', 'Y', 'Z', 'W' );
		is( nc('A B'), 'A B', 'works with odd output separators' );
		is( join( '|', $/ // 'undef', $,, $\, $", $; ), 'undef|X|Y|Z|W', 'separators unchanged' );
	}

	# Aliasing: nc with no argument, inside the idioms people use.
	my @names = ( 'ANNE JONES', 'BOB MCVEY' );
	$_ = nc for @names;
	is_deeply( \@names, [ 'Anne Jones', 'Bob McVey' ], '$_ = nc for @list' );
	my @from_constants = map { nc } qw( ANNE BOB );
	is_deeply( \@from_constants, [ 'Anne', 'Bob' ], 'map { nc } over read-only constants' );
	my @sorted = sort { nc($a) cmp nc($b) } qw( bob ANNE carl );
	is_deeply( \@sorted, [ 'ANNE', 'bob', 'carl' ], 'inside sort, $a and $b are untouched' );
	for (1) { is( nc, 1, 'nc on a numeric constant alias' ) }

	# Handlers set by the caller.
	my @handler_calls;
	local $SIG{__WARN__} = sub { push @handler_calls, @_ };
	nc($_) for ( 'A B', undef, '', 0 );
	is_deeply( \@handler_calls, [], 'nothing warns, so a dying warn handler would never fire' );
	{
		local $SIG{__DIE__} = sub { die "wrapped: $_[0]" };
		throws_ok { nc( {} ) } qr/^wrapped: Usage: nc /, 'a __DIE__ handler can wrap the error, which still dies';
	}
	local $_ = $SENTINEL;
	eval { nc( {} ) };
	eval { NameCase() };
	is( $_, $SENTINEL, '$_ intact after errors' );
};

# Purpose: a tied scalar answers differently on each read.  The module must
# read it once, so the type check and the use see the same value.
subtest 'tied arguments are read once (no check/use gap)' => sub {
	{
		package Counting::Scalar;
		sub TIESCALAR { my ( $class, @values ) = @_; return bless { values => [@values], reads => 0 }, $class }
		sub FETCH     { my $self = shift; my $i = $self->{reads}++; return $self->{values}[ $i < @{ $self->{values} } ? $i : -1 ] }
		sub STORE     { return }
	}

	# First read is a harmless string, later reads would be a hash ref.
	tie my $sneaky, 'Counting::Scalar', 'JOHN SMITH', {}, {};
	my $r = eval { nc($sneaky) };
	is( $@, '', 'no error from a value that changes after the first read' );
	is( $r, 'John Smith', 'the first value is the one used' );
	is( tied($sneaky)->{reads}, 1, 'exactly one read' );

	# First read is a hash ref: must be refused, not slipped through.
	tie my $bad, 'Counting::Scalar', {}, 'JOHN SMITH';
	throws_ok { nc($bad) } qr/\(got HASH\)/, 'a hash ref is refused on the first read';

	tie my $for_namecase, 'Counting::Scalar', 'ANNE JONES', {};
	is( scalar NameCase($for_namecase), 'Anne Jones', 'NameCase with a tied scalar' );
	is( tied($for_namecase)->{reads}, 1, 'NameCase also reads once' );

	# $_ itself tied.
	tie my $underscore, 'Counting::Scalar', 'MARY JONES', {};
	{
		local *_ = \$underscore;
		is( nc(), 'Mary Jones', 'tied $_' );
	}
	is( tied($underscore)->{reads}, 1, '$_ read once' );
};

# ---------------------------------------------------------------- security
# Purpose: input is only ever data.  Code, SQL, shell, HTML, format and path
# text must come back as text, nothing must run and no file may appear.
subtest 'injection payloads are inert data' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	my $here = Cwd::getcwd();
	chdir $dir or die "chdir: $!";

	our $executed = 0;
	my @payloads = (
		'$(touch pwned)', '`touch pwned`', '; touch pwned', "x\ntouch pwned", '| touch pwned', '&& touch pwned',
		'@{[ $main::executed++ ]}', '${\ ($main::executed++) }', '(?{ $main::executed++ })', '\\Q\\E\\U',
		"'; DROP TABLE names; --", '<script>alert(1)</script>', '%s%s%s%n', '{{7*7}}', '../../etc/passwd',
		'/dev/null', '/dev/urandom', 'C:\\Windows\\System32', 'file name with spaces', "evil\nname", 'NUL', 'CON',
	);
	for my $payload (@payloads) {
		my $r;
		my $w = quiet { $r = nc($payload) };
		is_deeply( $w, [], 'quiet: ' . join( '', map { /[[:print:]]/ ? $_ : '?' } split //, $payload ) );
		is( lc $r, lc $payload, '... only the case changed' );
	}
	is( $main::executed, 0, 'no payload was evaluated' );
	opendir( my $dh, $dir ) or die "opendir: $!";
	my @files = grep { !/^\.\.?$/ } readdir $dh;
	closedir $dh;
	chdir $here;
	is_deeply( \@files, [], 'no file was created' );
};

# Purpose: a static audit.  The module must not use anything that could run
# input as code or touch the system.  A new use would need a new review.
subtest 'source audit: no eval of strings, no process or file calls' => sub {
	open( my $fh, '<', $INC{'Lingua/EN/NameCase.pm'} ) or die "read module: $!";
	my @code;
	my $in_pod = 0;
	while ( my $line = <$fh> ) {
		$in_pod = 1 if $line =~ /^=[a-z]/;
		push @code, $line unless $in_pod || $line =~ /^\s*#/;
		$in_pod = 0 if $line =~ /^=cut/;
	}
	close $fh;
	my $source = join '', @code;
	for my $danger ( 'system', 'exec', 'fork', 'open', 'opendir', 'unlink', 'rename', 'mkdir', 'readpipe', 'glob', 'socket', 'syscall', 'dbmopen', 'sleep', 'alarm', 'local\s+\$SIG', 'time', 'localtime' ) {
		unlike( $source, qr/(?<![\w\$>:])$danger\s*[\(\$"'\w]/, "no call to $danger" );
	}
	unlike( $source, qr/\beval\s*[\$"'q]|\beval\s+[\$"']/, 'no string eval' );
	unlike( $source, qr/`|\bqx\b/, 'no backticks' );
	unlike( $source, qr/\brequire\s+\$|\bdo\s+\$/, 'no computed require' );
	# Every /e substitution may only evaluate a lookup in the module's own tables.
	my @evaluated = grep { /\}[a-z]*e[a-z]*;\s*$/ } @code;
	cmp_ok( scalar @evaluated, '>=', 1, 'the /e substitutions are found' );
	like( $_, qr/\$args->\{\$1\}|\$POST_NOMINAL_CANONICAL/, 'a /e substitution only does a table lookup' ) for @evaluated;
};

# Purpose: the error text must not become a channel for attacker-controlled
# data: a class name with newlines, braces, format codes or a huge size.
subtest 'error messages are safe to log' => sub {
	my %nasty = (
		'newline'   => "Evil\nINJECTED LOG LINE",
		'brace'     => 'A{got}B',
		'format'    => 'F%s%n%d',
		'ansi'      => "Esc\x1b[31m",
		'quote'     => 'Q"q\'q',
		'unicode'   => "Caf\x{e9}\x{1F600}",
	);
	for my $label ( sort keys %nasty ) {
		my $obj = bless {}, $nasty{$label};
		my $err = eval { nc($obj); 1 } ? '' : $@;
		like( $err, qr/^Usage: nc \S+ \(got [\w:?]+\) at /, "$label: a single clean line" );
		unlike( $err, qr/[\n\x00-\x08\x0b-\x1f\x7f].*\bat /s, "$label: no control characters before the location" );
		unlike( $err, qr/%n|\x1b|\n.*\n/s, "$label: no format code, escape or extra line" );
	}
	my $long = bless {}, 'L' x $LONG_CLASS_NAME;
	my $err = eval { nc($long); 1 } ? '' : $@;
	cmp_ok( length $err, '<', 1_000, 'a megabyte class name is cut down' );
	like( $err, qr/\(got L{$TYPE_NAME_LIMIT}\)/, 'to the limit' );

	# The same protection for NameCase.
	my $err2 = eval { NameCase( bless [], "Bad\nName" ); 1 } ? '' : $@;
	unlike( $err2, qr/Bad\nName/, 'NameCase too' );

	# Placeholder text in a value must not be expanded a second time.
	my $err3 = eval { nc( bless {}, 'X_got_' ); 1 } ? '' : $@;
	like( $err3, qr/\(got X_got_\)/, 'plain names are kept intact' );
};

# Purpose: a hostile %MESSAGES (set by the program, not by users, but it
# must still never run code).
subtest 'hostile %MESSAGES cannot run code' => sub {
	my $ran = 0;
	local %Lingua::EN::NameCase::MESSAGES = (
		usage_nc   => sub { $ran++; return 'pwned' },
		single_arg => [ 'array', 'as', 'template' ],
		too_long   => undef,
	);
	throws_ok { nc( [] ) } qr/^CODE\(0x[0-9a-f]+\) at /, 'a code ref is printed, not called';
	is( $ran, 0, 'never run' );
	my $error = eval { nc( [] ); 1 } ? '' : $@;
	is( ref $error, '', 'the exception is a plain string, not the code ref' );
	throws_ok { NameCase() } qr/^ARRAY\(0x[0-9a-f]+\) at /, 'an array ref is printed as text';
};

# Purpose: taint mode.  Tainted input must be accepted (it is only read),
# must not be laundered, and must not trigger an "Insecure dependency".
subtest 'taint mode' => sub {
	plan skip_all => 'child perl not used here' unless $CAN_FORK;
	# Taint mode ignores PERL5LIB, so pass the parent's whole module path
	# explicitly (-I is trusted); otherwise Readonly etc. are not found when
	# they were installed under PERL5LIB, as on CI.
	my @cmd = ( $^X, '-T', ( map { "-I$_" } @INC ), '-e', q{
		open STDERR, '>&', \*STDOUT;
		use Lingua::EN::NameCase qw(nc NameCase);
		use Scalar::Util qw(tainted);
		my $taint = substr( $ENV{HOME_TAINTED}, 0, 0 );    # an empty, tainted string
		my @report;
		# One name for each rule: plain, Mac, particle, Hebrew, roman, post-nominal, apostrophe.
		for my $name ( 'JOHN SMITH', 'MACDONALD', 'VAN DER POST', 'MIRIAM BAT RIVKAH', 'HENRY VIII', 'JANE PHD', "O'NEIL" ) {
			my $in = $name . $taint;
			my $out = nc($in);
			push @report, ( tainted($in) ? 1 : 0 ) . ( tainted($out) ? 1 : 0 );
		}
		my @list = NameCase( 'A B' . $taint, 'JANE PHD' . $taint );
		my $array = [ 'JANE PHD' . $taint ];
		NameCase($array);
		push @report, join '', map { tainted($_) ? 1 : 0 } @list, @{$array};
		print join( ',', @report ), "\n";
	} );
	local $ENV{HOME_TAINTED} = 'x';
	open( my $ph, '-|', @cmd ) or die "run: $!";
	my $out = do { local $/; <$ph> };
	close $ph;
	is( $out, "11,11,11,11,11,11,11,111\n", 'works under -T; every rule keeps the taint, none removes it' ) or diag $out;
};

# Purpose: case mapping can make text longer (one Greek letter becomes three
# characters).  The growth must stay bounded, so $MAX_LENGTH really bounds the
# size of the result too, to a known multiple.
subtest 'output length is at most three times the input' => sub {
	Readonly my $GROWTH_LIMIT => 3;
	my $worst = 0;
	no warnings;
	for my $code_point ( 0x20 .. 0x2FFFF ) {
		next if $code_point >= 0xD800 && $code_point <= 0xDFFF;
		my $text = chr $code_point;
		my $ratio = length( nc($text) ) / length $text;
		$worst = $ratio if $ratio > $worst;
	}
	cmp_ok( $worst, '<=', $GROWTH_LIMIT, "worst single-character growth is $worst" );
	cmp_ok( length nc( "\x{390}" x 1000 ), '<=', $GROWTH_LIMIT * 1000, 'and in a long run' );
};

# Purpose: private routines refuse outside callers, including the newest one.
subtest 'private routines cannot be reached from outside' => sub {
	plan skip_all => 'Sub::Private is not installed (it is optional)' unless $INC{'Sub/Private.pm'};
	local $Sub::Private::BYPASS = 0;
	local $Sub::Private::config{harness_bypass} = 0;
	for my $private (qw( _i18n _fail _safe_type _base_case _mac_case _particle_case _roman_case _postnominal_case )) {
		throws_ok { no strict 'refs'; &{"${PKG}::$private"}('x') } qr/^\Q$private\E\(\) is a private subroutine of \Q$PKG\E and cannot be called from main/, "$private refused";
		throws_ok { Lingua::EN::NameCase->import($private) } qr/not exported/, "$private cannot be imported";
	}
};

# ---------------------------------------------------------------- size limits
# Purpose: $MAX_LENGTH, the documented size limit, at and around its edge.
subtest 'MAX_LENGTH boundary' => sub {
	local $Lingua::EN::NameCase::MAX_LENGTH = $LENGTH_LIMIT;
	my $at   = 'a' x $LENGTH_LIMIT;
	my $over = 'a' x ( $LENGTH_LIMIT + 1 );

	is( nc($at), 'A' . ( 'a' x ( $LENGTH_LIMIT - 1 ) ), 'exactly at the limit is accepted' );
	throws_ok { nc($over) } qr/^Name is too long: 11 characters \(the maximum is 10\) at \Q$0\E line \d+/, 'one over is refused, exact text';
	throws_ok { nc( \$over ) } qr/^Name is too long: 11 characters/, 'through a reference too';
	is( nc( "\x{1F600}" x $LENGTH_LIMIT ), "\x{1F600}" x $LENGTH_LIMIT, 'characters are counted, not bytes' );
	throws_ok { nc( "\x{e9}" x ( $LENGTH_LIMIT + 1 ) ) } qr/11 characters/, 'multi-byte characters over the limit';

	# False values are never "too long".
	is( nc(undef), undef, 'undef passes' );
	is( nc(''), '', 'empty passes' );
	is( nc('0'), '0', 'zero passes' );

	# The limit applies to every name of a list, and in place it is all or nothing.
	my @mixed = ( 'ANNE JONES', $over, 'BOB MCVEY' );
	throws_ok { NameCase( \@mixed ) } qr/too long/, 'one long name in an array';
	is_deeply( [ @mixed[ 0, 2 ] ], [ 'ANNE JONES', 'BOB MCVEY' ], 'array unchanged' );
	throws_ok { my @r = NameCase( 'OK', $over ) } qr/too long/, 'one long name in a list';

	# Limit of zero: every non-empty name is too long.
	local $Lingua::EN::NameCase::MAX_LENGTH = 0;
	throws_ok { nc('a') } qr/maximum is 0\)/, 'limit 0';

	# Limit switched off again.
	local $Lingua::EN::NameCase::MAX_LENGTH = undef;
	is( length nc($over), length $over, 'undef means no limit' );

	# The message can be translated, with its placeholders.
	local $Lingua::EN::NameCase::MAX_LENGTH = 1;
	local %Lingua::EN::NameCase::MESSAGES = ( too_long => 'Zu lang: {length} > {max}' );
	throws_ok { nc('ab') } qr/^Zu lang: 2 > 1 at /, 'translated';
};

# Purpose: oversize input is refused cheaply, without first making copies.
subtest 'oversize input is refused fast' => sub {
	plan skip_all => 'fork not available' unless $CAN_FORK;
	my $result = bounded( $STRESS_SECONDS, sub {
		local $Lingua::EN::NameCase::MAX_LENGTH = $LENGTH_LIMIT;
		my $huge = 'x' x $HUGE_STRING;
		my $refused = !eval { nc($huge); 1 } && $@ =~ /^Name is too long: $HUGE_STRING characters/;
		return $refused;
	} );
	ok( $result->{ok}, '10 MB name refused at once with the size-limit message' ) or diag explain $result;
};

# Purpose: volume without a limit set: a 10 MB name and a large array are
# processed correctly (no crash, no wrong answer), within a generous bound.
subtest 'large payloads without a limit' => sub {
	plan skip_all => 'fork not available' unless $CAN_FORK;

	my $big_name = bounded( $HUGE_SECONDS, sub {
		my $r = nc( 'JOHN ' x ( $HUGE_STRING / 5 ) );
		return length $r == $HUGE_STRING && substr( $r, 0, 10 ) eq 'John John ';
	} );
	ok( $big_name->{ok}, '10 MB name processed correctly' ) or diag explain $big_name;

	my $big_array = bounded( $HUGE_SECONDS, sub {
		my @names = ('JOHN SMITH') x $MANY_ELEMENTS;
		NameCase( \@names );
		return @names == $MANY_ELEMENTS && $names[-1] eq 'John Smith';
	} );
	ok( $big_array->{ok}, "$MANY_ELEMENTS-element array processed in place" ) or diag explain $big_array;

	my $one_bad = bounded( $HUGE_SECONDS, sub {
		my @names = ( ('JOHN SMITH') x $MANY_ELEMENTS, {} );
		my $died = !eval { NameCase( \@names ); 1 };
		return $died && $names[0] eq 'JOHN SMITH' && $names[ $MANY_ELEMENTS - 1 ] eq 'JOHN SMITH';
	} );
	ok( $one_bad->{ok}, 'a bad last element still leaves 100000 names untouched' ) or diag explain $one_bad;
};

# ---------------------------------------------------------------- ReDoS
# Purpose: crafted strings aimed at each regular expression in the module
# (Mac, roman numerals, particles, Hebrew look-behind, post-nominals,
# apostrophes).  Each runs in a child that is killed after one second.
subtest 'regular expression stress (ReDoS)' => sub {
	plan skip_all => 'fork not available' unless $CAN_FORK;

	my $n = $STRESS_SIZE;
	my %attack = (
		'Mac then one long word'      => 'Mac' . 'a' x $n,
		'many Mac words'              => join( ' ', ( 'Mac' . 'a' x 100 ) x ( $n / 100 ) ),
		'Mc repeated'                 => 'Mc' x $n,
		'roman letters, one word'     => 'i' x $n,
		'roman letters with apostrophes' => "i'" x $n,
		'roman mixed'                 => 'xxxivivxl' x ( $n / 9 ),
		'Al then spaces'              => 'Al' . ' ' x $n,
		'many Al with spaces'         => join( '', ( 'Al' . ' ' x 100 ) x ( $n / 100 ) ),
		'Van then spaces'             => 'Van' . ' ' x $n,
		'Ben look-behind'             => 'x Ben ' x ( $n / 5 ),
		'Ben after long spaces'       => 'x' . ' ' x $n . 'ben x',
		'word boundaries'             => 'a-' x $n,
		'post-nominal at the end'     => ( 'ab ' x ( $n / 3 ) ) . 'phd',
		'near post-nominal'           => ( 'phd ' x ( $n / 4 ) ) . 'phdx',
		'apostrophes'                 => "O'" x $n,
		'apostrophe-s'                => "'s" x $n,
		'only spaces'                 => ' ' x ( $n * 10 ),
		'only punctuation'            => '-' x ( $n * 10 ),
		'digits'                      => '1' x ( $n * 10 ),
		'newlines'                    => "a\n" x $n,
		'wide characters'             => "\x{3b1}\x{3b2}" x $n,
		'dot entries'                 => 'MCh' . '.' x $n,
	);
	for my $label ( sort keys %attack ) {
		my $text = $attack{$label};
		my $started = time;
		my $result = bounded( $STRESS_SECONDS, sub { my $r = nc($text); return defined $r && length $r > 0 } );
		ok( $result->{ok}, "finishes within ${STRESS_SECONDS}s: $label" ) or diag explain $result;
		dbg("$label: $result->{ok}");
	}

	# Same check through NameCase with every switch turned on and off.
	for my $setting ( 0, 1 ) {
		local ( $Lingua::EN::NameCase::HEBREW, $Lingua::EN::NameCase::SPANISH, $Lingua::EN::NameCase::ROMAN, $Lingua::EN::NameCase::POSTNOMINAL ) = ( $setting ) x 4;
		my $result = bounded( $STRESS_SECONDS, sub { my @r = NameCase( $attack{'Ben look-behind'}, $attack{'Mac then one long word'}, $attack{'roman letters with apostrophes'} ); return @r == 3 } );
		ok( $result->{ok}, "NameCase with every switch = $setting" ) or diag explain $result;
	}
};

# ---------------------------------------------------------------- mocked failures
# Purpose: the internal failure path is "croak".  If the thing that raises
# errors were to stop dying (here: replaced by a function that returns
# undef, 0 or ''), the guard clauses must still stop: no bad value may be
# processed and returned as if it were a name.
subtest 'error raiser that returns instead of dying' => sub {
	for my $upstream ( [ undef => sub { return undef } ], [ zero => sub { return 0 } ], [ empty => sub { return '' } ], [ nothing => sub { return } ] ) {
		my ( $label, $replacement ) = @{$upstream};
		mock "${PKG}::croak" => $replacement;

		throws_ok { nc( {} ) } qr/^Usage: nc /, "$label: nc with a hash still dies";
		throws_ok { NameCase() } qr/^NameCase only accepts/, "$label: NameCase() still dies";
		throws_ok { NameCase( {} ) } qr/^Usage: /, "$label: NameCase(hash) still dies";
		throws_ok { my @r = NameCase( 'a', 'b' ); my $s = NameCase( 'a', 'b' ) } qr/^NameCase only accepts/, "$label: two scalars in scalar context still dies";
		{
			local $Lingua::EN::NameCase::MAX_LENGTH = 1;
			throws_ok { nc('too long') } qr/^Name is too long/, "$label: size limit still enforced";
		}
		my @array = ( 'ANNE JONES', {} );
		dies_ok { NameCase( \@array ) } "$label: bad element in an array still dies";
		is( $array[0], 'ANNE JONES', "$label: and the array is untouched" );
		restore_all();
	}
	is( nc('JOHN SMITH'), 'John Smith', 'normal service after the mocks are removed' );
};

# Purpose: the message builder failing (returning undef, '' or 0) must not
# turn an error into a success.
subtest 'message builder that returns nothing useful' => sub {
	for my $value ( undef, '', 0 ) {
		mock "${PKG}::_i18n" => sub { return $value };
		my $label = defined $value ? "'$value'" : 'undef';
		# '0' is a real (if silly) message and is used as given; nothing falls back.
		my ( $nc_text, $single_text ) = ( defined $value && length $value ) ? ( $value, $value ) : ( 'usage_nc', 'single_arg' );
		throws_ok { nc( {} ) } qr/^\Q$nc_text\E at /, "nc still dies, text $label gives '$nc_text'";
		throws_ok { NameCase() } qr/^\Q$single_text\E at /, "NameCase still dies too ($label)";
		restore_all();
	}
};

# ---------------------------------------------------------------- resources
# Purpose: with the process short of file descriptors, the module (which
# needs none) must still work, and must leave none open.
subtest 'file descriptor exhaustion' => sub {
	plan skip_all => 'needs fork-like POSIX environment' unless $CAN_FORK;
	test_needs 'BSD::Resource';
	BSD::Resource->import(qw( getrlimit setrlimit RLIMIT_NOFILE ));

	my ( $soft, $hard ) = BSD::Resource::getrlimit( BSD::Resource::RLIMIT_NOFILE() );
	plan skip_all => 'cannot lower the descriptor limit here' unless defined $soft && BSD::Resource::setrlimit( BSD::Resource::RLIMIT_NOFILE(), $FD_LIMIT, $hard );

	# Open handles until the OS says no.
	my @handles;
	my $refused_with;
	while ( @handles < $FD_SAFETY_CAP ) {
		if ( open( my $fh, '<', File::Spec->devnull ) ) { push @handles, $fh; next }
		$refused_with = $!;
		last;
	}
	ok( defined $refused_with, 'the OS refused another descriptor' ) or diag 'limit not reached';
	ok( $!{EMFILE} || $!{ENFILE}, 'refused with EMFILE or ENFILE' ) if defined $refused_with;
	my $opened = @handles;
	dbg("opened $opened handles before refusal");

	# The module works without any free descriptor, and its errors do too.
	my @results;
	my $w = quiet {
		push @results, nc('JOHN SMITH'), scalar NameCase('ANNE JONES');
		my @list = NameCase( 'A B', 'C D' );
		push @results, @list;
		eval { nc( {} ) };
		push @results, $@ =~ /^Usage: nc / ? 'error ok' : "bad error: $@";
	};
	is_deeply( $w, [], 'no warning or death' );
	is_deeply( \@results, [ 'John Smith', 'Anne Jones', 'A B', 'C D', 'error ok' ], 'correct results' );

	# Release everything, then check we are back where we started: no leak.
	close $_ for @handles;
	@handles = ();
	my $reopened = 0;
	my @again;
	while ( $reopened < $opened && open( my $fh, '<', File::Spec->devnull ) ) { push @again, $fh; $reopened++ }
	is( $reopened, $opened, 'the same number of descriptors can be opened again: nothing leaked' );
	close $_ for @again;
	BSD::Resource::setrlimit( BSD::Resource::RLIMIT_NOFILE(), $soft, $hard );
};

# Purpose: the filesystem, network, database and clock scenarios from the
# brief do not apply (see the top of this file); say so, and prove the claim
# by showing the module works when everything around it is hostile.
subtest 'hostile environment' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	my $here = Cwd::getcwd();
	my $gone = File::Spec->catdir( $dir, 'deleted' );
	mkdir $gone or die "mkdir: $!";
	chdir $gone or die "chdir: $!";
	rmdir $gone;    # the current directory no longer exists

	local %ENV = ();
	local $0 = "evil\nname";
	local $SIG{ALRM} = 'IGNORE';
	local $SIG{PIPE} = 'IGNORE';
	my $r = eval { nc('JOHN SMITH') };
	chdir $here;
	is( $@, '', 'no error with a deleted working directory and an empty environment' );
	is( $r, 'John Smith', 'correct result' );
};

# ---------------------------------------------------------------- regressions
# Purpose: bugs found while hardening this module; each must stay fixed.
subtest 'regressions' => sub {
	# Unescaped dot in post-nominal entries made "MCHX" become "MCh.".
	is( nc('JOHN MCHX'), 'John McHx', 'MCHX is not turned into MCh.' );
	# nc() with a reference in $_ used to overwrite $_.
	{
		my $ref = \'JOHN SMITH';
		local $_ = $ref;
		nc();
		is( $_, $ref, '$_ keeps its reference' );
	}
	# A bad element used to leave an in-place array half converted.
	my @half = ( 'ANNE JONES', {}, 'BOB MCVEY' );
	eval { NameCase( \@half ) };
	is( $half[0], 'ANNE JONES', 'in place is all-or-nothing' );
	# A missing message key used to warn about an undefined hash key.
	is_deeply( quiet { eval { Lingua::EN::NameCase::_fail() } }, [], 'a missing key does not warn' );
	# Wide characters warned under non-UTF-8 locales, and Latin-1 names were
	# mis-cased there (the module used "use locale").
	require POSIX;
	my $old = POSIX::setlocale( POSIX::LC_ALL() );
	POSIX::setlocale( POSIX::LC_ALL(), 'C' );
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		is( nc("\x{c9}MILE ZOLA"), "\x{c9}mile Zola", 'accented name in the C locale' );
		is( nc("\x{3b1}\x{3b2} SMITH"), "\x{391}\x{3b2} Smith", 'Greek in the C locale' );
	}
	POSIX::setlocale( POSIX::LC_ALL(), $old ) if defined $old;
	is_deeply( \@warnings, [], 'no wide-character warnings' );
	# Error text used to echo a class name unchecked.
	my $err = eval { nc( bless {}, "A\nB" ); 1 } ? '' : $@;
	unlike( $err, qr/A\nB/, 'class names are sanitised in errors' );
};

done_testing();
