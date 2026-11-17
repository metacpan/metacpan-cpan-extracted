use strict;
use warnings;

use Test::More;
use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use Software::License::Perl_5;

plan skip_all => 'git binary not available' unless can_run('git');

# Builds a small core dist (core = 1) end to end: like a driver it versions
# through @Git::VersionManager, so every module under lib/ carries the version
# of the dist (the $VERSION of the main module).

my $tempdir = tempdir(CLEANUP => 1);
my $root    = path($tempdir, 'dist');
$root->child('lib', 'DBIO', 'Test')->mkpath;

$root->child('dist.ini')->spew(<<'INI');
name = DBIO-Test
copyright_year = 2005

[@DBIO]
core = 1
INI
$root->child('lib', 'DBIO', 'Test.pm')->spew(<<'PM');
package DBIO::Test;
# ABSTRACT: A core for the build test
our $VERSION = '0.900004';
1;
PM
$root->child('lib', 'DBIO', 'Test', 'Row.pm')->spew(<<'PM');
package DBIO::Test::Row;
# ABSTRACT: A module lying behind
our $VERSION = '0.900001';
1;
PM
$root->child('LICENSE')->spew(
  Software::License::Perl_5->new({ holder => 'DBIO Authors', year => 2005 })->license);
$root->child('Changes')->spew("Release history for DBIO-Test\n\n{{\$NEXT}}\n    - first\n");
$root->child('cpanfile')->spew("requires 'perl', '5.020';\n");

for my $args (
  [qw(init -q)],
  [qw(remote add origin git@codeberg.org:getty/DBIO-Test.git)],
  [qw(add -A -f)],
  ['-c', 'user.email=test@test.de', '-c', 'user.name=Test', 'commit', '-q', '-m', 'init'],
  [qw(tag v0.900004)],
) {
  system('git', '-C', "$root", @$args) == 0 or die "git @$args failed: $?";
}

my $tzil = Dist::Zilla::Tester->from_config(
  { dist_root => "$root" },
  { tempdir_root => $tempdir, chrome => Dist::Zilla::Chrome::Term->new },
);
$tzil->build;
my $built = path($tzil->tempdir)->child('build');

my $version = $tzil->version;
is $version, '0.900004', 'dist version: the $VERSION of the main module';
is $tzil->distmeta->{version}, $version, 'META version is the dist version';

for my $pm (qw( DBIO/Test.pm DBIO/Test/Row.pm )) {
  like $built->child('lib', $pm)->slurp_utf8,
    qr/^our \$VERSION = '\Q$version\E';$/m, "$pm carries the version of the dist";
}

ok !$built->child('xt', 'release', 'coverage.t')->exists && !$built->child('t', 'release-coverage.t')->exists,
  'the build carries no coverage test';

done_testing;
