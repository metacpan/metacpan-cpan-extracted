#!/usr/bin/env perl
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

subtest 'DZIL_DOCKER_API_SKIP=1 builds the dist without touching the client' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP} = 1;

    my $tzil = build_dist($RECORDER);
    $tzil->build;

    my $rec = docker_plugin($tzil)->client;
    is(scalar @{ $rec->calls }, 0, 'no client call at all - no precheck, no build');

    my $logged = join "\n", @{ $tzil->log_messages };
    like($logged, qr/DZIL_DOCKER_API_SKIP/,
        'the skip is loud and names its own switch');
};

subtest 'DZIL_DOCKER_API_SKIP=1 needs no reachable engine' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP} = 1;

    my $tzil = build_dist($UNREACHABLE);
    ok(eval { $tzil->build; 1 },
        'the build survived an engine that would fail every contact')
        or diag('build died: ' . $@);
};

subtest 'DZIL_DOCKER_API_SKIP=0 keeps the normal build path' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP} = 0;

    my $tzil = build_dist($RECORDER);
    $tzil->build;

    my $rec = docker_plugin($tzil)->client;
    is(scalar @{ $rec->calls_of('build_image') }, 1,
        'a false value does not skip');
};

subtest 'release refuses to run with DZIL_DOCKER_API_SKIP set' => sub {
    local $ENV{DZIL_DOCKER_API_SKIP};
    delete $ENV{DZIL_DOCKER_API_SKIP};

    my $tzil = build_dist($RECORDER);
    $tzil->build;

    local $ENV{DZIL_DOCKER_API_SKIP} = 1;
    my $p = docker_plugin($tzil);
    my $ok = eval { $p->release('Test-Dist-1.234.tar.gz'); 1 };
    my $err = $@;

    ok(!$ok, 'release died instead of releasing without an image');
    like($err, qr/DZIL_DOCKER_API_SKIP/,
        'the refusal names the switch that caused it');
};

done_testing;
