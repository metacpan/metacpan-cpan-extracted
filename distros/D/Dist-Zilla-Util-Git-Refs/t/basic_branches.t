
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
use Test::Fatal qw(exception);
use Sort::Versions;

my $wrapper = Dist::Zilla::Util::Git::Wrapper->new( git => Git::Wrapper->new( $tempdir->child('git-repo') ) );

our ($IS_ONE_FIVE_PLUS);

if ( versioncmp( $wrapper->version, '1.5' ) > 0 ) {
  note "> 1.5";
  $IS_ONE_FIVE_PLUS = 1;
}

sub report_ctx {
  my (@lines) = @_;
  note explain \@lines;
}

my $tip;

my $excp = exception {
  if ($IS_ONE_FIVE_PLUS) {
    $wrapper->init();
  }
  else {
    $wrapper->init_db();
  }
  note 'touch';
  $file->touch;

  note 'git add ' . $file->relative($repo);
  $wrapper->add( $file->relative($repo) );
  note 'git commit';
  $wrapper->commit( '-m', 'Test Commit' );
  note 'git checkout -b';
  $wrapper->checkout( '-b', 'master_2' );
  $file->spew('New Content');
  if ($IS_ONE_FIVE_PLUS) {
    note 'git add ' . $file->relative($repo);
    $wrapper->add( $file->relative($repo) );
  }
  else {
    note 'git update-index ' . $file->relative($repo);
    $wrapper->update_index( $file->relative($repo) );
  }
  note 'git commit';
  $wrapper->commit( '-m', 'Test Commit 2' );
  note 'git checkout -b';
  $wrapper->checkout( '-b', 'master_3' );

  ( $tip, ) = $wrapper->rev_parse('HEAD');
};

is( $excp, undef, 'Git::Wrapper methods executed without failure' ) or do {
  diag $excp;
  print "$tempdir\n";
  system('urxvt');
};

use Dist::Zilla::Util::Git::Refs;
my $branch_finder = Dist::Zilla::Util::Git::Refs->new( git => $wrapper );

is( scalar $branch_finder->get_ref('refs/heads/**'), 3, '3 Branches found' );
my $branches = {};
for my $branch ( $branch_finder->get_ref('refs/heads/**') ) {
  $branches->{ $branch->name } = $branch;
}
ok( exists $branches->{'refs/heads/master'},   'master branch found' );
ok( exists $branches->{'refs/heads/master_2'}, 'master_2 branch found' );
ok( exists $branches->{'refs/heads/master_3'}, 'master_3 branch found' );
is(
  $branches->{'refs/heads/master_2'}->sha1,
  $branches->{'refs/heads/master_3'}->sha1,
  'master_2 and master_3 have the same sha1'
);

done_testing;

