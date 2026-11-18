#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use JSON::PP ();

plan skip_all => "Dist::Zilla::Tester not available"
  unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };

# The binary* keys of [@Author::GETTY], the [@Author::GETTY::Binary / name]
# subsections and the x_binaries key they write into META.json. Every dist
# declaring a binary runs with DZIL_BINARY_SKIP=1, so no pp is ever needed.
# No network and no real git remote: a GitHub remote is fabricated in a
# git-init'ed tempdir, and the dist.ini additionally pins no_github = 0 /
# no_github_release = 0 where the release plugin must be present.

my @ALL_PLATFORMS = qw(linux-x86_64 linux-arm64 macos-arm64 macos-x86_64 windows-x86_64);
my $BINARY_CLASS  = 'Dist::Zilla::Plugin::Author::GETTY::Binary';
my $RELEASE_CLASS = 'Dist::Zilla::Plugin::Author::GETTY::GitHubRelease';

# Builds (or only configures) a dist around $bundle_ini, the part of dist.ini
# from [@Author::GETTY] on. %o: scripts (relative paths to create under the
# dist root), remote (url written to .git/config, default a GitHub one; undef
# = git repository without remote), build (default 1).
# The tempdir is chdir'ed into while the dist is configured and built, so the
# cwd-dependent remote detection of the bundle measures the fabricated repo,
# and chdir'ed back afterwards.
sub build_dist {
  my ($bundle_ini, %o) = @_;
  my $tempdir  = tempdir(CLEANUP => 1);
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->mkpath;
  $dist_dir->child('dist.ini')->spew(<<"CONF");
name = Test-Dist
author = Test <test\@test.de>
license = Perl_5
copyright_holder = Test
copyright_year = 2026

$bundle_ini
CONF
  $dist_dir->child('Changes')->spew("Revision history for Test-Dist\n\n{{\$NEXT}}\n\n  - initial\n");
  $dist_dir->child('lib')->mkpath;
  $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n# ABSTRACT: t\n1;\n");
  require Software::License::Perl_5;
  $dist_dir->child("LICENSE")->spew(
    Software::License::Perl_5->new({ holder => "Test", year => 2026 })->license);
  for my $s (@{ $o{scripts} || [] }) {
    $dist_dir->child($s)->parent->mkpath;
    $dist_dir->child($s)->spew("#!/usr/bin/env perl\n# PODNAME: tool\n# ABSTRACT: t\nprint 1;\n");
  }

  system('git', 'init', '-q', "$dist_dir") == 0 or die "git init failed";
  my $url = exists $o{remote} ? $o{remote} : 'git@github.com:getty/test-dist.git';
  if (defined $url) {
    open my $fh, '>>', "$dist_dir/.git/config" or die "open: $!";
    print $fh "[remote \"origin\"]\n\turl = $url\n\tfetch = +refs/heads/*:refs/remotes/origin/*\n";
    close $fh;
  }
  system('git', '-C', "$dist_dir", 'add', '-A') == 0 or die "git add failed";

  my $cwd = getcwd();
  chdir "$dist_dir" or die "chdir $dist_dir: $!";
  my ($tzil, $err);
  {
    local $ENV{DZIL_BINARY_SKIP} = 1;
    local $@;
    eval {
      $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => "$dist_dir" },
        { tempdir_root => $tempdir, chrome => Dist::Zilla::Chrome::Term->new },
      );
      $tzil->build if $o{build} // 1;
      1;
    } or $err = $@;
  }
  chdir $cwd or die "chdir back: $!";
  return ($tzil, $err);
}

# The x_binaries hash of the built META.json, or undef when absent.
sub x_binaries {
  my ($tzil) = @_;
  return undef unless eval { $tzil->slurp_file("build/META.json"); 1 };
  my $meta = JSON::PP->new->decode($tzil->slurp_file('build/META.json'));
  return $meta->{x_binaries};
}

# A bundle section that keeps the GitHub release plugin in.
my $BUNDLE = "[\@Author::GETTY]\nno_github = 0\nno_github_release = 0\n";

