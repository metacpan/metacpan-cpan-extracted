use strict;
use warnings;

use Dist::Zilla  1.093250;
use Dist::Zilla::Tester;
use Path::Tiny qw(path);
use Test::More   tests => 8;
use Try::Tiny qw(try);

use lib 't';
use Util qw( chdir_original_cwd clean_environment init_repo );

# Mock HOME to avoid ~/.gitexcludes from causing problems
# and clear GIT_ environment variables
my $homedir = clean_environment;

my $corpus_dir = path('corpus/commit-build-src-as-parent')->absolute;

my $zilla = Dist::Zilla::Tester->from_config({ dist_root => $corpus_dir, });

# build fake repository
chdir path( $zilla->tempdir )->child('source');

my $git = init_repo( qw{ .   dist.ini Changes } );

$zilla->build;
ok( $git->rev_parse('-q', '--verify', 'refs/heads/build/master'), 'source repo has the "build/master" branch')
    or diag $git->branch;
is( scalar $git->log('build/master'), 2, 'two commit on the build/master branch')
    or diag $git->branch;
is( scalar $git->ls_tree('build/master'), 2, 'two files in latest commit on the build/master branch')
    or diag $git->branch;

my @log = $git->log('build/master');

like try {$log[1]->message} => qr/initial commit/, 'master is a parent';
like try {$log[0]->message} => qr/Build results of \w+ \(on master\)/, 'build commit';

chdir_original_cwd;

my $zilla2 = Dist::Zilla::Tester->from_config({
  dist_root => path('corpus/commit-build')->absolute,
});

# build fake repository
chdir path( $zilla2->tempdir )->child('source');
my $git2 = init_repo('.');
$git2->remote('add','origin', path( $zilla->tempdir )->child('source')->stringify);
$git2->fetch;
$git2->reset('--hard','origin/master');
$git2->checkout('-b', 'topic/1');
append_to_file('dist.ini', "\n");
$git2->commit('-a', '-m', 'commit on topic branch');
$zilla2->build;

ok( $git2->rev_parse('-q', '--verify', 'refs/heads/build/topic/1'), 'source repo has the "build/topic/1" branch') or diag $git2->branch;

chdir_original_cwd;
my $zilla3 = Dist::Zilla::Tester->from_config({
  dist_root => path('corpus/commit-build')->absolute,
});

# build fake repository
chdir path($zilla3->tempdir)->child('source');
my $git3 = init_repo('.');
$git3->remote('add','origin', path( $zilla->tempdir )->child('source')->stringify);
$git3->fetch;
$git3->branch('build/master', 'origin/build/master');
$git3->reset('--hard','origin/master');
append_to_file('dist.ini', "\n\n");
$git3->commit('-a', '-m', 'commit on master');
$zilla3->build;
is( scalar $git3->log('build/master'), 3, 'three commits on the build/master branch')
    or diag $git3->branch;
is( scalar $git->ls_tree('build/master'), 2, 'two files in latest commit on the build/master branch')
    or diag $git->branch;

chdir_original_cwd;

sub append_to_file {
    my ($file, @lines) = @_;
    my $fh = path($file)->opena(@lines);
    print $fh @_;
    close $fh;
}
