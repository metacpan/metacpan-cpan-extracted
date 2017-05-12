#!perl -w

print "1..6\n";

use strict;
use Digest::MD4 qw(md4_hex);

my $a = Digest::MD4->new;
$a->add("a");
my $b = $a->clone;

print "not " unless $b->clone->hexdigest eq md4_hex("a");
print "ok 1\n";

$a->add("a");
print "not " unless $a->hexdigest eq md4_hex("aa");
print "ok 2\n";

print "not " unless $a->hexdigest eq md4_hex("");
print "ok 3\n";

$b->add("b");
print "not " unless $b->clone->hexdigest eq md4_hex("ab");
print "ok 4\n";

$b->add("c");
print "not " unless $b->clone->hexdigest eq md4_hex("abc");
print "ok 5\n";

# Test that cloning picks up the correct class for subclasses.
{
   package MD4;
   @MD4::ISA = qw(Digest::MD4);
}

$a = MD4->new;
$a->add("a");
$b = $a->clone;

print "not " unless ref($b) eq "MD4" && $b->add("b")->hexdigest eq md4_hex("ab");
print "ok 6\n";
