#!/usr/bin/perl -w
#
# Recipe numbers must be JSON integers (-07 section 5) whichever backend
# JSON.pm picks. JSON::PP decodes 1e0 as a plain integer where JSON::XS
# gives a float, so Mail::DKIM2 0.25 accepted it on a box without JSON::XS
# (a cpanm install failing t/recipe-order.t, 2026-10-20). Pin JSON::PP here
# so the test means the same thing on every box.

use 5.020;
use strict;
use warnings;
BEGIN { $ENV{PERL_JSON_BACKEND} = 'JSON::PP' }
use Test::More;
use MIME::Base64 qw(encode_base64);
use lib 'lib';
use Mail::DKIM2::Common qw(decode_tag_json);

is(JSON->backend, 'JSON::Backend::PP', 'JSON.pm is using JSON::PP');

sub refuses {
    my ($json, $name) = @_;
    my $ok = eval { decode_tag_json(encode_base64($json, '')); 1 };
    ok(!$ok, "refuses $name") or return;
    is($@, "JSON number is not an integer\n", '... as a number that is not an integer');
}

refuses('{"b":[{"c":[1e0,3]}]}',  'an exponent bound');
refuses('{"b":[{"c":[1,3E0]}]}',  'an upper-case exponent');
refuses('{"b":[{"c":[1e+0,3]}]}', 'a signed exponent');
refuses('{"b":[{"c":[1.0,3]}]}',  'a zero fraction');
refuses('[-1.5]',                 'a negative fraction');

my $data = eval { decode_tag_json(encode_base64('{"b":[{"c":[1,3]},{"d":["1e0 x.5"]}]}', '')) };
is_deeply($data, { b => [ { c => [ 1, 3 ] }, { d => ['1e0 x.5'] } ] },
    'integers and strings that look like numbers decode')
    or diag($@);

done_testing;
