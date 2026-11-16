#!/usr/bin/perl -w

# Data-flow tests for Lingua::EN::NameCase.
#
# Method: follow each piece of data from where it is Defined (D), through
# where it is Used (U), to where it is Killed (K) or handed back.  The chains:
#
#   A  caller scalar    D caller -> U nc reads it once -> never written back
#   B  caller array     D caller -> U NameCase (in place) -> same element
#                       variables hold the answer (aliases see it)
#   C  failing array    D caller -> U partly -> croak -> nothing written
#   D  list results     D nc -> returned as fresh values, not the inputs
#   E  error arguments  D hashref -> U _fail/_i18n -> caller's hash unchanged
#   F  module tables    D at load -> U per call -> never changed (no hidden state)
#   G  switches         D at load / caller -> U per call; undef must not warn
#   H  stage values     D each stage -> U next stage; the input is not re-used
#   I  special vars     $_ $@ $! $1 pos(): read-only to the module
#
# Anomalies looked for: use before definition (a warning), a value written and
# lost, and a value defined twice with nothing between.  The module opens no
# file or socket, so the resource-lifecycle checks prove that nothing is left
# open and that the result does not depend on file permissions; a time-of-
# check/time-of-use race needs a file or lock to race on, and there is none.

use strict;
use warnings;

use Cwd ();
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();
use Readonly;
use Scalar::Util qw(refaddr);
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use lib 't/lib';
use ReturnsOk;

use Lingua::EN::NameCase qw( NameCase nc );

$Sub::Private::BYPASS = 1;    # white-box calls to private routines below

Readonly my $PKG       => 'Lingua::EN::NameCase';
Readonly my $SENTINEL  => 'SENTINEL';
Readonly my $SHUFFLES  => 2_000;
Readonly my $BIG_BATCH => 20_000;

sub dbg {
	diag(@_) if $ENV{TEST_VERBOSE};
	return;
}

# Warnings (and any death) produced by a block.
sub quiet(&) {
	my $code = shift;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	eval { $code->() };
	return [ @warnings, ( $@ ? "DIED: $@" : () ) ];
}

# The lowest free file descriptor: it moves if anything was left open.
sub lowest_free_descriptor {
	open( my $probe, '<', File::Spec->devnull ) or die "open devnull: $!";
	my $number = fileno $probe;
	close $probe;
	return $number;
}

# ---------------------------------------------------------------- chain A
# Purpose: the caller's scalar is read, never written, however it is passed.
subtest 'A: a scalar argument is read once and never written back' => sub {
	my $name   = 'anne jones';
	my $before = refaddr \$name;
	my $result = nc($name);
	is( $result, 'Anne Jones', 'result is the new value' );
	is( $name, 'anne jones', 'the caller variable keeps its old value' );
	is( refaddr( \$name ), $before, 'and is the same variable' );
	isnt( refaddr( \$result ), $before, 'the result is a different variable' );

	# Through an alias: $_[0] in the caller's sub is the caller's variable.
	my $through_alias = sub { my $r = nc( $_[0] ); return ( $r, $_[0] ) };
	my ( $r, $argument ) = $through_alias->($name);
	is( $argument, 'anne jones', 'an aliased argument is not written' );

	# A stage that writes to its own argument must not reach the caller.
	mock "${PKG}::_base_case" => sub { my $copy = $_[0]; $_[0] = 'CLOBBERED'; return lc $copy };
	my $caller_value = 'JOHN SMITH';
	nc($caller_value);
	restore_all();
	is( $caller_value, 'JOHN SMITH', 'a helper that clobbers its argument only changes the module copy' );

	# A scalar reference: the target is read, not written.
	my $target = 'mary jones';
	is( nc( \$target ), 'Mary Jones', 'read through a reference' );
	is( $target, 'mary jones', 'target unchanged' );
	is( scalar NameCase( \$target ), 'Mary Jones', 'NameCase through a reference' );
	is( $target, 'mary jones', 'target unchanged' );
};

