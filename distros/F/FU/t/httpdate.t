use v5.36;
use Test::More;
use FU::Util 'httpdate_format', 'httpdate_parse';

is httpdate_format(0), 'Thu, 01 Jan 1970 00:00:00 GMT';
is httpdate_format(1740325942), 'Sun, 23 Feb 2025 15:52:22 GMT';

is httpdate_parse('Thu, 01 Jan 1970 00:00:00 GMT'), 0;
is httpdate_parse('Sun, 23 Feb 2025 15:52:22 GMT'), 1740325942;
is httpdate_parse('Sub, 23 Feb 2025 15:52:22 GMT'), undef;
is httpdate_parse('Sun, 3 Feb 2025 15:52:22 GMT'), undef;

done_testing;
