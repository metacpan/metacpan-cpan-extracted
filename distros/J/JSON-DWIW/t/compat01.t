#!/usr/bin/env perl

# Authors: don

use strict;
use warnings;

use Test;

BEGIN { plan tests => 2 }

use JSON::DWIW;

local $SIG{__DIE__};

my $bad_str = '{"stuff":}';
my $data;

eval { $data = JSON::DWIW->from_json($bad_str, { use_exceptions => 1 }); };

my $first_eval = $@ ? 1 : 0;

eval { $data = JSON::DWIW::deserialize($bad_str, { use_exceptions => 1 }); };

my $second_eval = $@ ? 1 : 0;

ok($first_eval and $second_eval);

# needs converting case -- do the conversion
my $json_str = qq{{"var":"\xe9"}};
{
    $data = JSON::DWIW::deserialize($json_str, { bad_char_policy => 'convert' });
}
ok($data and ord($data->{var}) == 0xe9);

# The old version doesn't respect bad_char_policy when parsing
# {
#     local $SIG{__WARN__} = sub { };
#     $data = JSON::DWIW->from_json($json_str, { bad_char_policy => 'convert' });
# }
# print "var: $data->{var}\n";
# ok($data and ord($data->{var}) == 0xe9);
