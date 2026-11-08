use strict;
use warnings;

use Test::More;
use File::Temp ();
use Dist::Zilla::Tester;
use Digest::MD5 ();
use Software::License::Perl_5;

# Pins DBIO::LicenseFile (k18): the LICENSE stays a committed file that
# Git::GatherDir gathers; the plugin only checks it, and breaks the build when
# it is missing or not the text the dist is supposed to carry.
#
#   - without heritage: the parent's behaviour -- the file must be the license
#     of dist.ini (Perl_5 with holder and year)
#   - with heritage: the file must be the fixed DBIx::Class text the heritage
#     repos commit (413 lines, md5 below)

my $class = 'Dist::Zilla::Plugin::DBIO::LicenseFile';
use_ok $class or BAIL_OUT("$class does not load");

my $HERITAGE_MD5 = 'af858129644bc9ae236fd901ef843f27';

# The heritage text as the plugin ships it; its identity is pinned here so a
# change of the embedded text cannot slip through unnoticed.
my $heritage = $class->heritage_text;
is Digest::MD5::md5_hex($heritage), $HERITAGE_MD5,
  'embedded heritage text is byte-identical to the committed DBIO LICENSE';
is scalar(() = $heritage =~ /\n/g), 413, 'embedded heritage text has 413 lines';
like $heritage, qr/^DBIO is a fork of DBIx::Class\./, 'it opens with the fork preamble';

my $perl5 = Software::License::Perl_5->new({
  holder => 'DBIO Authors',
  year   => 2026,
})->license;

sub build_with {
  my ($plugin_args, $license) = @_;
  my %files = (
    'source/dist.ini' => join("\n",
      'name = DBIO-Test',
      'author = DBIO Authors',
      'license = Perl_5',
      'copyright_holder = DBIO Authors',
      'copyright_year = 2026',
      'version = 0.001',
      '',
      '[GatherDir]',
      '[DBIO::LicenseFile]',
      $plugin_args,
      '',
    ),
    'source/lib/DBIO/Test.pm' =>
      "package DBIO::Test;\n# ABSTRACT: test\nour \$VERSION = '0.001';\n1;\n",
  );
  $files{'source/LICENSE'} = $license if defined $license;

  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => '/tmp/dbio-dzil-corpus-does-not-exist' },
    { tempdir_root => File::Temp::tempdir(CLEANUP => 1), add_files => \%files },
  );
  my $ok = eval { $tzil->build; 1 };
  return ($ok, $@, $tzil);
}

# --- without heritage: the parent's license-from-dist.ini behaviour ---
{
  my ($ok, $err, $tzil) = build_with('', $perl5);
  ok $ok, 'no heritage: LICENSE equal to the dist.ini license builds' or diag $err;
  is $tzil->slurp_file('build/LICENSE'), $perl5, 'the committed file is shipped as-is';
}
{
  my ($ok, $err) = build_with('', $heritage);
  ok !$ok, 'no heritage: the heritage text in LICENSE breaks the build';
  like $err, qr/LICENSE is out of date/, '... and says LICENSE is out of date';
}
{
  my ($ok, $err) = build_with('', undef);
  ok !$ok, 'no heritage: a missing LICENSE breaks the build';
  like $err, qr/no LICENSE in the distribution/, '... and says it is missing';
}

# --- with heritage: the fixed DBIx::Class text ---
{
  my ($ok, $err, $tzil) = build_with('heritage = 1', $heritage);
  ok $ok, 'heritage: the fixed text builds' or diag $err;
  is Digest::MD5::md5_hex($tzil->slurp_file('build/LICENSE')), $HERITAGE_MD5,
    'the committed file is shipped as-is';
}
{
  my ($ok, $err) = build_with('heritage = 1', $perl5);
  ok !$ok, 'heritage: a plain Perl_5 LICENSE breaks the build';
  like $err, qr/LICENSE is out of date/, '... and says LICENSE is out of date';
  like $err, qr/DBIx::Class/, '... and names the expected DBIx::Class text';
}
{
  (my $changed = $heritage) =~ s/Artistic License 1\.0/Artistic License 2.0/;
  my ($ok, $err) = build_with('heritage = 1', $changed);
  ok !$ok, 'heritage: a deviating LICENSE breaks the build';
  like $err, qr/LICENSE/, '... and names the file';
}
{
  my ($ok, $err) = build_with('heritage = 1', undef);
  ok !$ok, 'heritage: a missing LICENSE breaks the build';
  like $err, qr/no LICENSE in the distribution/, '... and says it is missing';
}
{
  my ($ok, $err) = build_with('heritage = 1', "$heritage\n\n");
  ok $ok, 'heritage: trailing whitespace is not a deviation' or diag $err;
}

done_testing;
