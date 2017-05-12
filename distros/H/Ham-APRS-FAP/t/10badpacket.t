
# a bad packet test
# Tue Dec 11 2007, Hessu, OH7LZB

use Test;

BEGIN { plan tests => 17 };
use Ham::APRS::FAP qw(parseaprs);

#
# corrupted uncompressed packet #########
#

my $srccall = "OH2RDP-1";
my $dstcall = "BEACON-15";
my $aprspacket = "$srccall>$dstcall,OH2RDG*,WIDE:!60ff.51N/0250akh3r99hfae";
my %h;
my $retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "succeeded to parse a broken packet");
ok($h{'resultcode'}, 'loc_inv', "wrong result code");
ok($h{'type'}, 'location', "wrong packet type");

ok($h{'srccallsign'}, $srccall, "incorrect source callsign parsing");
ok($h{'dstcallsign'}, $dstcall, "incorrect destination callsign parsing");
ok($h{'latitude'}, undef, "parsed latitude out of crap");
ok($h{'latitude'}, undef, "parsed longitude out of crap");

#
# bad source call #########
#

$aprspacket = "K6IFR_S>APJS10,TCPIP*,qAC,K6IFR-BS:;K6IFR B *250300z3351.79ND11626.40WaRNG0040 440 Voice 447.140 -5.00 Mhz";
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "succeeded to parse a packet with bad srccall");
ok($h{'resultcode'}, 'srccall_badchars', "wrong result code");
ok($h{'type'}, undef, "found packet type for bad srccall");

#
# bad digipeater call #########
#

$aprspacket = "SV2BRF-6>APU25N,TCPXX*,qAX,SZ8L_GREE:=/:\$U#T<:G- BVagelis, qrv:434.350, tsq:77 {UIV32N}";
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "succeeded to parse a packet with bad digi call");
ok($h{'resultcode'}, 'digicall_badchars', "wrong result code");
ok($h{'type'}, undef, "found packet type for bad digi call");

#
# bad symbol table  #########
#

$aprspacket = "ASDF>DSALK,OH2RDG*,WIDE:!6028.51N,02505.68E#";
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "succeeded to parse a packet with bad symbol table");
ok($h{'resultcode'}, 'sym_inv_table', "wrong result code");

#
# unsupported experimental  #########
#

$aprspacket = "ASDF>DSALK,OH2RDG*,WIDE:{{ unsupported experimental format";
%h = ();
$retval = parseaprs($aprspacket, \%h);

ok($retval, 0, "succeeded to parse an experimental packet");
ok($h{'resultcode'}, 'exp_unsupp', "wrong result code");
