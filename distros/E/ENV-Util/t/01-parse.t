use strict;
use warnings;
use Test::More tests => 3;

use ENV::Util;

local %ENV = (
    FOO_BAR => '/meep/moop/',
    FOO_BLIP_BLOOP => 42,
    UNRELATED => 'nope!',
);

my %cfg = ENV::Util::prefix2hash('FOO_');

is_deeply(
    \%cfg,
    { bar => '/meep/moop/', blip_bloop => 42 },
    '%ENV properly parsed by load_prefix'
);

is_deeply(
    \%ENV,
    { FOO_BAR => '/meep/moop/', FOO_BLIP_BLOOP => 42, UNRELATED => 'nope!' },
    '%ENV unchanged after parsing'
);

%cfg = ENV::Util::prefix2hash();
is_deeply(
    \%cfg,
    { foo_bar => '/meep/moop/', foo_blip_bloop => 42, unrelated => 'nope!' },
    '%ENV properly parsed on no prefix '
);
