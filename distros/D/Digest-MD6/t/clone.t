#!perl -w

print "1..6\n";

use strict;
use Digest::MD6 qw(md6_hex);

my $a = Digest::MD6->new;
$a->add("a");
my $b = $a->clone;

print "not " unless $b->clone->hexdigest eq md6_hex("a");
print "ok 1\n";

$a->add("a");
print "not " unless $a->hexdigest eq md6_hex("aa");
print "ok 2\n";

print "not " unless $a->hexdigest eq md6_hex("");
print "ok 3\n";

$b->add("b");
print "not " unless $b->clone->hexdigest eq md6_hex("ab");
print "ok 4\n";

$b->add("c");
print "not " unless $b->clone->hexdigest eq md6_hex("abc");
print "ok 5\n";

# Test that cloning picks up the correct class for subclasses.
{
   package MD6;
   @MD6::ISA = qw(Digest::MD6);
}

$a = MD6->new;
$a->add("a");
$b = $a->clone;

print "not " unless ref($b) eq "MD6" && $b->add("b")->hexdigest eq md6_hex("ab");
print "ok 6\n";
