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

# The classic /build endpoint takes exactly one platform. 'platform' stays a
# repeatable key so the refusal comes from this plugin and not from
# Config::MVP, but a second value must not be silently dropped.

my $RECORDER = 'Dist::Zilla::Plugin::Docker::API::Client::Recorder';

sub build_dist {
    my ($plugin_config) = @_;
    my $tempdir  = tempdir(CLEANUP => 1);
    my $dist_dir = path($tempdir, 'dist');
    $dist_dir->mkpath;

    $dist_dir->child('dist.ini')->spew(<<"DIST");
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

subtest 'one platform is passed to the build' => sub {
    my $tzil = build_dist("platform = linux/arm64\n");
    $tzil->build;

    my ($build) = @{ docker_plugin($tzil)->client->calls_of('build_image') };
    is($build->{platform}, 'linux/arm64', 'the platform reaches build_image');
};

subtest 'two platforms are refused, not truncated' => sub {
    my $tzil = build_dist("platform = linux/amd64\nplatform = linux/arm64\n");

    ok(!eval { $tzil->build; 1 }, 'the build dies');
    like($@, qr{only one platform}i, 'the message says one platform is allowed');
    like($@, qr{linux/amd64.*linux/arm64}s, 'the message names the values given');

    is(scalar @{ docker_plugin($tzil)->client->calls_of('build_image') }, 0,
        'no image was built');
};

done_testing;
