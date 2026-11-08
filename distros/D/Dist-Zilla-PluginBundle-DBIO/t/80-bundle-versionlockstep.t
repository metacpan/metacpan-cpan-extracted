use strict;
use warnings;

use Test::More;
use File::Temp ();
use Dist::Zilla::Tester;
use Cwd ();
use IPC::Open3;
use Path::Tiny;
use Dist::Zilla::File::InMemory;

# Pins the version gate [@DBIO] puts into the core distribution (k14).
#
# Why it exists: core carries a literal $VERSION in every module but versions
# only from its main module (VersionFromMainModule); nothing rewrites the rest.
# A module left behind at a version bump installed with a stale $VERSION and no
# build or test noticed. The claim of the gate is therefore:
#
#   with core = 1, a module under lib/ whose $VERSION is missing or differs
#   from the main module's turns the built dist's test red and names the file.
#
# Drivers are versioned by RewriteVersion::Transitional and must not get it.
#
# The generated script is run, not grepped: only executing it against a lib/
# shows whether it goes red.

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

sub by_class {
  my $tzil = shift;
  my %c;
  $c{ ref $_ } = $_ for @{ $tzil->plugins };
  return \%c;
}

my $class = 'Dist::Zilla::Plugin::DBIO::VersionLockstepTest';

# --- core gets the gate, a driver does not ---
my $core_tzil = tzil_for('core = 1');
my $core      = by_class($core_tzil);
{
  my $driver = by_class( tzil_for('') );

  ok $core->{$class},    'core:   VersionLockstepTest present';
  ok !$driver->{$class}, 'driver: VersionLockstepTest absent';
}

# --- gathered as an author test, promoted by ExtraTests ---
my $promoted;
{
  # The main module is only known once the source files are in. Git::GatherDir
  # needs a repository, so put the one source file in by hand.
  $core->{$class}->add_file(Dist::Zilla::File::InMemory->new(
    name    => 'lib/DBIO/Test.pm',
    content => "package DBIO::Test;\nour \$VERSION = '0.001';\n1;\n",
  ));
  $core->{$class}->gather_files;
  my ($file) = grep { $_->name eq 'xt/author/version-lockstep.t' }
    @{ $core_tzil->files };
  ok $file, 'xt/author/version-lockstep.t gathered';

  $core->{'Dist::Zilla::Plugin::ExtraTests'}->munge_file($file);
  is $file->name, 't/author-version-lockstep.t',
    'ExtraTests promotes it to t/author-version-lockstep.t';

  $promoted = $file->content;
  like $promoted, qr{lib/DBIO/Test\.pm},
    'the main module of the dist is written into the test';
}

sub mod {
  my ($pkg, $version_line) = @_;
  return "package $pkg;\n# ABSTRACT: x\n"
    . (defined $version_line ? "$version_line\n" : '')
    . "1;\n";
}

# Lay out a built dist with the promoted test in t/, run it from the dist
# root, return (exit, output).
sub run_gate {
  my ($files, %env) = @_;

  my $dist = Path::Tiny->tempdir;
  for my $name (keys %$files) {
    my $path = $dist->child($name);
    $path->parent->mkpath;
    $path->spew_utf8($files->{$name});
  }
  my $script = $dist->child('t', 'author-version-lockstep.t');
  $script->parent->mkpath;
  $script->spew_utf8($promoted);

  delete local @ENV{qw(PERL5OPT AUTHOR_TESTING)};
  local $ENV{AUTHOR_TESTING} = $env{AUTHOR_TESTING}
    if defined $env{AUTHOR_TESTING};

  my $cwd = Cwd::getcwd();
  chdir $dist or die "chdir $dist: $!";
  my $pid = open3(my $in, my $out, undef, $^X, 't/author-version-lockstep.t');
  close $in;
  my $output = do { local $/; <$out> };
  waitpid $pid, 0;
  my $exit = $? >> 8;
  chdir $cwd or die "chdir $cwd: $!";

  return ($exit, $output);
}

my $main = mod('DBIO::Test', q{our $VERSION = '0.900004';});

# --- all modules in step: green ---
{
  my ($exit, $out) = run_gate({
    'lib/DBIO/Test.pm'        => $main,
    'lib/DBIO/Test/Row.pm'    => mod('DBIO::Test::Row', q{our $VERSION = '0.900004';}),
    'lib/DBIO/Test/Deep/X.pm' => mod('DBIO::Test::Deep::X', q{our $VERSION = "0.900004";}),
  }, AUTHOR_TESTING => 1);

  is $exit, 0, 'all modules at the main version: the gate passes' or diag $out;
}

# --- a module left behind: red, and the file and both versions are named ---
{
  my ($exit, $out) = run_gate({
    'lib/DBIO/Test.pm'     => $main,
    'lib/DBIO/Test/Row.pm' => mod('DBIO::Test::Row', q{our $VERSION = '0.900003';}),
  }, AUTHOR_TESTING => 1);

  isnt $exit, 0, 'a module at an older version: the gate fails';
  like $out, qr{lib/DBIO/Test/Row\.pm}, 'the failure names the file';
  like $out, qr/0\.900003/, 'the failure names the version it carries';
}

# --- a module without any $VERSION: red ---
{
  my ($exit, $out) = run_gate({
    'lib/DBIO/Test.pm'      => $main,
    'lib/DBIO/Test/Bare.pm' => mod('DBIO::Test::Bare'),
  }, AUTHOR_TESTING => 1);

  isnt $exit, 0, 'a module without $VERSION: the gate fails';
  like $out, qr{lib/DBIO/Test/Bare\.pm}, 'the failure names the file';
}

# --- an install is not gated ---
{
  my ($exit, $out) = run_gate({
    'lib/DBIO/Test.pm'     => $main,
    'lib/DBIO/Test/Row.pm' => mod('DBIO::Test::Row', q{our $VERSION = '0.900003';}),
  });

  is $exit, 0, 'no AUTHOR_TESTING: a stale module does not fail an install';
  like $out, qr/^1\.\.0 # SKIP/m, 'no AUTHOR_TESTING: the test skips';
}

done_testing;
