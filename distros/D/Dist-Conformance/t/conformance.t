#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Capture::Tiny();
use FindBin();
use FindBin::libs;

use Fixture();
use Dist::Conformance::Schema();

my $SCRIPT    = "$FindBin::Bin/../script/conformance";
my $STANDARDS = "$FindBin::Bin/data/standards";

ok( ( require $SCRIPT ), 'the modulino loads without running' );

sub run_main (@arguments) {
    my ( $out, $err, $status ) = Capture::Tiny::capture( sub { Dist::Conformance::Program::main(@arguments) } );
    return { out => $out, err => $err, status => $status };
}

sub repo ( $flavor, %files ) {
    return Fixture::checkout( '.conformance.yml' => "flavor: $flavor\nsource: { directory: $STANDARDS }\n", %files );
}

subtest 'check' => sub {
    my $failing = run_main( qw{check --root}, repo('github-ci') );
    is( $failing->{status}, 1, 'a failure exits 1' );
    like( $failing->{out}, qr/\AFlavor\ github-ci\ from\ \S+standards\n/,     'names the flavor and the source' );
    like( $failing->{out}, qr/^fail\ \ Workflows\ \ missing:\ \S+ci[.]yml$/m, 'a line for each check' );
    like( $failing->{out}, qr/^1\ fail\n\z/m,                                 'and the count' );

    my $passing = run_main( qw{check --root}, repo( 'github-ci', '.github/workflows/ci.yml' => q{} ) );
    is( $passing->{status}, 0, 'no failure exits 0' );

    my $info = run_main( qw{check --root}, repo('troglodyne-5.040') );
    like( $info->{out}, qr/^info\ \ DistFiles\ +no\ dist[.]ini$/m, 'info is reported' );
};

subtest 'check --json' => sub {
    my $run    = run_main( qw{check --json --root}, repo('github-ci') );
    my $report = Dist::Conformance::Schema::parse_json( $run->{out}, 'the output' );
    is( $run->{status}, 1, 'exits as the text does' );
    is(
        $report,
        { command => 'check', flavor => 'github-ci', source => $STANDARDS, failed => T(), results => [ { check => 'Workflows', status => 'fail', detail => 'missing: .github/workflows/ci.yml' } ] },
        'the results as JSON'
    );
};

subtest 'update' => sub {
    my $root   = repo('github-ci');
    my $before = Fixture::tree_of($root);
    my $dry    = run_main( qw{update --dry-run --root}, $root );
    is( $dry->{status}, 0, 'a dry run exits 0' );
    like( $dry->{out}, qr/^would\ create\ +\S+ci[.]yml\ \ \(Workflows\)$/m, 'and says what it would change' );
    is( Fixture::tree_of($root), $before, 'without changing anything' );

    my $real = run_main( qw{update --root}, $root );
    like( $real->{out}, qr/^create\ +[.]github\/workflows\/ci[.]yml/m, 'an update says what it changed' );
    ok( -e $root->child(qw{.github workflows ci.yml}), 'and changes it' );
    like( run_main( qw{update --root},           $root )->{out}, qr/^Nothing\ changed[.]$/m,       'and then has nothing to do' );
    like( run_main( qw{update --dry-run --root}, $root )->{out}, qr/^Nothing\ would\ change[.]$/m, 'nor would' );

    my $manual = run_main( qw{update --root}, repo('troglodyne') );
    like( $manual->{out}, qr/^by\ hand\ +ClaudeMd:\ CLAUDE[.]md\ is\ missing/m, 'what is left for a person is printed' );

    my $json = Dist::Conformance::Schema::parse_json( run_main( qw{update --json --dry-run --root}, repo('github-ci') )->{out}, 'the output' );
    is( $json->{dry_run}, T(),                                                                                                                   'the JSON says it was a dry run' );
    is( $json->{results}, [ { check => 'Workflows', changes => [ { action => 'create', path => '.github/workflows/ci.yml' } ], manual => [] } ], 'and has the results' );
};

subtest '--standards and --offline' => sub {
    my $root = Fixture::checkout( '.conformance.yml' => "flavor: github-ci\nsource: { git: /bogus/standards.git }\n" );
    my $run  = run_main( qw{check --root}, $root, '--standards', $STANDARDS );
    is( $run->{status}, 1, 'the standards replace the source' );
    like( $run->{out}, qr/\AFlavor\ github-ci\ from\ \S+standards\n/, 'and are named' );
    my $offline = run_main( qw{check --root}, $root, qw{--offline --cache}, Fixture::checkout() );
    is( $offline->{status}, 2, 'offline without a cache cannot run' );
    like( $offline->{err}, qr/\Aconformance:\ Offline,\ and\ there\ is\ no\ cached\ copy/, 'and says why' );
};

subtest 'errors' => sub {
    my $none = run_main( qw{check --root}, Fixture::checkout() );
    is( $none->{status}, 2,                                                                              'a checkout without .conformance.yml cannot run' );
    is( $none->{err},    "conformance: The repository has no .conformance.yml, so it names no flavor\n", 'and says why, without a line number' );
    my $bad = run_main( qw{check --root}, Fixture::checkout( '.conformance.yml' => "flavor: x\n" ) );
    like( $bad->{err}, qr/\Aconformance:\ [.]conformance[.]yml\ is\ not\ valid:/, 'an invalid file is named' );
    like( $bad->{err}, qr/^\ \ \/source:\ /m,                                     'with each error under it' );
    is( run_main('nonsense')->{status},        2, 'an unknown command exits 2' );
    is( run_main(qw{check --bogus})->{status}, 2, 'and so does an unknown option' );
    is( run_main(qw{check extra})->{status},   2, 'and an extra argument' );
    like( run_main('nonsense')->{err}, qr/Usage:/, 'with the usage on standard error' );
};

subtest 'help' => sub {
    my $help = run_main('help');
    is( $help->{status}, 0, 'help exits 0' );
    like( $help->{out}, qr/conformance\ check/, 'and prints the usage' );
    like( $help->{out}, qr/--dry-run/,          'with the options' );
    is( run_main()->{status}, 0, 'and is the default' );
};

done_testing;
