#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

plan skip_all => "Dist::Zilla::Tester not available"
  unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };

# The local binary check of dzil build (after_build) and the workflow check of
# dzil release (before_release) of Dist::Zilla::Plugin::Author::GETTY::Binary.
# The real pp never runs here: a fake pp (and fake verify / smoke commands) in
# a temp directory is put first on PATH. They record their argv, one line per
# argument, and the fake pp creates its -o file (executable). No network and
# no real git remote: a GitHub remote is fabricated in a git-init'ed tempdir.

my $BINARY_CLASS = 'Dist::Zilla::Plugin::Author::GETTY::Binary';
my $WF_REPO      = 'Getty/p5-dist-zilla-pluginbundle-author-getty';

my $tools = path(tempdir(CLEANUP => 1));
my $bin   = $tools->child('bin');
$bin->mkpath;

sub tool {
  my ($name, $body) = @_;
  my $f = $bin->child($name);
  $f->spew("#!/bin/sh\n$body");
  chmod 0755, "$f";
}

# FAKE_LOG is the directory the fakes record into.
tool('pp', <<'SH');
: > "$FAKE_LOG/pp.argv"
for a in "$@"; do printf '%s\n' "$a" >> "$FAKE_LOG/pp.argv"; done
env > "$FAKE_LOG/pp.env"
pwd > "$FAKE_LOG/pp.cwd"
out=
while [ $# -gt 0 ]; do
  if [ "$1" = "-o" ]; then out=$2; fi
  shift
done
[ -n "$out" ] || exit 3
printf '#!/bin/sh\nexit 0\n' > "$out"
chmod +x "$out"
SH

for my $hook (qw(verify smoke)) {
  tool("fake-$hook", <<"SH");
last=
for a in "\$@"; do printf '%s %s\\n' $hook "\$a" >> "\$FAKE_LOG/hooks.log"; last=\$a; done
pwd > "\$FAKE_LOG/$hook.cwd"
[ -x "\$last" ] && echo yes > "\$FAKE_LOG/$hook.executable"
exit \${FAKE_${\ uc $hook}_EXIT:-0}
SH
}

# A PATH without any pp (the host may have a real one) that still has sh and git (the build needs git ls-files).
my $nopp = $tools->child('nopp');
$nopp->mkpath;
for my $t (qw(sh git)) {
  my ($real) = grep { -x } map { "$_/$t" } grep { length } split /:/, $ENV{PATH};
  die "no $t on PATH" unless $real;
  symlink $real, "$nopp/$t" or die "symlink: $!";
}

# Builds a dist around $bundle_ini (the part of dist.ini from [@Author::GETTY]
# on). The tempdir is chdir'ed into while the dist is configured and built so
# the cwd-dependent remote detection measures the fabricated repo.
# %o: root (directory the tempdirs go under, default a fresh one),
#     workflow (content of .github/workflows/binaries.yml, written into the
#     zilla root after configuring, so it is never gathered), env (hash of
#     extra %ENV), path (PATH override), skip (DZIL_BINARY_SKIP, default unset).
# Returns ($tzil, $err, $log_dir, $build_root).
sub build_dist {
  my ($bundle_ini, %o) = @_;
  my $tempdir  = path($o{root} // tempdir(CLEANUP => 1));
  $tempdir->mkpath;
  my $log      = path(tempdir(CLEANUP => 1));
  my $dist_dir = $tempdir->child('dist');
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
  $dist_dir->child('bin')->mkpath;
  $dist_dir->child('bin', 'foo')->spew("#!/usr/bin/env perl\n# PODNAME: foo\n# ABSTRACT: t\nprint 1;\n");

  system('git', 'init', '-q', "$dist_dir") == 0 or die "git init failed";
  open my $fh, '>>', "$dist_dir/.git/config" or die "open: $!";
  print $fh "[remote \"origin\"]\n\turl = git\@github.com:getty/test-dist.git\n"
          . "\tfetch = +refs/heads/*:refs/remotes/origin/*\n";
  close $fh;
  system('git', '-C', "$dist_dir", 'add', '-A') == 0 or die "git add failed";

  my $cwd = getcwd();
  chdir "$dist_dir" or die "chdir $dist_dir: $!";
  my ($tzil, $err);
  {
    local $ENV{FAKE_LOG} = "$log";
    local $ENV{PATH}     = $o{path} // "$bin:$ENV{PATH}";
    local @ENV{ keys %{ $o{env} || {} } } = values %{ $o{env} || {} };
    delete local $ENV{DZIL_BINARY_SKIP};
    local $ENV{DZIL_BINARY_SKIP} = $o{skip} if defined $o{skip};
    local $@;
    eval {
      $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => "$dist_dir" },
        { tempdir_root => "$tempdir", chrome => Dist::Zilla::Chrome::Term->new },
      );
      if (defined $o{workflow}) {
        my $wf = path($tzil->root)->child('.github', 'workflows', 'binaries.yml');
        $wf->parent->mkpath;
        $wf->spew($o{workflow});
      }
      $tzil->build unless $o{no_build};
      1;
    } or $err = $@;
  }
  chdir $cwd or die "chdir back: $!";
  my $build = $tzil ? path($tzil->tempdir)->child('build') : undef;
  return ($tzil, $err, $log, $build);
}

