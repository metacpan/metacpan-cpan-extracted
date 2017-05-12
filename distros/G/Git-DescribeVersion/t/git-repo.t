# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;
use Git::DescribeVersion ();
use File::Temp qw( tempdir );
use Cwd qw( cwd ); # core

# for debugging test reports: only print output upon failure
my $failed = 0;
my @exe_output;

plan skip_all => '"git" command not available'
  if exe(qw(git --version)) != 0;

plan tests => 3 * 2;

# need to cd back to let dir get removed
my $oldpwd = cwd;
my $dir = tempdir( CLEANUP => 1 );
chdir "$dir" or die "failed to chdir: $!";

my $path = 'git-dv.txt';
append($path, 'foo');

exe(@$_) for (
  [qw(git), (qx/git --version/ =~ /(\d+\.\d+)/)[0] < 1.5 ? 'init-db' : 'init'],
  [qw(git config user.name GitDV)],
  [qw(git config user.email gitdv@example.org)],
  [qw(git add), $path],
  [qw(git commit -m foo)],
  [qw(git tag -a -m v1 v1.001)],
);

append($path, 'bar');
exe(qw(git commit -q -m bar), $path);

my $exp_version = '1.001001';

test_all();
{
  # test operations with alternate record separator (rt-71622)
  local $/ = "\n\n";
  test_all();
}

diag join("\n", @exe_output) if $failed;

chdir $oldpwd or die "chdir back failed: $!";

sub test_all {
  SKIP: {
    skip 'Git::Repository not available' => 1
      if ! eval { require Git::Repository };

    my $gdv = Git::DescribeVersion->new(git_repository => 1);
    is $gdv->version, $exp_version, 'tag from Git::Repository'
      or $failed++;
  }

  SKIP: {
    skip 'Git::Wrapper not available' => 1
      if ! eval { require Git::Wrapper };

    my $gdv = Git::DescribeVersion->new(git_wrapper => 1);
    is $gdv->version, $exp_version, 'tag from Git::Wrapper'
      or $failed++;
  }

  {
    my ($opt, $mod) = qw(git_backticks backticks);

    my $gdv = Git::DescribeVersion->new(git_backticks => 1);
    is $gdv->version, $exp_version, 'tag from backticks'
      or $failed++;
  }
}

sub append {
  my $path = shift;
  open(my $fh, '>>', $path)
    or die "failed to open $path: $!";
  print $fh "gdv\n";
  close $fh;
}

sub exe {
  local $, = ' ';
  my $out = qx/@_/; # 2>&1 ?
  my $status = $?;
  chomp $out;
  # for debugging test reports:
  push @exe_output, "@_: $out ($status)";
  return $status;
}
