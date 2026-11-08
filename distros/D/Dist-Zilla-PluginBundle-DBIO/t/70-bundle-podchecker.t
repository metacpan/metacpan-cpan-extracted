use strict;
use warnings;

use Test::More;
use File::Temp ();
use Dist::Zilla::Tester;
use Cwd ();
use IPC::Open3;
use Path::Tiny;

# Pins the POD gate the [@DBIO] bundle puts into every distribution (k10).
#
# Why it exists: dbio-async shipped a woven DBIO::Async::Storage with 19
# podchecker errors -- L</_submit_query> and friends pointing at headings the
# woven POD did not have -- and no suite noticed, because nothing checked the
# POD of the *built* modules. The claim of the gate is therefore:
#
#   an unresolved internal link in a built module turns `dzil test` red and
#   says which file and which link.
#
# That claim is why the generated test uses Pod::Checker. A Test::Pod /
# [PodSyntaxTests] test passes on exactly this fault (Pod::Simple does not
# resolve link targets), so it could never have gone red on the case that
# started this.
#
# The script is run, not grepped: only executing it against real POD shows
# whether it goes red.

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

# --- the gate is wired in both driver and core configurations ---
{
  my $driver = by_class( tzil_for('') );
  my $core   = by_class( tzil_for("core = 1") );

  ok $driver->{'Dist::Zilla::Plugin::DBIO::PodCheckerTest'},
    'driver: PodCheckerTest present';
  ok $core->{'Dist::Zilla::Plugin::DBIO::PodCheckerTest'},
    'core:   PodCheckerTest present';
}

# --- the file is gathered as an author test and ExtraTests promotes it ---
#
# The test only gates anything if it ends up in t/ of the built dist, and it
# must stay out of the way of a plain install. Both follow from ExtraTests
# picking the file up: it moves xt/author/*.t to t/author-*.t and guards it
# with AUTHOR_TESTING. So this runs the bundle's own ExtraTests over the
# gathered file instead of asserting where the plugin sits in the plugin
# list -- ExtraTests is a FileMunger and sees every gathered file whatever the
# order, so an order assertion could not fail on anything that matters.
my $promoted;
{
  my $tzil    = tzil_for('');
  my $plugins = by_class($tzil);

  $plugins->{'Dist::Zilla::Plugin::DBIO::PodCheckerTest'}->gather_files;
  my ($file) = grep { $_->name eq 'xt/author/pod-checker.t' } @{ $tzil->files };
  ok $file, 'xt/author/pod-checker.t gathered';

  $plugins->{'Dist::Zilla::Plugin::ExtraTests'}->munge_file($file);
  is $file->name, 't/author-pod-checker.t',
    'ExtraTests promotes it to t/author-pod-checker.t';

  $promoted = $file->content;
}

# Lay out a built dist (path => content) with the promoted test in t/, run the
# test from the dist root the way `make test` does, return (exit, output).
sub run_gate {
  my ($files, %env) = @_;

  my $dist = Path::Tiny->tempdir;
  for my $name (keys %$files) {
    my $path = $dist->child($name);
    $path->parent->mkpath;
    $path->spew_utf8($files->{$name});
  }
  my $script = $dist->child('t', 'author-pod-checker.t');
  $script->parent->mkpath;
  $script->spew_utf8($promoted);

  # PERL5OPT: a suite run under -MDevel::Cover must not drag Devel::Cover into
  # the child. AUTHOR_TESTING is set per case -- `dzil test` exports it, a
  # plain `prove` does not, and the gate must behave the same under both.
  delete local @ENV{qw(PERL5OPT AUTHOR_TESTING)};
  local $ENV{AUTHOR_TESTING} = $env{AUTHOR_TESTING}
    if defined $env{AUTHOR_TESTING};

  my $cwd = Cwd::getcwd();
  chdir $dist or die "chdir $dist: $!";
  my $pid = open3(
    my $in, my $out, undef,   # no separate stderr handle: merged into $out
    $^X, 't/author-pod-checker.t',
  );
  close $in;
  my $output = do { local $/; <$out> };
  waitpid $pid, 0;
  my $exit = $? >> 8;
  chdir $cwd or die "chdir $cwd: $!";

  return ($exit, $output);
}

