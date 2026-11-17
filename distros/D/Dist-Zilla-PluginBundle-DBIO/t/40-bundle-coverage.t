use strict;
use warnings;

use Test::More;
use File::Temp ();
use Dist::Zilla::Tester;
use IPC::Open3;
use Path::Tiny;
use File::pushd ();

# Pins the coverage gate of the [@DBIO] bundle, Dist::Zilla::Plugin::DBIO::CoverageGate:
# - it is a TestRunner that runs after the build plugin (MakeMaker or
#   MakeMaker::Awesome), so it judges cover_db/ once the whole suite has run
# - coverage_threshold defaults to 80, a custom value is forwarded, 0 disables
# - test($dir) scores the lib/ of $dir from a real Devel::Cover database: it
#   passes above the threshold, warns below it, and fails below it under
#   RELEASE=1 or COVERAGE_STRICT=1; a missing cover_db/ fails under RELEASE=1
#   and only notes otherwise; files outside lib/ do not count

sub tzil_for {
  my ($bundle_args) = @_;
  Dist::Zilla::Tester->from_config(
    { dist_root => '/tmp/dbio-dzil-corpus-does-not-exist' },
    { tempdir_root => File::Temp::tempdir(CLEANUP => 1), add_files => {
        'source/dist.ini' => join("\n",
          'name = DBIO-Test',
          'author = Test <test@example.com>',
          'license = Perl_5',
          'copyright_holder = DBIO Contributors',
          '',
          "[\@DBIO]",
          $bundle_args,
          '',
        ),
        'source/lib/DBIO/Test.pm' =>
          "package DBIO::Test;\n# ABSTRACT: test\nour \$VERSION = '0.001';\n1;\n",
        'source/cpanfile' => "requires 'perl', '5.020';\n",
      } },
  );
}

my $GATE = 'Dist::Zilla::Plugin::DBIO::CoverageGate';

sub gate_of {
  my ($tzil) = @_;
  my ($gate) = grep { ref $_ eq $GATE } @{ $tzil->plugins };
  return $gate;
}

# --- the gate runs after the build plugin, driver and core ---
#
# Dist::Zilla runs the TestRunner plugins in this order; the build plugin has
# to come first, the gate after it.
for my $case (
  [ driver => '',         'Dist::Zilla::Plugin::MakeMaker' ],
  [ core   => 'core = 1', 'Dist::Zilla::Plugin::MakeMaker::Awesome' ],
) {
  my ($label, $args, $builder) = @$case;
  my @runners = map { ref } @{ tzil_for($args)->plugins_with(-TestRunner) };
  my %at; @at{reverse @runners} = reverse 0 .. $#runners;
  ok defined $at{$GATE}, "$label: CoverageGate is a TestRunner";
  ok defined $at{$builder}, "$label: $builder is a TestRunner";
  cmp_ok $at{$GATE}, '>', $at{$builder}, "$label: the gate runs after $builder"
    or diag join ', ', @runners;
}

# --- coverage_threshold ---
is gate_of( tzil_for('') )->coverage_threshold, 80, 'default coverage_threshold = 80';
is gate_of( tzil_for('coverage_threshold = 95') )->coverage_threshold, 95,
  'coverage_threshold = 95 reaches the gate';

