use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $repo      = abs_path('.');
my $entry     = File::Spec->catfile( $repo, 'script', 'coverage-gate' );
my $checker   = File::Spec->catfile( $repo, 'script', 'check-all-metric-coverage' );
my $clean     = "File              stmt   bran   cond    sub  total\nTotal            100.0  100.0  100.0  100.0  100.0\n";
my $shortfall = "File              stmt   bran   cond    sub  total\nTotal            100.0   99.9  100.0  100.0   99.9\n";

# The scripted stand-in used for both cover and prove. It records the
# environment it observed before doing anything, which is how the one-
# environment guarantee is measured rather than assumed.
my $STUB_TEMPLATE = <<'PERL';
#!/usr/bin/env perl
use strict;
use warnings;

my $root = '__STUB_ROOT__';
my $name = '__STUB_NAME__';

open my $log, '>>', "$root/invocations.log" or die "stub cannot log: $!";
printf {$log} "%s\t%s\t%s\t%s\n",
    $name,
    defined $ENV{PERL5LIB} ? $ENV{PERL5LIB} : '(unset)',
    defined $ENV{DD_COVERAGE_GATE_PROBE} ? $ENV{DD_COVERAGE_GATE_PROBE} : '(unset)',
    join ' ', @ARGV;
close $log or die "stub cannot close its log: $!";

sub slurp {
    my ($path) = @_;
    open my $handle, '<', $path or die "stub cannot read $path: $!";
    my $body = do { local $/; <$handle> };
    close $handle or die "stub cannot close $path: $!";
    return $body;
}

if ( $name eq 'prove' ) {
    print "stub prove ran the suite\n";
    exit slurp("$root/prove.exit") + 0;
}

exit 0 if grep { $_ eq '-delete' } @ARGV;

print slurp("$root/report.out");
print STDERR slurp("$root/report.err");
exit slurp("$root/report.exit") + 0;
PERL

# Purpose: write a file in one call and fail loudly when it cannot be written.
# Input: an absolute path and the content to write.
# Output: nothing; dies on any failure.
sub write_file {
    my ( $path, $content ) = @_;
    open my $handle, '>', $path or die "cannot write $path: $!";
    print {$handle} $content;
    close $handle or die "cannot close $path: $!";
    return;
}

# Purpose: read a whole file, returning the empty string when it is absent.
# Input: an absolute path.
# Output: the file content as one string.
sub slurp_file {
    my ($path) = @_;
    return '' if !-e $path;
    open my $handle, '<', $path or die "cannot read $path: $!";
    my $body = do { local $/; <$handle> };
    close $handle or die "cannot close $path: $!";
    return $body;
}

# Purpose: build a throwaway PATH directory holding scripted cover and prove
#          stand-ins, so the whole chain can be exercised without spending a
#          real multi-minute Devel::Cover slot.
# Input: named overrides - report_out, report_err, report_exit, prove_exit.
# Output: a hash reference carrying the stub directory and its invocation log.
sub build_stub_path {
    my (%behaviour) = @_;

    my $dir = tempdir( CLEANUP => 1 );

    write_file( File::Spec->catfile( $dir, 'report.out' ),  defined $behaviour{report_out}  ? $behaviour{report_out}  : $clean );
    write_file( File::Spec->catfile( $dir, 'report.err' ),  defined $behaviour{report_err}  ? $behaviour{report_err}  : '' );
    write_file( File::Spec->catfile( $dir, 'report.exit' ), defined $behaviour{report_exit} ? $behaviour{report_exit} : 0 );
    write_file( File::Spec->catfile( $dir, 'prove.exit' ),  defined $behaviour{prove_exit}  ? $behaviour{prove_exit}  : 0 );

    for my $name (qw(cover prove)) {
        my $body = $STUB_TEMPLATE;
        $body =~ s/__STUB_ROOT__/$dir/g;
        $body =~ s/__STUB_NAME__/$name/g;
        my $path = File::Spec->catfile( $dir, $name );
        write_file( $path, $body );
        chmod 0755, $path or die "cannot make $path executable: $!";
    }

    return { dir => $dir, log => File::Spec->catfile( $dir, 'invocations.log' ) };
}

