#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::SystemPackages();
use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Snapshot::Tree();

my $CLASS = Dist::Conformance::Check::SystemPackages::;

my $FINGERPRINT = '0123456789ABCDEF0123456789abcdef01234567';

my $SOURCE = <<"YAML";
    - name: jellyfin
      uri: https://repo.test.test/ubuntu
      suites: ['{codename}', stable]
      components: [main]
      key: https://repo.test.test/key.gpg
      fingerprint: $FINGERPRINT
YAML

my $EXAMPLE = <<"YAML";
x_system_packages:
  FooLib:
    deb:
      name: libfoo-devel
      ubuntu/24.04: libfoo-dev
      debian/13: ~
    rpm: libfoo-devel
  ffmpeg:
    deb:
      name: ffmpeg
      source: jellyfin
    test: ffmpeg -version
x_system_sources:
  deb:
$SOURCE
YAML

sub snapshot_of ($metamerge) {
    my $root = defined $metamerge ? Fixture::checkout( 'metamerge.yml' => $metamerge ) : Fixture::checkout();
    return Dist::Conformance::Snapshot::Directory->new( root => $root );
}

sub check_of ($metamerge) { return [ Fixture::make_check( $CLASS, {} )->check( snapshot_of($metamerge) ) ] }

# The errors of a metamerge.yml, or the empty string when it is valid.
sub refusal_of ($metamerge) {
    return eval { $CLASS->declared( snapshot_of($metamerge) ); q{} } // $@;
}

# The errors of x_system_packages with one dependency, Dep, whose mapping is the YAML $dependency.
sub dependency_refusal ($dependency) { return refusal_of("x_system_packages:\n  Dep:\n$dependency") }

# The errors of a deb package name, as the plain entry of a dependency.
sub deb_refusal ($name) { return dependency_refusal("    deb: '$name'\n") }

