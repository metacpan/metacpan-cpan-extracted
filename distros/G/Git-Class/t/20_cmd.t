use strict;
use warnings;
use Test::More;
use Git::Class::Cmd;
use Path::Tiny qw/path cwd tempdir/;

my $cwd;
BEGIN { $cwd = cwd; }

my $dir = tempdir(CLEANUP => 1);
chdir $dir;

my $cmd = Git::Class::Cmd->new(verbose => 1);
plan skip_all => 'git is not available' unless $cmd->is_available;

local $ENV{GIT_CLASS_TRACE} = 1;

subtest 'init' => sub {
  is cwd() => $dir, "current directory is correct";

  my $got = $cmd->git('init');

  ok $got, "initialized local repository";
  ok !$cmd->_error, 'and no error';

  ok $dir->child('.git')->is_dir, '.git exists';
};

subtest 'config' => sub {
  unless ($dir->child('.git')->is_dir) {
    note 'not in a local repository';
    return;
  }

  my $got = $cmd->config('user.email' => 'test@localhost');

  ok !$cmd->_error, 'set local user.email without errors';

  $got = $cmd->config('user.name' => 'foo bar');

  ok !$cmd->_error, 'set local user.name without errors';

  my $config = $dir->child('.git/config')->slurp;
  like $config => qr/email\s*=\s*test\@localhost/, "contains user.email";
  like $config => qr/name\s*=\s*(['"]?)foo bar\1/, "contains user.name";
};

subtest 'add' => sub {
  unless ($dir->child('.git')->is_dir) {
    note 'not in a local repository';
    return;
  }

  my $file = $dir->child('README');
  $file->spew('readme');
  ok $file->is_file, "created README file";

  my $got = $cmd->git('add', 'README');

  ok !$cmd->_error, 'added README to the local repository without errors';
};

subtest 'commit' => sub {
  unless ($dir->child('.git')->is_dir) {
    note 'not in a local repository';
    return;
  }

  my $got = $cmd->git('commit', { message => 'committed README', author => 'A U Thor <author@example.com>' });

  ok $got, "committed to the local repository";
  ok !$cmd->_error, 'and no error';
};

done_testing;

END {
  chdir $cwd if $cwd ne cwd;
  $dir->remove_tree({safe => 0}) if $dir;
}
