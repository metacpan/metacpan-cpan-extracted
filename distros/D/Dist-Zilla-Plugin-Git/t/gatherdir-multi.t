# Test multiple instances of Git::GatherDir (including prefix)

use strict;
use warnings;

use Dist::Zilla     1.093250;
use Test::DZil;
use Path::Tiny 0.012 qw( path );
use Test::More 0.88 tests => 8; # done_testing

use lib 't';
use Util;

# Mock HOME to avoid ~/.gitexcludes from causing problems
my $homedir = clean_environment;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/gatherdir' },
  {
    add_files => {
      'source/tracked'            => "tracked\n",
      'source/untracked'          => "do not load untracked\n",
      'source/subdir/tracked'     => "subdir/tracked\n",
      'source/dist.ini'           => simple_ini(
        [ 'Git::GatherDir' ],
        [ 'Git::GatherDir', 'GatherRepo1', => {
          root => '../repo1',
        }],
        [ 'Git::GatherDir', 'GatherRepo2s', => {
          root => '../repo2/subdir',
          include_untracked => 1,
        }],
        [ 'Git::GatherDir', 'GatherRepo3s', => {
          root => '../repo3/subdir',
          prefix => 'r3',
        }],
      ),
      'repo1/r1-tracked'          => "r1-tracked\n",
      'repo1/r1-untracked'        => "do not load r1-untracked\n",
      'repo1/subdir/r1s-tracked'  => "subdir/r1s-tracked\n",
      'repo1/subdir/r1s-untracked'=> "do not load subdir/r1s-untracked\n",
      'repo2/r2r-tracked'         => "do not load r2r-tracked\n",
      'repo2/r2r-untracked'       => "do not load r2r-untracked\n",
      'repo2/subdir/r2-tracked'   => "r2-tracked\n",
      'repo2/subdir/r2-untracked' => "r2-untracked\n",
      'repo3/r3r-tracked'         => "do not load r3r-tracked\n",
      'repo3/r3r-untracked'       => "do not load r3r-untracked\n",
      'repo3/subdir/r3-tracked'   => "r3/r3-tracked\n",
      'repo3/subdir/r3-untracked' => "do not load r3/r3-untracked\n",
   },
  },
);

my $base = path($tzil->tempdir);

my $git = init_repo( $base->child('source')->stringify,
                     qw(dist.ini lib subdir tracked) );

init_repo( $base->child('repo1')->stringify,
           qw(r1-tracked subdir/r1s-tracked) );
init_repo( $base->child('repo2')->stringify,
           qw(r2r-tracked subdir/r2-tracked) );
init_repo( $base->child('repo3')->stringify,
           qw(r3r-tracked subdir/r3-tracked) );

$tzil->build;

my $files = $tzil->files;
my @expected_files = qw(
  dist.ini lib/DZT/Sample.pm
  r1-tracked
  r2-tracked r2-untracked
  r3/r3-tracked
  subdir/r1s-tracked subdir/tracked
  tracked
);

# diag($_) for @{ $tzil->log_messages };

is_deeply(
  [ sort map {; $_->name } @$files ],
  \@expected_files,
  "the right files were gathered",
);

my %content =  map {; $_->name => $_->content } @$files;


for my $fn (@expected_files) {
  next unless $fn =~ /track/;

  is($content{$fn}, "$fn\n", "content of $fn");
}

done_testing;
