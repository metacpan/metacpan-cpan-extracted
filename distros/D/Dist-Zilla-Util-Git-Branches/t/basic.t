
use strict;
use warnings;

use Test::More;

use Path::Tiny qw(path);

my $tempdir = Path::Tiny->tempdir;
my $repo    = $tempdir->child('git-repo');
my $home    = $tempdir->child('homedir');

local $ENV{HOME}                = $home->absolute->stringify;
local $ENV{GIT_AUTHOR_NAME}     = 'A. U. Thor';
local $ENV{GIT_AUTHOR_EMAIL}    = 'author@example.org';
local $ENV{GIT_COMMITTER_NAME}  = 'A. U. Thor';
local $ENV{GIT_COMMITTER_EMAIL} = 'author@example.org';

$repo->mkpath;
my $file = $repo->child('testfile');

use Dist::Zilla::Util::Git::Wrapper;
use Git::Wrapper;

my $git = Git::Wrapper->new( $tempdir->child('git-repo') );
my $wrapper = Dist::Zilla::Util::Git::Wrapper->new( git => $git );

sub report_ctx {
  my (@lines) = @_;
  note explain \@lines;
}

$wrapper->init();
$file->touch;
$wrapper->add($file);
$wrapper->commit( '-m', 'Test Commit' );
$wrapper->checkout( '-b', 'master_2' );
$file->spew('New Content');
$wrapper->add($file);
$wrapper->commit( '-m', 'Test Commit 2' );
$wrapper->checkout( '-b', 'master_3' );

my ( $tip, ) = $wrapper->rev_parse('HEAD');
pass('Git::Wrapper methods executed without failure');

use Dist::Zilla::Util::Git::Branches;
my $branch_finder = Dist::Zilla::Util::Git::Branches->new( git => $wrapper );

is( $branch_finder->current_branch->name, 'master_3', 'master_3 exists' );
is( scalar $branch_finder->branches,      3,          '3 Branches found' );
my $branches = {};
for my $branch ( $branch_finder->branches ) {
  $branches->{ $branch->name } = $branch;
}
ok( exists $branches->{master},   'master branch found' );
ok( exists $branches->{master_2}, 'master_2 branch found' );
ok( exists $branches->{master_3}, 'master_3 branch found' );
is( $branches->{master_2}->sha1, $branches->{master_3}->sha1, 'master_2 and master_3 have the same sha1' );

done_testing;

