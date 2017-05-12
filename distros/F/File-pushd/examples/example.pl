#!perl
use strict;
use warnings;
use Cwd qw/cwd/;
use File::pushd qw/tempd pushd/;

print "Starting directory:\n  " . cwd() . "\n";

# tempd() is equivalent to pushd( File::Temp::tempdir )
{
    my $tempdir = tempd();
    print "Directory after tempd():\n  " . cwd() . "\n";

    mkdir "new_dir";

    {
        my $new_dir = pushd "new_dir";
        print "Directory after pushd('new_dir'):\n  " . cwd() . "\n";
    }

    print "Directory after pushd object destroyed:\n  " . cwd() . "\n";
}

print "Directory after tempd object destroyed:\n  " . cwd() . "\n";

