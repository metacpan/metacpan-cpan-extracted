use strict;
use warnings;

use Test::More tests => 30;
use File::Temp;
use Cwd;

BEGIN {
    use_ok('File::Path::Tiny');
}

diag("Testing File::Path::Tiny $File::Path::Tiny::VERSION");

note "Relative paths";
{
    my $dir          = File::Temp->newdir;
    my $starting_dir = cwd();
    chdir $dir || die "Could not change into temp dir: $!";

    ok( File::Path::Tiny::mk("foo/bar"),  "make simple path - return true" );
    ok( -d "foo/bar",                     "make simple path - path recursively created" );
    ok( File::Path::Tiny::mk("foo") == 2, "make already existing dir" );

    if ( open my $fh, '>', "foo/bar/file" ) {
        print {$fh} "test";
        close $fh;
    }
    else {
        die "test file not created: $!";
    }
    ok( !File::Path::Tiny::mk("foo/bar/file"), "make already existing non dir - return false" );
    ok( $! == 20,                              "make already existing file - errno" );

    my $file = "zib/dib/kib";
    ok( File::Path::Tiny::mk_parent($file),      "mk_parent() simple path returns true" );
    ok( -d "zib/dib",                            "mk_parent() simple path - parent recursively created" );
    ok( !-e $file,                               "mk_parent() simple path - file not created" );
    ok( File::Path::Tiny::mk_parent($file) == 2, "mk_parent() already existing simple path dir" );

    chdir $starting_dir || die "Could not go back into $starting_dir: $!\n";
}

note "Absolute paths";
{
    my $dir = File::Temp->newdir();
    my $new = "$dir/foo/bar/baz";
    ok( File::Path::Tiny::mk($new),      "make absolute path - return true" );
    ok( -d $new,                         "make absolute path - path recursively created" );
    ok( File::Path::Tiny::mk($new) == 2, "make already existing absolute path dir" );

    my $file = "$dir/zib/dib/kib";
    ok( File::Path::Tiny::mk_parent($file),      "mk_parent() absolute path returns true" );
    ok( -d "$dir/zib/dib",                       "mk_parent() absolute path - parent recursively created" );
    ok( !-e $file,                               "mk_parent() absolute path - file not created" );
    ok( File::Path::Tiny::mk_parent($file) == 2, "mk_parent() already existing absolute path dir" );
}

note "Modes and misc";
{

    my $dir          = File::Temp->newdir;
    my $starting_dir = cwd();
    chdir $dir || die "Could not change into temp dir: $!";
    File::Path::Tiny::mk('foo/bar/dir');

    my $mk_mode = ( stat('foo/bar') )[2];

    # $mk_mode       = sprintf('%04o', $mk_mode & 07777);
    my $mkdir_mode = ( stat('foo/bar/dir') )[2];

    # $mkdir_mode    = sprintf('%04o', $mkdir_mode & 07777);
    # diag("mk: $mk_mode, mkdir: $mkdir_mode");
    ok( $mk_mode == $mkdir_mode, 'MASK logic gets same results as mkdir()' );

    File::Path::Tiny::mk( "foo/bar/mode", 0700 );
    File::Path::Tiny::mk_parent( "parent_mode/x", 0700 );
    mkdir 'foo/bar/mode_mkdir', 0700;
    ok( ( stat('foo/bar/mode') )[2] == ( stat('foo/bar/mode_mkdir') )[2], 'MASK arg OCT gets same results as mkdir()' );
    ok( ( stat('parent_mode') )[2] ==  ( stat('foo/bar/mode_mkdir') )[2], 'MASK arg OCT gets same results as mkdir() - mk_parent()' );

    File::Path::Tiny::mk( "foo/bar/mode2", oct('0700') );
    File::Path::Tiny::mk_parent( "parent_oct/x", oct('0700') );
    mkdir 'foo/bar/mode_mkdir2', oct('0700');
    ok( ( stat('foo/bar/mode2') )[2] == ( stat('foo/bar/mode_mkdir2') )[2], 'MASK arg oct(STR) gets same results as mkdir()' );
    ok( ( stat('parent_oct') )[2] ==    ( stat('foo/bar/mode_mkdir2') )[2], 'MASK arg oct(STR) gets same results as mkdir() - mk_parent()' );

    File::Path::Tiny::mk( "foo/bar/mode3", "0700" );
    File::Path::Tiny::mk_parent( "parent_str/x", "0700" );

    # mkdir 'foo/bar/mode_mkdir3', "0700"; # this breaks permissions so we compare with previous one
    ok( ( stat('foo/bar/mode3') )[2] == ( stat('foo/bar/mode2') )[2], 'MASK arg STR gets detected and handled - different results as mkdir()' );
    ok( ( stat('parent_str') )[2] ==    ( stat('foo/bar/mode2') )[2], 'MASK arg STR gets detected and handled - different results as mkdir() - mk_parent()' );

    if ( open my $fh, '>', "foo/bar/file" ) {
        print {$fh} "test";
        close $fh;
    }
    else {
        die "test file not created: $!";
    }
    ok( !File::Path::Tiny::rm("foo/bar/file"), "remove existing non dir - return false" );
    ok( $! == 20,                              "remove existing non dir - errno" );
    undef $!;
    ok( File::Path::Tiny::rm('foo/bar'),      "empty and remove simple path - return true" );
    ok( !-d 'foo/bar',                        "remove simple path - path recursively removed" );
    ok( File::Path::Tiny::rm('foo/bar') == 2, "remove already non-existing dir" );
    ok( File::Path::Tiny::rm('foo'),          'remove empty dir' );

    chdir $starting_dir || die "Could not go back into $starting_dir: $!\n";
}
