#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
use IPC::Cmd qw(can_run);

use Dist::Zilla::PluginBundle::Author::GETTY;
use Dist::Zilla::Plugin::Author::GETTY::GiteaMeta;

# Remote detection runs git without a shell (list-form pipe open), so a remote
# name that is hostile to sh and cmd.exe reaches git untouched, and git's own
# complaints never reach the caller's STDERR. Everything runs on fabricated
# repositories in tempdirs; nothing is fetched. (The Windows half is proven by
# a separate probe on windows-latest, not here.)

plan skip_all => "git binary not available" unless can_run('git');

my $B = 'Dist::Zilla::PluginBundle::Author::GETTY';
my $G = 'Dist::Zilla::Plugin::Author::GETTY::GiteaMeta';
my $WEIRD = q{x'&%PATH%};

sub _git {
  my ($dir, @args) = @_;
  system('git', '-C', $dir, @args) == 0 or die "git @args failed in $dir: $?";
}

sub _repo {
  my ($dir) = @_;
  system('git', 'init', '-q', $dir) == 0 or die "git init $dir failed";
  return $dir;
}

# Runs $code in $dir with fd 2 redirected to a file (child processes included);
# returns ($result_list_ref, $captured_stderr). Whatever the code forces
# lazily must be forced inside $code, while the cwd is $dir.
sub _capture_in {
  my ($dir, $code) = @_;
  my $orig    = getcwd();
  my $errfile = File::Temp->new(DIR => tempdir(CLEANUP => 1));
  open my $olderr, '>&', \*STDERR or die "dup: $!";
  open STDERR, '>', $errfile->filename or die "redirect: $!";
  chdir $dir or die "chdir $dir: $!";
  my @res = eval { $code->() };
  my $err = $@;
  chdir $orig or die "chdir back: $!";
  open STDERR, '>&', $olderr or die "restore: $!";
  die $err if $err;
  open my $in, '<', $errfile->filename or die "read: $!";
  my $stderr = do { local $/; <$in> };
  return (\@res, $stderr);
}

subtest 'GiteaMeta reads a shell-hostile remote name' => sub {
  my $dir = _repo(tempdir(CLEANUP => 1));
  _git($dir, 'remote', 'add', $WEIRD, 'https://codeberg.org/getty/p5-www-gitea.git');

  my $plugin = bless { remote => $WEIRD }, $G;
  my ($res, $stderr) = _capture_in($dir, sub { $plugin->_build_remote_info });
  is_deeply $res->[0], { host => 'codeberg.org', slug => 'getty/p5-www-gitea' },
    'host and slug come out of the url of the odd remote';
  is $stderr, '', 'nothing on STDERR (the old form printed a sh syntax error)';
};

subtest 'bundle _remote_urls: origin first, then config order, odd name intact' => sub {
  my $dir = _repo(tempdir(CLEANUP => 1));
  _git($dir, 'remote', 'add', 'upstream', 'https://example.org/up/repo.git');
  _git($dir, 'remote', 'add', $WEIRD,     'https://example.org/odd/repo.git');
  _git($dir, 'remote', 'add', 'origin',   'https://github.com/me/repo.git');

  my ($res, $stderr) = _capture_in($dir, sub { $B->can('_remote_urls')->() });
  is_deeply $res, [
    [ origin     => 'https://github.com/me/repo.git' ],
    [ upstream   => 'https://example.org/up/repo.git' ],
    [ $WEIRD     => 'https://example.org/odd/repo.git' ],
  ], 'origin first, the others in config order, odd name unmangled';
  is $stderr, '', 'nothing on STDERR';
};

subtest 'broken .git/config: empty, undef, silent' => sub {
  my $dir = _repo(tempdir(CLEANUP => 1));
  open my $fh, '>>', "$dir/.git/config" or die "open: $!";
  print $fh "[[broken\n";
  close $fh;

  my ($res, $stderr) = _capture_in($dir, sub {
    my @urls = $B->can('_remote_urls')->();
    my $info = bless({ remote => 'origin' }, $G)->_build_remote_info;
    return (scalar(@urls), $info);
  });
  is $res->[0], 0, 'bundle: no remotes';
  is $res->[1], undef, 'GiteaMeta: no remote info';
  is $stderr, '', "git's exit-128 complaint stays off STDERR";
};

subtest 'no git on PATH: empty, undef, silent' => sub {
  my $dir   = _repo(tempdir(CLEANUP => 1));
  _git($dir, 'remote', 'add', 'origin', 'https://github.com/me/repo.git');
  my $empty = tempdir(CLEANUP => 1);

  my ($res, $stderr) = _capture_in($dir, sub {
    local $ENV{PATH} = $empty;
    my @urls = $B->can('_remote_urls')->();
    my $info = bless({ remote => 'origin' }, $G)->_build_remote_info;
    return (scalar(@urls), $info);
  });
  is $res->[0], 0, 'bundle: no remotes';
  is $res->[1], undef, 'GiteaMeta: no remote info';
  is $stderr, '', 'nothing on STDERR';
};

subtest 'STDERR is restored after the call' => sub {
  my $dir = _repo(tempdir(CLEANUP => 1));
  _git($dir, 'remote', 'add', 'origin', 'https://github.com/me/repo.git');

  my ($res, $stderr) = _capture_in($dir, sub {
    my @urls = $B->can('_remote_urls')->();
    my $info = bless({ remote => 'origin' }, $G)->_build_remote_info;
    print STDERR "after-the-calls\n";
    return (scalar(@urls), $info);
  });
  is $res->[0], 1, 'sanity: the remote was found';
  is $stderr, "after-the-calls\n", 'a write to STDERR after the calls reaches the redirected STDERR';
};

done_testing;
