use strict;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests=>1;
BEGIN {
    use_ok( 'JavaScript::Minifier::XS' );
}
