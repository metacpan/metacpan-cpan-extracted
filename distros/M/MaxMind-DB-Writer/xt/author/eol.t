use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MaxMind/DB/Writer.pm',
    'lib/MaxMind/DB/Writer/Serializer.pm',
    'lib/MaxMind/DB/Writer/Tree.pm',
    'lib/MaxMind/DB/Writer/Tree/Processor/VisualizeTree.pm',
    'lib/MaxMind/DB/Writer/Util.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/MaxMind/DB/Writer/Serializer-deduplication.t',
    't/MaxMind/DB/Writer/Serializer-large-pointer.t',
    't/MaxMind/DB/Writer/Serializer-types/array.t',
    't/MaxMind/DB/Writer/Serializer-types/boolean.t',
    't/MaxMind/DB/Writer/Serializer-types/bytes.t',
    't/MaxMind/DB/Writer/Serializer-types/double.t',
    't/MaxMind/DB/Writer/Serializer-types/end_marker.t',
    't/MaxMind/DB/Writer/Serializer-types/float.t',
    't/MaxMind/DB/Writer/Serializer-types/int32.t',
    't/MaxMind/DB/Writer/Serializer-types/map.t',
    't/MaxMind/DB/Writer/Serializer-types/pointer.t',
    't/MaxMind/DB/Writer/Serializer-types/uint128.t',
    't/MaxMind/DB/Writer/Serializer-types/uint16.t',
    't/MaxMind/DB/Writer/Serializer-types/uint32.t',
    't/MaxMind/DB/Writer/Serializer-types/uint64.t',
    't/MaxMind/DB/Writer/Serializer-types/utf8_string.t',
    't/MaxMind/DB/Writer/Serializer-utf8-as-bytes.t',
    't/MaxMind/DB/Writer/Serializer-utf8-round-trip.t',
    't/MaxMind/DB/Writer/Serializer.t',
    't/MaxMind/DB/Writer/Tree-bigint.t',
    't/MaxMind/DB/Writer/Tree-data-references.t',
    't/MaxMind/DB/Writer/Tree-freeze-thaw.t',
    't/MaxMind/DB/Writer/Tree-insert-range.t',
    't/MaxMind/DB/Writer/Tree-ipv4-and-6.t',
    't/MaxMind/DB/Writer/Tree-ipv6-aliases.t',
    't/MaxMind/DB/Writer/Tree-iterator-large-dataset.t',
    't/MaxMind/DB/Writer/Tree-iterator.t',
    't/MaxMind/DB/Writer/Tree-output/0-0-0-0.t',
    't/MaxMind/DB/Writer/Tree-output/basic.t',
    't/MaxMind/DB/Writer/Tree-output/freeze-thaw-record-size.t',
    't/MaxMind/DB/Writer/Tree-output/freeze-then-write-bug.t',
    't/MaxMind/DB/Writer/Tree-output/ipv6-aliases.t',
    't/MaxMind/DB/Writer/Tree-output/record-deduplication.t',
    't/MaxMind/DB/Writer/Tree-output/utf8-data.t',
    't/MaxMind/DB/Writer/Tree-record-collisions.t',
    't/MaxMind/DB/Writer/Tree-thaw-merge.t',
    't/MaxMind/DB/Writer/Tree.t',
    't/MaxMind/DB/Writer/Util.t',
    't/lib/Test/MaxMind/DB/Writer.pm',
    't/lib/Test/MaxMind/DB/Writer/Iterator.pm',
    't/lib/Test/MaxMind/DB/Writer/Serializer.pm',
    't/test-data/geolite2-sample.json'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
