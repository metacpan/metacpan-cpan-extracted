#!perl -Tw

use warnings;
use strict;

use Test::More tests => 5;

BEGIN {
    use_ok( 'HTML::Lint::Parser' );
}
BEGIN {
    use_ok( 'HTML::Lint' );
}
BEGIN {
    use_ok( 'Test::HTML::Lint' );
}

is( $HTML::Lint::VERSION, $Test::HTML::Lint::VERSION, 'HTML::Lint and Test::HTML::Lint versions match' );
is( $HTML::Lint::VERSION, $HTML::Lint::Parser::VERSION, 'HTML::Lint and Test::HTML::Lint versions match' );
