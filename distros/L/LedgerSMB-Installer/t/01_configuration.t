#!perl

use v5.20;
use experimental qw(signatures);
use Cwd qw( getcwd );
use HTTP::Tiny;
use JSON::PP;
use Getopt::Long qw(GetOptionsFromArray);

use Test2::V0;
use Test2::Mock;

use LedgerSMB::Installer::Configuration;

sub new_config(@args) {
    return LedgerSMB::Installer::Configuration->new(@args);
}

my $c;

####  Test configuration default values

$c = new_config();
ok( (defined $c->assume_yes and not $c->assume_yes), q{Assume 'no' by default});
ok( (defined $c->installpath and $c->installpath eq 'ledgersmb'),
    q{Default install path = './ledgersmb'});
ok( (defined $c->loglevel and $c->loglevel eq 'info'), q{Default log level = 'info'});
ok( (defined $c->locallib and $c->locallib eq 'local'), q{Default local::lib = './local'});
ok( (defined $c->verify_sig and $c->verify_sig), q{Verify tarball signatures by default});

#### Test download URL expansions
$c = new_config();
ok lives {
    $c->version( '1.12.0' );
    my $url = $c->dependency_url( 'debian', 'bookworm' );
    is( $url,
        'https://download.ledgersmb.org/f/dependencies/debian/bookworm.json',
        q{Dependency download URL expanded correctly});
}, q{Dependency download URL expansion runs without exceptions};

#### Test package cleanup markings
$c = new_config();
ok lives {
    $c->mark_pkgs_for_cleanup( [ qw(a b c) ] );
    $c->mark_pkgs_for_cleanup( [ qw(a d e) ] );
    is( [ $c->pkgs_for_cleanup ],
        [ qw(a b c a d e) ],
        q{Cleanup marking is cumulative} );
}, q{Cleanup marking runs without exceptions};

#### Test path normalization
###### Default settings
$c = new_config();
ok lives {
    $c->normalize_paths;
    ok( $c->installpath,
        File::Spec->catdir( getcwd(), 'ledgersmb' ),
        q{Default installpath expansion} );
    ok( $c->locallib,
        File::Spec->catdir( getcwd(), 'local' ),
        q{Default local::lib expansion} );
}, q{Default path normalization runs without exceptions};


##### Absolute paths don't get normalized
my $root_install = File::Spec->catdir( File::Spec->rootdir, 'ledgersmb' );
my $root_locallib = File::Spec->catdir( File::Spec->rootdir, 'local' );
$c = new_config( installpath => $root_install, locallib => $root_locallib );
ok lives {
    $c->normalize_paths;
    ok( $c->installpath, $root_install,
        q{Absolute installpath normalization} );
    ok( $c->locallib, $root_locallib,
        q{Absolute local::lib normalization} );
}, q{Absolute path normalization runs without exceptions};


#### Test precomputed deps retrieval
my $get_result;
my $json = JSON::PP->new->utf8;
sub _http_tiny_get_override($self, $url) {
    return $get_result;
}
my $http_mock = Test2::Mock->new(
    class => 'HTTP::Tiny',
    override => [
        get => \&_http_tiny_get_override
    ],
    );

$get_result = {
    status => 200,
    success => !!1,
    content => $json->encode({ packages => [ qw( a b c ) ],
                               modules => [ qw( d e f ) ],
                               schema_version => "1" }),
};

ok lives {
    my @computed = $c->retrieve_precomputed_deps( 'debian', 'bookworm' );
    is( \@computed,
        [ [ qw(a b c) ], [ qw( d e f ) ] ],
        q{Retrieval of existing precomputed dependencies} );
}, q{Precomputed dependency retrieval runs without exceptions};


$get_result = {
    status => 599,
    success => !!0,
    content => 'Unable to resolve domain name',
};

like(
    dies {
        $c->retrieve_precomputed_deps( 'debian', 'bookworm' );
    },
    qr{Error trying to retrieve precomputed dependencies: Unable to resolve domain name},
    q{Retrieval while failing network dies});

$get_result = {
    status => 404,
    success => !!0,
    reason => 'Not Found',
    content => '<html><body><h1>Not Found</h1></body></html>',
};

# undo built-in caching by creatign a new configuration object
$c = new_config();
ok lives {
    my @computed = $c->retrieve_precomputed_deps( 'debian', 'sarge' );
    is( \@computed,
        [ undef, undef ],
        q{Nonexisting precomputed dependencies return undef} );
}, q{Precomputed dependency retrieval runs without exceptions};


#### Test parsing of options

# no options
$c = new_config();
ok lives {
    GetOptionsFromArray(
        [],
        $c->option_callbacks(
            [ 'yes|y!', 'system-packages!', 'prepare-env!', 'target=s',
              'local-lib=s', 'log-level=s', 'verify-sig!' ])
        );
}, q{};

# all options
$c = new_config();
ok lives {
    GetOptionsFromArray(
        [ qw(--yes -y --system-packages --no-system-packages --prepare-env
             --no-prepare-env --target /srv/ledgersmb --local-lib cpan-libs
             --log-level debug --verify-sig --no-verify-sig) ],
        $c->option_callbacks(
            [ 'yes|y!', 'system-packages!', 'prepare-env!', 'target=s',
              'local-lib=s', 'log-level=s', 'verify-sig!' ])
        );
}, q{};


done_testing;
