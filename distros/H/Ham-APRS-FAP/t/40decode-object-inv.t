
# object decoding - bad packet
# the packet contains has some binary characters, which were destroyed in
# a cut 'n paste operation
# Tue Dec 11 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 3 };
use Ham::APRS::FAP qw(parseaprs);

my $srccall = "OH2KKU-1";
my $dstcall = "APRS";
my $aprspacket = "$srccall>$dstcall,TCPIP*,qAC,FIRST:;SRAL HQ *110507zS0%E/Th4_a AKaupinmaenpolku9,open M-Th12-17,F12-14 lcl";
my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "succeeded to parse a broken object packet");
ok($h{'resultcode'}, 'obj_inv', "wrong result code");
ok($h{'type'}, 'object', "wrong packet type");

