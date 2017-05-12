#!/usr/bin/perl

# Extract the body from a .msg file.

use Mail::Exchange::Message;
use Mail::Exchange::PidTagIDs;

my $mailfile=$ARGV[0];

die "$mailfile: $!" unless -r $mailfile;

my $message=Mail::Exchange::Message->new("$mailfile");

my $body=$message->get(PidTagBody); print "===== BODY ====\n$body\n\n";

$body=$message->getRtfBody; print "==== RTF ====\n$body\n\n";

