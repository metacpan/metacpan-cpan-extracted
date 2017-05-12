use strict;
use warnings;

use Test::More 'tests' => 1;

use_ok('Math::Random::MT::Auto', ':!auto');

if ($Math::Random::MT::Auto::VERSION) {
    diag('Testing Math::Random::MT::Auto ' . $Math::Random::MT::Auto::VERSION);
}

exit(0);

# EOF