# ---------------------------------------------------------------- chain B
# Purpose: in place means the existing element variables change.  This is
# what lets NameCase(\@_) change the caller's own variables, and what lets a
# held reference to an element see the answer.
subtest 'B: in place changes the existing element variables (aliases see it)' => sub {
	my @names   = ( 'anne jones', 'bob mcvey' );
	my $array   = \@names;
	my @element = map { refaddr \$_ } @names;
	my $held    = \$names[0];

	my $returned = NameCase( \@names );
	is( $returned, $array, 'the same array is returned' );
	is( refaddr($returned), refaddr($array), 'same array variable' );
	is_deeply( \@names, [ 'Anne Jones', 'Bob McVey' ], 'values changed' );
	is_deeply( [ map { refaddr \$_ } @names ], \@element, 'every element is the same variable as before' );
	is( ${$held}, 'Anne Jones', 'a reference to an element sees the change' );

	# Through @_ the elements are the caller's variables.
	my ( $first, $second ) = ( 'carl smith', 'dave o\'neil' );
	my $via_args = sub { NameCase( \@_ ); return };
	$via_args->( $first, $second );
	is_deeply( [ $first, $second ], [ 'Carl Smith', "Dave O'Neil" ], 'NameCase(\@_) changes the caller variables' );

	# Lengths never change, and false values stay where they are.
	my @odd = ( 'anne', undef, '', '0', 'bob' );
	NameCase( \@odd );
	is_deeply( \@odd, [ 'Anne', undef, '', '0', 'Bob' ], 'count and false values kept' );

	# The slice assignment must also work on an empty array and a one-element array.
	my @empty;
	NameCase( \@empty );
	is( scalar @empty, 0, 'empty stays empty' );
	my @one = ('eve adams');
	NameCase( \@one );
	is_deeply( \@one, ['Eve Adams'], 'one element' );
};

# ---------------------------------------------------------------- chain C
# Purpose: a failure part way through writes nothing: same values in the
# same variables.
subtest 'C: a failing in-place call writes nothing' => sub {
	my @names = ( 'anne jones', 'bob mcvey', {}, 'carl smith' );
	my @before_values = map { ref $_ ? refaddr $_ : $_ } @names;
	my @before_vars   = map { refaddr \$_ } @names;
	my $held          = \$names[0];

	throws_ok { NameCase( \@names ) } qr/^Usage: nc .*\(got HASH\)/, 'the bad element is reported';
	is_deeply( [ map { ref $_ ? refaddr $_ : $_ } @names ], \@before_values, 'every value as before' );
	is_deeply( [ map { refaddr \$_ } @names ], \@before_vars, 'every element variable as before' );
	is( ${$held}, 'anne jones', 'a held reference is unchanged' );

	# Failure forced late: the third call to nc dies.
	my $calls = 0;
	mock "${PKG}::nc" => sub { die "late failure\n" if ++$calls == 3; return uc $_[0] };
	my @letters = qw( a b c d );
	throws_ok { NameCase( \@letters ) } qr/^late failure$/, 'late failure propagates';
	is_deeply( \@letters, [qw( a b c d )], 'nothing written, even though two names were already done' );
	restore_all();

	# Too long: the size limit is a failure of the same kind.
	local $Lingua::EN::NameCase::MAX_LENGTH = 5;
	my @sized = ( 'abc', 'abcdefgh', 'xyz' );
	throws_ok { NameCase( \@sized ) } qr/too long/, 'over the size limit';
	is_deeply( \@sized, [ 'abc', 'abcdefgh', 'xyz' ], 'nothing written' );
};

# ---------------------------------------------------------------- chain D
# Purpose: results are fresh values; changing a result never changes an input.
subtest 'D: list results are copies, not the inputs' => sub {
	my @source = ( 'anne jones', 'bob mcvey' );
	my @result = NameCase(@source);
	$_ .= '!' for @result;
	is_deeply( \@source, [ 'anne jones', 'bob mcvey' ], 'changing the results leaves the source alone' );

	my $array  = [ 'carl smith', 'dave jones' ];
	my @copies = NameCase($array);
	$copies[0] = 'changed';
	is_deeply( $array, [ 'carl smith', 'dave jones' ], 'array ref in list context is not touched' );

	my $same = nc('Same Name');
	my $again = nc('Same Name');
	isnt( refaddr( \$same ), refaddr( \$again ), 'each call returns a new value' );
	returns_ok( \@result, { type => 'arrayref', min => 2 }, 'a list of two' );
};

