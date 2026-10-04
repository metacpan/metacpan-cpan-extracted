#!/usr/bin/perl -w
# Recipe header keys are always emitted lowercase (canonical form).
# Header field names are case-insensitive; we always lowercase the Recipe (h)
# keys on output, regardless of the case they were computed/supplied with.
use 5.020;
use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(decode_base64);
use lib 'lib';
use Mail::DKIM2::MessageInstance;

my $mi = bless {
    bits => {
        m  => 2,
        h1 => 'AAAA', b1 => 'BBBB',
        rh => { 'List-ID' => [], 'Reply-To' => [], 'X-Weird-CASE' => [] },
    },
}, 'Mail::DKIM2::MessageInstance';

my ($r) = $mi->as_string =~ /r=(\S+?);/;
my $json = decode_base64($r);
like($json, qr/"list-id"/,       'List-ID -> list-id');
like($json, qr/"reply-to"/,      'Reply-To -> reply-to');
like($json, qr/"x-weird-case"/,  'X-Weird-CASE -> x-weird-case');
unlike($json, qr/[A-Z]/,         'no uppercase in recipe keys');

done_testing;