# Purpose: run the canonical coverage-gate entrypoint against a stub PATH.
# Input: the stub hash reference from build_stub_path, then the argument list.
# Output: the child exit status, its standard output, and its standard error.
sub run_entry {
    my ( $stub, @args ) = @_;

    # Every run gets a database of its own unless the caller named one. The gate
    # takes an exclusive lock on whatever database it is about to own, so a run
    # that defaulted to the repository's real cover_db would contend with any
    # genuine gate on this host - including the one running this very suite,
    # which holds that lock for its entire duration. These runs drive stubbed
    # commands and never touch a real database, so the private path costs
    # nothing and removes the conflict entirely.
    unshift @args, '--database', File::Spec->catdir( $stub->{dir}, 'cover_db' )
        if !grep { $_ eq '--database' } @args;

    my ( $stdout, $stderr, $status ) = capture {
        local $ENV{PATH}                   = $stub->{dir} . ':' . $ENV{PATH};
        local $ENV{DD_COVERAGE_GATE_PROBE} = 'one-environment';
        local $ENV{PERL5OPT};
        local $ENV{HARNESS_PERL_SWITCHES};
        delete $ENV{PERL5OPT};
        delete $ENV{HARNESS_PERL_SWITCHES};
        system( $^X, $entry, @args );
    };

    return ( $status >> 8, $stdout, $stderr );
}

# Purpose: read back every command the chain actually ran.
# Input: the stub hash reference.
# Output: a list of hash references with the observed name, library path,
#         marker variable, and argument string.
sub invocations {
    my ($stub) = @_;
    my @rows;
    for my $line ( grep { length } split /\n/, slurp_file( $stub->{log} ) ) {
        my ( $name, $library, $probe, $arguments ) = split /\t/, $line, 4;
        push @rows, { name => $name, library => $library, probe => $probe, arguments => defined $arguments ? $arguments : '' };
    }
    return @rows;
}

# Feature: one canonical entrypoint runs the whole coverage chain.
# Scenario: the entrypoint is a real, executable repository script.
# Given the repository, when the canonical coverage gate is looked for, then it
# exists beside the report checker it drives and is executable.
{
    ok( -f $entry,   'the canonical coverage-gate entrypoint exists under script/' );
    ok( -x $entry,   'the canonical coverage-gate entrypoint is executable' );
    ok( -f $checker, 'the report checker it drives is still present' );
}

# Scenario: the whole chain runs inside ONE environment.
# Given a scripted PATH, when the entrypoint runs the chain, then the delete,
# suite and report commands are all invoked and every one of them observed the
# same library path and the same marker variable - which is the property that
# makes a split-environment read impossible by construction.
{
    my $stub = build_stub_path();
    my ( $exit, $stdout, $stderr ) = run_entry($stub);

    is( $exit, 0, 'a clean four-metric report passes through the canonical entrypoint' );

    my @ran = invocations($stub);
    is( scalar @ran, 3, 'the entrypoint ran exactly three commands: delete, suite, report' );
    is_deeply( [ map { $_->{name} } @ran ], [qw(cover prove cover)], 'the chain ran delete, then the instrumented suite, then the report' );

    my %libraries = map { $_->{library} => 1 } @ran;
    is( scalar keys %libraries, 1, 'every command in the chain saw exactly one PERL5LIB value' );

    my %probes = map { $_->{probe} => 1 } @ran;
    is_deeply( [ keys %probes ], ['one-environment'], 'every command in the chain inherited the caller environment unchanged' );

    like( $stdout, qr/\Q100.0\E/, 'the entrypoint prints the coverage report it collected' );
    is( $stderr, '', 'a passing run emits no error output' );
}

