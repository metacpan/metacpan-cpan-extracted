use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

use Dist::Zilla::PluginBundle::Author::GETTY;

# Helpers -----------------------------------------------------------------

sub _write_git_config {
  my ($dir, $remote_url) = @_;
  mkdir "$dir/.git" or die "mkdir $dir/.git: $!";
  open my $fh, '>', "$dir/.git/config" or die "open: $!";
  if (defined $remote_url) {
    print $fh "[remote \"origin\"]\n";
    print $fh "\turl = $remote_url\n";
    print $fh "\tfetch = +refs/heads/*:refs/remotes/origin/*\n";
  }
  close $fh;
}

sub _bundle_in_dir {
  my ($dir, $payload) = @_;
  my $orig_cwd = getcwd();
  chdir $dir or die "chdir $dir: $!";
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => $payload // {},
  );
  # Force the lazy attributes while we're still in the right cwd.
  my $no_github         = $bundle->no_github         ? 1 : 0;
  my $no_github_release = $bundle->no_github_release ? 1 : 0;
  my $has_remote        = $bundle->_has_github_remote ? 1 : 0;
  chdir $orig_cwd or die "chdir back: $!";
  return {
    no_github         => $no_github,
    no_github_release => $no_github_release,
    has_remote        => $has_remote,
  };
}

# Tests -------------------------------------------------------------------

subtest 'github remote -> github plugins enabled' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'git@github.com:getty/some-dist.git');
  my $r = _bundle_in_dir($dir);
  is $r->{has_remote},        1, 'github remote detected';
  is $r->{no_github},         0, 'no_github stays 0';
  is $r->{no_github_release}, 0, 'no_github_release stays 0';
};

subtest 'https github remote also detected' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'https://github.com/getty/some-dist.git');
  my $r = _bundle_in_dir($dir);
  is $r->{has_remote}, 1, 'https github remote detected';
  is $r->{no_github},  0, 'no_github stays 0';
};

subtest 'non-github remote -> github plugins auto-disabled' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'git@gitlab.com:getty/some-dist.git');
  my $r = _bundle_in_dir($dir);
  is $r->{has_remote},        0, 'no github remote';
  is $r->{no_github},         1, 'no_github auto-set to 1';
  is $r->{no_github_release}, 1, 'no_github_release auto-set to 1';
};

subtest 'no .git/config at all -> github plugins auto-disabled' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $r = _bundle_in_dir($dir);
  is $r->{has_remote},        0, 'no .git/config means no remote';
  is $r->{no_github},         1, 'no_github auto-set to 1';
  is $r->{no_github_release}, 1, 'no_github_release auto-set to 1';
};

subtest 'explicit no_github = 0 wins over detection' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'git@gitlab.com:getty/some-dist.git');
  my $r = _bundle_in_dir($dir, { no_github => 0, no_github_release => 0 });
  is $r->{no_github},         0, 'explicit no_github = 0 honored';
  is $r->{no_github_release}, 0, 'explicit no_github_release = 0 honored';
};

subtest 'explicit no_github = 1 wins even with github remote' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'git@github.com:getty/some-dist.git');
  my $r = _bundle_in_dir($dir, { no_github => 1, no_github_release => 1 });
  is $r->{no_github},         1, 'explicit no_github = 1 honored';
  is $r->{no_github_release}, 1, 'explicit no_github_release = 1 honored';
};

done_testing;
