use strict;
use warnings;
use Test::More tests => 2;

use MARC::Charset qw(marc8_to_utf8);

# once upon a time MARC::Charset::Compiler did not know that there were
# code points in the lc mapping table that lacked ucs values and used 
# alt instead...these caused nulls to get sprinkled in MARC::Charset output
# now MARC::Charset::Compiler should use the alt value when available

unlike 
  marc8_to_utf8("\xEB\x70\xEC\x75"), 
  qr/\x00/, 
  'no nulls';
unlike 
  marc8_to_utf8("\x31\x20\x1f\x61\x44\x6f\x6e\xeb\x74\xec\x73\x6f\x76\x61\x2c\x20\x44\x61\x72\xa7\xeb\x69\xec\x61\x2e\x1e"),
  qr/\x00/, 
  'no nulls';


