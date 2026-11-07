#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Capture::Tiny();
use Cwd();
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

my $METAMERGE = <<'YAML';
x_system_packages:
  Ssl:
    deb:
      name: libssl3
      ubuntu/24.04: libssl3t64
      debian/13: ~
    rpm: openssl-libs
    test: openssl version
  ffmpeg:
    deb:
      name: ffmpeg
      source: jellyfin
    rpm: ffmpeg-free
    test: ffmpeg -version
x_system_sources:
  deb:
    - name: jellyfin
      uri: https://repo.test.test/ubuntu
      suites: ['{codename}']
      components: [main]
      key: https://repo.test.test/key.gpg
      fingerprint: 0123456789ABCDEF0123456789ABCDEF01234567
      distros: [ubuntu, debian]
YAML

subtest 'packages' => sub {
    my $root = Fixture::checkout(
        'metamerge.yml' => $METAMERGE,
        'noble'         => qq{ID=ubuntu\nVERSION_ID="24.04"\nVERSION_CODENAME='noble'\n},
        'bookworm'      => "ID=debian\nVERSION_ID=\"12\"\nVERSION_CODENAME=bookworm\n",
        'fedora'        => "ID=fedora\nVERSION_ID=41\n",
    );
    my @noble  = ( '--os-release', $root->child('noble') );
    my @debian = ( '--os-release', $root->child('bookworm') );
    is( run_main( 'packages', @noble, $root ),                                                                                { out => "libssl3t64\nffmpeg\n", err => q{}, status => 0 }, 'the deb packages of the host of the os-release, one per line, and nothing else' );
    is( run_main( 'packages', @debian, $root )->{out},                                                                        "libssl3\nffmpeg\n",                                        'and of another host' );
    is( run_main( qw{packages --distro debian --release 13 --codename trixie --os-release /bogus/os-release}, $root )->{out}, "ffmpeg\n",                                                 'the host can be given, and then no os-release is read, and a null needs no package' );
    is( run_main( 'packages', @noble, qw{--distro debian}, $root )->{out},                                                    "libssl3\nffmpeg\n",                                        'an option replaces one value of the os-release' );
    is( run_main( qw{packages --packager rpm --os-release}, $root->child('fedora'), $root )->{out},                           "openssl-libs\nffmpeg-free\n",                              'or those of another packager' );
    is( run_main( qw{packages --programs}, @noble, $root )->{out},                                                            "openssl version\nffmpeg -version\n",                       'the tests, with --programs' );

    my $sources = run_main( qw{packages --sources}, @noble, $root );
    is( $sources->{status}, 0, '--sources exits 0' );
    is(
        [ map { Dist::Conformance::Schema::parse_json( $_, 'a line' ) } split /\n/, $sources->{out} ],
        [ { name => 'jellyfin', uri => 'https://repo.test.test/ubuntu', suites => ['noble'], components => ['main'], key => 'https://repo.test.test/key.gpg', fingerprint => '0123456789ABCDEF0123456789ABCDEF01234567' } ],
        'and prints each source that a package comes from as a line of JSON, resolved'
    );
    is(
        [ map { Dist::Conformance::Schema::parse_json( $_, 'a line' ) } split /\n/,        run_main( qw{packages --needs --distro debian --release 13 --codename trixie}, $root )->{out} ],
        [ { name => 'Ssl', package => undef, source => undef, test => 'openssl version' }, { name => 'ffmpeg', package => 'ffmpeg', source => 'jellyfin', test => 'ffmpeg -version' } ],
        '--needs prints each dependency as a line of JSON'
    );
    is( run_main( qw{packages --sources --programs}, @noble, $root )->{status}, 2, 'only one of --programs, --sources and --needs' );
    is( run_main( qw{packages --sources --needs},    @noble, $root )->{status}, 2, 'at once' );

    my $cwd = Cwd::getcwd();
    chdir $root or die "Cannot chdir to $root: $!";
    my $here = run_main( 'packages', @noble );
    chdir $cwd or die "Cannot chdir to $cwd: $!";
    is( $here->{out}, "libssl3t64\nffmpeg\n", 'the directory defaults to the current one' );

    is( run_main( qw{packages --os-release /bogus/os-release}, Fixture::checkout() ), { out => q{}, err => q{}, status => 0 }, 'no declaration prints nothing, reads no os-release, and exits 0' );
    is( run_main( qw{packages --programs}, @noble, Fixture::checkout( 'metamerge.yml' => "x_system_packages: { Xz: { deb: xz-utils } }\n" ) ), { out => q{}, err => q{}, status => 0 }, 'and no tests print none' );

    my $unresolved = run_main( qw{packages --packager pkg}, @noble, $root );
    is( $unresolved, { out => q{}, err => "conformance: The dependency Ssl has no package for pkg\nThe dependency ffmpeg has no package for pkg\n", status => 2 }, 'a dependency without a package for the host exits 2, and prints nothing' );
    is( run_main( qw{packages --programs --packager pkg},   @noble,                 $root )->{status}, 2,                                                             'whatever it prints' );
    is( run_main( qw{packages --packager deb --os-release}, $root->child('fedora'), $root )->{err},    "conformance: The dependency ffmpeg has no package for deb\n", 'and so does one whose source is not for the host' );

    my $no_os = run_main( qw{packages --os-release /bogus/os-release}, $root );
    is( $no_os->{status}, 2,   'an os-release that cannot be read exits 2' );
    is( $no_os->{out},    q{}, 'and prints no package' );
    like( $no_os->{err}, qr{\Aconformance:\ Cannot\ read\ /bogus/os-release:}, 'and says so' );

    my $no_codename = run_main( qw{packages --distro ubuntu --release 24.04 --os-release}, Fixture::checkout( 'os-release' => "ID=ubuntu\n" )->child('os-release'), $root );
    is( $no_codename->{status}, 2, 'a source that needs a codename that the host does not have exits 2' );
    like( $no_codename->{err}, qr{needs\ the\ codename}, 'and says so' );

    my $bad = run_main( 'packages', @noble, Fixture::checkout( 'metamerge.yml' => "x_system_packages:\n  Dep: { deb: ffmpeg- }\n" ) );
    is( $bad->{status}, 2,   'an invalid declaration exits 2' );
    is( $bad->{out},    q{}, 'and prints no package' );
    like( $bad->{err}, qr{\Aconformance:\ \S+\ is\ not\ valid:\n\ \ /x_\w+/Dep/deb:}, 'and says why on standard error' );

    my $packager = run_main( qw{packages --packager ../deb}, @noble, $root );
    is( $packager->{status}, 2, 'a packager that is not a name exits 2' );
    like( $packager->{err}, qr{\Aconformance:\ [.][.]/deb\ is\ not\ the\ name}, 'and says so' );
    is( run_main( 'packages', @noble, $root, $root )->{status}, 2, 'and so does a second directory' );
    is( run_main( qw{packages --bogus}, $root )->{status}, 2, 'and an unknown option' );
};

subtest 'help' => sub {
    my $help = run_main('help');
    is( $help->{status}, 0, 'help exits 0' );
    like( $help->{out}, qr/conformance\ check/, 'and prints the usage' );
    like( $help->{out}, qr/--dry-run/,          'with the options' );
    is( run_main()->{status}, 0, 'and is the default' );
};

done_testing;
