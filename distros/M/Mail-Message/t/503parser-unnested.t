#!/usr/bin/env perl
# Test processing a message/rfc822, in transport-encoded form

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message;

use Test::More;

#
# Reading a very complicate message from scalar
#

my $msg = Mail::Message->read(<<'END-OF-MESSAGE', strip_status_fields => 0);
Subject: test
Content-Type: multipart/mixed; boundary=BOUND_63F902B74261E3.60363083

--BOUND_63F902B74261E3.60363083
Content-Type: message/rfc822; name="email.eml"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="email.eml"

UmV0dXJuLVBhdGg6IDxzdGVmYW5vLnZpcnppQHZhbGJydW5hLml0Pg0KUmVjZWl2ZWQ6IChxbWFp
bCAyNTY5MyBpbnZva2VkIGJ5IHVpZCA4OSk7IDEzIEZlYiAyMDIzIDEyOjQzOjMxIC0wMDAwDQpS
ZWNlaXZlZDogZnJvbSB1bmtub3duIChIRUxPIG14ZGhmZTAxLmFkLmFydWJhLml0KSAoMTAuMTAu
MTAuMjExKQ0KICBieSBteGRoYmUxMi5hZC5hcnViYS5pdCB3aXRoIFNNVFA7IDEzIEZlYiAyMDIz
IDEyOjQzOjMxIC0wMDAwDQpSZWNlaXZlZDogZnJvbSBzZXJ2ZXIuZHJlYW12aWV3LmNvLmlsIChb
DQo=

--BOUND_63F902B74261E3.60363083--
END-OF-MESSAGE

my $part = $msg->body->part(0);
ok ! $part->isNested, "message/rf822 not parsed as nested";
is $part->contentType, 'message/rfc822', '... correct type';

done_testing;
