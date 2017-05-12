use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/mmdb-dump-metadata',
    'bin/mmdb-dump-search-tree',
    'lib/MaxMind/DB/Reader.pm',
    'lib/MaxMind/DB/Reader/Data/Container.pm',
    'lib/MaxMind/DB/Reader/Data/EndMarker.pm',
    'lib/MaxMind/DB/Reader/Decoder.pm',
    'lib/MaxMind/DB/Reader/PP.pm',
    'lib/MaxMind/DB/Reader/Role/HasDecoder.pm',
    'lib/MaxMind/DB/Reader/Role/HasMetadata.pm',
    'lib/MaxMind/DB/Reader/Role/NodeReader.pm',
    'lib/MaxMind/DB/Reader/Role/Reader.pm',
    'lib/MaxMind/DB/Reader/Role/Sysreader.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/MaxMind/DB/Reader-broken-databases.t',
    't/MaxMind/DB/Reader-decoder.t',
    't/MaxMind/DB/Reader-no-ipv4-search-tree.t',
    't/MaxMind/DB/Reader.t',
    't/MaxMind/DB/Reader/Decoder-maps-with-pointers.t',
    't/MaxMind/DB/Reader/Decoder-types/array.t',
    't/MaxMind/DB/Reader/Decoder-types/boolean.t',
    't/MaxMind/DB/Reader/Decoder-types/bytes.t',
    't/MaxMind/DB/Reader/Decoder-types/container.t',
    't/MaxMind/DB/Reader/Decoder-types/double.t',
    't/MaxMind/DB/Reader/Decoder-types/end_marker.t',
    't/MaxMind/DB/Reader/Decoder-types/float.t',
    't/MaxMind/DB/Reader/Decoder-types/int32.t',
    't/MaxMind/DB/Reader/Decoder-types/map.t',
    't/MaxMind/DB/Reader/Decoder-types/pointer.t',
    't/MaxMind/DB/Reader/Decoder-types/uint128.t',
    't/MaxMind/DB/Reader/Decoder-types/uint16.t',
    't/MaxMind/DB/Reader/Decoder-types/uint32.t',
    't/MaxMind/DB/Reader/Decoder-types/uint64.t',
    't/MaxMind/DB/Reader/Decoder-types/utf8_string.t',
    't/MaxMind/DB/Reader/Decoder.t',
    't/MaxMind/DB/Reader/NoMoose.t',
    't/lib/Test/MaxMind/DB/Reader.pm',
    't/lib/Test/MaxMind/DB/Reader/Decoder.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
