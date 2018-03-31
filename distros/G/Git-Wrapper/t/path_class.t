use strict;
use warnings;
use Test::More;

use File::Temp qw(tempdir);
use Git::Wrapper;
use POSIX qw(strftime);
use Sort::Versions;
use Test::Deep;
use Test::Exception;
use File::Spec;
use Cwd qw/abs_path/;

my $DO_WIN32_GETLONGPATHNAME = ($^O eq 'MSWin32') ? eval 'use Win32; 1' : 0;

eval "use Path::Class 0.26; 1" or plan skip_all =>
    "Path::Class 0.26 is required for this test.";

my $tmpdir = File::Spec->tmpdir;
$tmpdir = Win32::GetLongPathName(abs_path($tmpdir)) if $DO_WIN32_GETLONGPATHNAME;

my $tempdir = tempdir(DIR => $tmpdir, CLEANUP => 1);

my $dir = Path::Class::dir($tempdir);

my $git = Git::Wrapper->new($dir);

my $version = $git->version;
if ( versioncmp( $git->version , '1.5.0') eq -1 ) {
  plan skip_all =>
    "Git prior to v1.5.0 doesn't support 'config' subcmd which we need for this test."
}

diag( "Testing git version: " . $version );

$git->init; # 'git init' also added in v1.5.0 so we're safe

# see https://github.com/genehack/Git-Wrapper/issues/91
$git->config('commit.gpgsign', 'false');

$git->config( 'user.name'  , 'Test User'        );
$git->config( 'user.email' , 'test@example.com' );

# make sure git isn't munging our content so we have consistent hashes
$git->config( 'core.autocrlf' , 'false' );
$git->config( 'core.safecrlf' , 'false' );

my $foo = $dir->subdir('foo');
$foo->mkpath;

$foo->file('bar')->spew(iomode => '>:raw', "hello\n");

is_deeply(
  [ $git->ls_files({ o => 1 }) ],
  [ 'foo/bar' ],
);

$git->add(Path::Class::dir('.'));
is_deeply(
  [ $git->ls_files ],
  [ 'foo/bar' ],
);

SKIP: {
  skip "Fails on Mac OS X with Git version < 1.7.5 for unknown reasons." , 1
    if (($^O eq 'darwin') and ( versioncmp( $git->version , '1.7.5') eq -1 ));

  $git->commit({ message => "FIRST\n\n\tBODY\n" });

  my $baz = $dir->file('baz');

  $baz->spew("world\n");

  $git->add($baz);

  ok(1);
}

done_testing();
