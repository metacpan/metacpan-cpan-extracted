# watch -*-perl-*-

use strict;
use Test::More tests => 3;
use Event ();

my $expected = Event->Inline(q{C});
is q{HASH}, ref $expected, q{returns hash reference};
is_deeply $expected, Event->Inline(q{notC}, q{Non-'C' Inline will return same hasref as 'C'});
is_deeply $expected, Event->Inline(q{notC}, q{undef will return same hasref as 'C'});
