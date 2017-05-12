use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

my $tempdir = no_git_tempdir();
my $tzil = Builder->from_config(
  { dist_root => 't/does-not-exist' },
  {
    add_files => {
      path(qw(source dist.ini)) => simple_ini(
        [ GatherDir => ],
        [ 'Git::Describe' ],
      ),
      path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
    },
    tempdir_root => $tempdir->stringify,
  },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
$git->commit({ message => 'first commit', author => 'Hey Jude <jude@example.org>' });

$tzil->chrome->logger->set_debug(1);

is(
  exception { $tzil->build },
  undef,
  'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(lib Foo.pm));
my $content = $file->slurp_utf8;

like(
  $content,
  qr/\Apackage Foo;\n# git description: [0-9a-f]+\n\n1;\n\z/,
  'git description added as a comment to the module',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
