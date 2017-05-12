use Test;

BEGIN { plan tests => 1 };

use Mac::CoreMIDI qw(FindObject);

ok(!defined FindObject(0));

