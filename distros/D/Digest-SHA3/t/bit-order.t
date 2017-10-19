use strict;
use Digest::SHA3;

my $numtests = 3;
print "1..$numtests\n";

my $testnum = 1;
my $s1 = Digest::SHA3->new;
my $s2 = Digest::SHA3->new;
my $d1 = $s1->add_bits("110")->hexdigest;
my $d2 = $s2->add_bits("0")->add_bits("1")->add_bits("1")->hexdigest;
print "not " unless $d1 eq $d2;
print "ok ", $testnum++, "\n";

my $bits = "10101010";

my $tempfile = "bit-order.tmp";
END { 1 while unlink $tempfile }

open(F, "> $tempfile");
print F "a" x 4095;
print F $bits;
close F;

$s1 = Digest::SHA3->new;
$s2 = Digest::SHA3->new;
$d1 = $s1->add_bits($bits)->hexdigest;
$d2 = $s2->addfile($tempfile, "0")->hexdigest;
print "not " unless $d1 eq $d2;
print "ok ", $testnum++, "\n";

open(F, "> $tempfile");
print F "a";
print F "$bits\n" x 7777;
close F;

$s1 = Digest::SHA3->new;
$s2 = Digest::SHA3->new;
$d1 = $s1->add(chr(0xaa) x 7777)->hexdigest;
$d2 = $s2->addfile($tempfile, "0")->hexdigest;
print "not " unless $d1 eq $d2;
print "ok ", $testnum++, "\n";
