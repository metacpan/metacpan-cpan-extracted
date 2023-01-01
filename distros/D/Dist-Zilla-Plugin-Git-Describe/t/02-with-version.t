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
      path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
our $VERSION = '0.001';
1;
FOO
    },
    tempdir_root => $tempdir->stringify,
  },
);

# test that we can use this module with an existing $VERSION statement.

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
{
    # Make sure the git messages come in English. (LC_ALL)
    # Eliminate the effects of system wide (GIT_CONFIG_NOSYSTEM)
    # and global configuration (XDG_CONFIG_HOME and HOME).
    # https://metacpan.org/dist/Git-Repository/view/lib/Git/Repository/Tutorial.pod#Ignore-the-system-and-global-configuration-files
    local $ENV{LC_ALL} = 'C';
    local $ENV{GIT_CONFIG_NOSYSTEM} = '1';
    local $ENV{XDG_CONFIG_HOME} = undef;
    local $ENV{HOME} = undef;

    $git->add('Changes');
    $git->commit({ message => 'first commit', author => 'Hey Jude <jude@example.org>' });
}

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
  qr/\Apackage Foo;\n# git description: [0-9a-f]+\n\nour \$VERSION = '0.001';\n1;\n\z/,
  'git description added as a comment to the module, right after the package statement',
);

diag 'got log messages: ', explain $tzil->log_messages
  if not Test::Builder->new->is_passing;

done_testing;