# --- the gate scores a real Devel::Cover database ---
SKIP: {
  # The author (AUTHOR_TESTING) and the release (RELEASE_TESTING) always run
  # this block: a missing Devel::Cover is a failure there, a skip elsewhere.
  unless ( eval { require Devel::Cover::DB; 1 } ) {
    fail 'Devel::Cover::DB is needed under AUTHOR_TESTING / RELEASE_TESTING'
      if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};
    skip 'Devel::Cover not installed', 21;
  }

  # A suite run under -MDevel::Cover, RELEASE=1 or COVERAGE_STRICT=1 must not
  # change what the cases below claim.
  delete local @ENV{qw(PERL5OPT COVERAGE_STRICT RELEASE HARNESS_PERL_SWITCHES)};

  # One dist directory with a real cover_db/ from a Devel::Cover run of
  # prog.pl. Besides lib/ it holds files the gate must not score: other/ is
  # no lib/, and vendor/lib/ only ends in lib/.
  my $cwd = Path::Tiny->cwd;
  my $fixture = sub {
    my ($mods) = @_;
    my $dir = Path::Tiny->tempdir;
    $dir->child($_)->mkpath for qw(lib vendor/lib other);
    $dir->child('lib', "$_.pm")->spew_utf8($mods->{$_}) for keys %$mods;
    my $dead = "package %s;\nsub a { 1 }\nsub b { 2 }\nsub c { 3 }\n1;\n";
    $dir->child('vendor', 'lib', 'Vend.pm')->spew_utf8(sprintf $dead, 'Vend');
    $dir->child('other', 'Foreign.pm')->spew_utf8(sprintf $dead, 'Foreign');
    $dir->child('prog.pl')->spew_utf8(
      "use lib 'lib', 'vendor/lib', 'other';\n"
      . "use Cov; use Vend; use Foreign; Cov::a(); Cov::b();\n"
      . ( $mods->{Weak} ? "use Weak; Weak::a();\n" : '' ));
    chdir $dir or die $!;
    my $pid = open3(my $in, my $out, undef,
      $^X, '-MDevel::Cover=-silent,1,-db,cover_db', 'prog.pl');
    close $in; my $o = do { local $/; <$out> }; waitpid $pid, 0;
    chdir $cwd or die $!;
    die "fixture run failed: $o" if $?;
    die 'fixture has no cover_db/runs' unless $dir->child('cover_db', 'runs')->is_dir;
    return $dir;
  };
  my $copy = sub {
    my ($dir) = @_;
    my $new = Path::Tiny->tempdir;
    system('cp', '-a', "$dir/.", "$new") == 0 or die "cp failed";
    return $new;
  };

  my $cov = "package Cov;\nuse strict;\nuse warnings;\nsub a { 1 }\nsub b { 2 }\n1;\n";
  my $weak = join '', "package Weak;\nuse strict;\nuse warnings;\n",
    ( map { "sub $_ { 1 }\n" } 'a' .. 'h' ), "1;\n";
  my $good_db = $fixture->({ Cov => $cov });
  my $weak_db = $fixture->({ Cov => $cov, Weak => $weak });

  my $run = sub {
    my ($tzil, $dir, %env) = @_;
    $tzil->clear_log_events;
    local @ENV{ keys %env } = values %env;
    my $ok = eval { gate_of($tzil)->test("$dir"); 1 };
    return ( $ok, "$@", join "\n", @{ $tzil->log_messages } );
  };

  # --- above the threshold: ok, and the success line has the total ---
  {
    my $tzil = tzil_for('');
    my $dir = $copy->($good_db);
    my ($ok, $err, $log) = $run->($tzil, $dir);
    ok $ok, 'above the threshold: no exception' or diag $err;
    like $log, qr/statement coverage 100\.0%/,
      'the success line names the total, which counts lib/ only';
    ok scalar(glob "$dir/cover_db/cover.*"), 'the gate merged the runs itself'
      or diag join ' ', glob "$dir/cover_db/*";

    ($ok, $err) = $run->($tzil, $copy->($good_db), RELEASE => 1);
    ok $ok, 'above the threshold under RELEASE=1: still ok' or diag $err;
  }

  # --- a relative target, as Dist::Zilla passes it ---
  #
  # run_tests_in changes into the build directory (a path relative to the
  # directory it started in) and then calls test() with that same relative
  # path. The gate has to take the current directory as the build directory,
  # not resolve the relative target against it a second time.
  {
    my $tzil = tzil_for('');
    my $dir = $copy->($good_db);
    $tzil->clear_log_events;
    my $ok = do {
      my $start = File::pushd::pushd($dir->parent);
      my $rel   = $dir->basename;
      my $in    = File::pushd::pushd($rel);
      local $ENV{RELEASE} = 1;
      eval { gate_of($tzil)->test($rel); 1 };
    };
    ok $ok, 'a relative target with the build directory as cwd: found and scored under RELEASE=1'
      or diag $@;
    like join("\n", @{ $tzil->log_messages }), qr/statement coverage 100\.0%/,
      'a relative target: the lib/ of the build directory is scored';
  }

  # --- below the threshold ---
  {
    my $tzil = tzil_for('');
    my ($ok, $err, $log) = $run->($tzil, $copy->($weak_db));
    ok $ok, 'below the threshold: a warning, no exception' or diag $err;
    like $log, qr/below threshold 80%/, 'the warning says it is below the threshold';

    for my $env (qw(RELEASE COVERAGE_STRICT)) {
      ($ok, $err) = $run->($tzil, $copy->($weak_db), $env => 1);
      ok !$ok, "below the threshold under $env=1: fails";
      like $err, qr/below threshold 80%/, "$env: the failure says so";
      like $err, qr/lib\/Weak\.pm.*lib\/Cov\.pm/s,
        "$env: the weakest module is named first";
    }
  }

  # --- coverage_threshold lower than the score lets the weak run pass ---
  {
    my ($ok, $err) = $run->(tzil_for('coverage_threshold = 10'), $copy->($weak_db),
      RELEASE => 1);
    ok $ok, 'threshold 10: the weak run passes even under RELEASE=1' or diag $err;
  }

  # --- coverage_threshold = 0 switches the gate off ---
  {
    my $tzil = tzil_for('coverage_threshold = 0');
    my $empty = Path::Tiny->tempdir;
    my ($ok, $err, $log) = $run->($tzil, $empty, RELEASE => 1);
    ok $ok, 'threshold 0: no exception, not even without cover_db/ under RELEASE=1'
      or diag $err;
    like $log, qr/disabled/, 'threshold 0: the log says the gate is off';
  }

  # --- no cover_db/ ---
  {
    my $tzil = tzil_for('');
    my $empty = Path::Tiny->tempdir;
    my ($ok, $err, $log) = $run->($tzil, $empty, RELEASE => 1);
    ok !$ok, 'no cover_db/ under RELEASE=1: fails';
    like $err, qr/-MDevel::Cover/, 'the failure says how to get a coverage run';

    ($ok, $err, $log) = $run->($tzil, $empty);
    ok $ok, 'no cover_db/ without RELEASE: no exception' or diag $err;
    like $log, qr/cover_db/, 'no cover_db/ without RELEASE: a note in the log';
  }
}

done_testing;
