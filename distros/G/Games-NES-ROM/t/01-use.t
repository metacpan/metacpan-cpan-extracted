use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok( 'Games::NES::ROM' );
    use_ok( 'Games::NES::ROM::Format::INES' );
    use_ok( 'Games::NES::ROM::Format::UNIF' );
}
