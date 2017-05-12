use Test::More tests => 4;

use lib "../lib";

BEGIN {
    use_ok( 'Devel::PerlySense' );
    use_ok( 'Devel::PerlySense::Document' );
    use_ok( 'Devel::PerlySense::Document::Location' );
    use_ok( 'Devel::PerlySense::Util' );
}

