#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl linked.t'

use strict;
use warnings;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN{
    if( !eval{ symlink q{}, q{}; 1 } ) {
        plan skip_all => q{'symlink' not implemented};
    }
    plan tests => 20;
    use_ok('File::Spec::Link');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Cwd ();
use File::Temp qw(tempdir);

chdir tempdir() or die;
my $dir = 'test';
mkdir $dir or die;

my $file = File::Spec->catfile($dir,'file.txt');
my $link = File::Spec->catfile($dir,'link.lnk');
my $loopx = File::Spec->catfile($dir,'x.lnk');
my $loopy = File::Spec->catfile($dir,'y.lnk');

open my $fh, q{>}, $file or die $!;
print {$fh} "text\n" or die;
close $fh or die;

    die unless
	symlink 'file.txt', $link  and
	symlink 'y.lnk',    $loopx and
	symlink 'x.lnk',    $loopy;

    is( File::Spec->canonpath(File::Spec::Link->linked($link)),
	File::Spec->canonpath($file), 'linked - to file');
    is( File::Spec->canonpath(File::Spec::Link->linked($loopx)),
	File::Spec->canonpath($loopy), 'linked - to link');

    is( File::Spec->canonpath(File::Spec::Link->resolve($link)),
	File::Spec->canonpath($file), 'resolve - file');
    ok( !defined(File::Spec::Link->resolve($loopx)), 'resolve - loop');

    my $subdir = File::Spec->catdir($dir,'testdir');
    my $linked = File::Spec->catdir($dir,'linkdir');
    my $target = File::Spec->catfile($subdir,'file.txt');
    my $unresolved = File::Spec->catfile($linked,'file.txt');

    mkdir $subdir or die;
    open $fh, q{>}, $target or die "$target - $!\n";
    print {$fh} "test\ntest\n" or die;
    close $fh or die;

    symlink 'testdir', $linked or die;

    is( File::Spec->canonpath(File::Spec::Link->linked($linked)),
	File::Spec->canonpath($subdir), 'linked - directory');
    is( File::Spec->canonpath(File::Spec::Link->resolve($linked)),
	File::Spec->canonpath($subdir), 'resolve - directory');

    SKIP: {
	skip q{Can't determine directory separator}, 2
	    unless File::Spec->catdir('abc','xyz') =~ /\A abc (\W+) xyz \z/msx;
	my $sep = $1;

	is( File::Spec->canonpath(File::Spec::Link->linked($linked.$sep)),
	    File::Spec->canonpath($subdir), "linked - directory with $sep");
	is( File::Spec->canonpath(File::Spec::Link->resolve($linked.$sep)),
	    File::Spec->canonpath($subdir), "resolve - directory with $sep");
    }

    is( File::Spec->canonpath(File::Spec::Link->resolve($unresolved)),
	File::Spec->canonpath($unresolved), 'resolve - embedded link');

    is( File::Spec->canonpath(File::Spec::Link->resolve_all($linked)),
	File::Spec->canonpath($subdir), 'resolve_all - directory');
    is( File::Spec->canonpath(File::Spec::Link->resolve_all($unresolved)),
	File::Spec->canonpath($target), 'resolve_all - file');

    is( File::Spec->canonpath(File::Spec::Link->resolve_all(
		File::Spec->catfile($dir,File::Spec->updir,$unresolved))),
	File::Spec->canonpath($target), 'resolve_all - file');

    my $hasCwd =  eval { require Cwd };
    SKIP: {
	skip 'No Cwd!', 1 unless $hasCwd;
	is( File::Spec->canonpath(File::Spec::Link->resolve_all(
		File::Spec->rel2abs($unresolved))),
	    File::Spec->catfile(Cwd::abs_path($subdir),'file.txt'),
	    'resolve_all - file absolute');
    }

    is( File::Spec->canonpath(File::Spec::Link->full_resolve($linked)),
	File::Spec->canonpath($subdir), 'full_resolve - directory');
    is( File::Spec->canonpath(File::Spec::Link->full_resolve($unresolved)),
	File::Spec->canonpath($target), 'full_resolve - file');

    if( $hasCwd ) {
	is( File::Spec->canonpath(File::Spec::Link->resolve_path($linked)),
	    File::Spec->canonpath($subdir), 'resolve_path - directory');
    }
    else {
	ok( !File::Spec::Link->resolve_path($linked),
	    'resolve_path - directory');
    }

	
    SKIP: {
	my $got = File::Spec::Link->resolve_path($unresolved);
	skip 'Old Cwd', 1 unless $hasCwd and (eval{Cwd->VERSION(2.18)} or $got);
	is( File::Spec->canonpath($got),
	    File::Spec->canonpath($target), 'resolve_path - file');
    }

    ok( !eval { File::Spec::Link->linked($file); 1 }, 'linked failed on file' );
    like($@, qr/\bnot\s+a\s+link\b/, q{not 'nota link' in error message});

# $Id: linked.t 224 2008-06-12 14:22:17Z rmb1 $