sub same_dir {
  my ($file, $dir) = @_;
  return 0 unless $file->exists;
  return path($file->slurp =~ s/\n\z//r)->realpath eq path($dir)->realpath;
}

sub lines {
  my ($file) = @_;
  return [] unless $file->exists;
  return [ split /\n/, $file->slurp ];
}

my $BUNDLE = "[\@Author::GETTY]\nno_github = 0\nno_github_release = 0\n";

# skip_env: DZIL_BINARY_SKIP=1 -> nothing runs
{
  my ($tzil, $err, $log) = build_dist(
    $BUNDLE . "binary = foo\nbinary_verify = fake-verify\nbinary_smoke = fake-smoke\n", skip => 1);
  is $err, undef, 'skip_env: builds' or diag $err;
  ok !$log->child('pp.argv')->exists, 'skip_env: the fake pp was never called';
  ok !$log->child('hooks.log')->exists, 'skip_env: neither verify nor smoke ran';
}

# packs_with_args, pp_args_lines_are_single_arguments, verify_and_smoke_get_binary_path
sub packs_scenario {
  my ($label, %o) = @_;
  my ($tzil, $err, $log, $build) = build_dist(
    $BUNDLE
      . "binary = foo\nbinary_modules = A\n"
      . q{binary_pp_args = printf "%s\n" -a "/x y;lib/z"} . "\n"
      . "binary_verify = fake-verify\nbinary_smoke = fake-smoke\n", %o);
  is $err, undef, "$label: builds" or diag $err;
  return unless $tzil;
  my $sib = "$build-binaries";

  is_deeply lines($log->child('pp.argv')),
    ['-o', "$sib/foo", '-I', "$build/lib", '-M', 'A', '-a', '/x y;lib/z', "$build/bin/foo"],
    "$label: packs_with_args: the exact pp argv, '-a' value as ONE argument";
  my %env = map { /\A([^=]+)=(.*)\z/s ? ($1 => $2) : () } @{ lines($log->child('pp.env')) };
  is $env{PAR_VERBATIM}, 1, "$label: packs_with_args: pp runs with PAR_VERBATIM=1";
  ok same_dir($log->child('pp.cwd'), $build),
    "$label: pp runs with the build root as cwd";

  ok -x "$sib/foo", "$label: the binary sits at <build_root>-binaries/foo";
  is_deeply lines($log->child('hooks.log')),
    ["verify $sib/foo", "smoke $sib/foo"],
    "$label: verify_and_smoke_get_binary_path: verify then smoke, the path as the one argument";
  ok $log->child("$_.executable")->exists, "$label: $_ saw an executable binary" for qw(verify smoke);
  for my $h (qw(verify smoke)) {
    ok same_dir($log->child("$h.cwd"), $build),
      "$label: $h runs with the build root as cwd";
  }
}
packs_scenario('plain');

# Ruling R6: a build root path with a space still yields exactly one path argument
{
  my $spaced = path(tempdir(CLEANUP => 1))->child('with space');
  packs_scenario('spaced_root', root => "$spaced");
}

# Ruling R6: the hook's own words come first, then the path as one extra argument
{
  my ($tzil, $err, $log, $build) = build_dist(
    $BUNDLE . "binary = foo\nbinary_verify = fake-verify --flag 'two words'\n");
  is $err, undef, 'hook_words: builds' or diag $err;
  my $sib = "$build-binaries";
  is_deeply lines($log->child('hooks.log')),
    ['verify --flag', 'verify two words', "verify $sib/foo"],
    'hook_words: own words (shell-quoted) first, then the binary path last';
}

# Ruling R4: split on newlines only, strip one trailing CR, drop empty lines
{
  my ($tzil, $err, $log, $build) = build_dist(
    $BUNDLE . "binary = foo\n" . q{binary_pp_args = printf '%s\r\n\n%s\n' -a "x y"} . "\n");
  is $err, undef, 'pp_args_line_rule: builds' or diag $err;
  my $argv = lines($log->child('pp.argv'));
  is_deeply [ @$argv[ 4 .. 5 ] ], ['-a', 'x y'],
    'pp_args_line_rule: the CR is stripped, the empty line yields nothing';
  ok !(grep { $_ eq '' || /\r/ } @$argv), 'pp_args_line_rule: no empty and no CR-bearing argument';
  is scalar(@$argv), 7, 'pp_args_line_rule: exactly -o P -I L -a X SCRIPT (7 arguments, no -M without modules)';
}

# k30: a trailing ::* in binary_modules reaches pp as ::**, in order, both values kept
{
  my ($tzil, $err, $log, $build) = build_dist(
    $BUNDLE . "binary = foo\nbinary_modules = A::*\nbinary_modules = B\nbinary_modules = C::D::*\n");
  is $err, undef, 'glob_modules: builds' or diag $err;
  is_deeply lines($log->child('pp.argv')),
    ['-o', "$build-binaries/foo", '-I', "$build/lib", '-M', 'A::**', '-M', 'B', '-M', 'C::D::**', "$build/bin/foo"],
    'glob_modules: A::* -> -M A::**, B unchanged, C::D::* -> -M C::D::**, order kept';
}

# no pp_args at all: nothing is added between the options and the script
{
  my ($tzil, $err, $log, $build) = build_dist($BUNDLE . "binary = foo\n");
  is $err, undef, 'no_pp_args: builds' or diag $err;
  is_deeply lines($log->child('pp.argv')),
    ['-o', "$build-binaries/foo", '-I', "$build/lib", "$build/bin/foo"],
    'no_pp_args: just -o, -I and the script';
}

# verify_failure_fails_build
{
  my ($tzil, $err) = build_dist(
    $BUNDLE . "binary = foo\nbinary_verify = fake-verify\nbinary_smoke = fake-smoke\n",
    env => { FAKE_VERIFY_EXIT => 1 });
  like $err // '', qr/fake-verify/, 'verify_failure_fails_build: the build dies naming the command';
}

# missing_pp_dies_with_hint
{
  my ($tzil, $err) = build_dist($BUNDLE . "binary = foo\n", path => "$nopp");
  like $err // '', qr/PAR::Packer.*DZIL_BINARY_SKIP=1/s,
    'missing_pp_dies_with_hint: names PAR::Packer and DZIL_BINARY_SKIP=1';
}

# pp is found but cannot be started (system returns -1): the build dies with the
# reason from $!, not with a bogus exit code. The interpreter of its #! line does
# not exist (a file without #! would be run through sh instead).
{
  my $badbin = $tools->child('badpp');
  $badbin->mkpath;
  $badbin->child('pp')->spew("#!/nonexistent/interpreter\n");
  chmod 0755, $badbin->child('pp');
  my @warn;
  my ($tzil, $err) = do {
    local $SIG{__WARN__} = sub { push @warn, @_ };   # perl's "Can't exec ..."
    build_dist($BUNDLE . "binary = foo\n", path => "$badbin:$nopp");
  };
  my $enoent = do { local $! = 2; "$!" };
  like $err // '', qr/cannot run pp for binary foo: \Q$enoent\E/,
    'unstartable_pp: the build dies with "cannot run pp for binary foo: <reason from $!>"';
  # the message without its " at FILE line N" tail: a smoker's path may hold long numbers
  my $msg = ( $err // '' ) =~ s/ at .*//sr;
  unlike $msg, qr/exit|pp failed/, 'unstartable_pp: no exit code in the message';
  unlike $msg, qr/\d{6,}/, 'unstartable_pp: no bogus exit code number';
}

# pp runs and fails: the exit code is named
{
  my $badbin = $tools->child('failpp');
  $badbin->mkpath;
  $badbin->child('pp')->spew("#!/bin/sh\nexit 4\n");
  chmod 0755, $badbin->child('pp');
  my ($tzil, $err) = build_dist($BUNDLE . "binary = foo\n", path => "$badbin:$nopp");
  like $err // '', qr/pp failed for binary foo \(exit 4\)/,
    'failing_pp: the build dies with "pp failed for binary foo (exit 4)"';
  unlike $err // '', qr/cannot run pp/, 'failing_pp: ... and not as an unstartable pp';
}

# release: the caller workflow, read from the zilla root
my $USES = "uses: $WF_REPO/.github/workflows/dzil-binary.yml";

sub release_check {
  my ($workflow) = @_;
  my ($tzil, $err) = build_dist($BUNDLE . "binary = foo\n", skip => 1, workflow => $workflow);
  die "setup build failed: $err" if $err;
  my ($plugin) = grep { $_->isa($BINARY_CLASS) } @{ $tzil->plugins };
  local $@;
  my $ok = eval { $plugin->before_release('Test-Dist-0.001.tar.gz'); 1 };
  return $ok ? undef : ($@ || 'died');
}

{
  my ($tzil, $err) = build_dist($BUNDLE . "binary = foo\n", skip => 1);
  my ($plugin) = grep { $_->isa($BINARY_CLASS) } @{ $tzil->plugins };
  local $@;
  my $ok = eval { $plugin->before_release('Test-Dist-0.001.tar.gz'); 1 };
  ok !$ok, 'release_without_workflow_dies: before_release dies';
  like $@, qr{\.github/workflows/binaries\.yml}, 'release_without_workflow_dies: names the workflow file';
}

is release_check("name: Binaries\njobs:\n  b:\n    $USES\@binary-v1\n"), undef,
  'release_with_workflow_passes: @binary-v1';
is release_check("jobs:\n  b:\n    $USES\@binary-form\n"), undef,
  'release_with_other_ref_passes (R5): @binary-form';

for my $bad (
  [ 'another repo',     "jobs:\n  b:\n    uses: Getty/other/.github/workflows/dzil-binary.yml\@binary-v1\n" ],
  [ 'another workflow', "jobs:\n  b:\n    uses: $WF_REPO/.github/workflows/other.yml\@binary-v1\n" ],
  [ 'no uses at all',   "name: Binaries\non: push\n" ],
  [ 'empty ref',        "jobs:\n  b:\n    $USES\@\n" ],
) {
  my $e = release_check($bad->[1]);
  ok defined $e, "release_bad_workflow: $bad->[0] dies";
  like $e // '', qr{\.github/workflows/binaries\.yml}, "release_bad_workflow: $bad->[0] names the file";
}

done_testing;
