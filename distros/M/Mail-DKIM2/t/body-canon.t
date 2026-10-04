#!/usr/bin/perl -w

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use lib 'lib';

use Mail::DKIM2::MessageInstance;

# Body canonicalization edge cases: DKIM simple body canon requires
# stripping trailing empty lines and ensuring exactly one trailing CRLF.

# Same content, different trailing whitespace
my $body_no_crlf = "Hello, world.";
my $body_with_crlf = "Hello, world.\r\n";
my $body_multi_crlf = "Hello, world.\r\n\r\n\r\n";

my $msg1 = Email::MIME->new("Subject: test\r\n\r\n$body_no_crlf");
my $msg2 = Email::MIME->new("Subject: test\r\n\r\n$body_with_crlf");
my $msg3 = Email::MIME->new("Subject: test\r\n\r\n$body_multi_crlf");

my $d1 = Mail::DKIM2::MessageInstance::b_digest($msg1);
my $d2 = Mail::DKIM2::MessageInstance::b_digest($msg2);
my $d3 = Mail::DKIM2::MessageInstance::b_digest($msg3);

is($d1, $d2, "no trailing CRLF == one trailing CRLF");
is($d2, $d3, "one trailing CRLF == multiple trailing CRLFs");

# Empty body
my $msg_empty = Email::MIME->new("Subject: test\r\n\r\n");
my $msg_empty2 = Email::MIME->new("Subject: test\r\n\r\n\r\n");
my $d_empty1 = Mail::DKIM2::MessageInstance::b_digest($msg_empty);
my $d_empty2 = Mail::DKIM2::MessageInstance::b_digest($msg_empty2);
is($d_empty1, $d_empty2, "empty body == body with only CRLFs");

# Multi-line body
my $multi = "Line one.\r\nLine two.\r\nLine three.";
my $multi_crlf = "Line one.\r\nLine two.\r\nLine three.\r\n";
my $multi_extra = "Line one.\r\nLine two.\r\nLine three.\r\n\r\n\r\n";

my $m1 = Email::MIME->new("Subject: test\r\n\r\n$multi");
my $m2 = Email::MIME->new("Subject: test\r\n\r\n$multi_crlf");
my $m3 = Email::MIME->new("Subject: test\r\n\r\n$multi_extra");

my $dm1 = Mail::DKIM2::MessageInstance::b_digest($m1);
my $dm2 = Mail::DKIM2::MessageInstance::b_digest($m2);
my $dm3 = Mail::DKIM2::MessageInstance::b_digest($m3);

is($dm1, $dm2, "multi-line: no trailing CRLF == one trailing CRLF");
is($dm2, $dm3, "multi-line: one trailing CRLF == multiple trailing CRLFs");

done_testing();
