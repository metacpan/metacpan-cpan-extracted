use strict;
use warnings;

use Dist::Zilla     1.093250;
use Test::DZil qw{ Builder simple_ini };
use File::pushd qw{ pushd };
use Path::Tiny 0.012 qw(path); # cwd
use Test::More 0.88 tests => 50; # done_testing
use Test::Fatal;
use lib 't';
use Util qw( clean_environment init_repo );

# Mock HOME to avoid ~/.gitexcludes from causing problems
# and clear GIT_ environment variables
my $homedir = clean_environment;

my ($zilla, $git, $pushd);

sub new_tzil
{
  undef $pushd;             # Restore original directory, if necessary

  # build fake repository
  $zilla = Builder->from_config(
    { dist_root => 'corpus/check' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          [ 'Git::Check' => { @_ } ],
          'MetaConfig',
          'FakeRelease',
        ),
        'source/.gitignore' => "DZT-Sample-*\n",
      },
    },
  );

  $pushd = pushd(path($zilla->tempdir)->child('source'));
  $git   = init_repo( qw{ .  .gitignore } );
} # end new_tzil

#---------------------------------------------------------------------
# Test with default config:

new_tzil();

# untracked files
like(
    exception { $zilla->release },
    qr/untracked files/,
    'untracked files',
);
our_messages_are(<<'', 'lists untracked files');
[Git::Check] branch master has some untracked files:
[Git::Check] 	Changes
[Git::Check] 	dist.ini
[Git::Check] 	foobar

# index not clean
$git->add( qw{ dist.ini Changes foobar } );
like(
    exception { $zilla->release },
    qr/some changes staged/,
    'index not clean',
);
our_messages_are(<<'', 'lists staged files');
[Git::Check] branch master has some changes staged for commit:
[Git::Check] 	A	Changes
[Git::Check] 	A	dist.ini
[Git::Check] 	A	foobar

$git->commit( { message => 'initial commit' } );

# modified files
append_to_file('foobar', 'Foo-*');
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'uncommitted files',
);
our_messages_are(<<'', 'lists uncommitted files');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	foobar

$git->checkout( 'foobar' );

# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
is(
    exception { $zilla->release },
    undef,
    'Changes and dist.ini can be modified',
);
our_messages_are(<<'', 'reports master in clean state');
[Git::Check] branch master is in a clean state

# ensure dist.ini does not match dist_ini
append_to_file('dist_ini', 'Hello');
$git->add( qw{ dist_ini } );
$git->commit( { message => 'add dist_ini' } );
append_to_file('dist_ini', 'World');

like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'dist_ini must not be modified',
);
our_messages_are(<<'', 'lists uncommitted dist_ini');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	dist_ini

#---------------------------------------------------------------------
# Test with no dirty files allowed at all:

new_tzil(allow_dirty => '');

# untracked files
like(
    exception { $zilla->release },
    qr/untracked files/,
    'untracked files with allow_dirty = ""',
);
our_messages_are(<<'', 'lists untracked files');
[Git::Check] branch master has some untracked files:
[Git::Check] 	Changes
[Git::Check] 	dist.ini
[Git::Check] 	foobar

# index not clean
$git->add( qw{ dist.ini Changes foobar } );
like(
    exception { $zilla->release },
    qr/some changes staged/,
    'index not clean with allow_dirty = ""',
);
our_messages_are(<<'', 'lists staged files');
[Git::Check] branch master has some changes staged for commit:
[Git::Check] 	A	Changes
[Git::Check] 	A	dist.ini
[Git::Check] 	A	foobar

$git->commit( { message => 'initial commit' } );

# modified files
append_to_file('foobar', 'Foo-*');
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'uncommitted files with allow_dirty = ""',
);
our_messages_are(<<'', 'lists uncommitted files');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	foobar

$git->checkout( 'foobar' );

# changelog cannot be modified
append_to_file('Changes', "\n");
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'Changes must not be modified',
);
our_messages_are(<<'', 'lists uncommitted Changes file');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	Changes

$git->checkout( 'Changes' );

# dist.ini cannot be modified
append_to_file('dist.ini', "\n");
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'dist.ini must not be modified',
);
our_messages_are(<<'', 'lists uncommitted dist.ini');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	dist.ini

$git->checkout( 'dist.ini' );

is(
    exception { $zilla->release },
    undef,
    'Changes and dist.ini are unmodified',
);
our_messages_are(<<'', 'reports master in clean state');
[Git::Check] branch master is in a clean state

#---------------------------------------------------------------------
# Test with some files allowed by regex:

new_tzil(allow_dirty => '', allow_dirty_match => 'a');

# untracked files
like(
    exception { $zilla->release },
    qr/untracked files/,
    'untracked files with allow_dirty_match = "a"',
);
our_messages_are(<<'', 'lists untracked files');
[Git::Check] branch master has some untracked files:
[Git::Check] 	Changes
[Git::Check] 	dist.ini
[Git::Check] 	foobar

