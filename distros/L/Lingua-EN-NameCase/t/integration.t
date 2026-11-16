#!/usr/bin/perl -w

# End-to-end tests for Lingua::EN::NameCase, written from the POD.
#
# Scope notes, so nobody wonders what is missing:
#  * The module is a set of functions with no constructor, so there is no
#    new() to call; "independent instances" are separate scopes, separate
#    importing packages and separate processes.
#  * Its one optional dependency, Sub::Private, and its recommended partner
#    (Lingua::EN::NameParse) are tested present and absent with
#    Test::Without::Module; the hard dependency Readonly is tested for a
#    clear failure.
#  * It touches no files, network or database, so there is nothing to
#    revoke permissions on or to sabotage upstream.  The file and JSON
#    workflows below are the realistic pipelines around it, and they check
#    that bad records neither hang nor stop the batch.

use strict;
use warnings;
no warnings 'once';    # the module's switches are set before it is seen at compile time

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::Most;
use Test::Needs 'Test::Mockingbird';    # needs a recent Perl; skip the file without it
use Test::Mockingbird;
use Test::Needs;
use lib 't/lib';
use ReturnsOk;
use Readonly;
use Time::HiRes qw(time);

Readonly my $MODULE        => 'Lingua::EN::NameCase';
Readonly my $PARTNER       => 'Lingua::EN::NameParse';
Readonly my $BATCH_SIZE    => 20_000;
Readonly my $HANG_SECONDS  => 30;       # only to stop a hung test, not a speed target
Readonly my $PAYLOAD       => [ 'ANNE JONES', "\x{c9}MILE ZOLA", "john \x{1F600} smith", q{O'CALLAGHAN}, 'MIRIAM BAT RIVKAH' ];
Readonly my $PAYLOAD_FIXED => [ 'Anne Jones', "\x{c9}mile Zola", "John \x{1F600} Smith", q{O'Callaghan}, 'Miriam bat Rivkah' ];

# Loaded at compile time too, so the package variables set below are known
# to Perl and do not trigger "used only once" warnings on some Perl versions.
use Lingua::EN::NameCase ();

use_ok($MODULE) or BAIL_OUT("cannot load $MODULE");
require_ok($MODULE);
Lingua::EN::NameCase->import(qw( nc NameCase ));

sub dbg {
	diag(@_) if $ENV{TEST_VERBOSE};
	return;
}

# Directory that holds the module under test, so child perls load the same copy.
my ($LIB_DIR) = $INC{'Lingua/EN/NameCase.pm'} =~ m{^(.*)/Lingua/EN/NameCase\.pm$};
$LIB_DIR = File::Spec->rel2abs($LIB_DIR) if defined $LIB_DIR;

# Run a fresh perl with some modules hidden, and return its combined output.
sub run_child {
	my ( $hidden, $code ) = @_;
	my @cmd = ( $^X, "-I$LIB_DIR" );
	push @cmd, '-MTest::Without::Module=' . join( ',', @{$hidden} ) if @{$hidden};
	push @cmd, '-e', "open STDERR, '>&', \\*STDOUT; binmode STDOUT, ':utf8'; $code";
	open( my $ph, '-|', @cmd ) or die "cannot run $^X: $!";
	my $out = do { local $/; <$ph> };
	close $ph;
	return $out // '';
}

# ---------------------------------------------------------------- importing
# Purpose: the exports promised by the POD: nc by default, NameCase on request.
subtest 'exports: default, on request, and unknown names' => sub {
	{
		package Import::Default;
		Lingua::EN::NameCase->import();
	}
	{
		package Import::Both;
		Lingua::EN::NameCase->import(qw( nc NameCase ));
	}
	{
		package Import::Only::NameCase;
		Lingua::EN::NameCase->import('NameCase');
	}
	ok( Import::Default->can('nc'),                'default import gives nc' );
	ok( !Import::Default->can('NameCase'),         '... but not NameCase' );
	ok( Import::Both->can('nc') && Import::Both->can('NameCase'), 'both on request' );
	ok( Import::Only::NameCase->can('NameCase') && !Import::Only::NameCase->can('nc'), 'NameCase alone' );
	throws_ok { Lingua::EN::NameCase->import('no_such_function') } qr/not exported/, 'unknown name refused';

	# The imported copies are the real thing, in every importing package.
	is( Import::Default::nc('JOHN SMITH'), 'John Smith', 'imported nc works' );
	is( scalar Import::Both::NameCase('JOHN SMITH'), 'John Smith', 'imported NameCase works' );
};

# ---------------------------------------------------------------- file pipeline
# Purpose: the everyday workflow: read upper-case names from a file, fix
# them, write them out, read them back.  UTF-8 and emoji must survive.
subtest 'file workflow: read, fix, write, read back' => sub {
	my $dir  = tempdir( CLEANUP => 1 );
	my $in   = File::Spec->catfile( $dir, 'names.txt' );
	my $out  = File::Spec->catfile( $dir, 'fixed.txt' );

	open( my $w, '>:encoding(UTF-8)', $in ) or die "write $in: $!";
	print {$w} "$_\n" for @{$PAYLOAD};
	close $w;

	open( my $r, '<:encoding(UTF-8)', $in ) or die "read $in: $!";
	open( my $o, '>:encoding(UTF-8)', $out ) or die "write $out: $!";
	while ( my $line = <$r> ) {
		chomp $line;
		print {$o} nc($line), "\n";
	}
	close $r;
	close $o;

	open( my $back, '<:encoding(UTF-8)', $out ) or die "read $out: $!";
	chomp( my @fixed = <$back> );
	close $back;
	is_deeply( \@fixed, $PAYLOAD_FIXED, 'file round trip' );
	dbg( 'fixed: ' . join( ' | ', @fixed ) );
};

# Purpose: the same data through the array interface, then checked for
# consistency between nc, NameCase (list), NameCase (in place) and refs.
subtest 'all interfaces agree on the same data' => sub {
	my @source   = @{$PAYLOAD};
	my @via_nc   = map { nc($_) } @source;
	my @via_list = NameCase(@source);
	my @via_ref  = NameCase( \@source );
	my @inplace  = @source;
	NameCase( \@inplace );
	my @via_scalar_ref = map { nc( \$_ ) } @source;

	is_deeply( \@via_nc, $PAYLOAD_FIXED, 'nc' );
	is_deeply( \@via_list, \@via_nc, 'NameCase list' );
	is_deeply( \@via_ref, \@via_nc, 'NameCase array ref' );
	is_deeply( \@inplace, \@via_nc, 'NameCase in place' );
	is_deeply( \@via_scalar_ref, \@via_nc, 'nc with scalar refs' );
	is_deeply( \@source, $PAYLOAD, 'source never modified by the copying forms' );
	returns_ok( \@via_list, { type => 'arrayref', min => 1 }, 'list result' );

	# Running the output through again changes nothing.
	is_deeply( [ NameCase(@via_nc) ], \@via_nc, 'idempotent' );
};

# Purpose: sort and de-duplicate names that differ only by case, a common
# clean-up that depends on nc being stable.
subtest 'workflow: de-duplicate names that differ only in case' => sub {
	my @raw    = ( 'JOHN SMITH', 'john smith', 'John Smith', 'MARY JONES', 'mary jones' );
	my %seen;
	my @unique = grep { !$seen{$_}++ } NameCase(@raw);
	is_deeply( [ sort @unique ], [ 'John Smith', 'Mary Jones' ], 'duplicates collapse' );
};

# ---------------------------------------------------------------- spies
# Purpose: confirm NameCase delegates to nc, once per name, with each
# original name, and that errors go through croak with the documented text.
subtest 'spies: delegation and error reporting' => sub {
	my $nc_spy = spy 'Lingua::EN::NameCase::nc';
	my @got = NameCase( 'ANNE JONES', 'BOB MCVEY' );
	my @calls = $nc_spy->();
	restore_all();

	is( scalar @calls, 2, 'nc called once per name' );
	is_deeply( [ map { $_->[1] } @calls ], [ 'ANNE JONES', 'BOB MCVEY' ], 'with the original names, in order' );
	is_deeply( \@got, [ 'Anne Jones', 'Bob McVey' ], 'results unaffected by the spy' );

	my $croak_spy = spy 'Lingua::EN::NameCase::croak';
	throws_ok { nc( {} ) } qr/^Usage: nc /, 'the call still fails as documented';
	my @croaks = $croak_spy->();
	restore_all();
	is( scalar @croaks, 1, 'croak called exactly once' );
	like( $croaks[0][1], qr/^Usage: nc \[\[\\\]\$SCALAR\] \(got HASH\)$/, 'with the full documented message' );
};

# ---------------------------------------------------------------- configuration
# Purpose: the switches are shared by nc and NameCase, take effect on the
# next call, and a scoped change leaves nothing behind.
subtest 'configuration is shared by every entry point and scoped by local' => sub {
	my @names = ( 'EL PASO', 'LA LUNA', 'NA LI', 'JANE PHD', 'MIRIAM BAT RIVKAH' );
	my @default = NameCase(@names);

	{
		local $Lingua::EN::NameCase::SPANISH     = 1;
		local $Lingua::EN::NameCase::ROMAN       = 0;
		local $Lingua::EN::NameCase::POSTNOMINAL = 0;
		local $Lingua::EN::NameCase::HEBREW      = 0;
		my @custom = NameCase(@names);
		is_deeply( \@custom, [ 'El Paso', 'La Luna', 'Na Li', 'Jane Phd', 'Miriam Bat Rivkah' ], 'list form sees all four switches' );
		is( nc('EL PASO'), 'El Paso', 'nc sees them too' );

		my @inplace = @names;
		NameCase( \@inplace );
		is_deeply( \@inplace, \@custom, 'in place sees them too' );
	}
	is_deeply( [ NameCase(@names) ], \@default, 'everything restored after the block' );
	is_deeply( \@default, [ 'el Paso', 'la Luna', 'Na LI', 'Jane PhD', 'Miriam bat Rivkah' ], 'documented defaults' );
};

# Purpose: independent users of the module do not affect each other.  Two
# interleaved "sessions" with different rules, then separate processes.
subtest 'concurrency: interleaved sessions and separate processes' => sub {
	my %session = (
		spanish => sub { local $Lingua::EN::NameCase::SPANISH = 1; return nc( $_[0] ) },
		greek   => sub { local $Lingua::EN::NameCase::SPANISH = 0; return nc( $_[0] ) },
	);
	my @order = qw( spanish greek greek spanish spanish greek );
	my @got   = map { $session{$_}->('EL PASO') } @order;
	is_deeply( \@got, [ map { $_ eq 'spanish' ? 'El Paso' : 'el Paso' } @order ], 'interleaved sessions do not interfere' );

	# A child process gets a copy of the program; its changes are its own.
	plan skip_all => 'fork is not available here' if $^O eq 'MSWin32';
	pipe( my $reader, my $writer ) or die "pipe: $!";
	my $pid = fork();
	die "fork: $!" unless defined $pid;
	if ( !$pid ) {
		close $reader;
		$Lingua::EN::NameCase::SPANISH = 1;
		print {$writer} nc('EL PASO');
		close $writer;
		exit 0;
	}
	close $writer;
	my $child_result = <$reader>;
	waitpid( $pid, 0 );
	is( $child_result, 'El Paso', 'child used its own setting' );
	is( nc('EL PASO'), 'el Paso', 'parent unaffected by the child' );
};

# ---------------------------------------------------------------- bad records
# Purpose: a batch with bad records must report each one and carry on,
# and the module must be fully usable afterwards.
subtest 'batch: bad records are isolated and do not stop the run' => sub {
	my @records = ( 'ANNE JONES', {}, 'BOB MCVEY', [], undef, '', 'CARL VAN DYKE', sub { 1 }, 'DAVE', \'EVE ADAMS', ( bless {}, 'Evil' ) );
	my ( @fixed, @errors );
	for my $record (@records) {
		my $result = eval { nc($record) };
		if ($@) { push @errors, $@; next }
		push @fixed, $result;
	}
	is_deeply( \@fixed, [ 'Anne Jones', 'Bob McVey', undef, '', 'Carl van Dyke', 'Dave', 'Eve Adams' ], 'good records fixed, empty ones passed on' );
	is( scalar @errors, 4, 'one error per bad record' );
	like( $errors[0], qr/^Usage: nc .*\(got HASH\)/, 'first error names its type' );
	like( $errors[-1], qr/\(got Evil\)/, 'last error names its class' );
	is( nc('JOHN SMITH'), 'John Smith', 'still working afterwards' );
};

# Purpose: JSON from another system.  Valid payloads work; malformed ones
# fail in the decoder, not in this module, and the next payload still works.
subtest 'JSON payloads: valid, malformed, hostile' => sub {
	my $json = JSON::PP->new->utf8;

	my $text    = $json->encode($PAYLOAD);
	my $decoded = $json->decode($text);
	is_deeply( [ NameCase(@{$decoded}) ], $PAYLOAD_FIXED, 'valid payload' );

	my @malformed = ( '{"names":[', '["ANNE"', 'not json', '' );
	for my $bad (@malformed) {
		my $data = eval { $json->decode($bad) };
		ok( $@ && !defined $data, "decoder rejects: '$bad'" );
	}
	is( nc('AFTER BAD JSON'), 'After Bad Json', 'module unaffected by upstream failures' );

	# Valid JSON with unexpected shapes inside the list.
	my $mixed = $json->decode('["ANNE JONES", null, 42, "", {"a":1}, [1], true]');
	my ( @ok, @bad );
	for my $item ( @{$mixed} ) {
		my $r = eval { nc($item) };
		$@ ? push( @bad, ref $item ) : push( @ok, $r );
	}
	is_deeply( [ @ok[ 0 .. 3 ] ], [ 'Anne Jones', undef, 42, '' ], 'strings, null and numbers handled' );
	ok( scalar @bad >= 2, 'a hash and an array are rejected' );
	dbg( 'rejected types: ' . join( ',', @bad ) );
};

# Purpose: a very large batch finishes (a hang would be a failure), gives
# the right answer, and uses the documented in-place form.
subtest 'large batch finishes and stays correct' => sub {
	my @batch = map { $_ % 2 ? 'JOHN SMITH' : "MARY O'NEIL-JONES $_" } 1 .. $BATCH_SIZE;

	local $SIG{ALRM} = sub { die "batch hung\n" };
	my $start = time;
	alarm $HANG_SECONDS;
	my $done = eval { NameCase( \@batch ); 1 };
	alarm 0;
	dbg( sprintf 'batch of %d took %.2fs', $BATCH_SIZE, time - $start );

	ok( $done, 'finished before the watchdog' ) or diag $@;
	is( scalar @batch, $BATCH_SIZE, 'count unchanged' );
	is( $batch[0],  "John Smith", 'first (odd) record' );
	is( $batch[1],  "Mary O'Neil-Jones 2", 'second (even) record' );
};

# ---------------------------------------------------------------- dependencies
# Purpose: Readonly is a hard dependency: missing, loading fails at once
# with a message that names it (no half-working module).
subtest 'missing required module fails clearly' => sub {
	plan skip_all => 'child perl not used on this platform' if $^O eq 'MSWin32';
	my $out = run_child( ['Readonly'], 'eval { require Lingua::EN::NameCase; 1 } ? print "LOADED\n" : print "FAILED: $@\n";' );
	like( $out, qr/^FAILED: .*Readonly/s, 'load fails and names Readonly' );
	unlike( $out, qr/LOADED/, '... and does not load' );

	$out = run_child( [], 'require Lingua::EN::NameCase; print Lingua::EN::NameCase::nc("JOHN SMITH"), "\n";' );
	is( $out, "John Smith\n", 'control: with nothing hidden it works' );
};

# Purpose: Sub::Private is optional.  Without it the module must load and
# give the same answers; the only difference is that the internals are not
# locked.
subtest 'optional Sub::Private present or absent' => sub {
	plan skip_all => 'child perl not used on this platform' if $^O eq 'MSWin32';
	local $ENV{HARNESS_ACTIVE} = 0;    # prove sets it, and Sub::Private then skips its checks

	my $names = 'print Lingua::EN::NameCase::nc("DR SARAH BEETLE"), "|", join(",", Lingua::EN::NameCase::NameCase("a b", "c d")), "\n";';
	my $call_private = 'print eval { Lingua::EN::NameCase::_base_case("x") } // "REFUSED", "\n";';

	my $without = run_child( ['Sub::Private'], "require Lingua::EN::NameCase; $names $call_private" );
	is( $without, "Dr Sarah Beetle|A B,C D\nX\n", 'hidden: loads, same answers, internals open' );

	SKIP: {
		skip 'Sub::Private is not installed', 2 unless $INC{'Sub/Private.pm'};
		my $with = run_child( [], "require Lingua::EN::NameCase; $names $call_private" );
		is( $with, "Dr Sarah Beetle|A B,C D\nREFUSED\n", 'present: same answers, internals locked' );
		like( run_child( [], 'require Lingua::EN::NameCase; eval { Lingua::EN::NameCase::_base_case("x") }; print $@;' ),
			qr/^_base_case\(\) is a private subroutine of Lingua::EN::NameCase and cannot be called from main/, 'present: exact refusal message' );
	}
};

# Purpose: the optional partner module (NameParse) may be present or
# absent; nc must work identically either way.
subtest 'optional partner module present or absent' => sub {
	plan skip_all => 'child perl not used on this platform' if $^O eq 'MSWin32';
	my $code = 'require Lingua::EN::NameCase; print Lingua::EN::NameCase::nc("DR SARAH BEETLE"), "\n";';

	is( run_child( [$PARTNER], $code ), "Dr Sarah Beetle\n", 'works with NameParse hidden' );
	is( run_child( [ $PARTNER, 'JSON::PP', 'File::Temp' ], $code ), "Dr Sarah Beetle\n", 'works with all optional extras hidden' );
	is( run_child( [], $code ), "Dr Sarah Beetle\n", 'works with everything available' );
};

# Purpose: the POD recommends NameParse for real parsing; cased names must
# feed it cleanly and come back as the right parts.
subtest 'partner workflow: NameCase then Lingua::EN::NameParse' => sub {
	test_needs $PARTNER;

	my %expected = (
		'MR JOHN SMITH'          => { title_1 => 'Mr', given_name_1 => 'John', surname_1 => 'Smith' },
		'DR SARAH BEETLE'        => { title_1 => 'Dr', given_name_1 => 'Sarah', surname_1 => 'Beetle' },
		"JOHN O'LEARY"           => { given_name_1 => 'John', surname_1 => "O'Leary" },
		'MICHAEL JOHN JACOBS JR' => { given_name_1 => 'Michael', middle_name => 'John', surname_1 => 'Jacobs', suffix => 'Jr' },
	);
	for my $raw ( sort keys %expected ) {
		my $parser = $PARTNER->new();
		my $error  = $parser->parse( nc($raw) );
		is( $error, 0, "parses cleanly: $raw" );
		my %parts = $parser->components;
		for my $part ( sort keys %{ $expected{$raw} } ) {
			is( $parts{$part}, $expected{$raw}{$part}, "$raw: $part" );
		}
	}

	# Two parsers working side by side on cased names do not share state.
	my ( $first, $second ) = ( $PARTNER->new(), $PARTNER->new() );
	$first->parse( nc('MR JOHN SMITH') );
	$second->parse( nc('DR SARAH BEETLE') );
	my %one = $first->components;
	my %two = $second->components;
	is( $one{surname_1}, 'Smith', 'first parser keeps its own result' );
	is( $two{surname_1}, 'Beetle', 'second parser keeps its own result' );
};

done_testing();
