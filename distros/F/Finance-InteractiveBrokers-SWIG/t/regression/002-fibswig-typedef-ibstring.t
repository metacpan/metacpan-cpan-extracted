#!perl -T
#
#   Regression tests - Finance::InteractiveBrokers::SWIG typedef IBString
#
#   Make sure typedef std::string IBString; works
#
#   Bug ID: #79014 - https://rt.cpan.org/Ticket/Display.html?id=79014
#   Reported on: 2012-08-14
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

my( $obj );
my $SYMBOL = 'MSFT';

###
### Tests
###

BEGIN {
    use_ok( 'Finance::InteractiveBrokers::SWIG' ) || print "Bail out!";
    use_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI' ) || print "Bail out!";
}

##########################################################################
# Regression Test: swig_symbol_set works properly
# Expected: PASS
eval {
    my $contract = Finance::InteractiveBrokers::SWIG::IBAPI::Contract->new();
    isa_ok( $contract, 'Finance::InteractiveBrokers::SWIG::IBAPI::Contract' );
    $contract->swig_symbol_set( $SYMBOL );
};
my $e = $@;
note( $e );
is( $e, '', 'No exception thrown when using IBString' );

# Always return true
1;

__END__
