# Test that md6 works on unaligned memory blocks

use strict;
use warnings;

use Test::More tests => 1;

use Digest::MD6 qw(md6_hex);

my $str = "\100" x 20;
# chopping off first char makes the string unaligned
substr( $str, 0, 1 ) = "";
# aligned copy
my $str2 = $str;

is md6_hex($str), md6_hex($str2), 'non-aligned string'

