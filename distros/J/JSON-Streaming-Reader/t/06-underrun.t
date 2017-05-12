use strict;
use warnings;

use Test::More tests => 3;
use JSON::Streaming::Reader::TestUtil;

compare_event_parse("[", "null,428", "]");
compare_event_parse("[", "null,428", "123]");
compare_event_parse("[", "null,\"foo", "bar\"]");
