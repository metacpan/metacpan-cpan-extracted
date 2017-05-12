#
# このファイルのエンコーディングはUTF-8
#

# copied over from JSON::PC and modified to use JSON::XS
# and modified yet again to use JSON::SL

use Test::More;
use strict;
use warnings;
use utf8;
use JSON::SL qw(decode_json unescape_json_string);

#########################
my ($js,$obj,$str);




$obj = decode_json(q|{"id":"abc\ndef"}|);
is($obj->{id},"abc\ndef",q|{"id":"abc\ndef"}|);

$obj = decode_json(q|{"id":"abc\\\ndef"}|);
is($obj->{id},"abc\\ndef",q|{"id":"abc\\\ndef"}|);

$obj = decode_json(q|{"id":"abc\\\\\ndef"}|);
is($obj->{id},"abc\\\ndef",q|{"id":"abc\\\\\ndef"}|);

done_testing();