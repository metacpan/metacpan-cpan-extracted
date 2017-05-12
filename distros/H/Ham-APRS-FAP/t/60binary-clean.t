# TODO
#
# Test all binary characters (except \r\n) in:
# 1) message content
# 2) bulletin content
# 3) status message content
# 4) comment string
# 5) some other beacon packet
#

#
# The test definition in the beginning skips ascii 127 (delete character)
# and 255 (0xFF), which is invalid: not defined by UTF-8 specification.
# Other chars starting for 32 seem to go through fine.
#

use Test;

my $ascii = '';
for (my $i = 32; $i <= 126; $i++) { $ascii .= chr($i); }
my $binary1 = '';
my $binary2 = '';
my $binary3 = '';
my $binary4 = '';
for (my $i = 32; $i < 32+67; $i++) { $binary1 .= chr($i); }
for (my $i = 32+67; $i < 32+67+67; $i++) { $binary2 .= chr($i) if ($i != 127); }
for (my $i = 32+67+67; $i < 32+67+67+67; $i++) { $binary3 .= chr($i); }
for (my $i = 32+67+67+67; $i < 255; $i++) { $binary4 .= chr($i); }

my @binarycontents = ( $ascii, $binary1, $binary2, $binary3, $binary4 );

my @binarychars;
for (my $i = 32; $i < 255; $i++) { push @binarychars, chr($i) if ($i != 127); }

# 5 content sets, 6 message tests
BEGIN { plan tests => (5 + (255-32-1)) * (6) };

use Ham::APRS::FAP qw(parseaprs);

sub do_tests($$)
{
	my($setname, $binary) = @_;
	
	my $srccall = "OH7AA-1";
	my $destination = "OH7LZB   ";
	my $dstcall = "APRS";
	my $message = $binary;
	my $messageid = 42;
	
	# these characters are not allowed in a message, so strip them:
	$message =~ s/[{~|]//g;
	
	my $aprspacket = "$srccall>$dstcall,WIDE1-1,WIDE2-2,qAo,OH7AA::$destination:$message\{$messageid";
	my %h;
	my $retval = parseaprs($aprspacket, \%h);
	
	# whitespace will be stripped, ok...
	$destination =~ s/\s+$//;
	
	ok($retval, 1, "$setname: failed to parse a message packet");
	ok($h{'resultcode'}, undef, "$setname: wrong result code");
	ok($h{'type'}, 'message', "$setname: wrong packet type");
	ok($h{'destination'}, $destination, "$setname: wrong message dst callsign");
	ok($h{'messageid'}, $messageid, "$setname: wrong message id");
	ok($h{'message'}, $message, "$setname: wrong message");
}

my $set = 0;
foreach my $binary (@binarycontents) {
	$set++;
	
	do_tests("msg set $set", $binary);
}


foreach my $binary (@binarychars) {
	do_tests("binary char " . ord($binary), "char: $binary");
}

