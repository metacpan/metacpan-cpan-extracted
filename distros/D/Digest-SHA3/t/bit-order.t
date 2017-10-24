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

$d1 = $s1->add_bits("111100001010")->hexdigest;
$d2 = $s2->add_bits("\xF0\xA0", 12)->hexdigest;
print "not " unless $d1 eq $d2;
print "ok ", $testnum++, "\n";

$d2 = $s2->add_bits("\xF0\x0A", 12, 1)->hexdigest;
print "not " unless $d1 eq $d2;
print "ok ", $testnum++, "\n";