# index not clean
$git->add( qw{ dist.ini Changes foobar } );
like(
    exception { $zilla->release },
    qr/some changes staged/,
    'index not clean with allow_dirty_match = "a"',
);
our_messages_are(<<'', 'lists staged files');
[Git::Check] branch master has some changes staged for commit:
[Git::Check] 	A	Changes
[Git::Check] 	A	dist.ini
[Git::Check] 	A	foobar

$git->commit( { message => 'initial commit' } );

# modified files
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
append_to_file('foobar', "\n");
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'uncommitted files with allow_dirty_match = "a"',
);
our_messages_are(<<'', 'lists uncommitted files');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	dist.ini

$git->checkout( 'dist.ini' );

# files matching /a/ can be modified
is(
    exception { $zilla->release },
    undef,
    'Changes foobar can be modified',
);
our_messages_are(<<'', 'reports master in clean state');
[Git::Check] branch master is in a clean state


#---------------------------------------------------------------------
# Test with untracked_files = warn:

new_tzil(untracked_files => 'warn');

# untracked files
is(
    exception { $zilla->release },
    undef,
    'untracked files are ok',
);
our_messages_are(<<'', 'warns about untracked files');
[Git::Check] branch master has some untracked files:
[Git::Check] 	Changes
[Git::Check] 	dist.ini
[Git::Check] 	foobar
[Git::Check] branch master has 3 untracked files

# index not clean
$git->add( qw{ dist.ini Changes foobar } );
like(
    exception { $zilla->release },
    qr/some changes staged/,
    'index not clean',
);
our_messages_are(<<'', 'lists staged files');
[Git::Check] branch master has some changes staged for commit:
[Git::Check] 	A	Changes
[Git::Check] 	A	dist.ini
[Git::Check] 	A	foobar

$git->commit( { message => 'initial commit' } );

# modified files
append_to_file('foobar', 'Foo-*');
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'uncommitted files',
);
our_messages_are(<<'', 'lists uncommitted files');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	foobar

$git->checkout( 'foobar' );

# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
is(
    exception { $zilla->release },
    undef,
    'Changes and dist.ini can be modified',
);
our_messages_are(<<'', 'reports master in clean state');
[Git::Check] branch master is in a clean state

# ensure dist.ini does not match dist_ini
append_to_file('dist_ini', 'Hello');
$git->add( qw{ dist_ini } );
$git->commit( { message => 'add dist_ini' } );
append_to_file('dist_ini', 'World');
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'dist_ini must not be modified',
);
our_messages_are(<<'', 'lists dist_ini as uncommitted');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	dist_ini

#---------------------------------------------------------------------
# Test with untracked_files = ignore:

new_tzil(untracked_files => 'ignore');

# untracked files
is(
    exception { $zilla->release },
    undef,
    'untracked files are ok',
);
our_messages_are(<<'', 'counts untracked files');
[Git::Check] branch master has 3 untracked files

# index not clean
$git->add( qw{ dist.ini Changes foobar } );
like(
    exception { $zilla->release },
    qr/some changes staged/,
    'index not clean',
);
our_messages_are(<<'', 'lists staged files');
[Git::Check] branch master has some changes staged for commit:
[Git::Check] 	A	Changes
[Git::Check] 	A	dist.ini
[Git::Check] 	A	foobar

$git->commit( { message => 'initial commit' } );

# modified files
append_to_file('foobar', 'Foo-*');
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'uncommitted files',
);
our_messages_are(<<'', 'lists foobar as uncommitted');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	foobar

$git->checkout( 'foobar' );

# changelog and dist.ini can be modified
append_to_file('Changes',  "\n");
append_to_file('dist.ini', "\n");
is(
    exception { $zilla->release },
    undef,
    'Changes and dist.ini can be modified',
);
our_messages_are(<<'', 'reports master in clean state');
[Git::Check] branch master is in a clean state

# ensure dist.ini does not match dist_ini
append_to_file('dist_ini', 'Hello');
$git->add( qw{ dist_ini } );
$git->commit( { message => 'add dist_ini' } );
append_to_file('dist_ini', 'World');
like(
    exception { $zilla->release },
    qr/uncommitted files/,
    'dist_ini must not be modified',
);
our_messages_are(<<'', 'lists dist_ini as uncommitted');
[Git::Check] branch master has some uncommitted files:
[Git::Check] 	dist_ini

#---------------------------------------------------------------------
sub append_to_file {
    my ($file, @lines) = @_;
    my $fh = path($file)->opena;
    print $fh @lines;
    close $fh;
}

#---------------------------------------------------------------------
sub our_messages_are
{
  my ($expected, $name) = @_;

  my $got = join("\n", grep { /^\Q[Git::Check]\E/ } @{ $zilla->log_messages });
  $got =~ s/\s*\z/\n/;

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is( $got, $expected, $name);

  $zilla->clear_log_events;
}

done_testing;
