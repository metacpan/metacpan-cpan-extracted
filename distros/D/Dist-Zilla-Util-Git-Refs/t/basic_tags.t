
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
  $file->touch;
  $wrapper->add('testfile');
  $wrapper->commit( '-m', 'Test Commit' );
  ( $tip, ) = $wrapper->rev_parse('HEAD');
  $wrapper->tag( '0.1.0', $tip );
  $wrapper->tag( '0.1.1', $tip );
};

is( $excp, undef, 'Git::Wrapper methods executed without failure' ) or diag $excp;

use Dist::Zilla::Util::Git::Refs;
my $ref_finder = Dist::Zilla::Util::Git::Refs->new( git => $wrapper );

my $sha1s = {};

is( scalar $ref_finder->get_ref('refs/tags/**'), 2, '2 refs found in tags/' );
for my $tag ( $ref_finder->get_ref('refs/tags/**') ) {
  $sha1s->{ $tag->sha1 } = $tag;
  is( $tag->sha1, $tip, 'Found tags report right sha1' );
}
is( scalar keys %{$sha1s}, 1, '1 tagged sha1' );
done_testing;
