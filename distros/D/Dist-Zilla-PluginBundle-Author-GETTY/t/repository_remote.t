#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);

use Dist::Zilla::PluginBundle::Author::GETTY;

# [Repository] falls back to `git svn info` ("git: 'svn' is not a git command")
# when there is no remote to report, so without any remote the bundle adds no
# repository plugin at all. Remote detection runs on a fabricated .git/config;
# nothing is fetched or pushed.

sub _repo {
  my ($dir, %remotes) = @_;
  system('git', 'init', '-q', $dir) == 0 or die "git init $dir failed";
  open my $fh, '>>', "$dir/.git/config" or die "open: $!";
  for my $name (sort keys %remotes) {
    print $fh "[remote \"$name\"]\n\turl = $remotes{$name}\n\tfetch = +refs/heads/*:refs/remotes/$name/*\n";
  }
  close $fh;
  return $dir;
}

# The cwd-dependent lazy attributes and configure() are forced inside $dir.
# Like _repo, but the remotes are written in the given order (name => url pairs).
sub _repo_ordered {
  my ($dir, @pairs) = @_;
  system('git', 'init', '-q', $dir) == 0 or die "git init $dir failed";
  open my $fh, '>>', "$dir/.git/config" or die "open: $!";
  while (my ($name, $url) = splice @pairs, 0, 2) {
    print $fh "[remote \"$name\"]\n\turl = $url\n\tfetch = +refs/heads/*:refs/remotes/$name/*\n";
  }
  close $fh;
  return $dir;
}

# The [Repository] entries of the plugin list: [name, class, config] each.
sub _repository_entries {
  my ($r) = @_;
  return grep { $_->[1] =~ /(?:\A|::)Repository\z/ } @{ $r->{plugins} };
}

sub _in_dir {
  my ($dir, $payload) = @_;
  my $orig = getcwd();
  chdir $dir or die "chdir $dir: $!";
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => $payload // {},
  );
  my $has_remote = $bundle->_has_remote ? 1 : 0;
  # forced here, while the cwd is the fabricated repository (can: a missing attribute fails the _remote_name tests, not the file)
  my $remote_name = $bundle->can('_remote_name') ? $bundle->_remote_name : undef;
  $bundle->configure;
  chdir $orig or die "chdir back: $!";
  my %seen = map { $_->[1] => $_->[2] } @{ $bundle->plugins };
  return { has_remote => $has_remote, remote_name => $remote_name, classes => \%seen, plugins => $bundle->plugins };
}


# A plugin class is stored fully qualified or as the short name given to add_plugins.
sub _repo_plugins {
  my ($r) = @_;
  my @found = sort map { /(?:\A|::)(GithubMeta|GiteaMeta|Repository)\z/ ? $1 : () } keys %{ $r->{classes} };
  return join ',', @found;
}

subtest '_has_remote' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1)));
  is $r->{has_remote}, 0, 'git repository without a remote: 0';

  $r = _in_dir(tempdir(CLEANUP => 1));
  is $r->{has_remote}, 0, 'no .git at all: 0';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'git@gitlab.com:getty/some-dist.git'));
  is $r->{has_remote}, 1, 'an origin: 1';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), upstream => 'https://example.com/getty/some-dist.git'));
  is $r->{has_remote}, 1, 'only a remote named upstream: 1';
};

subtest 'no remote -> no repository plugin' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1)));
  is _repo_plugins($r), '', 'neither Repository nor GithubMeta nor GiteaMeta';
};

subtest 'no .git at all -> no repository plugin' => sub {
  my $r = _in_dir(tempdir(CLEANUP => 1));
  is _repo_plugins($r), '', 'neither Repository nor GithubMeta nor GiteaMeta';
};

subtest 'no_github = 0 without a remote -> GithubMeta as before' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1)), { no_github => 0 });
  is _repo_plugins($r), 'GithubMeta', 'explicit no_github = 0 keeps GithubMeta';
};

subtest 'other remote -> Repository' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'git@gitlab.com:getty/some-dist.git'));
  is _repo_plugins($r), 'Repository', 'gitlab origin: Repository only';
};

subtest 'only a non-origin remote -> Repository' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), upstream => 'https://example.com/getty/some-dist.git'));
  is _repo_plugins($r), 'Repository', 'upstream only: Repository';
};

subtest 'no_github = 1 with a github remote -> Repository' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'git@github.com:getty/some-dist.git'), { no_github => 1 });
  is _repo_plugins($r), 'Repository', 'explicit no_github = 1: Repository, no GithubMeta';
};

subtest 'github origin -> GithubMeta as before' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'https://github.com/getty/p5-some-dist.git'));
  is _repo_plugins($r), 'GithubMeta', 'GithubMeta only';
};