# simple_form
{
  my ($tzil, $err) = build_dist("$BUNDLE" . "binary = foo\n", scripts => ['bin/foo']);
  is $err, undef, 'simple_form: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil);
  ok $x, 'simple_form: META.json has x_binaries' or $x = {};
  is $x->{binaries}{foo}{script}, 'bin/foo', 'simple_form: script defaults to bin/<name>';
  is_deeply $x->{platforms}, \@ALL_PLATFORMS, 'simple_form: all five platforms, in order';
  is_deeply $x->{binaries}{foo}{modules}, [], 'simple_form: modules is present and empty';
  is_deeply $x->{binaries}{foo}{require}, [], 'simple_form: require is present and empty';
  ok !exists $x->{binaries}{foo}{$_}, "simple_form: $_ absent when unset"
    for qw(pp_args verify smoke);
  ok !exists $x->{prepare}, 'simple_form: prepare absent when unset';
  my @bins = $tzil ? grep { $_->isa($BINARY_CLASS) } @{ $tzil->plugins } : ();
  is scalar(@bins), 1, 'simple_form: one Binary plugin';
}

# two_binaries_share_defaults
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary = foo\nbinary = bar\nbinary_modules = A B\nbinary_smoke = s.sh\n",
    scripts => ['bin/foo', 'bin/bar']);
  is $err, undef, 'two_binaries_share_defaults: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply $x->{binaries}{$_}{modules}, [qw(A B)],
    "two_binaries_share_defaults: $_ gets modules A B" for qw(foo bar);
  is $x->{binaries}{$_}{smoke}, 's.sh', "two_binaries_share_defaults: $_ gets the smoke" for qw(foo bar);
  is_deeply [sort keys %{ $x->{binaries} || {} }], [qw(bar foo)],
    'two_binaries_share_defaults: both binaries survive (multi-value binary key)';
  my @bins = $tzil ? grep { $_->isa($BINARY_CLASS) } @{ $tzil->plugins } : ();
  is scalar(@bins), 2, 'two_binaries_share_defaults: two Binary plugins';
}

# repeatable options keep two values each
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary = foo\nbinary_modules = A\nbinary_modules = B\n"
      . "binary_require = R1\nbinary_require = R2\n",
    scripts => ['bin/foo']);
  is $err, undef, 'multivalue: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply $x->{binaries}{foo}{modules}, [qw(A B)], 'multivalue: two binary_modules lines both survive';
  is_deeply $x->{binaries}{foo}{require}, [qw(R1 R2)], 'multivalue: two binary_require lines both survive';
}

# k30: META keeps the glob as the user wrote it; only the pp argv translates it
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary = foo\nbinary_modules = Foo::*\nbinary_modules = Baz\n",
    scripts => ['bin/foo']);
  is $err, undef, 'meta_glob: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply $x->{binaries}{foo}{modules}, [ 'Foo::*', 'Baz' ],
    'meta_glob: x_binaries modules keeps Foo::* (not Foo::**)';
}

# subsection_overrides
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary_default = 0\nbinary_smoke = s.sh\n\n"
      . "[\@Author::GETTY::Binary / baz]\nscript = script/baz.pl\nmodules = C\n",
    scripts => ['script/baz.pl']);
  is $err, undef, 'subsection_overrides: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply [sort keys %{ $x->{binaries} || {} }], ['baz'], 'subsection_overrides: only baz, no auto-default';
  is $x->{binaries}{baz}{script}, 'script/baz.pl', 'subsection_overrides: script from subsection';
  is_deeply $x->{binaries}{baz}{modules}, ['C'], 'subsection_overrides: modules from subsection';
  is $x->{binaries}{baz}{smoke}, 's.sh', 'subsection_overrides: smoke inherited from binary_smoke';
}

# platform_subset
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary = foo\nbinary_platforms = linux-x86_64 macos-arm64\n",
    scripts => ['bin/foo']);
  is $err, undef, 'platform_subset: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply $x->{platforms}, [qw(linux-x86_64 macos-arm64)], 'platform_subset: only the declared platforms';
}
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary = foo\nbinary_platforms = linux-x86_64\nbinary_platforms = macos-arm64\n",
    scripts => ['bin/foo']);
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply $x->{platforms}, [qw(linux-x86_64 macos-arm64)],
    'platform_subset: repeated binary_platforms lines both survive';
}

# unknown_platform_croaks
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary = foo\nbinary_platforms = linux-mips\n", scripts => ['bin/foo'], build => 0);
  like $err // '', qr/unknown platform linux-mips/, 'unknown_platform_croaks';
}