# Scenario: the collected report is the four-metric lib/ report.
# Given a scripted PATH, when the chain runs, then the database is dropped
# first and the report requests every enforced metric restricted to lib/.
{
    my $stub = build_stub_path();
    run_entry($stub);

    my @ran    = invocations($stub);
    my $delete = $ran[0]{arguments};
    my $report = $ran[2]{arguments};

    like( $delete, qr/-delete/,            'the chain drops the previous coverage database first' );
    like( $report, qr/-report text/,       'the report step asks for the text report' );
    like( $report, qr/-select_re \^lib\//, 'the report step is restricted to lib/' );
    for my $metric (qw(statement branch condition subroutine)) {
        like( $report, qr/-coverage \Q$metric\E\b/, "the report step requests $metric coverage" );
    }
}

# Scenario: a serialization mismatch is named as an instrument failure.
# Given a report command that fails the way a mismatched reader fails, when the
# chain runs, then the entrypoint reports an instrument failure with its own
# exit status instead of a parse error or a coverage verdict.
{
    my $stub = build_stub_path(
        report_out  => '',
        report_err  => "Can't read database: File is not a perl storable at /usr/share/perl5/Storable.pm line 411.\n",
        report_exit => 2,
    );
    my ( $exit, $stdout, $stderr ) = run_entry($stub);

    is( $exit, 3, 'a serialization mismatch exits with the instrument-failure status' );
    like( $stderr, qr/INSTRUMENT FAILURE/,       'the operator is told the instrument failed, not the code' );
    like( $stderr, qr/Sereal/,                   'the instrument-failure verdict names the Sereal format' );
    like( $stderr, qr/Storable/,                 'the instrument-failure verdict names the Storable format' );
    like( $stderr, qr/Devel\/Cover\/DB\/IO\.pm/, 'the instrument-failure verdict names the reader module path' );
    like( $stderr, qr/not a corrupt database/i,  'the verdict tells the reader re-running will not help' );
    unlike( $stdout, qr/coverage gate: statement/, 'an instrument failure never reports a coverage figure' );
}

# Scenario: a genuine shortfall keeps its own status.
# Given a report whose branch total is below 100, when the chain runs, then the
# entrypoint fails as a coverage shortfall, distinctly from an instrument
# failure, and names the failing metric.
{
    my $stub = build_stub_path( report_out => $shortfall );
    my ( $exit, $stdout, $stderr ) = run_entry($stub);

    is( $exit, 1, 'a genuine below-100 result exits with the coverage-shortfall status' );
    like( $stderr, qr/below 100\.0: branch 99\.9/, 'the shortfall names the metric and the figure' );
}

# Scenario: a failing suite stops the chain before any coverage verdict.
# Given an instrumented suite that fails, when the chain runs, then the
# entrypoint stops, says which step failed, and reports no coverage figure.
{
    my $stub = build_stub_path( prove_exit => 1 );
    my ( $exit, $stdout, $stderr ) = run_entry($stub);

    isnt( $exit, 0, 'a failing instrumented suite fails the coverage gate' );
    isnt( $exit, 1, 'a failing suite is not reported as a coverage shortfall' );
    isnt( $exit, 3, 'a failing suite is not reported as an instrument failure' );
    like( $stderr, qr/instrumented suite/i, 'the failing step is named' );
    unlike( $stdout, qr/coverage gate: statement/, 'no coverage verdict is produced when the suite failed' );
    is( scalar invocations($stub), 2, 'the report step is never reached after a failing suite' );
}

# Scenario: a report that was never produced fails closed.
# Given a report command that emits nothing at all, when the chain runs, then
# the gate exits non-zero, because could-not-look must never read as clean.
{
    my $stub = build_stub_path( report_out => '', report_exit => 0 );
    my ( $exit, $stdout, $stderr ) = run_entry($stub);

    isnt( $exit, 0, 'an empty report fails closed rather than passing' );
    like( $stderr, qr/coverage gate:/, 'the empty report produces a gate diagnostic' );
    unlike( $stdout, qr/coverage gate: statement/, 'an empty report emits no success verdict' );
}

# Scenario: the chain is inspectable before a host-exclusive slot is spent.
# Given the dry-run flag, when the entrypoint is asked what it would do, then it
# prints one resolved environment and all three commands, and runs nothing.
{
    my $stub = build_stub_path();
    my ( $exit, $stdout, $stderr ) = run_entry( $stub, '--dry-run' );

    is( $exit, 0, 'a dry run succeeds' );
    like( $stdout, qr/cover_db/,                 'the dry run names the coverage database it would use' );
    like( $stdout, qr/prove -lr t\b/,            'the dry run shows the instrumented suite command' );
    like( $stdout, qr/-coverage subroutine/,     'the dry run shows the four-metric report command' );
    like( $stdout, qr/Devel\/Cover\/DB\/IO\.pm/, 'the dry run names the serializer module the chain resolved' );
    is( slurp_file( $stub->{log} ), '', 'a dry run executes none of the chain' );
}

# Scenario: an unusable instrument is reported before the suite slot is spent.
# Given a library path that shadows Devel::Cover::DB::IO with an unloadable
# copy, when the entrypoint runs, then it refuses up front rather than running
# a multi-minute suite whose result it could not read.
{
    my $shadow = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $shadow, 'Devel', 'Cover', 'DB' ) );
    write_file(
        File::Spec->catfile( $shadow, 'Devel', 'Cover', 'DB', 'IO.pm' ),
        "package Devel::Cover::DB::IO;\ndie \"shadowed instrument cannot load\\n\";\n1;\n"
    );

    my $stub = build_stub_path();
    my ( $stdout, $stderr, $status ) = capture {
        local $ENV{PATH}     = $stub->{dir} . ':' . $ENV{PATH};
        local $ENV{PERL5LIB} = $shadow . ( defined $ENV{PERL5LIB} ? ':' . $ENV{PERL5LIB} : '' );
        local $ENV{PERL5OPT};
        local $ENV{HARNESS_PERL_SWITCHES};
        delete $ENV{PERL5OPT};
        delete $ENV{HARNESS_PERL_SWITCHES};
        system( $^X, $entry );
    };

    is( $status >> 8, 2, 'an unloadable coverage instrument exits with the unusable status' );
    like( $stderr, qr/coverage gate:/, 'the unusable instrument produces a gate diagnostic' );
    is( slurp_file( $stub->{log} ), '', 'nothing in the chain runs when the instrument cannot load' );
}

