use strict;
use warnings;

use Test::More tests => 5;
use Test::NoWarnings;
use Test::Exception;

use Memoize::HashKey::Ignore;
use Memoize;

throws_ok { tie my %scalar_cache => 'Memoize::HashKey::Ignore', IGNORE => {}; }
    qr/IGNORE argument must be a code ref/,
    "IGNORE argument must be a code ref";

lives_ok { tie my %scalar_cache => 'Memoize::HashKey::Ignore', () }
    "no argument to TIE";

throws_ok { tie my %scalar_cache => 'Memoize::HashKey::Ignore', TIE => [ 'xyz' ] }
    qr/Could not load hash tie module/,
    "Could not load hash tie module";

lives_ok { tie my %scalar_cache => 'Memoize::HashKey::Ignore', HASH => {} }
    "HASH argument to TIE";