# A woven module in the shape of the dbio-async case: the text links to a
# method heading. $heading decides whether that heading exists.
sub woven {
  my ($heading) = @_;
  return join "\n",
    'package DBIO::Test::Storage;',
    'use strict;',
    'use warnings;',
    '1;',
    '',
    '__END__',
    '',
    '=pod',
    '',
    '=encoding UTF-8',
    '',
    '=head1 NAME',
    '',
    'DBIO::Test::Storage - fixture',
    '',
    '=head1 METHODS',
    '',
    '=head2 connect',
    '',
    'Hands the query to L</_submit_query>.',
    '',
    $heading,
    '',
    '=cut',
    '';
}

my $broken = woven('');
my $clean  = woven("=head2 _submit_query\n\nDriver seam.");
my $no_pod = "package DBIO::Test::Plain;\nuse strict;\nuse warnings;\n1;\n";

# --- the reason this gate exists: an unresolved internal link is red ---
{
  my ($exit, $output) = run_gate(
    { 'lib/DBIO/Test/Storage.pm' => $broken },
    AUTHOR_TESTING => 1,
  );

  isnt $exit, 0, 'unresolved internal link: the gate fails';
  like $output, qr{lib/DBIO/Test/Storage\.pm},
    'the failure names the file';
  like $output, qr/_submit_query/,
    'the failure names the link that does not resolve';
}

# --- the same module with the heading in place is green ---
{
  my ($exit, $output) = run_gate(
    { 'lib/DBIO/Test/Storage.pm' => $clean },
    AUTHOR_TESTING => 1,
  );

  is $exit, 0, 'resolved link: the gate passes' or diag $output;
}

# --- Pod::Checker warnings neither fail nor show: a green run stays quiet ---
#
# An empty =over/=back block is a Pod::Checker warning, not an error. The gate
# is for faults that break the rendered document; a family-wide red over
# style warnings would bury them.
{
  my ($exit, $output) = run_gate(
    { 'lib/DBIO/Test/Storage.pm' => woven(
        "=head2 _submit_query\n\n=over 4\n\n=back") },
    AUTHOR_TESTING => 1,
  );

  is $exit, 0, 'warning-only POD: the gate passes' or diag $output;
  unlike $output, qr/^#/m, 'warning-only POD: no diagnostics printed';
}

# --- a module without any POD is not a fault ---
{
  my ($exit, $output) = run_gate(
    { 'lib/DBIO/Test/Plain.pm' => $no_pod },
    AUTHOR_TESTING => 1,
  );

  is $exit, 0, 'module without POD: the gate passes' or diag $output;
}

# --- bin/ is checked too (core ships scripts with POD) ---
{
  my ($exit, $output) = run_gate(
    {
      'lib/DBIO/Test/Storage.pm' => $clean,
      'bin/dbio-test'            => "#!perl\n" . $broken,
    },
    AUTHOR_TESTING => 1,
  );

  isnt $exit, 0, 'unresolved internal link in bin/: the gate fails';
  like $output, qr{bin/dbio-test}, 'the failure names the script';
}

# --- a run that found nothing to check must not look like a pass ---
{
  my ($exit, $output) = run_gate( {}, AUTHOR_TESTING => 1 );

  isnt $exit, 0, 'no lib/ and no bin/ in sight: the gate fails, it does not pass on nothing';
}

# --- an install is not gated: without AUTHOR_TESTING the test skips ---
{
  my ($exit, $output) = run_gate( { 'lib/DBIO/Test/Storage.pm' => $broken } );

  is $exit, 0, 'no AUTHOR_TESTING: broken POD does not fail an install';
  like $output, qr/^1\.\.0 # SKIP/m, 'no AUTHOR_TESTING: the test skips';
}

done_testing;
