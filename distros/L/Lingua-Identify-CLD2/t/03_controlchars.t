use strict;
use warnings;
use utf8;

use Test::Exception tests => 1;

use Lingua::Identify::CLD2 qw/:all/;

my $TEXT = "Ole\x{84}ka \x{440}\x{43e}\x{437}\x{442}\x{430}\x{448}\x{43e}\x{432}\x{430}\x{43d}\x{438}\x{439}";

throws_ok { DetectLanguage($TEXT) } qr/^input contains invalid UTF-8 around byte 3 of 32/;