# ---------------------------------------------------------------- chain E
# Purpose: the arguments of the error routines are used but not changed.
subtest 'E: error arguments and message tables are not modified' => sub {
	my $args   = { got => "Evil\nClass", length => 7, max => 3 };
	my %before = %{$args};
	throws_ok { Lingua::EN::NameCase::_fail( 'usage_nc', $args ) } qr/^Usage: nc .*\(got Evil\?Class\)/, '_fail sanitises its own copy';
	is_deeply( $args, \%before, 'the caller hash still holds the raw value' );

	my $text = Lingua::EN::NameCase::_i18n( 'too_long', $args );
	is_deeply( $args, \%before, '_i18n leaves its hash alone' );
	is( $text, 'Name is too long: 7 characters (the maximum is 3)', 'and fills the template' );

	my %messages = ( usage_nc => 'Bad: {got}' );
	local %Lingua::EN::NameCase::MESSAGES = %messages;
	eval { nc( [] ) };
	is_deeply( \%Lingua::EN::NameCase::MESSAGES, \%messages, 'the message table is not modified by use' );
	is( Lingua::EN::NameCase::_i18n( 'usage_nc', { got => 'X' } ), 'Bad: X', 'and the template is not consumed' );
	is( Lingua::EN::NameCase::_i18n( 'usage_nc', { got => 'Y' } ), 'Bad: Y', 'it can be used again' );

	# Nothing is created in the caller's table: a missing key is read, not stored.
	my %empty;
	local %Lingua::EN::NameCase::MESSAGES = %empty;
	Lingua::EN::NameCase::_i18n('no_such_key');
	is_deeply( \%Lingua::EN::NameCase::MESSAGES, {}, 'reading a missing key does not create it' );
};

# ---------------------------------------------------------------- chain F
# Purpose: the module's tables are built once and never change, so the answer
# for a name depends only on the name and the switches, never on earlier calls.
subtest 'F: no hidden state between calls' => sub {
	my @names = ( 'JOHN SMITH', "O'CALLAGHAN", 'VAN DER POST', 'MACHADO', 'MCCARTHY', 'HENRY VIII', 'JANE SMITH PHD',
		'MIRIAM BAT RIVKAH', 'EL PASO', 'NA LI', 'DR SARAH BEETLE', '', '0', "ST. JOHN\n" );
	my %baseline = map { $_ => nc($_) } @names;

	srand 11;
	my @wrong;
	for ( 1 .. $SHUFFLES ) {
		my $name = $names[ rand @names ];
		# Interleave switch changes, which must not outlive their block.
		{
			local $Lingua::EN::NameCase::ROMAN = rand() < 0.5 ? 0 : 1;
			local $Lingua::EN::NameCase::SPANISH = rand() < 0.5 ? 0 : 1;
			nc( $names[ rand @names ] );
		}
		push @wrong, $name if nc($name) ne $baseline{$name};
	}
	is_deeply( \@wrong, [], "$SHUFFLES shuffled calls, every answer equal to its baseline" );

	# Stash: nothing was added to the module's namespace by use.
	my @stash_before = sort keys %Lingua::EN::NameCase::;
	nc($_) for @names;
	NameCase( \@{ [@names] } );
	eval { nc( {} ) };
	is_deeply( [ sort keys %Lingua::EN::NameCase:: ], \@stash_before, 'no new package variables or subs' );

	# No global match state is left for the next caller.
	"abc" =~ /(b)/;
	nc('JOHN MCVEY');
	is( "$1$&", 'bb', 'capture variables of the caller survive' );
};

# ---------------------------------------------------------------- chain G
# Purpose: every switch, defined or undef, is read before use without a warning
# (no use-before-definition), on every path through the code.
subtest 'G: switches and limits are always defined when read' => sub {
	my @inputs = ( 'JOHN SMITH', 'VAN DER POST', 'HENRY VIII', 'JANE PHD', 'MACHADO', '', '0', undef );
	for my $value ( undef, '', 0, 1 ) {
		my $w = quiet {
			local ( $Lingua::EN::NameCase::HEBREW, $Lingua::EN::NameCase::SPANISH, $Lingua::EN::NameCase::ROMAN,
				$Lingua::EN::NameCase::POSTNOMINAL, $Lingua::EN::NameCase::MAX_LENGTH ) = ( $value, $value, $value, $value, undef );
			nc($_) for @inputs;
			my @list = NameCase(@inputs[ 0 .. 4 ]);
			NameCase( [@inputs] );
		};
		is_deeply( $w, [], 'no warning with every switch = ' . ( defined $value ? "'$value'" : 'undef' ) );
	}

	my $w = quiet {
		local %Lingua::EN::NameCase::MESSAGES = ();
		for my $bad ( {}, [], sub { 1 } ) { eval { nc($bad) } }
		eval { NameCase() };
		eval { Lingua::EN::NameCase::_i18n() };
		eval { Lingua::EN::NameCase::_fail('single_arg') };
	};
	is_deeply( $w, [], 'the error paths warn about nothing, with an empty message table' );
};

