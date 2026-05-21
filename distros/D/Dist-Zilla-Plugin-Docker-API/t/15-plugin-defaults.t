use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "Dist::Zilla::Tester not installed"
        unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };
}

use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);

sub build_dist {
    my ($plugin_config) = @_;
    my $tempdir  = tempdir(CLEANUP => 1);
    my $dist_dir = path($tempdir, 'dist');
    $dist_dir->mkpath;

    my $dist_ini = <<"DIST";
name = Test-Dist
author = Test <test\@test.de>
license = Perl_5
copyright_holder = Test

[GatherDir]

[Docker::API]
image = ghcr.io/example/my-app
$plugin_config
DIST

    $dist_dir->child('dist.ini')->spew($dist_ini);
    $dist_dir->child('lib', 'Foo.pm')->parent->mkpath;
    $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n1;\n");

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

subtest 'default attribute values' => sub {
    my $tzil = build_dist('');
    my $p    = docker_plugin($tzil);

    is($p->image,        'ghcr.io/example/my-app', 'image set');
    is($p->repository,   'ghcr.io/example/my-app', 'repository alias mirrors image');
    is($p->dockerfile,   'Dockerfile',             'default dockerfile');
    is_deeply($p->tag,         ['latest', '%V', '%v'], 'default tag list');
    is_deeply($p->build_arg,   [], 'no build_args by default');
    is_deeply($p->label,       [], 'no labels by default');
    is_deeply($p->platform,    [], 'no platforms by default');
    is($p->build_load,           1, 'build_load default on');
    is($p->release_push,         1, 'release_push default on');
    is($p->release_load,         0, 'release_load default off');
    is($p->release_enabled,      1, 'release_enabled default on');
    is($p->pull,                 0, 'pull default off');
    is($p->no_cache,             0, 'no_cache default off');
    is($p->rm,                   1, 'rm default on');
    is($p->force_rm,             1, 'force_rm default on');
    is($p->target,              '', 'no target by default');
    is($p->network_mode,        '', 'no network_mode by default');
    is($p->fail_if_tag_exists,   0, 'fail_if_tag_exists default off');
    is($p->skip_latest_on_trial, 1, 'skip_latest_on_trial default on');
};

subtest 'attribute overrides via dist.ini' => sub {
    my $tzil = build_dist(<<'CFG');
file = Dockerfile.multi
build_arg = DIST_NAME=%n
label = org.opencontainers.image.title=%n
platform = linux/amd64
build_load = 0
release_push = 1
pull = 1
no_cache = 1
_target = build
_network_mode = host
fail_if_tag_exists = 1
CFG

    my $p = docker_plugin($tzil);

    is($p->dockerfile,         'Dockerfile.multi');
    is_deeply($p->build_arg,   ['DIST_NAME=%n']);
    is_deeply($p->label,       ['org.opencontainers.image.title=%n']);
    is_deeply($p->platform,    ['linux/amd64']);
    is($p->build_load,         0);
    is($p->release_push,       1);
    is($p->pull,               1);
    is($p->no_cache,           1);
    is($p->target,             'build');
    is($p->network_mode,       'host');
    is($p->fail_if_tag_exists, 1);
};

done_testing;
