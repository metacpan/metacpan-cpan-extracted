
use strict;
use warnings;

use Test::More;

# FILENAME: basic.t
# CREATED: 12/07/13 06:28:57 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Simple functionality test.

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
  $file->touch;
  $wrapper->add('testfile');
  $wrapper->commit( '-m', 'Test Commit' );
  ( $tip, ) = $wrapper->rev_parse('HEAD');
  $wrapper->tag( '0.1.0', $tip );
  $wrapper->tag( '0.1.1', $tip );
};

is( $excp, undef, 'Git::Wrapper methods executed without failure' ) or diag $excp;

use Dist::Zilla::Util::Git::Tags;
my $tag_finder = Dist::Zilla::Util::Git::Tags->new( git => $wrapper );

is( scalar $tag_finder->tags, 2, '2 tags found' );
for my $tag ( $tag_finder->tags ) {
  is( $tag->sha1, $tip, 'Found tags report right sha1' );
}
is( scalar keys %{ $tag_finder->tag_sha1_map }, 1, '1 tagged sha1' );
is( scalar $tag_finder->tags_for_rev($tip),     2, '2 tags found from tags_for_rev' );
for my $tag ( $tag_finder->tags_for_rev($tip) ) {
  note $tag->name;
  is( $tag->sha1, $tip, 'Found tags report right sha1' );
}
done_testing;

