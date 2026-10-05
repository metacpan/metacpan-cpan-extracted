#!/usr/bin/perl -w
#
# Removing a header field whose value is empty is a change. The header Recipe
# builder compared the joined canonical values of the field's instances, and
# zero instances and one empty instance both join to "", so the removal of an
# empty "Bcc:" -- which Sympa's egress does, and 2005-era Hotmail sent -- went
# unrecorded and the instance did not verify (2026-10-04, charset corpus).

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use MIME::Base64 qw(decode_base64);
use lib 'lib';

use Mail::DKIM2::MessageInstance;

my $previous = Email::MIME->new(join('',
    "From: sender\@example.com\r\n",
    "To: list\@example.org\r\n",
    "Bcc: \r\n",
    "Subject: empty bcc\r\n",
    "Message-ID: <empty-bcc\@example.com>\r\n",
    "\r\n",
    "body\r\n"));
my $mi1 = Mail::DKIM2::MessageInstance->calculate($previous);
$previous->header_raw_prepend('Message-Instance', $mi1->as_string);

my $current = Email::MIME->new($previous->as_string);
$current->header_raw_set('Bcc');

my $mi2 = Mail::DKIM2::MessageInstance->calculate($current, $previous);
my ($r) = $mi2->as_string =~ /\br=([A-Za-z0-9+\/=\s]+)/;
ok($r, 'm=2 has a Recipe') or BAIL_OUT($mi2->as_string);
$r =~ s/\s+//g;
like(decode_base64($r), qr/"bcc":\[\{"d":\[""\]\}\]/, 'the removed empty Bcc is restored by the Recipe');

$current->header_raw_prepend('Message-Instance', $mi2->as_string);
my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($current->as_string);
ok($ok, 'the chain undoes to m=1') or diag $why;

done_testing;
