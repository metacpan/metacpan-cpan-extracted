
# message decoding
# Tue Dec 11 2007, Hessu, OH7LZB

use Test;

my @messageids = (1, 42, 10512, 'a', '1Ff84', 'F00b4');

BEGIN { plan tests => 6 * (6 + 5 + 5)};

use Ham::APRS::FAP qw(parseaprs);


foreach my $messageid (@messageids) {
	my $srccall = "OH7AA-1";
	my $destination = "OH7LZB   ";
	my $dstcall = "APRS";
	my $message = "Testing, 1 2 3";
	
	my $aprspacket = "$srccall>$dstcall,WIDE1-1,WIDE2-2,qAo,OH7AA::$destination:$message\{$messageid";
	my %h;
	my $retval = parseaprs($aprspacket, \%h);
	
	# whitespace will be stripped, ok...
	$destination =~ s/\s+$//;
	
	ok($retval, 1, "failed to parse a message packet");
	ok($h{'resultcode'}, undef, "wrong result code");
	ok($h{'type'}, 'message', "wrong packet type");
	ok($h{'destination'}, $destination, "wrong message dst callsign");
	ok($h{'messageid'}, $messageid, "wrong message id");
	ok($h{'message'}, $message, "wrong message");
	
	# ack
	$destination = "OH7LZB   ";
	$aprspacket = "$srccall>$dstcall,WIDE1-1,WIDE2-2,qAo,OH7AA::$destination:ack$messageid";
	$retval = parseaprs($aprspacket, \%h);
	$destination =~ s/\s+$//; # whitespace will be stripped, ok...
	
	ok($retval, 1, "failed to parse a message packet");
	ok($h{'resultcode'}, undef, "wrong result code");
	ok($h{'type'}, 'message', "wrong packet type");
	ok($h{'destination'}, $destination, "wrong message dst callsign");
	ok($h{'messageack'}, $messageid, "wrong message id in ack");
	
	# reject
	$destination = "OH7LZB   ";
	$aprspacket = "$srccall>$dstcall,WIDE1-1,WIDE2-2,qAo,OH7AA::$destination:rej$messageid";
	$retval = parseaprs($aprspacket, \%h);
	$destination =~ s/\s+$//; # whitespace will be stripped, ok...
	
	ok($retval, 1, "failed to parse a message packet");
	ok($h{'resultcode'}, undef, "wrong result code");
	ok($h{'type'}, 'message', "wrong packet type");
	ok($h{'destination'}, $destination, "wrong message dst callsign");
	ok($h{'messagerej'}, $messageid, "wrong message id in reject");
}


