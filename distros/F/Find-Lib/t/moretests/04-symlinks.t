use strict;
use warnings;
use Test::More;
use File::Copy;
use File::Spec;
use Cwd;

our $cwd;
our $PWD;
our @dirs = ("testdir_$$", "testdir");
our $link = "symlink_$$";
my $script = 'symlink_test.pl';
my $nested_dir = File::Spec->catdir(@dirs);
my $srcfile = File::Spec->catfile('t', 'moretests', $script);
my $dstfile = File::Spec->catfile(@dirs, $script);

BEGIN {
    $cwd = Cwd::cwd();
    $PWD = $ENV{PWD};
    if ($^O eq 'MSWin32' or $^O eq 'os2') {
        plan skip_all => "irrelevant on dosish OS";
    }
    unless (eval { symlink(".", "symlinktest$$") } ) {
        plan 'skip_all' => "symlink support is missing on this FS";
    }
}
plan tests => 2;

END {
    chdir $cwd; ## restore original directory
    unlink "symlinktest$$";
    unlink $link;
    unlink $dstfile;
    rmdir $nested_dir;
    rmdir $dirs[0];
}

## let's create some stuff
mkdir $dirs[0];
mkdir $nested_dir;
symlink $nested_dir, $link
    or die "Couldn't symlink the test directory '$nested_dir $link': $!";

copy $srcfile, $dstfile;

## this is where we do the real test;
{
    ## Go into the symlinked directory
    chdir $link or die "couldn't chdir to $link";
    ## damn chdir doesn't update PWD unless coming from Cwd (which might not be installed?)
    local $ENV{PWD} = File::Spec->catdir( $ENV{PWD}, $link );
    ## execute from there, if all is ok, succeeds
    my $ret = system $^X, $script;
    ok !$ret, "script succeeded, meaning that compilation with symlink worked"
        or diag "cwd=$cwd, PWD=$PWD script=$script";

    $ret = system $^X, ".///$script";
    ok !$ret, "crufty path doesn't make it blow up";
}