# bad_name_croaks
{
  my ($tzil, $err) = build_dist("$BUNDLE" . "binary = ../x\n", scripts => ['bin/foo'], build => 0);
  like $err // '', qr/binary name/, 'bad_name_croaks';
}

# missing_script_fails_build
{
  my ($tzil, $err) = build_dist("$BUNDLE" . "binary = foo\n", scripts => []);
  like $err // '', qr{bin/foo}, 'missing_script_fails_build: the build dies naming bin/foo';
}

# needs_github_release
{
  my ($tzil, $err) = build_dist(
    "[\@Author::GETTY]\nno_github_release = 1\nbinary = foo\n", scripts => ['bin/foo'], build => 0);
  like $err // '', qr/needs the GitHub release/, 'needs_github_release: no_github_release = 1 croaks';
}
{
  my ($tzil, $err) = build_dist(
    "[\@Author::GETTY]\nno_github = 1\nbinary = foo\n", scripts => ['bin/foo'], build => 0);
  like $err // '', qr/needs the GitHub release/, 'needs_github_release: no_github = 1 croaks';
}
# Ruling R3: no GitHub remote defaults both off, which also croaks.
{
  my ($tzil, $err) = build_dist(
    "[\@Author::GETTY]\nbinary = foo\n",
    scripts => ['bin/foo'], remote => undef, build => 0);
  like $err // '', qr/needs the GitHub release/, 'needs_github_release: no GitHub remote croaks';
}
{
  my ($tzil, $err) = build_dist(
    "[\@Author::GETTY]\nbinary = foo\n",
    scripts => ['bin/foo'], remote => 'git@gitlab.com:getty/test-dist.git', build => 0);
  like $err // '', qr/needs the GitHub release/, 'needs_github_release: a non-GitHub remote croaks';
}
# ... and the auto-default leg: a GitHub remote alone is enough, no explicit flags
{
  my ($tzil, $err) = build_dist("[\@Author::GETTY]\nbinary = foo\n", scripts => ['bin/foo'], build => 0);
  is $err, undef, 'needs_github_release: a GitHub remote alone satisfies it' or diag $err;
  ok $tzil && (grep { $_->isa($RELEASE_CLASS) } @{ $tzil->plugins }),
    'needs_github_release: the release plugin is present with a GitHub remote';
}

# no_binary_no_change
{
  my ($tzil, $err) = build_dist($BUNDLE);
  is $err, undef, 'no_binary_no_change: builds' or diag $err;
  my $meta = $tzil ? JSON::PP->new->decode($tzil->slurp_file("build/META.json")) : {};
  ok !exists $meta->{x_binaries}, 'no_binary_no_change: no x_binaries';
  ok !($tzil && grep { $_->isa($BINARY_CLASS) } @{ $tzil->plugins }),
    'no_binary_no_change: no Binary plugin';
  ok $tzil && (grep { $_->isa($RELEASE_CLASS) } @{ $tzil->plugins }),
    'no_binary_no_change: release plugin still present';
}
# no binaries and no GitHub release is fine (the croak is only for binaries)
{
  my ($tzil, $err) = build_dist("[\@Author::GETTY]\nno_github_release = 1\n", build => 0);
  is $err, undef, 'no_binary_no_change: no_github_release without binaries does not croak' or diag $err;
}

# make_latest_false_with_binaries
{
  my ($tzil, $err) = build_dist("$BUNDLE" . "binary = foo\n", scripts => ['bin/foo'], build => 0);
  is $err, undef, 'make_latest_false_with_binaries: configures' or diag $err;
  my ($rel) = $tzil ? grep { $_->isa($RELEASE_CLASS) } @{ $tzil->plugins } : ();
  ok $rel, 'make_latest_false_with_binaries: release plugin present';
  ok $rel && !$rel->make_latest, 'make_latest_false_with_binaries: make_latest is false';
}
{
  my ($tzil, $err) = build_dist($BUNDLE, build => 0);
  my ($rel) = $tzil ? grep { $_->isa($RELEASE_CLASS) } @{ $tzil->plugins } : ();
  ok $rel && $rel->make_latest, 'make_latest_false_with_binaries: still true without binaries';
}

