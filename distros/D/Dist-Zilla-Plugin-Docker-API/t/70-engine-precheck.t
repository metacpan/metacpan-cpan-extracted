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

my $RECORDER    = 'Dist::Zilla::Plugin::Docker::API::Client::Recorder';
my $UNREACHABLE = 'Dist::Zilla::Plugin::Docker::API::Client::Unreachable';

sub build_dist {
    my ($client_class, $plugin_config) = @_;
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
client_class = $client_class
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

subtest 'precheck asks the engine before anything is built' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    delete $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};

    my $tzil = build_dist($RECORDER);
    $tzil->build;

    my $rec = docker_plugin($tzil)->client;

    is(scalar @{ $rec->calls_of('engine_info') }, 1,
        'engine_info asked exactly once');

    my $first = $rec->calls->[0];
    is($first->{method}, 'engine_info',
        'engine_info is the very first call on the client, before build_image');

    is(scalar @{ $rec->calls_of('build_image') }, 1,
        'the build still happened');
};

subtest 'an unreachable engine aborts before a single image is built' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};
    delete $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};

    my $tzil = build_dist($UNREACHABLE);
    my $ok = eval { $tzil->build; 1 };
    my $err = $@;

    ok(!$ok, 'the build died instead of running into a doomed docker build');
    like($err, qr/DZIL_DOCKER_API_SKIP_PRECHECK/,
        'the error names the escape hatch');
    my $logged = join "\n", @{ $tzil->log_messages };
    like($logged, qr/DOCKER_HOST/,
        'the log names the knob that actually fixes it');
    like($logged, qr/podman\.socket/,
        'and spells out the podman recipe');

    my $rec = docker_plugin($tzil)->client;
    is(scalar @{ $rec->calls_of('build_image') }, 0,
        'build_image was never reached');
};

subtest 'DZIL_DOCKER_API_SKIP_PRECHECK skips the check entirely' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP_PRECHECK} = 1;

    # The unreachable client would kill the build if it were asked at all.
    my $tzil = build_dist($UNREACHABLE);
    ok(eval { $tzil->build; 1 },
        'the build survived an engine that would have failed the precheck')
        or diag('build died: ' . $@);

    my $rec = docker_plugin($tzil)->client;
    is(scalar @{ $rec->calls_of('engine_info') }, 0,
        'engine_info was never asked');
    is(scalar @{ $rec->calls_of('build_image') }, 1,
        'the build proceeded regardless');
};

done_testing;
