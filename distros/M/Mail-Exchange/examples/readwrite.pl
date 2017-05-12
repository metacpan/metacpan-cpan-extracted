#!/usr/bin/perl

# This is a test program more than an example, really - it reads a message
# file and writes a copy of it. It's used mainly to check if the result
# is identical to the original.

use Mail::Exchange::Message;
use Mail::Exchange::Recipient;

my $filename=$ARGV[0] || "t/minimal.msg";
my $message=Mail::Exchange::Message->new($filename);

$message->save("copied.msg");
