#!perl -T
#
#   Regression tests - Finance::InteractiveBrokers::SWIG _resolve_host
#
#   Make sure _resolve_host returns a sane answer
#
#   Reported by: Uwe Voelker
#   Reported on: 2010-02-20
#
#   Copyright (c) 2010-2014 Jason McManus
#

use Data::Dumper;
use Test::More tests => 4;
use strict;
use warnings;
$|=1;

###
### Vars
###

use vars qw( $TRUE $FALSE $VERSION );

$VERSION = '0.13';
*TRUE    = \1;
*FALSE   = \0;

my( $hostname, @addresses );

###
### Tests
###

BEGIN {
    use_ok( 'Finance::InteractiveBrokers::SWIG' ) || print "Bail out!";
}

##########################################################################
# Regression Test: _resolve_host returns a sane answer
# Expected: PASS
eval {
    ( $hostname, @addresses ) =
        Finance::InteractiveBrokers::SWIG::_resolve_host( 'www.google.com' );
};
#diag( Dumper( $hostname ), Dumper( \@addresses ), Dumper( $@ ) );
TODO: {
    local $TODO = 'DNS resolution may not work everywhere.';

    ok( length( $hostname ), 'Hostname exists' );
    isnt( ref( $addresses[0] ), 'ARRAY', 'Addresses existed' );
    ok( @addresses, 'Addresses returned more than 0 values' );
}

# Always return true
1;

__END__