subtest 'codeberg origin -> GiteaMeta as before' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'https://codeberg.org/getty/p5-some-dist.git'));
  is _repo_plugins($r), 'GiteaMeta', 'GiteaMeta only';
};

subtest '_remote_name' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'git@github.com:getty/some-dist.git'));
  is $r->{remote_name}, 'origin', 'an origin: origin';

  $r = _in_dir(_repo_ordered(tempdir(CLEANUP => 1),
    zeta => 'https://example.com/a.git', origin => 'https://example.com/b.git', alpha => 'https://example.com/c.git'));
  is $r->{remote_name}, 'origin', 'origin wins over remotes that come first in the config';

  $r = _in_dir(_repo_ordered(tempdir(CLEANUP => 1),
    zeta => 'https://example.com/a.git', alpha => 'https://example.com/c.git'));
  is $r->{remote_name}, 'zeta', 'no origin: the first remote of the config (not the alphabetically first)';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), upstream => 'https://gitlab.com/getty/some-dist.git'));
  is $r->{remote_name}, 'upstream', 'only an upstream: upstream';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1)));
  is $r->{remote_name}, undef, 'no remote: undef';

  $r = _in_dir(tempdir(CLEANUP => 1));
  is $r->{remote_name}, undef, 'no .git at all: undef';
};

subtest '[Repository] is pointed at the remote it can read' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), upstream => 'https://gitlab.com/getty/some-dist.git'));
  my @e = _repository_entries($r);
  is scalar(@e), 1, 'only an upstream (gitlab): one [Repository]';
  is_deeply $e[0][2], { git_remote => 'upstream' }, '... with git_remote = upstream';

  $r = _in_dir(_repo_ordered(tempdir(CLEANUP => 1),
    zeta => 'https://example.com/a.git', alpha => 'https://example.com/c.git'));
  @e = _repository_entries($r);
  is_deeply $e[0][2], { git_remote => 'zeta' }, 'several remotes, no origin: git_remote = the first one';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'git@gitlab.com:getty/some-dist.git'));
  @e = _repository_entries($r);
  is scalar(@e), 1, 'a gitlab origin: one [Repository]';
  is_deeply $e[0][2], {}, '... without any payload, exactly as before (it reads origin by default)';

  $r = _in_dir(_repo_ordered(tempdir(CLEANUP => 1),
    upstream => 'https://example.com/a.git', origin => 'https://gitlab.com/getty/some-dist.git'));
  @e = _repository_entries($r);
  is_deeply $e[0][2], {}, 'origin and upstream: origin wins, no payload';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'git@github.com:getty/some-dist.git'), { no_github => 1 });
  @e = _repository_entries($r);
  is_deeply $e[0][2], {}, 'github origin with no_github = 1: Repository without payload';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1)));
  is scalar(_repository_entries($r)), 0, 'no remote: no [Repository] at all';
};

# The payload of the one plugin whose class ends in ::$short (or is $short).
sub _meta_payload {
  my ($r, $short) = @_;
  my @e = grep { $_->[1] =~ /(?:\A|::)\Q$short\E\z/ } @{ $r->{plugins} };
  return @e ? $e[0][2] : undef;
}

subtest 'GithubMeta and GiteaMeta are pointed at the remote too' => sub {
  my $r = _in_dir(_repo(tempdir(CLEANUP => 1), upstream => 'https://github.com/x/y.git'));
  is_deeply _meta_payload($r, 'GithubMeta'), { issues => 1, remote => 'upstream' },
    'only a github upstream: GithubMeta remote = upstream';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), upstream => 'https://codeberg.org/x/y.git'));
  is_deeply _meta_payload($r, 'GiteaMeta'), { issues => 1, host => 'codeberg.org', remote => 'upstream' },
    'only a codeberg upstream: GiteaMeta remote = upstream';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'https://github.com/x/y.git'));
  is_deeply _meta_payload($r, 'GithubMeta'), { issues => 1 }, 'github origin: no remote key';

  $r = _in_dir(_repo(tempdir(CLEANUP => 1), origin => 'https://codeberg.org/x/y.git'));
  is_deeply _meta_payload($r, 'GiteaMeta'), { issues => 1, host => 'codeberg.org' }, 'codeberg origin: no remote key';

  $r = _in_dir(_repo_ordered(tempdir(CLEANUP => 1),
    upstream => 'https://github.com/x/y.git', origin => 'https://github.com/x/y.git'));
  is_deeply _meta_payload($r, 'GithubMeta'), { issues => 1 }, 'github origin + upstream: no remote key';

  $r = _in_dir(_repo_ordered(tempdir(CLEANUP => 1),
    upstream => 'https://codeberg.org/x/y.git', origin => 'https://codeberg.org/x/y.git'));
  is_deeply _meta_payload($r, 'GiteaMeta'), { issues => 1, host => 'codeberg.org' }, 'codeberg origin + upstream: no remote key';
};

done_testing;
