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

my $tempdir = File::Tempdir->new;
my $tdir = $tempdir->name;
my $bdir = 't/base';

my $copy = "$tdir/test.txt";

my $rw = File::Edit::Portable->new;

{
    my @file = $rw->read("$bdir/unix.txt", 1);

    for (@file){
        if (/([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/){
            ok ($1 =~ /(?<!\r)\n/, "unix line endings have remained in test");
        }
    }
}
{
    my @file = $rw->read("$bdir/win.txt", 1);

    for (@file){
        if (/([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/){
            ok ($1 =~ /\r\n/, "win line endings have remained in test");
        }
    }
}
{
    my $file = "$bdir/unix.txt";

    copy $file, $copy;
    $file = $copy;

    my @file = $rw->read($file);

    for (@file){
        /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/;
        is ($1, undef, "out of testing, EOR is removed");
    }

    my $eor = $rw->recsep($file, 'hex');

    is ($eor, '\0a', "nix EOR was saved from the orig file");
}
{
    my $file = "$bdir/win.txt";

    copy $file, $copy;
    $file = $copy;

    my @file = $rw->read($file);

    for (@file){
        /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/;
        is ($1, undef, "out of testing, EOR is removed");
    }

    my $eor = $rw->recsep($file, 'hex');

    is ($eor, '\0d\0a', "win EOR was saved from the orig file");
}
{
    my $file = "$bdir/unix.txt";
    my @file = $rw->read(file => $file);
    is (scalar @file, 5, "file hash param still works");
}
{
    my $rw = File::Edit::Portable->new;

    my $f1 = "$bdir/unix.txt";
    my $f2 = "$bdir/win.txt";
    my $f3 = "$bdir/splice.txt";
    my $f4 = "$bdir/empty.txt";

    my $fh1 = $rw->read(file => $f1);
    my $fh2 = $rw->read(file => $f2);
    my $fh3 = $rw->read(file => $f3);
    my $fh4 = $rw->read(file => $f4);

    is ($rw->{reads}{count}, 4, "reads count is correct");

    $rw->write(file => $f1, copy => $copy, contents => $fh1);
    is ($rw->{reads}{count}, 4, "reads count is 3 after write");

    $rw->write(file => $f2, copy => $copy, contents => $fh2);
    is ($rw->{reads}{count}, 4, "reads count is 2 after write");

    $rw->write(file => $f3, copy => $copy, contents => $fh3);
    is ($rw->{reads}{count}, 4, "reads count is 1 after write");

    $rw->write(file => $f4, copy => $copy, contents => $fh4);
    is ($rw->{reads}{count}, 0, "reads count is 0 after write");
}
{
    my $rw = File::Edit::Portable->new;

    my $f1 = "$bdir/unix.txt";
    my $f2 = "$bdir/win.txt";

    my $fh1 = $rw->read(file => $f1);
    my $fh2 = $rw->read(file => $f2);
    my $fh3 = $rw->read(file => $f1);


    $rw->write(file => $f1, copy => $copy, contents => $fh1);
    is ($rw->recsep($copy, 'type'), 'nix', "after first read, recsep is ok");

    $rw->write(file => $f2, copy => $copy, contents => $fh2);
    is ($rw->recsep($copy, 'type'), 'win', "after other file, recsep is ok");

    $rw->write(file => $f1, copy => $copy, contents => $fh3);
    is ($rw->recsep($copy, 'type'), 'nix', "after double-reading, recsep is ok");
}

done_testing();
