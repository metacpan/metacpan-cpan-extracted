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

# Builds a small driver dist with [@DBIO] end to end and looks at what comes out:
# META (name, version, prereqs, resources), Makefile.PL, the woven COPYRIGHT
# section, the script from bin/ and the shipped skill.

my $tempdir = tempdir(CLEANUP => 1);
my $root    = path($tempdir, 'dist');
$root->child('lib', 'DBIO')->mkpath;
$root->child('bin')->mkpath;
$root->child('.claude', 'skills', 'dbio-test')->mkpath;

$root->child('dist.ini')->spew(<<'INI');
name = DBIO-Test
copyright_year = 2005

[@DBIO]
eumm_version = 7.1101
share_skill = dbio-test
INI
$root->child('lib', 'DBIO', 'Test.pm')->spew(<<'PM');
package DBIO::Test;
# ABSTRACT: A driver for the build test
our $VERSION = '0.900004';
use strict;
use warnings;

=method hello

Says hello.

=cut

sub hello { 'hello' }

1;
PM
$root->child('bin', 'dbio-test-tool')->spew(<<'PL');
#!/usr/bin/env perl
# PODNAME: dbio-test-tool
# ABSTRACT: A script of the build test
use strict;
use warnings;
print "tool\n";
PL
$root->child('LICENSE')->spew(
  Software::License::Perl_5->new({ holder => 'DBIO Authors', year => 2005 })->license);
$root->child('Changes')->spew("Release history for DBIO-Test\n\n{{\$NEXT}}\n    - first\n");
$root->child('cpanfile')->spew(
  "requires 'perl', '5.020';\nrequires 'DBIO', '0.900005';\non test => sub { requires 'Test::More'; };\n");
$root->child('.claude', 'skills', 'dbio-test', 'SKILL.md')->spew("owned skill\n");

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

# --- META ---
my $meta = $tzil->distmeta;
is $meta->{name}, 'DBIO-Test', 'META name';
is $meta->{version}, '0.900004', 'META version: the $VERSION of the main module';
is_deeply $meta->{license}, ['perl_5'], 'META license';
is_deeply $meta->{author}, ['DBIO Authors'], 'META author';
is $meta->{prereqs}{runtime}{requires}{DBIO}, '0.900005', 'META runtime prereq DBIO from the cpanfile';
is $meta->{prereqs}{runtime}{requires}{perl}, '5.020', 'META runtime prereq perl';
ok exists $meta->{prereqs}{test}{requires}{'Test::More'}, 'META test prereq from the cpanfile';
is $meta->{resources}{repository}{url}, 'https://codeberg.org/getty/DBIO-Test.git',
  'META repository from the git remote';
is $meta->{resources}{bugtracker}{web}, 'https://codeberg.org/getty/DBIO-Test/issues',
  'META bugtracker';
is $meta->{resources}{x_IRC}, 'irc://irc.perl.org/#dbio', 'META IRC channel';
ok exists $meta->{provides}{'DBIO::Test'}, 'META provides the module';

# --- files ---
ok $built->child('META.json')->is_file, 'META.json built';
ok $built->child('META.yml')->is_file,  'META.yml built';
ok $built->child('Makefile.PL')->is_file, 'Makefile.PL built';
like $built->child('Makefile.PL')->slurp_utf8, qr{bin/dbio-test-tool},
  'Makefile.PL installs the script from bin/';
like $built->child('Makefile.PL')->slurp_utf8, qr/DBIO-Test/, 'Makefile.PL names the dist';

like $built->child('Makefile.PL')->slurp_utf8, qr/use ExtUtils::MakeMaker 7\.1101;/,
  'Makefile.PL asks for the eumm_version';
is $meta->{prereqs}{configure}{requires}{'ExtUtils::MakeMaker'}, '7.1101',
  'META configure_requires carries the eumm_version';

# --- woven POD ---
my $pm = $built->child('lib', 'DBIO', 'Test.pm')->slurp_utf8;
like $pm, qr/^=head1 COPYRIGHT AND LICENSE$/m, 'module has a COPYRIGHT AND LICENSE section';
like $pm, qr/^Copyright \(C\) 2026 DBIO Authors$/m, 'copyright line of the DBIO code';
like $pm, qr/^=head2 hello$/m, '=method woven into METHODS';
like $built->child('bin', 'dbio-test-tool')->slurp_utf8, qr/^=head1 NAME$/m,
  'script from bin/ is woven';

# --- the coverage gate is no generated test ---
ok !$built->child('xt', 'release', 'coverage.t')->exists && !$built->child('t', 'release-coverage.t')->exists,
  'the build carries no coverage test';

# --- the shipped skill ---
ok $built->child('share', 'skills', 'dbio-test', 'SKILL.md')->is_file, 'SKILL.md ships';

done_testing;
