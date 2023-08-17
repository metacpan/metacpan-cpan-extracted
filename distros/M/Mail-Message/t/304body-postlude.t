#!/usr/bin/env perl
# Test the processing of the prelude of multiparts
# Github issue #16

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Multipart;

use Test::More;

# /tmp/multipart_close-delimiter_test_no-CRLF.eml.txt
# /tmp/multipart_close-delimiter_test_CRLF_empty-epilogue.eml.txt
# /tmp/multipart_close-delimiter_test_CRLF_epilogue.eml.txt
# /tmp/multipart_close-delimiter_test_CRLF_transport-padding_epilogue.eml.txt

my $message = <<'__MESSAGE';
Subject: multipart epilogue handling test
Content-Type: multipart/alternative;	boundary="_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_"
MIME-Version: 1.0

--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

This is the text/plain part

--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_
Content-Type: text/html; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

<html>
<head>
</head>
<body>
This is the text/html part.
</body>
</html>

--_000_MW2PR1501MB2139B94F359ACBAB03EB6BA9C6629MW2PR1501MB2139_--
__MESSAGE

#
### No CRLF after closing boundary
#

my $msg1  = Mail::Message->read($message =~ s/[\r\n]*\z//r);
my $post1 = $msg1->body->epilogue;
ok !defined $post1, "No epilogue when no CRLF";

#
### Only CRLF after closing boundary
#

my $msg2  = Mail::Message->read($message);
my $post2 = $msg2->body->epilogue;
ok defined $post2, "Empty epilogue";
cmp_ok $post2->nrLines, '==', 0, '... is empty';

#
### A real epilogue
#

my @lines3 = ("line 1\n", "line 2\n", "line 3\n");
my $msg3   = Mail::Message->read($message . (join '', @lines3));
my $post3  = $msg3->body->epilogue;
ok defined $post3, "Filled epilogue";
cmp_ok $post3->nrLines, '==', 3, '... has content';

#
### Epilogue, blanks on boundary line
#

my $epi4   = <<'__EPILOGUE';
__EPILOGUE
my $msg4   = Mail::Message->read(($message =~ s/\n/  \n/r) . $epi4);
my $post4  = $msg4->body->epilogue;
ok defined $post4, "Epilogue with blanks on boundary line";
is $post4->string, $epi4, "... text";

done_testing;