# Scenario: an unknown option is refused rather than ignored.
# Given an argument the entrypoint does not understand, when it is invoked, then
# it prints usage and exits with the unusable status without running anything.
{
    my $stub = build_stub_path();
    my ( $exit, $stdout, $stderr ) = run_entry( $stub, '--no-such-option' );

    is( $exit, 2, 'an unknown option exits with the unusable status' );
    like( $stderr, qr/usage/i, 'an unknown option prints usage' );
    is( slurp_file( $stub->{log} ), '', 'an unknown option runs none of the chain' );
}

# Scenario: help is available without running the chain.
# Given the help flag, when the entrypoint is invoked, then it explains itself
# on standard output and succeeds.
{
    my $stub = build_stub_path();
    my ( $exit, $stdout, $stderr ) = run_entry( $stub, '--help' );

    is( $exit, 0, 'help succeeds' );
    like( $stdout, qr/coverage-gate/, 'help names the entrypoint' );
    is( slurp_file( $stub->{log} ), '', 'help runs none of the chain' );
}

done_testing;

__END__

=pod

=head1 NAME

t/148-coverage-gate-entrypoint.t - acceptance contract for the canonical
coverage-gate entrypoint

=head1 PURPOSE

An executable specification for C<script/coverage-gate>, the single command that
runs the whole four-metric coverage chain: dropping the coverage database,
running the instrumented suite, collecting the C<lib/> report, and passing that
report through the enforcing checker.

It proves the property the entrypoint exists to guarantee: that every command in
the chain runs inside one environment. The scenarios run the real entrypoint
against scripted C<cover> and C<prove> stand-ins placed on C<PATH>, then read
back what each stand-in actually observed, so the guarantee is measured rather
than asserted.

=head1 WHY IT EXISTS

The coverage gate used to be three separate commands typed one after another.
Each is its own process with its own C<@INC>, and C<Devel::Cover::DB::IO> picks
its on-disk serialization format at C<BEGIN> from whatever C<@INC> makes visible
- Sereal, then JSON, then Storable - without recording that choice beside the
data. On a host carrying two Devel::Cover installations with different
serializers available, omitting the library path from one command of the chain
makes the reader unable to parse what the writer had just produced. The failure
surfaces as C<File is not a perl storable>, which reads as a corrupt database
and invites a re-run that fails identically, spending another host-exclusive
suite slot each time. Two automated rounds paid that cost inside two hours.

=head1 WHEN TO USE

Run it when changing the coverage entrypoint, the report checker, the metric set
the gate enforces, or any workflow step that collects coverage.

=head1 HOW TO USE

Run it directly while iterating, then run the whole suite before integration.

=head1 WHAT USES IT

The Perl test suite, the repository coverage gate, and every continuous
integration workflow that collects coverage rely on this contract.

=head1 EXAMPLES

Example 1:

  prove -lv t/148-coverage-gate-entrypoint.t

Run the focused acceptance scenarios.

Example 2:

  perl script/coverage-gate --dry-run

Inspect the resolved environment and the three commands the gate would run,
without spending a host-exclusive suite slot.

Example 3:

  perl script/coverage-gate

Run the real gate: drop the database, run the instrumented suite, and enforce
100.0 on statement, branch, condition and subroutine coverage for C<lib/>.

=cut
