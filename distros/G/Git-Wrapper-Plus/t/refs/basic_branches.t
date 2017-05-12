
use strict;
use warnings;

use Test::More;
use Git::Wrapper::Plus::Tester;
use Test::Fatal qw(exception);
use Git::Wrapper::Plus::Support;
use Git::Wrapper::Plus::Refs;

my $t = Git::Wrapper::Plus::Tester->new();
my $s = Git::Wrapper::Plus::Support->new( git => $t->git );

my $file  = $t->repo_dir->child('testfile');
my $rfile = $file->relative( $t->repo_dir )->stringify;
my $tip;

$t->run_env(
  sub {
    my $wrapper = $t->git;
    my $excp    = exception {
      if ( $s->supports_command('init') ) {
        $wrapper->init();
      }
      elsif ( $s->supports_command('init-db') ) {
        $wrapper->init_db();
      }
      else {
        die "No database initialiser supported";
      }

      note 'touch';
      $file->touch;

      note 'git add ' . $rfile;
      $wrapper->add($rfile);

      note 'git commit';
      $wrapper->commit( '-m', 'Test Commit' );
      note 'git checkout -b';
      $wrapper->checkout( '-b', 'master_2' );
      $file->spew('New Content');
      if ( $s->supports_behavior('add-updates-index') ) {
        note 'git add ' . $rfile;
        $wrapper->add($rfile);
      }
      else {
        note 'git update-index ' . $rfile;
        $wrapper->update_index($rfile);
      }
      note 'git commit';
      $wrapper->commit( '-m', 'Test Commit 2' );
      note 'git checkout -b';
      $wrapper->checkout( '-b', 'master_3' );

      ( $tip, ) = $wrapper->rev_parse('HEAD');
    };

    is( $excp, undef, 'Git::Wrapper methods executed without failure' ) or diag $excp;

    my $branch_finder = Git::Wrapper::Plus::Refs->new( git => $wrapper );

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
  }
);
done_testing;

