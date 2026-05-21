use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/lib";

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

subtest 'after_build hits client->build_image with resolved tags' => sub {
    my $tzil = build_dist('');
    $tzil->build;

    my $p = docker_plugin($tzil);
    my $rec = $p->client;
    isa_ok($rec, $RECORDER, 'client_class was honored via dynamic require');

    my $builds = $rec->calls_of('build_image');
    is(scalar @$builds, 1, 'build_image called exactly once');

    my $b = $builds->[0];
    is_deeply(
        $b->{tags},
        [
            'ghcr.io/example/my-app:latest',
            'ghcr.io/example/my-app:1',
            'ghcr.io/example/my-app:1.234',
        ],
        'default tag list expands and prefixes image',
    );
    is($b->{dockerfile}, 'Dockerfile', 'dockerfile passed through');
    is($b->{pull},  0, 'pull default false');
    is($b->{rm},    1, 'rm default true');
    is($b->{forcerm}, 1, 'forcerm default true');
};

subtest 'release tags and pushes existing built image' => sub {
    my $tzil = build_dist('');
    $tzil->build;
    my $p   = docker_plugin($tzil);
    my $rec = $p->client;
    $rec->reset_calls;

    $p->release('Test-Dist-1.234.tar.gz');

    my $tags = $rec->calls_of('tag_image');
    is(scalar @$tags, 2, 'tag_image called twice (source tag is skipped — no self-retag)');
    is($tags->[0]{source}, 'ghcr.io/example/my-app:latest', 'source tag');
    is($tags->[0]{target}, 'ghcr.io/example/my-app:1',      'first target (major)');
    is($tags->[1]{target}, 'ghcr.io/example/my-app:1.234',  'second target (full version)');

    my $pushes = $rec->calls_of('push_image');
    is(scalar @$pushes, 3, 'push_image called once per tag');
    is($pushes->[0]{image_ref}, 'ghcr.io/example/my-app:latest', 'pushed latest');
    is($pushes->[1]{image_ref}, 'ghcr.io/example/my-app:1',      'pushed major version');
    is($pushes->[2]{image_ref}, 'ghcr.io/example/my-app:1.234',  'pushed full version');
};

subtest 'release_push = 0 tags but does not push' => sub {
    my $tzil = build_dist("release_push = 0");
    $tzil->build;
    my $p   = docker_plugin($tzil);
    my $rec = $p->client;
    $rec->reset_calls;

    $p->release('Test-Dist-1.234.tar.gz');

    is(scalar @{ $rec->calls_of('tag_image') },  2, 'still tagged (source self-tag skipped)');
    is(scalar @{ $rec->calls_of('push_image') }, 0, 'not pushed');
};

subtest 'release_enabled = 0 short-circuits before client work' => sub {
    my $tzil = build_dist("release_enabled = 0");
    $tzil->build;
    my $p   = docker_plugin($tzil);
    my $rec = $p->client;
    $rec->reset_calls;

    $p->release('Test-Dist-1.234.tar.gz');

    is(scalar @{ $rec->calls }, 0, 'no client calls when release disabled');
};

done_testing;
