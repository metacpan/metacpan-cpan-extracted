BEGIN {
	if ($ENV{PERL_CORE}) {
	        chdir 't' if -d 't';
	        @INC = '../lib';
	}
}

# Test that md4 works on unaligned memory blocks

print "1..1\n";

use strict;
use Digest::MD4 qw(md4_hex);

my $str = "\100" x 20;
substr($str, 0, 1) = "";  # chopping off first char makes the string unaligned

#use Devel::Peek; Dump($str); 

print "not " unless md4_hex($str) eq "d76cb45d0cd2b1fd04c581c641ee2201";
print "ok 1\n";

