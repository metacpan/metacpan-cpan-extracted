package main;

use strict;
use warnings;

use Test::More 0.88;

require_ok( 'HTML::TableContentParser' )
    or BAIL_OUT();

ok( ( local $HTML::TableContentParser::DEBUG = 1 ), 'Can turn on debugging' )
    or BAIL_OUT();

ok( ! ( $HTML::TableContentParser::DEBUG = 0 ), 'Can turn off debugging' )
    or BAIL_OUT();

my $obj = eval {
    HTML::TableContentParser->new();
} or BAIL_OUT "Failed to instantiate: $@";

isa_ok( $obj, 'HTML::TableContentParser' );

done_testing;

1;

# ex: set textwidth=72 :
