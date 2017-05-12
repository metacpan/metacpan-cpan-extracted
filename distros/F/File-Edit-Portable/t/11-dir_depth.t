#!perl
use 5.006;
use strict;
use warnings;

use File::Copy;
use File::Tempdir;
use Test::More;

BEGIN {
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

# set up the test bed

my $tempdir = File::Tempdir->new;
my $tdir = $tempdir->name;

mkdir "$tdir/a";
mkdir "$tdir/a/b";
mkdir "$tdir/a/b/c";
mkdir "$tdir/a/b/c/d";

my $a = "$tdir/a";
my $ab = "$tdir/a/b";
my $abc = "$tdir/a/b/c";
my $abcd = "$tdir/a/b/c/d";

my $rw = File::Edit::Portable->new;

{
    _reset();

    my @files = $rw->dir(dir => $a, maxdepth => 1, list => 1);
    is (scalar @files, 2, "dir() returns the correct number of files maxdepth() as only param");

    @files = $rw->dir(dir => $a, types => [qw(*.txt)], maxdepth => 1, list => 1);
    is (scalar @files, 1, "dir() with types() and maxdepth() returns correct number of files");

    @files = $rw->dir(dir => $a, maxdepth => 2, list => 1);
    is (scalar @files, 3, "dir() returns the correct number of files maxdepth() as only param");

    @files = $rw->dir(dir => $a, maxdepth => 3, list => 1);
    is (scalar @files, 4, "dir() returns the correct number of files maxdepth() as only param");

    @files = $rw->dir(dir => $a, maxdepth => 4, list => 1);
    is (scalar @files, 5, "dir() returns the correct number of files maxdepth() as only param");

}
{
    _reset();

    my @files = $rw->dir(dir => $a, types => ['*.txt'], recsep => "\r");

    is (scalar @files, 4, "dir() processes correct files with types param and no maxdepth");

    for (@files){

        my @contents = $rw->read($_);

        if ($contents[0] =~ /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/){
            is($rw->recsep($_, 'hex'), '\0d', 
               "dir() replaces with custom recsep on just specified files"
            );

        }
    }

    @files = $rw->dir(dir => $a, types => ['*.none']);

    is (scalar @files, 1, "dir() with types param collects proper files");

}
{
    _reset();

    my @files = $rw->dir(dir => $a, types => ['*.txt'], recsep => "\r", maxdepth => 2);

    is (scalar @files, 2, "dir() processes correct files with types and maxdepth set");

    for (@files){

        my @contents = $rw->read($_);

        if ($contents[0] =~ /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/){
            is($rw->recsep($_, 'hex'), '\0d', 
               "dir() replaces with custom recsep on just specified files"
            );

        }
    }

    @files = $rw->dir(dir => $a, types => ['*.none']);

    is (scalar @files, 1, "dir() with types param collects proper files");

}

done_testing();

sub _reset {

    open my $afh, '>', "$a/a.txt" or die $!;
    print $afh "one\ntwo\nthree\n";
    close $afh;

    open my $bfh, '>', "$ab/b.txt" or die $!;
    print $bfh "one\ntwo\nthree\n";
    close $bfh;


    open my $cfh, '>', "$abc/c.txt" or die $!;
    print $cfh "one\ntwo\nthree\n";
    close $cfh;

    open my $dfh, '>', "$abcd/d.txt" or die $!;
    print $dfh "one\ntwo\nthree\n";
    close $dfh;

    open my $nfh, '>', "$a/a.none" or die $!;
    print $nfh "one\ntwo\nthree\n";
    close $nfh;
}
