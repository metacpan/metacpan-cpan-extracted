# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
BEGIN { $^W = 1 }

######################### We start with some black magic to print on failure.

my $loaded;
BEGIN { $| = 1; print "1..27\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Tee;
use IO::File;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $testfile1 = IO::File->new('>test.1');
open TEST3, '>test.3' and $testfile1
    and print "ok 2\n" or print "not ok 2\n";

{
    my $tee = IO::Tee->new(\*STDOUT, $testfile1);
    undef $testfile1;
    print  $tee  "ok 3\n"       and print "ok 4\n"  or print "not ok 3\nnot ok 4\n";
    printf $tee  "ok %d\n", 5   and print "ok 6\n"  or print "not ok 5\nnot ok 6\n";
    $tee->print ("ok 7\n"     ) and print "ok 8\n"  or print "not ok 7\nnot ok 8\n";
    $tee->printf("ok %d\n", 9 ) and print "ok 10\n" or print "not ok 9\nnot ok 10\n";
}

{
    my $t1 = IO::Tee->new(['>test.2'], \*TEST3);
    my $t2 = IO::Tee->new(\*STDOUT, $t1);
    $testfile1 = IO::File->new('<test.1');
    if (join('', <$testfile1>) eq "ok 3\nok 5\nok 7\nok 9\n")
    {
        $t2->print("ok 11\n") and print "ok 12\n" or print "not ok 12\n";
    }
    else
    {
        $t2->print("not ok 11\n") and print "ok 12\n" or print "not ok 12\n";
    }
    undef $testfile1;
}

IO::Tee->new->print('123') and print "ok 13\n" or print "not ok 13\n";

my $testfile2;
close TEST3
    and $testfile2 = IO::File->new('<test.2')
    and open TEST3, '<test.3'
    and join('', <$testfile2>) eq "ok 11\n"
    and join('', <TEST3>) eq "ok 11\n"
    and print "ok 14\n" or print "not ok 14\n";

my $t3 = IO::Tee->new(\*STDOUT, ['>test.4']);
$t3 and ($t3->autoflush(1), $t3->flush)
    and print "ok 15\n" or print "not ok 15\n";

{
    my $t5 = IO::File->new('<test.1');
    print(($t5 ? '' : 'not '), "ok 16\n");
    my $t6 = IO::File->new('>test.5');
    print(($t6 ? '' : 'not '), "ok 17\n");
    my $t7 = IO::Tee->new($t5, $t6);
    print(($t7 ? '' : 'not '), "ok 18\n");

    my $char = $t7->getc();
    print(($char eq 'o' ? '' : 'not '), "ok 19\n");
    my $line1 = $t7->getline();
    print(($line1 eq "k 3\n" ? '' : 'not '), "ok 20\n");
    #print(($t7->input_record_separator(' ') eq "\n" ? '' : 'not '), "ok 21\n");
    print((ref($t7)->input_record_separator(' ') eq "\n" ? '' : 'not '), "ok 21\n");
    my $line2 = $t7->getline();
    print(($line2 eq 'ok ' ? '' : 'not '), "ok 22\n");
    my $block;
    my $result = $t7->read($block, 4000);
    print(($block eq "5\nok 7\nok 9\n" ? '' : 'not '), "ok 23\n");
    print(($t7->eof ? '' : 'not '), "ok 24\n");
    $t7->close;
    my $expected = $char . $line1 . $line2 . $block;

    my $t8 = IO::File->new('<test.5');
    my $contents = join('', $t8->getlines);
    print((($contents eq $expected) ? '' : 'not '), "ok 25\n");

    $t8 = IO::File->new('<test.5');
    $t7 = IO::Tee->new($t8);
    $contents = '';
    $result = $t7->sysread($contents, 4000);
    print((($contents eq $expected) ? '' : 'not '), "ok 26\n");
}

undef $testfile2; close TEST3; undef $t3;
5 == unlink 'test.1', 'test.2', 'test.3', 'test.4', 'test.5'
    and print "ok 27\n" or print "not ok 27\n";
