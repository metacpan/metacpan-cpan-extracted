use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

use Dist::Zilla::PluginBundle::Author::GETTY;

# The bundle additively picks Author::GETTY::GiteaMeta for Gitea/Forgejo-hosted
# dists, while GitHub dists keep GithubMeta. A dist is treated as Gitea when its
# remote host is a known Gitea host (codeberg.org, src.ci) or when gitea = 1 is
# set. This pins _remote_host extraction and the _is_gitea_remote decision.

sub _write_git_config {
  my ($dir, $remote_url) = @_;
  system('git', 'init', '-q', $dir) == 0 or die "git init $dir failed";
  open my $fh, '>>', "$dir/.git/config" or die "open: $!";
  if (defined $remote_url) {
    print $fh "[remote \"origin\"]\n";
    print $fh "\turl = $remote_url\n";
    print $fh "\tfetch = +refs/heads/*:refs/remotes/origin/*\n";
  }
  close $fh;
}

sub _detect_in_dir {
  my ($dir, $payload) = @_;
  my $orig_cwd = getcwd();
  chdir $dir or die "chdir $dir: $!";
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => $payload // {},
  );
  my %r = (
    host       => $bundle->_remote_host,
    is_gitea   => $bundle->_is_gitea_remote ? 1 : 0,
    has_github => $bundle->_has_github_remote ? 1 : 0,
    no_github  => $bundle->no_github ? 1 : 0,
  );
  chdir $orig_cwd or die "chdir back: $!";
  return \%r;
}

subtest 'known host codeberg.org -> gitea (no flag needed)' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'https://codeberg.org/getty/p5-www-gitea.git');
  my $r = _detect_in_dir($dir);
  is $r->{host},     'codeberg.org', 'remote host extracted (https)';
  is $r->{is_gitea}, 1,              'codeberg.org is a known gitea host';
  is $r->{no_github}, 1,             'no github -> gitea branch taken';
};

subtest 'known host src.ci (ssh) -> gitea' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'git@src.ci:getty/some-dist.git');
  my $r = _detect_in_dir($dir);
  is $r->{host},     'src.ci', 'remote host extracted (ssh scp-form)';
  is $r->{is_gitea}, 1,        'src.ci is a known gitea host';
};

subtest 'github remote -> NOT gitea (github wins)' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'git@github.com:getty/some-dist.git');
  my $r = _detect_in_dir($dir);
  is $r->{has_github}, 1, 'github detected';
  is $r->{is_gitea},   0, 'github is not gitea';
};

subtest 'unknown host without flag -> not gitea (Repository fallback)' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'git@gitlab.com:getty/some-dist.git');
  my $r = _detect_in_dir($dir);
  is $r->{host},     'gitlab.com', 'host still extracted';
  is $r->{is_gitea}, 0,            'unknown host is not gitea without the flag';
};

subtest 'unknown host WITH gitea = 1 -> gitea for that host' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _write_git_config($dir, 'https://git.example.com/getty/some-dist.git');
  my $r = _detect_in_dir($dir, { gitea => 1 });
  is $r->{host},     'git.example.com', 'self-hosted host extracted';
  is $r->{is_gitea}, 1,                 'gitea = 1 forces gitea for the remote host';
};

subtest 'no remote at all -> not gitea (even with the flag)' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $r = _detect_in_dir($dir, { gitea => 1 });
  is $r->{host},     undef, 'no remote host';
  is $r->{is_gitea}, 0,     'nothing to build META from';
};

# Detection asks git, so it must see through a linked worktree (where .git is a
# file) and must prefer origin to whatever remote happens to be listed first.
sub _git { my ($dir, @cmd) = @_; system('git', '-C', $dir, @cmd) == 0 or die "git @cmd failed" }

subtest 'linked worktree -> remote still found' => sub {
  my $main = tempdir(CLEANUP => 1);
  _git($main, 'init', '-q');
  _git($main, qw(-c user.name=t -c user.email=t@t commit -q --allow-empty -m init));
  _git($main, qw(remote add origin git@codeberg.org:getty/some-dist.git));
  my $wt = "$main/wt";
  _git($main, qw(worktree add -q), $wt);
  ok -f "$wt/.git", 'the worktree has a .git file, not a directory';
  my $r = _detect_in_dir($wt);
  is $r->{host},     'codeberg.org', 'host found through the worktree';
  is $r->{is_gitea}, 1,              'and gitea decided';
};

subtest 'origin wins over an earlier remote' => sub {
  my $dir = tempdir(CLEANUP => 1);
  _git($dir, 'init', '-q');
  _git($dir, qw(remote add mirror git@gitlab.com:getty/some-dist.git));
  _git($dir, qw(remote add origin git@codeberg.org:getty/some-dist.git));
  my $r = _detect_in_dir($dir);
  is $r->{host},     'codeberg.org', 'host is the one of origin, not of the first remote';
  is $r->{is_gitea}, 1,              'so GiteaMeta gets a host it will accept';
};

done_testing;
