use strict;
use warnings;
use Test::More;
use Test::Warnings qw(:all);

BEGIN {
    plan skip_all => "Dist::Zilla::Tester not installed"
        unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };
}

use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);

# The one-to-one deprecated spellings (file, push, repository) used to be
# declared as lazy attributes reading *from* the canonical attribute. Setting
# them in dist.ini therefore changed nothing at all. These tests pin down that
# they now actually take effect, and that the canonical key still wins when
# both are given.

sub build_dist {
    my ($plugin_config) = @_;
    my $tempdir  = tempdir(CLEANUP => 1);
    my $dist_dir = path($tempdir, 'dist');
    $dist_dir->mkpath;

    $dist_dir->child('dist.ini')->spew(<<"DIST");
name = Test-Dist
author = Test <test\@test.de>
license = Perl_5
copyright_holder = Test

[GatherDir]

[Docker::API]
$plugin_config
DIST

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

subtest 'each deprecated key reaches its canonical attribute' => sub {
    my @case = (
        # deprecated key/value      canonical reader   expected
        [ 'file = Dockerfile.web',  'dockerfile', 'Dockerfile.web' ],
        [ 'push = 0',               'release_push', 0 ],
    );

    for my $case (@case) {
        my ($cfg, $reader, $want) = @$case;
        my ($warning) = warnings {
            my $p = docker_plugin(build_dist("image = ghcr.io/example/app\n$cfg"));
            is($p->$reader, $want, "'$cfg' sets $reader");
        };
        like($warning, qr/is deprecated; use '\Q$reader\E' instead/,
            "'$cfg' warns and names the canonical key");
    }
};

subtest 'repository alone satisfies the required image' => sub {
    my ($warning) = warnings {
        my $p = docker_plugin(build_dist('repository = ghcr.io/example/legacy'));
        is($p->image, 'ghcr.io/example/legacy', 'repository funnels into image');
        is($p->repository, 'ghcr.io/example/legacy', 'reader still mirrors it');
    };
    like($warning, qr/'repository' is deprecated; use 'image' instead/,
        'repository warns');
};

subtest 'the canonical key wins when both are given' => sub {
    my @warning = warnings {
        my $p = docker_plugin(build_dist(<<'CFG'));
image = ghcr.io/example/app
dockerfile = Dockerfile.canonical
file = Dockerfile.deprecated
CFG
        is($p->dockerfile, 'Dockerfile.canonical',
            'dockerfile wins over file');
    };
    ok(scalar(grep { /'file' is deprecated and 'dockerfile' is set explicitly/ } @warning),
        'the collision is reported');
};

subtest 'deprecated readers still mirror the canonical attributes' => sub {
    my $p = docker_plugin(build_dist('image = ghcr.io/example/app'));
    is($p->repository, 'ghcr.io/example/app', 'repository mirrors image');
    is($p->push,  $p->release_push, 'push mirrors release_push');
    is($p->file,  $p->dockerfile,   'file mirrors dockerfile');
};

subtest 'removed keys are warned about and discarded' => sub {
    for my $key (qw(phase load build_load release_load)) {
        my @warning = warnings {
            my $p = docker_plugin(build_dist("image = ghcr.io/example/app\n$key = 0"));
            ok($p, "'$key' does not stop the plugin from loading");
            ok(!$p->can($key), "'$key' is no longer an attribute");
        };
        ok(scalar(grep { /'\Q$key\E' is no longer supported and has no effect/ } @warning),
            "'$key' warns that it is no longer supported");
    }
};

done_testing;
