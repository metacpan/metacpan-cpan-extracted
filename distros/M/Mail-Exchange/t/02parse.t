#!/usr/bin/perl -w

use Test::More;
use Mail::Exchange::Message;
use Mail::Exchange::PidTagIDs;
use Mail::Exchange::PidLidIDs;
use strict;
use diagnostics;

plan tests => 16;

ok(1, "Load Module");

SKIP: {
	ok(-f "t/minimal.msg", "test message existant");
	skip("Test message not found") unless -f "t/minimal.msg";

	my $message=Mail::Exchange::Message->new("t/minimal.msg");
	ok($message, "load test messsage");
	is($message->get(PidTagSubject), "some subject", "string property");
	is($message->get(PidTagCreationTime), 129943353273940000,
							   "date property");
	is($message->get(PidTagAccess), 2, 	   	   "numeric property");
	is($message->get(PidTagRtfInSync), 1, 	   "boolean property");

	my $binval=$message->get(PidTagChangeKey);
	is(length($binval), 20,  "binary property length");
	is(substr($binval, 0, 8), "\xa6\xa1\x10\x68\xe5\x47\xfa\x4d",
					"binary property value");

	is($message->get(PidLidCurrentVersionName), "12.0",
							"lid string property");
	is($message->get(PidLidValidFlagStringProof), 129943352997900000,
							"lid date property");
	is($message->get(PidLidCurrentVersion), 126539, "lid numeric property");
	is($message->get(PidLidTaskComplete), 0,	"lid boolean property");

	my $rtf=$message->getRtfBody();
	# print length($rtf), "\n",
	# 	substr($rtf, 0, 20), "\n",
	# 	substr($rtf, -20), "\n";
	is(length($rtf), 24080, "decompress rtf body length");
	is(substr($rtf, 0, 20), '{\rtf1\ansi\ansicpg1',
						"decompress rtf body start");
	is(substr($rtf, -20), '\htmltag27 </html>}}',
						"decompress rtf body end");

}
