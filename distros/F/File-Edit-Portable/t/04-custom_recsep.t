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

my $unix = "$bdir/unix.txt";
my $win = "$bdir/win.txt";
my $copy = "$tdir/test.txt";

{
    my $rw = File::Edit::Portable->new;

    my @file = $rw->read($unix);

    for (@file){
        /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/;
        is ($1, undef, "no EOLs present after read");
    }

    for (qw(a b c d e)){
        push @file, $_;
    }

    $rw->write(recsep => "\r\n", copy => $copy, contents => \@file);

    # print "*** " . unpack("H*", $rw->{eor}) . "\n";
    
    my $recsep = $rw->recsep($copy, 'hex');

    is ($recsep, '\0d\0a', "custom recsep takes precedence" );
}
{
    my $rw = File::Edit::Portable->new;

    my @file = $rw->read($win);

    for (@file){
        /([\n\x{0B}\f\r\x{85}]{1,2}|[{utf8}2028-{utf8}2029]]{1,2})/;
        is ($1, undef, "no EOLs present after read");
    }

    for (qw(a b c d e)){
        push @file, $_;
    }

    $rw->write(recsep => "\n", copy => $copy, contents => \@file);

    # print "*** " . unpack("H*", $rw->{eor}) . "\n";

    my $recsep = $rw->recsep($copy, 'hex');

    is ($recsep, '\0a', "on windows file, custom recsep took precedence" );
}

done_testing();