# ---------------------------------------------------------------- chain H
# Purpose: each stage hands its output to the next; the original input is
# not used again after the first stage.
subtest 'H: each stage feeds the next; the input is not re-used' => sub {
	my %seen;
	for my $step (qw( _base_case _mac_case _particle_case _roman_case _postnominal_case )) {
		mock "${PKG}::$step" => sub { push @{ $seen{$step} }, $_[0]; return "$_[0]>$step" };
	}
	local ( $Lingua::EN::NameCase::ROMAN, $Lingua::EN::NameCase::POSTNOMINAL ) = ( 1, 1 );
	my $result = Lingua::EN::NameCase::nc('ORIGINAL');
	restore_all();

	is( $seen{_base_case}[0], 'ORIGINAL', 'the first stage gets the input' );
	is( $seen{_mac_case}[0], 'ORIGINAL>_base_case', 'the second gets the first output' );
	is( $seen{_particle_case}[0], 'ORIGINAL>_base_case>_mac_case', 'and so on' );
	is( $seen{_roman_case}[0], 'ORIGINAL>_base_case>_mac_case>_particle_case', 'down the chain' );
	is( $result, 'ORIGINAL>_base_case>_mac_case>_particle_case>_roman_case>_postnominal_case', 'the last output is the result' );
	my @original_uses = grep { grep { $_ eq 'ORIGINAL' } @{ $seen{$_} } } keys %seen;
	is_deeply( \@original_uses, ['_base_case'], 'only the first stage ever saw the original' );
	is( scalar( map { @{ $seen{$_} } } keys %seen ), 5, 'each stage ran exactly once' );
};

# ---------------------------------------------------------------- anomaly regression
# Purpose: a value defined but never found (use before definition).  A name
# that matches a post-nominal only through case folding has no exact key; its
# lookup used to return undef, which was then written into the name, deleting
# the text and warning.
subtest 'regression: fold-only post-nominal matches must not delete text' => sub {
	my %cases = (
		"JOHN M\x{17F}"     => "John M\x{17F}",       # long s matches "s"
		"JOHN M\x{FB01}N"   => "John M\x{FB01}n",     # "fi" ligature matches "fi" in MFin
		"ANNE FD\x{17F}"    => "Anne Fd\x{17F}",
	);
	for my $in ( sort keys %cases ) {
		my $got;
		my $w = quiet { $got = nc($in) };
		is_deeply( $w, [], sprintf( 'no warning for %vX', $in ) );
		is( $got, $cases{$in}, sprintf( '%vX: text kept', $in ) );
	}

	# Property over the whole list: replace each s or k by a look-alike that
	# folds to it.  Nothing may be lost and nothing may warn.
	open( my $fh, '<', $INC{'Lingua/EN/NameCase.pm'} ) or die "read module: $!";
	my $source = do { local $/; <$fh> };
	close $fh;
	my ($list) = $source =~ /Readonly my \@POST_NOMINAL_INITIALS => qw\((.*?)\);/s;
	my %unique = map { lc $_ => 1 } split ' ', $list;
	my @lost;
	my @warned;
	for my $entry ( sort keys %unique ) {
		( my $fold_only = $entry ) =~ s/s/\x{17F}/g;
		$fold_only =~ s/k/\x{212A}/g;
		next if $fold_only eq $entry;
		my $in = "Jane $fold_only";
		my $got;
		my $w = quiet { $got = nc($in) };
		push @warned, $entry if @{$w};
		push @lost, $entry if length($got) < length($in);
	}
	is_deeply( \@warned, [], 'no warning for any look-alike entry' );
	is_deeply( \@lost, [], 'no look-alike entry loses characters' );
};

