
# beacon decoding (well, they're non-APRS packets, so they're ignored)
# Tue Dec 11 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 5 };
use Ham::APRS::FAP qw(parseaprs);

my $srccall = "OH2RDU";
my $dstcall = "UIDIGI";
my $message = " UIDIGI 1.9";
my $aprspacket = "$srccall>$dstcall:$message";

my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "failed to parse a message packet");
ok($h{'resultcode'}, undef, "wrong result code");
ok($h{'srccallsign'}, "$srccall", "wrong source callsign");
ok($h{'dstcallsign'}, "$dstcall", "wrong destination callsign");
ok($h{'body'}, $message, "wrong body");

