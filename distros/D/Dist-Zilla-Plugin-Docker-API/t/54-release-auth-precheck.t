use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

# These tests drive the real build path. A DZIL_DOCKER_API_SKIP=1 left in
# the shell (it is set when building dists with an image) must not turn it off.
BEGIN { delete $ENV{DZIL_DOCKER_API_SKIP} }

BEGIN {
    plan skip_all => "Dist::Zilla::Tester not installed"
        unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };
}

use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);

my $RECORDER = 'Dist::Zilla::Plugin::Docker::API::Client::Recorder';

sub build_dist {
    my ($plugin_config) = @_;
    $plugin_config //= '';
    my $tempdir  = tempdir(CLEANUP => 1);
    my $dist_dir = path($tempdir, 'dist');
    $dist_dir->mkpath;

    my $dist_ini = <<"DIST";
name = Test-Dist
version = 1.234
author = Test <test\@test.de>
license = Perl_5
copyright_holder = Test

[GatherDir]

[Docker::API]
image = ghcr.io/example/my-app
client_class = $RECORDER
$plugin_config
DIST

    $dist_dir->child('dist.ini')->spew($dist_ini);
    $dist_dir->child('lib', 'Foo.pm')->parent->mkpath;
    $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n# ABSTRACT: stub\n1;\n");
    $dist_dir->child('Dockerfile')->spew("FROM scratch\n");

    return Dist::Zilla::Tester->from_config(
        { dist_root => "$dist_dir" },
        { tempdir_root => $tempdir,
          chrome => Dist::Zilla::Chrome::Term->new },
    );
}

sub docker_plugin {
    my $tzil = shift;
    my ($plugin) = grep { $_->plugin_name =~ /Docker::API/ } @{ $tzil->plugins };
    return $plugin;
}

# DZIL_RELEASING is what Dist::Zilla::Dist::Builder::release sets before it
# rebuilds the archive, so this is how before_build tells a release from a
# plain build. release_push defaults to 1, so a plain [Docker::API] block
# with DZIL_RELEASING set is enough to arm the precheck.
subtest 'fires on a release build (DZIL_RELEASING + release_push)' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    delete $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    local $ENV{DZIL_RELEASING} = 1;

    my $tzil = build_dist('');
    $tzil->build;

    my $rec = docker_plugin($tzil)->client;
    my $calls = $rec->calls_of('verify_auth_for_image_ref');
    is(scalar @$calls, 1, 'the auth precheck ran exactly once');
    is($calls->[0]{image_ref}, 'ghcr.io/example/my-app',
        'it was asked about the configured image');

    is(scalar @{ $rec->calls_of('engine_info') }, 1,
        'the engine precheck still ran too');
    is(scalar @{ $rec->calls_of('build_image') }, 1,
        'and the build still happened');
};

# A plain `dzil build` never sets DZIL_RELEASING. No release is happening,
# so no registry credentials should be needed at all.
subtest 'does not fire on a plain dzil build' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    delete $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    local $ENV{DZIL_RELEASING};
    delete $ENV{DZIL_RELEASING};

    my $tzil = build_dist('');
    $tzil->build;

    my $rec = docker_plugin($tzil)->client;
    is(scalar @{ $rec->calls_of('verify_auth_for_image_ref') }, 0,
        'the auth precheck was never asked');
    is(scalar @{ $rec->calls_of('build_image') }, 1,
        'the build still happened');
};

# A release that never pushes needs no registry credentials either.
subtest 'does not fire when release_push = 0' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    delete $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    local $ENV{DZIL_RELEASING} = 1;

    my $tzil = build_dist("release_push = 0");
    $tzil->build;

    my $rec = docker_plugin($tzil)->client;
    is(scalar @{ $rec->calls_of('verify_auth_for_image_ref') }, 0,
        'the auth precheck was never asked');
};

# A rejected credential is fatal, and it has to stop the run before
# after_build ever gets to build_image -- otherwise a release could still
# leave behind a built, half-tagged image after refusing to push it.
subtest 'a rejected credential is fatal, before a single image is built' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    delete $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    local $ENV{DZIL_RELEASING} = 1;

    my $tzil = build_dist('');
    my $rec  = docker_plugin($tzil)->client; # forces the lazy client, no calls yet
    $rec->verify_auth_error('401 unauthorized: incorrect username or password');

    my $ok = eval { $tzil->build; 1 };
    my $err = $@;

    ok(!$ok, 'the build died instead of proceeding with a bad credential');
    like($err, qr/registry credential/i, 'error names what failed');
    like($err, qr/ghcr\.io\/example\/my-app/, 'error names the image');
    like($err, qr/401 unauthorized: incorrect username or password/,
        'the registry\'s own error text rides along verbatim');
    like($err, qr/DZIL_DOCKER_API_SKIP_PRECHECK/,
        'the error names the escape hatch');

    is(scalar @{ $rec->calls_of('build_image') }, 0,
        'build_image was never reached');
};

# No credential at all is not an error -- an anonymous push to a public
# registry is a legal thing to attempt. The release must run through.
subtest 'no resolvable credential runs the release through anonymously' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    delete $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    local $ENV{DZIL_RELEASING} = 1;

    my $tzil = build_dist('');
    my $rec  = docker_plugin($tzil)->client;
    $rec->verify_auth_result(undef); # explicit: this is already the default

    my $ok = eval { $tzil->build; 1 };
    ok($ok, 'the build did not die') or diag("build died: $@");

    is(scalar @{ $rec->calls_of('verify_auth_for_image_ref') }, 1,
        'the precheck was still asked');
    is(scalar @{ $rec->calls_of('build_image') }, 1,
        'and the build proceeded');

    my $logged = join "\n", @{ $tzil->log_messages };
    like($logged, qr/no registry credentials found/i,
        'the anonymous case is noted in the log');
};

# DZIL_DOCKER_API_SKIP_PRECHECK=1 skips *both* prechecks. Prove it against a
# credential that would otherwise be fatal, so a no-op skip couldn't pass by
# accident.
subtest 'DZIL_DOCKER_API_SKIP_PRECHECK=1 skips the engine and the auth check' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK} = 1;
    local $ENV{DZIL_RELEASING} = 1;

    my $tzil = build_dist('');
    my $rec  = docker_plugin($tzil)->client;
    $rec->verify_auth_error('this must never be evaluated');

    my $ok = eval { $tzil->build; 1 };
    ok($ok, 'the build did not die even though the credential would have failed')
        or diag("build died: $@");

    is(scalar @{ $rec->calls_of('engine_info') }, 0,
        'engine_info was never asked');
    is(scalar @{ $rec->calls_of('verify_auth_for_image_ref') }, 0,
        'verify_auth_for_image_ref was never asked');
    is(scalar @{ $rec->calls_of('build_image') }, 1,
        'the build proceeded regardless');
};

done_testing;
