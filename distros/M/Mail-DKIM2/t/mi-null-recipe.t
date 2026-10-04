#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64 decode_base64);
use lib 'lib';
use Mail::DKIM2::MessageInstance;

my $orig = "Subject: hi\r\nMessage-Instance: m=1; h=sha256:AAA:BBB;\r\n\r\nbody line one\r\n";
my $new  = "Subject: hi\r\nMessage-Instance: m=1; h=sha256:AAA:BBB;\r\n\r\nbody line one\r\nfooter\r\n";

my $mi = Mail::DKIM2::MessageInstance->calculate($new, $orig);
$mi->set_null_body_recipe;
my $str = $mi->as_string;

like($str, qr/^m=2;/, 'still increments the instance number');

# The r= tag value is base64-encoded JSON; decode it to inspect the Recipe.
my ($r) = $str =~ /r=([^;]+)/;
ok($r, 'has an r= tag');
my $json = decode_base64($r);
like($json, qr/"b"\s*:\s*null/, 'recipe JSON has b:null (non-recreatable body)');
unlike($json, qr/"c"\s*:/, 'no copy steps remain in body recipe');

# draft-03 §5.1 removed the possibility of a null header Recipe: parsing an
# instance whose "h" is null (or empty) MUST now be rejected.
my $nullh = encode_base64('{"h":null}', '');
eval { Mail::DKIM2::MessageInstance->parse("m=2; h=sha256:AAA:BBB; r=$nullh;") };
like($@, qr/header recipe/i, '"h": null rejected on parse (draft-03 §5.1)');

# A null body Recipe ("b": null) is still permitted and must still parse.
my $nullb = encode_base64('{"b":null}', '');
ok(eval { Mail::DKIM2::MessageInstance->parse("m=2; h=sha256:AAA:BBB; r=$nullb;"); 1 },
   '"b": null still accepted on parse');

done_testing;