# ---------------------------------------------------------------- chain I
# Purpose: special variables are read-only to the module.
subtest 'I: $_ $@ $! pos() and friends are left as they were' => sub {
	local $_ = $SENTINEL;
	local $@ = 'kept error';
	local $! = POSIX::ENOENT();

	nc('JOHN SMITH');
	my @list = NameCase( 'A B', 'C D' );
	NameCase( ['e f'] );
	is_deeply( [ $_, $@, $! + 0 ], [ $SENTINEL, 'kept error', POSIX::ENOENT() ], 'after success' );

	{
		local $@;
		eval { nc( {} ) };
		eval { NameCase() };
	}
	is_deeply( [ $_, $! + 0 ], [ $SENTINEL, POSIX::ENOENT() ], '$_ and $! after errors' );

	my $text = 'aaa';
	$text =~ /a/g;
	my $position = pos $text;
	nc( \$text );
	is( pos $text, $position, 'pos() of a referenced scalar' );

	# $_ aliased to caller data is never written.
	my @data = ( 'x y', 'z w' );
	nc() for @data;
	is_deeply( \@data, [ 'x y', 'z w' ], 'nc() on an aliased $_ does not write it' );
};

# ---------------------------------------------------------------- resources
# Purpose: nothing is left open.  The module has no open/use/close sequence of
# its own; this proves that no call, successful or not, leaks a descriptor.
subtest 'resources: no descriptor or file is left behind' => sub {
	my $before = lowest_free_descriptor();

	nc($_) for ( 'JOHN SMITH', 'MCCARTHY', 'VAN DER POST', undef, '' );
	eval { nc( {} ) } for 1 .. 50;
	eval { NameCase() } for 1 .. 50;
	my @many = ('JOHN SMITH') x $BIG_BATCH;
	NameCase( \@many );
	{
		local $Lingua::EN::NameCase::MAX_LENGTH = 3;
		eval { nc('too long') } for 1 .. 50;
	}
	is( lowest_free_descriptor(), $before, 'the lowest free descriptor is unchanged' );

	my $dir  = tempdir( CLEANUP => 1 );
	my $here = Cwd::getcwd();
	chdir $dir or die "chdir: $!";
	nc("name\nwith newline");
	nc('../../etc/passwd');
	eval { nc( {} ) };
	opendir( my $dh, $dir ) or die "opendir: $!";
	my @files = grep { !/^\.\.?$/ } readdir $dh;
	closedir $dh;
	chdir $here;
	is_deeply( \@files, [], 'no file is created, whatever the text looks like' );
};

# Purpose: the answer cannot depend on the file system: take away the right to
# create files and to search the directory the program is in, and call again.
subtest 'resources: file permission lockouts change nothing' => sub {
	eval { require Test::Permissions; Test::Permissions->import(qw( :revoke :guard :report )); 1 } or plan skip_all => 'Test::Permissions is not installed';

	my $dir = tempdir( CLEANUP => 1 );
	diag( permissions_report($dir) ) if $ENV{TEST_VERBOSE};
	my @names    = ( 'JOHN SMITH', 'MCCARTHY', 'HENRY VIII', 'JANE PHD' );
	my @expected = NameCase(@names);

	SKIP: {
		skip( why_not( 'create', $dir ), 2 ) unless can_revoke_create($dir);
		my @got;
		with_revoked( create => $dir, sub { @got = NameCase(@names) } );
		is_deeply( \@got, \@expected, 'same answers with the directory refusing new files' );
		my @error;
		with_revoked( create => $dir, sub { eval { nc( {} ) }; @error = ($@) } );
		like( $error[0], qr/^Usage: nc /, 'and the same error' );
	}

	SKIP: {
		skip( why_not( 'search', $dir ), 2 ) unless can_revoke_search($dir);
		my $here   = Cwd::getcwd();
		my $before = lowest_free_descriptor();
		chdir $dir or die "chdir: $!";
		my @got;
		with_revoked( search => $dir, sub { @got = NameCase(@names) } );
		chdir $here;
		is_deeply( \@got, \@expected, 'same answers with the directory unsearchable' );
		is( lowest_free_descriptor(), $before, 'and no descriptor was taken' );
	}
};

done_testing();