# The errors of $SOURCE, which a dependency names, with the line of $field replaced by $line, or removed when $line is undef.
sub source_refusal ( $field, $line ) {
    my $source = $field eq 'name' ? $SOURCE =~ s/name:\ jellyfin/$line/r : ( $SOURCE =~ s/^\ {6}\Q$field\E:[^\n]*\n//mr ) . ( defined $line ? "      $line\n" : q{} );
    return refusal_of("x_system_packages:\n  Dep:\n    deb: { name: dep, source: jellyfin }\nx_system_sources:\n  deb:\n$source");
}

subtest declared => sub {
    is(
        $CLASS->declared( snapshot_of($EXAMPLE) ),
        {
            packages => {
                FooLib => { deb => { name => 'libfoo-devel', 'ubuntu/24.04' => 'libfoo-dev', 'debian/13' => undef }, rpm => 'libfoo-devel' },
                ffmpeg => { deb => { name => 'ffmpeg', source => 'jellyfin' }, test => 'ffmpeg -version' },
            },
            sources => { deb => [ { name => 'jellyfin', uri => 'https://repo.test.test/ubuntu', suites => [ '{codename}', 'stable' ], components => ['main'], key => 'https://repo.test.test/key.gpg', fingerprint => $FINGERPRINT } ] },
        },
        'the dependencies and the sources, as written'
    );
    is( $CLASS->declared( snapshot_of(undef) ),                                         { packages => {}, sources => {} }, 'no metamerge.yml declares nothing' );
    is( $CLASS->declared( snapshot_of("resources:\n  homepage: https://test.test\n") ), { packages => {}, sources => {} }, 'and nor does one without the keys' );
    is( $CLASS->declared( snapshot_of("x_system_packages: {}\n") ),                     { packages => {}, sources => {} }, 'or with a key and nothing in it' );

    my $root = Fixture::checkout( 'metamerge.yml' => $EXAMPLE );
    is( $CLASS->declared("$root"), $CLASS->declared( snapshot_of($EXAMPLE) ), 'a directory is read as a checkout' );
    is( $CLASS->declared($root),   $CLASS->declared("$root"),                 'whether a string or a Mojo::File' );

    my %fetched;
    my $tree = Dist::Conformance::Snapshot::Tree->new(
        paths => { 'metamerge.yml' => Dist::Conformance::Snapshot::blob_sha($EXAMPLE), 'lib/Bogus.pm' => 'sha-of-bogus' },
        fetch => sub ($path) { $fetched{$path}++; return $EXAMPLE },
    );
    is( $CLASS->declared($tree), $CLASS->declared( snapshot_of($EXAMPLE) ), 'a remote tree is read like a checkout' );
    is( \%fetched,               { 'metamerge.yml' => 1 },                  'and only metamerge.yml is fetched' );

    like( dies { $CLASS->declared( snapshot_of("x_system_packages:\n  Dep: { deb: Bad }\n") ) }, qr{\Ametamerge[.]yml\ is\ not\ valid:\n\ \ /x_\w+/Dep/deb:}, 'an invalid declaration dies with its errors' );
    like( dies { $CLASS->declared( snapshot_of("- a\n") ) },                                     qr/\Ametamerge[.]yml\ does\ not\ hold\ a\ mapping/,          'and so does a file that is not a mapping' );
    like( dies { $CLASS->declared('/bogus/checkout') },                                          qr/is\ not\ a\ directory/,                                   'and a directory that is not there' );
};

subtest 'deb package names' => sub {
    is( deb_refusal($_), q{}, "$_ is a deb name" ) for qw{ffmpeg libmagic-dev g++ libstdc++6 python3.12 0ad xz};
    like( deb_refusal('x'),                          qr{/Dep/deb:}, 'one character is not' );
    like( deb_refusal('ffmpeg-'),                    qr{/Dep/deb:}, 'a name that ends in -, which apt reads as a removal, is refused' );
    like( deb_refusal('libMagic'),                   qr{/Dep/deb:}, 'and so is an uppercase letter' );
    like( deb_refusal('-ffmpeg'),                    qr{/Dep/deb:}, 'and a leading -' );
    like( deb_refusal('.ffmpeg'),                    qr{/Dep/deb:}, 'and a leading .' );
    like( deb_refusal('ffmpeg=7.0'),                 qr{/Dep/deb:}, 'and a version' );
    like( deb_refusal('ffmpeg vlc'),                 qr{/Dep/deb:}, 'and two names in one' );
    like( deb_refusal('ffmpeg/sid'),                 qr{/Dep/deb:}, 'and a release' );
    like( dependency_refusal("    deb: [ffmpeg]\n"), qr{/Dep/deb:}, 'an entry is not a list' );
};

subtest dependencies => sub {
    is( refusal_of("x_system_packages:\n  $_: { deb: dep }\n"), q{}, "$_ is the name of a dependency" ) for qw{Foo::Lib ffmpeg libfoo 0ad Foo-Bar_1.2+x};
    like( refusal_of("x_system_packages:\n  '-dep': { deb: dep }\n"),    qr{Properties\ not\ allowed:\ -dep},              'a dependency starts with a letter or a digit' );
    like( refusal_of("x_system_packages:\n  'foo lib': { deb: dep }\n"), qr{Properties\ not\ allowed:\ foo},               'and has no space' );
    like( refusal_of("x_system_packages:\n  'foo/lib': { deb: dep }\n"), qr{Properties\ not\ allowed:\ foo/lib},           'nor a /' );
    like( refusal_of("x_system_packages: [ffmpeg]\n"),                   qr{/x_system_packages:.*object},                  'the dependencies are a mapping' );
    like( refusal_of("x_system_packages:\n  Dep: deb\n"),                qr{/x_system_packages/Dep:.*object},              'and so is each one' );
    like( dependency_refusal("    test: dep --version\n"),               qr{:\n\ \ /x_\w+/Dep:\ names\ no\ packager\n\z},  'a dependency has a packager' );
    like( refusal_of("x_system_packages:\n  Dep: {}\n"),                 qr{/x_system_packages/Dep:\ names\ no\ packager}, 'and is not empty' );
    is( dependency_refusal("    rpm: perl-Moose\n"), q{}, 'another packager has the generic rule, until it has its own' );
    like( dependency_refusal("    rpm: perl-\n"),   qr{/Dep/rpm:},                       'which also refuses a trailing -' );
    like( dependency_refusal("    Deb: dep\n"),     qr{Properties\ not\ allowed:\ Deb},  'a packager is lowercase' );
    like( dependency_refusal("    9deb: dep\n"),    qr{Properties\ not\ allowed:\ 9deb}, 'and starts with a letter' );
    like( dependency_refusal("    deb-src: dep\n"), qr{Properties\ not\ allowed},        'and is only letters and digits' );
};

subtest tests => sub {
    is( dependency_refusal("    deb: dep\n    test: 'dep --version'\n"), q{}, 'a test is a command line' );
    like( dependency_refusal("    deb: dep\n    test: ''\n"),        qr{/Dep/test:}, 'an empty one is refused' );
    like( dependency_refusal("    deb: dep\n    test: '   '\n"),     qr{/Dep/test:}, 'and so is one of spaces' );
    like( dependency_refusal("    deb: dep\n    test: \"a\\nb\"\n"), qr{/Dep/test:}, 'and one of two lines, because the output is one per line' );
    like( dependency_refusal("    deb: dep\n    test: [a, b]\n"),    qr{/Dep/test:}, 'and a list' );
};

subtest entries => sub {
    is( dependency_refusal("    deb: { name: libssl3, ubuntu/24.04: libssl3t64, debian: libbar, debian/13: ~ }\n"), q{}, 'an entry can name a package by default, for a distro, or for a release, or none' );
    is( dependency_refusal("    deb: { ubuntu/24.04: libfoo-t64 }\n"),                                              q{}, 'and need not have a default' );
    like( dependency_refusal("    deb: {}\n"),                                                     qr{/Dep/deb:.*names\ no\ package}, 'a mapping without a key is refused' );
    like( dependency_refusal("    deb: { source: jellyfin }\nx_system_sources:\n  deb:\n$SOURCE"), qr{/Dep/deb:.*names\ no\ package}, 'and so is one with a source and no package' );
    my @lines = split /\n/, dependency_refusal("    deb: { Ubuntu: libfoo }\n");
    is( scalar( grep { /Properties\ not\ allowed/ } @lines ), 1, 'and each error of an entry of a packager with its own rule is reported once, not again under the generic rule' ) or diag join "\n", @lines;
    like( dependency_refusal("    deb: { Ubuntu: libfoo }\n"),                                                qr{/Dep/deb:.*Properties\ not\ allowed:\ Ubuntu},               'and a key that is not a distro' );
    like( dependency_refusal("    deb: { 'ubuntu/24 04': libfoo }\n"),                                        qr{/Dep/deb:.*Properties\ not\ allowed},                        'or a release' );
    like( dependency_refusal("    deb: { ubuntu/24.04/x: libfoo }\n"),                                        qr{/Dep/deb:.*Properties\ not\ allowed},                        'and a key has one / at most' );
    like( dependency_refusal("    deb: { name: libssl3, debian: libbar- }\n"),                                qr{/Dep/deb/debian:},                                           'each value has the name rule of the packager' );
    like( dependency_refusal("    deb: { name: x }\n"),                                                       qr{/Dep/deb/name:},                                             'name too' );
    like( dependency_refusal("    deb: { name: ~ }\n"),                                                       qr{/Dep/deb/name:},                                             'which is not null' );
    like( dependency_refusal("    deb: { debian: [libbar] }\n"),                                              qr{/Dep/deb/debian:},                                           'and a value is one name' );
    like( dependency_refusal("    rpm: { fedora: perl- }\n"),                                                 qr{/Dep/rpm/fedora:},                                           'another packager has its rule in a mapping too' );
    like( dependency_refusal("    deb: { name: dep, source: Jellyfin }\n"),                                   qr{/Dep/deb/source:},                                           'a source is the name of a source' );
    like( dependency_refusal("    deb: { name: dep, source: jellyfin }\n"),                                   qr{/Dep/deb/source:\ jellyfin\ is\ not\ a\ \w+\ in\ x_\w+/deb}, 'and one that is not declared is refused' );
    like( dependency_refusal("    rpm: { name: dep, source: jellyfin }\nx_system_sources:\n  deb:\n$SOURCE"), qr{/Dep/rpm/source:\ jellyfin\ is\ not\ a\ \w+\ in\ x_\w+/rpm}, 'and so is a source of another packager' );
};

subtest sources => sub {
    is( source_refusal( 'x',             undef ),                                         q{}, 'an apt archive with a fingerprint, which a dependency names' );
    is( source_refusal( 'distros',       'distros: [ubuntu/24.04, debian]' ),             q{}, 'with the distros that it is for' );
    is( source_refusal( 'pin',           "pin: { priority: 600, packages: 'ffmpeg*' }" ), q{}, 'and a pin' );
    is( source_refusal( 'architectures', 'architectures: [amd64, arm64]' ),               q{}, 'and its architectures' );
    like( source_refusal( 'fingerprint', undef ),                                                              qr{/x_system_sources/deb/0/fingerprint:\ Missing}, 'a source without a fingerprint is refused' );
    like( source_refusal( 'fingerprint', 'fingerprint: 0123456789ABCDEF0123456789ABCDEF0123456' ),             qr{/deb/0/fingerprint:},                           'and one of 39 digits' );
    like( source_refusal( 'fingerprint', 'fingerprint: 0123456789ABCDEF0123456789ABCDEF012345678' ),           qr{/deb/0/fingerprint:},                           'and of 41' );
    like( source_refusal( 'fingerprint', 'fingerprint: 0123456789ABCDEF0123456789ABCDEF0123456G' ),            qr{/deb/0/fingerprint:},                           'and one that is not hex' );
    like( source_refusal( 'fingerprint', "fingerprint: '0123 4567 89AB CDEF 0123 4567 89AB CDEF 0123 4567'" ), qr{/deb/0/fingerprint:},                           'and one with spaces' );
    like( source_refusal( 'key',         undef ),                                                              qr{/deb/0/key:\ Missing},                          'the key is required' );
    like( source_refusal( 'key',         'key: ftp://repo.test.test/key.gpg' ),                                qr{/deb/0/key:},                                   'and is http or https' );
    like( source_refusal( 'uri',         'uri: repo.test.test' ),                                              qr{/deb/0/uri:},                                   'and so is the archive' );
    like( source_refusal( 'name',        'name: Jellyfin' ),                                                   qr{/deb/0/name:},                                  'a name is lowercase' );
    like( source_refusal( 'suites',      'suites: []' ),                                                       qr{/deb/0/suites:},                                'one suite at least' );
    like( source_refusal( 'suites',      "suites: ['{release}']" ),                                            qr{/deb/0/suites/0:},                              '{codename} is the only placeholder' );
    like( source_refusal( 'suites',      "suites: ['{codename', stable]" ),                                    qr{/deb/0/suites/0:},                              'and is whole' );
    like( source_refusal( 'distros',     'distros: [Ubuntu]' ),                                                qr{/deb/0/distros/0:},                             'a distro has the form of a key of an entry' );
    like( source_refusal( 'distros',     'distros: []' ),                                                      qr{/deb/0/distros:},                               'and the list is not empty' );
    like( source_refusal( 'pin',         'pin: { packages: ffmpeg }' ),                                        qr{/deb/0/pin/priority:\ Missing},                 'a pin has a priority' );
    like( source_refusal( 'pin',         'pin: { priority: high }' ),                                          qr{/deb/0/pin/priority:},                          'which is an integer' );
    like( source_refusal( 'x',           'mirror: x' ),                                                        qr{Properties\ not\ allowed:\ mirror},             'and no other key is allowed' );

    my $dep = "x_system_packages:\n  Dep:\n    deb: { name: dep, source: jellyfin }\n";
    like( refusal_of("${dep}x_system_sources:\n  rpm:\n$SOURCE"),                                    qr{/x_system_sources:.*Properties\ not\ allowed:\ rpm},        'only deb takes sources' );
    like( refusal_of("${dep}x_system_sources:\n  deb: []\n"),                                        qr{/x_system_sources/deb:},                                    'an empty list of sources is refused' );
    like( refusal_of("${dep}x_system_sources: [jellyfin]\n"),                                        qr{/x_system_sources:.*object},                                'and the sources are a mapping of packagers' );
    like( refusal_of("${dep}x_system_sources:\n  deb:\n$SOURCE$SOURCE"),                             qr{/deb/1/name:\ jellyfin\ is\ the\ name\ of\ another},        'two sources do not have one name' );
    like( refusal_of("x_system_packages:\n  Dep: { deb: dep }\nx_system_sources:\n  deb:\n$SOURCE"), qr{/x_system_sources/deb/0:\ no\ dependency\ names\ jellyfin}, 'and a source that no dependency names is refused' );
    like( refusal_of("x_system_sources:\n  deb:\n$SOURCE"),                                          qr{/x_system_sources/deb/0:\ no\ dependency},                  'even without dependencies' );
};

subtest resolve => sub {
    my $sources = {
        deb => [
            { name => 'every',  uri => 'https://every.test.test',  suites => [qw/{codename} {codename}-updates stable/], components => ['main'], key => 'https://every.test.test/k', fingerprint => 'F' x 40 },
            { name => 'noble',  uri => 'https://noble.test.test',  suites => ['noble'],  components => ['main'], key => 'https://noble.test.test/k',  fingerprint => 'E' x 40, distros => ['ubuntu/24.04'] },
            { name => 'debian', uri => 'https://debian.test.test', suites => ['stable'], components => ['main'], key => 'https://debian.test.test/k', fingerprint => 'D' x 40, distros => ['debian'] },
        ],
    };
    my $declared = {
        packages => {
            Ssl     => { deb => { name           => 'libssl3', 'ubuntu/24.04' => 'libssl3t64', ubuntu => 'libssl3u', 'debian/13' => undef }, test => 'openssl version' },
            Foo     => { deb => { 'ubuntu/24.04' => 'libfoo-t64' } },
            Bar     => { deb => { debian => 'libbar', name => 'libbar0' }, rpm => 'bar' },
            ffmpeg  => { deb => 'ffmpeg', test => 'ffmpeg -version' },
            Ffmpeg2 => { deb => 'ffmpeg' },
            Jelly   => { deb => { name => 'jellyfin', source => 'every' } },
            Media   => { deb => { name => 'media',    source => 'every' } },
            Noble   => { deb => { name => 'noblepkg', source => 'noble' } },
            Deb     => { deb => { name => 'debpkg',   source => 'debian' } },
            RpmOnly => { rpm => 'only' },
        },
        sources => $sources,
    };
    my %shown = map { $_ => 1 } qw{Ffmpeg2 Noble Ssl};
    my sub on (%host) { return $CLASS->resolve( $declared, packager => 'deb', %host ) }

    my $noble = on( distro => 'ubuntu', release => '24.04', codename => 'noble' );
    is( $noble->{packages},   [qw{libbar0 ffmpeg libfoo-t64 jellyfin media noblepkg libssl3t64}], 'on the release, the most specific key wins, in the order of the names, without duplicates' );
    is( $noble->{unresolved}, [qw{Deb RpmOnly}],                                                  'a dependency without an entry for the packager, or whose source is not for the host, is unresolved' );
    is( $noble->{programs},   [ 'openssl version', 'ffmpeg -version' ],                           'the programs are the tests, in the order of the names, where uppercase sorts first' );
    is(
        [ grep { $shown{ $_->{name} } } @{ $noble->{needs} } ],
        [
            { name => 'Ffmpeg2', package => 'ffmpeg',     source => undef,   test => undef },
            { name => 'Noble',   package => 'noblepkg',   source => 'noble', test => undef },
            { name => 'Ssl',     package => 'libssl3t64', source => undef,   test => 'openssl version' },
        ],
        'each need has its package, source and test'
    );
    is( [ map { $_->{name} } @{ $noble->{needs} } ],   [qw{Bar Ffmpeg2 Foo Jelly Media Noble Ssl ffmpeg}],                                                                                                              'the needs are in the sorted order of the names' );
    is( [ map { $_->{name} } @{ $noble->{sources} } ], [qw{every noble}],                                                                                                                                               'only the sources that a package comes from, once each' );
    is( $noble->{sources}[0]{suites},                  [qw{noble noble-updates stable}],                                                                                                                                '{codename} is filled in each suite' );
    is( $noble->{sources}[1],                          { name => 'noble', uri => 'https://noble.test.test', suites => ['noble'], components => ['main'], key => 'https://noble.test.test/k', fingerprint => 'E' x 40 }, 'and a resolved source has no distros' );

    my $jammy = on( distro => 'ubuntu', release => '22.04', codename => 'jammy' );
    is( [ grep { /ssl/ } @{ $jammy->{packages} } ], ['libssl3u'],                'on another release of the distro, the distro wins' );
    is( $jammy->{unresolved},                       [qw{Deb Foo Noble RpmOnly}], 'and an entry only for the release is unresolved' );

    my $trixie = on( distro => 'debian', release => '13', codename => 'trixie' );
    is( $trixie->{packages},                                                           [qw{libbar debpkg ffmpeg jellyfin media}],                                           'a null on the release needs no package, and the distro wins over name' );
    is( [ grep { $_->{name} eq 'Ssl' } @{ $trixie->{needs} } ],                        [ { name => 'Ssl', package => undef, source => undef, test => 'openssl version' } ], 'but the dependency is still needed, with its test' );
    is( [ map { $_->{name} } @{ $trixie->{sources} } ],                                [qw{debian every}],                                                                  'a distro in distros matches each of its releases' );
    is( on( distro => 'debian', release => '12', codename => 'bookworm' )->{packages}, [qw{libbar debpkg ffmpeg jellyfin media libssl3}],                                   'and on another release, name is the default' );

    my $nowhere = on( codename => 'noble' );
    is( $nowhere->{packages},   [qw{libbar0 ffmpeg jellyfin media libssl3}], 'without a distro, only name matches' );
    is( $nowhere->{unresolved}, [qw{Deb Foo Noble RpmOnly}],                 'and a source with distros applies to no host' );

    is( $CLASS->resolve( $declared, packager => 'rpm' )->{packages},   [qw{bar only}],                                     'another packager has its own packages' );
    is( $CLASS->resolve( $declared, packager => 'rpm' )->{unresolved}, [qw{Deb Ffmpeg2 Foo Jelly Media Noble Ssl ffmpeg}], 'and the dependencies without one are unresolved' );
    is( $declared->{sources}{deb}[0]{suites}[0], '{codename}', 'the declaration is not changed' );

    like( dies { on( distro => 'ubuntu', release => '24.04' ) },     qr/\AThe\ source\ every\ needs\ the\ codename/, 'a source that needs a codename dies without one' );
    like( dies { $CLASS->resolve( $declared, distro => 'debian' ) }, qr/needs\ a\ packager/,                         'a packager is required' );
    is( $CLASS->resolve( { packages => {}, sources => {} }, packager => 'deb' ), { needs => [], packages => [], sources => [], programs => [], unresolved => [] }, 'a declaration of nothing resolves to nothing' );
};

subtest os_release => sub {
    my $text = <<'OS';
# a comment
PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME='Ubuntu'
ID=ubuntu
VERSION_ID="24.04"
VERSION_CODENAME=noble
QUOTED="say \"hi\" \\ \$HOME"

  ID_LIKE=debian
not a variable
OS
    my $vars = Dist::Conformance::Check::SystemPackages::os_release($text);
    is( [ @{$vars}{qw{ID VERSION_ID VERSION_CODENAME}} ],          [qw{ubuntu 24.04 noble}],                                             'bare and double-quoted values' );
    is( $vars->{NAME},                                             'Ubuntu',                                                             'single-quoted' );
    is( $vars->{PRETTY_NAME},                                      'Ubuntu 24.04.1 LTS',                                                 'with spaces' );
    is( $vars->{QUOTED},                                           'say "hi" \\ $HOME',                                                  'and with escapes in double quotes' );
    is( $vars->{ID_LIKE},                                          'debian',                                                             'leading space is allowed' );
    is( [ sort keys %$vars ],                                      [qw{ID ID_LIKE NAME PRETTY_NAME QUOTED VERSION_CODENAME VERSION_ID}], 'and comments, blank lines and other lines are skipped' );
    is( Dist::Conformance::Check::SystemPackages::os_release(q{}), {},                                                                   'an empty file has no variables' );
};

subtest check => sub {
    is( check_of(undef),                                        [ 'pass', 'there is no metamerge.yml, so it needs no system packages' ],      'no file passes' );
    is( check_of("name: x\n"),                                  [ 'pass', 'metamerge.yml declares no system packages' ],                      'and so does a file without the keys' );
    is( check_of($EXAMPLE),                                     [ 'pass', 'metamerge.yml declares 2 dependencies and 1 deb source' ],         'a valid declaration passes, and says what it holds' );
    is( check_of("x_system_packages:\n  Dep: { deb: dep }\n"),  [ 'pass', 'metamerge.yml declares 1 dependency' ],                            'one dependency' );
    is( check_of("x_system_packages:\n  Dep: { deb: dep- }\n"), [ 'fail', match(qr{\Ametamerge[.]yml\ is\ not\ valid:\ /x_\w+/Dep/deb:\ }) ], 'an invalid one fails, with the error on one line' );
    is( check_of("x_system_sources:\n  deb:\n$SOURCE"),         [ 'fail', match(qr{no\ dependency\ names\ jellyfin}) ],                       'and so does one that only the cross-check refuses' );
    is( check_of("x_system_packages: [\n"),                     [ 'fail', match(qr/\Ametamerge[.]yml\ does\ not\ parse\ as\ YAML/) ],         'and a file that does not parse' );
    like( dies { Fixture::make_check( $CLASS, { file => 'x.yml' } ) }, qr/Properties\ not\ allowed:\ file/, 'the check takes no configuration of its own' );
};

subtest update => sub {
    my $root   = Fixture::checkout( 'metamerge.yml' => "x_system_packages:\n  Dep: { deb: x }\n" );
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( Fixture::make_check( $CLASS, {} ), $root );
    is( Fixture::tree_of($root), $before,                                                             'nothing is written' );
    is( $update->manual,         [ match(qr/Dep\/deb.*:\ SystemPackages\ has\ no\ automatic\ fix/) ], 'and a person is told what is wrong' );
};

done_testing;
