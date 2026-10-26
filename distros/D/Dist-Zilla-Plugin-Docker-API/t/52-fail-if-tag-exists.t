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

# fail_if_tag_exists = 1, remote_tag_exists answers "yes" -> release must die
# with the "already exists" message before a single tag or push happens.
subtest 'remote_tag_exists true kills the release before tag/push' => sub {
    my $tzil = build_dist("fail_if_tag_exists = 1");
    $tzil->build;
    my $p   = docker_plugin($tzil);
    my $rec = $p->client;
    $rec->reset_calls;
    $rec->remote_tag_exists_result(1);

    my $ok = eval { $p->release('Test-Dist-1.234.tar.gz'); 1 };
    my $err = $@;

    ok(!$ok, 'release died');
    like($err, qr/already exists on remote registry/i,
        'error names the reason');
    like($err, qr/ghcr\.io\/example\/my-app:latest/,
        'error names the offending reference');

    is(scalar @{ $rec->calls_of('remote_tag_exists') }, 1,
        'checked exactly the one tag that already existed, stopped there');
    is(scalar @{ $rec->calls_of('tag_image') }, 0,
        'nothing was tagged');
    is(scalar @{ $rec->calls_of('push_image') }, 0,
        'nothing was pushed');
};

# remote_tag_exists cannot answer (no /distribution route on this engine,
# e.g. rootless Podman) -> that is fatal, not a silent "does not exist". The
# engine's own error text must survive into the message, and nothing may be
# tagged or pushed either.
subtest 'remote_tag_exists croaking kills the release, engine text included' => sub {
    my $tzil = build_dist("fail_if_tag_exists = 1");
    $tzil->build;
    my $p   = docker_plugin($tzil);
    my $rec = $p->client;
    $rec->reset_calls;
    $rec->remote_tag_exists_error('no /distribution route on this engine');

    my $ok = eval { $p->release('Test-Dist-1.234.tar.gz'); 1 };
    my $err = $@;

    ok(!$ok, 'release died');
    like($err, qr/cannot answer whether/i,
        'error says the engine could not answer the question, not "does not exist"');
    like($err, qr/no \/distribution route on this engine/,
        'the engine\'s own error text rides along verbatim');
    like($err, qr/fail_if_tag_exists\s*=\s*0/,
        'error names the escape hatch');

    is(scalar @{ $rec->calls_of('remote_tag_exists') }, 1,
        'stopped at the first tag that could not be answered');
    is(scalar @{ $rec->calls_of('tag_image') }, 0,
        'nothing was tagged');
    is(scalar @{ $rec->calls_of('push_image') }, 0,
        'nothing was pushed');
};

# remote_tag_exists answers "no" for every tag -> release proceeds normally.
subtest 'remote_tag_exists false lets the release proceed' => sub {
    my $tzil = build_dist("fail_if_tag_exists = 1");
    $tzil->build;
    my $p   = docker_plugin($tzil);
    my $rec = $p->client;
    $rec->reset_calls;
    $rec->remote_tag_exists_result(0);

    my $ok = eval { $p->release('Test-Dist-1.234.tar.gz'); 1 };
    ok($ok, 'release did not die') or diag("release died: $@");

    is(scalar @{ $rec->calls_of('remote_tag_exists') }, 3,
        'every configured tag was checked (none exists)');
    is(scalar @{ $rec->calls_of('tag_image') }, 2,
        'tagging proceeded (source self-tag skipped)');
    is(scalar @{ $rec->calls_of('push_image') }, 3,
        'pushing proceeded');
};

# fail_if_tag_exists = 0 is the default: remote_tag_exists must not even be
# called, no matter what it would answer.
subtest 'fail_if_tag_exists = 0 (default) never calls remote_tag_exists' => sub {
    my $tzil = build_dist('');
    $tzil->build;
    my $p   = docker_plugin($tzil);
    my $rec = $p->client;
    $rec->reset_calls;

    # Would kill the release immediately if it were ever consulted.
    $rec->remote_tag_exists_error('should never be evaluated');

    is($p->fail_if_tag_exists, 0, 'fail_if_tag_exists really defaults to 0');

    my $ok = eval { $p->release('Test-Dist-1.234.tar.gz'); 1 };
    ok($ok, 'release did not die') or diag("release died: $@");

    is(scalar @{ $rec->calls_of('remote_tag_exists') }, 0,
        'remote_tag_exists was never called');
    is(scalar @{ $rec->calls_of('tag_image') }, 2,
        'the release still ran, just without the check');
};

done_testing;