# full x_binaries shape, every key set
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE"
      . "binary = mcp-wiki\n"
      . "binary_modules = MCP::Wiki::Git::History Git::Raw\n"
      . "binary_require = Git::Raw MCP::Wiki::Git::History\n"
      . "binary_pp_args = perl -Ilib scripts/loaded-modules.pl --pp-args\n"
      . "binary_verify = scripts/binary-verify.sh\n"
      . "binary_smoke = scripts/binary-smoke.sh\n"
      . "binary_prepare = scripts/binary-prepare.sh\n",
    scripts => ['bin/mcp-wiki']);
  is $err, undef, 'x_binaries_shape: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil);
  is_deeply $x, {
    platforms => \@ALL_PLATFORMS,
    prepare   => 'scripts/binary-prepare.sh',
    binaries  => {
      'mcp-wiki' => {
        script  => 'bin/mcp-wiki',
        modules => [qw(MCP::Wiki::Git::History Git::Raw)],
        require => [qw(Git::Raw MCP::Wiki::Git::History)],
        pp_args => 'perl -Ilib scripts/loaded-modules.pl --pp-args',
        verify  => 'scripts/binary-verify.sh',
        smoke   => 'scripts/binary-smoke.sh',
      },
    },
  }, 'x_binaries_shape: the full shape, prepare at top level';
}

# the fabricated remote, not the repo around the test, drives the detection
{
  my ($tzil, $err) = build_dist("[\@Author::GETTY]\n", remote => "git\@gitlab.com:getty/test-dist.git", build => 0);
  is $err, undef, "remote_forcing: configures" or diag $err;
  ok !($tzil && grep { $_->isa($RELEASE_CLASS) } @{ $tzil->plugins }),
    "remote_forcing: a non-GitHub fabricated remote drops the release plugin";
}

# I1: subsection-only config (no binary key) must hit the same R3 croak
{
  my $sub = "binary_default = 0\n\n[\@Author::GETTY::Binary / x]\n";
  for my $case (
    [ 'no_github_release = 1', "[\@Author::GETTY]\nno_github_release = 1\n$sub", {} ],
    [ 'no GitHub remote',      "[\@Author::GETTY]\n$sub", { remote => undef } ],
  ) {
    my ($name, $ini, %o) = ($case->[0], $case->[1], %{ $case->[2] });
    my ($tzil, $err) = build_dist($ini, scripts => ['bin/x'], build => 0, %o);
    like $err // '', qr/needs the GitHub release/, "subsection_only_needs_release: $name croaks";
  }
  my ($tzil, $err) = build_dist("$BUNDLE$sub", scripts => ['bin/x']);
  is $err, undef, 'subsection_only_needs_release: GitHub remote builds' or diag $err;
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply [sort keys %{ $x->{binaries} || {} }], ['x'],
    'subsection_only_needs_release: x_binaries written for the subsection binary';
}

# I3: platforms and prepare are dist-wide
{
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary = foo\nbinary = bar\nbinary_platforms = linux-x86_64 macos-arm64\n"
      . "binary_prepare = scripts/p.sh\n",
    scripts => ['bin/foo', 'bin/bar']);
  is $err, undef, 'dist_wide: builds' or diag $err;
  my $x = $tzil && x_binaries($tzil) || {};
  is_deeply $x->{platforms}, [qw(linux-x86_64 macos-arm64)], 'dist_wide: platforms exactly the declared two';
  is $x->{prepare}, 'scripts/p.sh', 'dist_wide: prepare once at top level';
  ok !exists $x->{binaries}{$_}{prepare} && !exists $x->{binaries}{$_}{platforms},
    "dist_wide: neither prepare nor platforms inside binaries.$_" for qw(foo bar);
}
for my $k (['platforms', 'linux-x86_64', qr/platforms.*binary_platforms/s],
           ['prepare',   'scripts/p.sh', qr/prepare.*binary_prepare/s]) {
  my ($key, $val, $re) = @$k;
  my ($tzil, $err) = build_dist(
    "$BUNDLE" . "binary_default = 0\n\n[\@Author::GETTY::Binary / x]\n$key = $val\n",
    scripts => ['bin/x'], build => 0);
  like $err // '', $re, "dist_wide: subsection $key croaks naming binary_$key";
}

done_testing;
