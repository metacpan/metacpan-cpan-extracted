#!perl -w

BEGIN {
    if ($] < 5.006) {
	print "1..0 # Skipped: your perl don't know unicode\n";
	exit;
    }
}

print "1..3\n";

use strict;
use Digest::MD4 qw(md4_hex);

my $str;
$str = "foo\xFF\x{100}";

eval {
    print md4_hex($str);
    print "not ok 1\n";  # should not run
};
print "not " unless $@ && $@ =~ /^(Big byte|Wide character)/;
print "ok 1\n";

my $exp = ord "A" == 193 ? # EBCDIC
	   "c307ec81deba65e9a222ca81cd8f6ccd" :
	   "8966f0213b23980e844412b27129b739"; # Latin 1

chop($str);  # only bytes left
print "not " unless md4_hex($str) eq $exp;
print "ok 2\n";

# reference
print "not " unless md4_hex("foo\xFF") eq $exp;
print "ok 3\n";
