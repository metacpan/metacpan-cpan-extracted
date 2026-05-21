use strict;
use warnings;
use Test::More;
use Test::Warnings ':all';

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
image = test/image
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

subtest 'default tag list' => sub {
    my $tzil = build_dist('');
    my $p = docker_plugin($tzil);
    is_deeply($p->tag, ['latest', '%V', '%v'], 'default tag list is latest + %V + %v');
};

subtest 'explicit tag wins' => sub {
    my $tzil = build_dist("tag = foo\ntag = bar");
    my $p = docker_plugin($tzil);
    is_deeply($p->tag, ['foo', 'bar'], 'explicit tag list used');
};

subtest 'legacy build_tag funnels into tag with warning' => sub {
    my @warnings;
    my $tzil;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $tzil = build_dist("build_tag = legacy-build");
    }
    my $p = docker_plugin($tzil);
    is_deeply($p->tag, ['legacy-build'], 'build_tag funneled into tag');
    ok( (grep { /deprecated/i } @warnings), 'deprecation warning emitted' );
};

subtest 'legacy release_tag funnels into tag' => sub {
    my $tzil;
    {
        local $SIG{__WARN__} = sub { };
        $tzil = build_dist("release_tag = %v");
    }
    my $p = docker_plugin($tzil);
    is_deeply($p->tag, ['%v'], 'release_tag funneled into tag');
};

subtest 'build_tag + release_tag merge' => sub {
    my $tzil;
    {
        local $SIG{__WARN__} = sub { };
        $tzil = build_dist("build_tag = latest\nrelease_tag = %v");
    }
    my $p = docker_plugin($tzil);
    is_deeply($p->tag, ['latest', '%v'], 'both legacy attrs merged');
};

subtest 'explicit tag overrides legacy values' => sub {
    my @warnings;
    my $tzil;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $tzil = build_dist("tag = canonical\nbuild_tag = ignored");
    }
    my $p = docker_plugin($tzil);
    is_deeply($p->tag, ['canonical'], 'explicit tag wins over legacy');
    ok( (grep { /ignoring deprecated/i } @warnings), 'override warning emitted' );
};

done_testing;
