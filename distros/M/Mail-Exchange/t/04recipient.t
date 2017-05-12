#!/usr/bin/perl -w

use Test::More;
use Mail::Exchange::Message;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidLidIDs;
use strict;
use diagnostics;

plan tests => 1;

SKIP: {
	skip("tests not written yet", 1);

	my $message=Mail::Exchange::Message->new("t/minimal.msg");
	ok($message, "load test messsage");
	ok($message->get(PidTagSubject) eq "some subject", "string property");
	ok($message->get(PidTagCreationTime) == 129943353273940000,
							   "date property");
	ok($message->get(PidTagAccess) == 2, 	   	   "numeric property");
	ok($message->get(PidTagRtfInSync) == 1, 	   "boolean property");

	my $binval=$message->get(PidTagChangeKey);
	ok(length($binval) == 20,  "binary property length");
	ok(substr($binval, 0, 8) eq "\xa6\xa1\x10\x68\xe5\x47\xfa\x4d",
					"binary property value");

	ok($message->get(PidLidCurrentVersionName) eq "12.0",
							"lid string property");
	ok($message->get(PidLidValidFlagStringProof) == 129943352997900000,
							"lid date property");
	ok($message->get(PidLidCurrentVersion)==126539, "lid numeric property");
	ok($message->get(PidLidTaskComplete)==0,	"lid boolean property");

	my $rtf=$message->getRtfBody();
	# print length($rtf), "\n",
	# 	substr($rtf, 0, 20), "\n",
	# 	substr($rtf, -20), "\n";
	ok(length($rtf) == 24080, "decompress rtf body length");
	ok(substr($rtf, 0, 20) eq '{\rtf1\ansi\ansicpg1',
						"decompress rtf body start");
	ok(substr($rtf, -20) eq '\htmltag27 </html>}}',
						"decompress rtf body end");

}
