#!perl -T
#
#   Regression tests - Finance::InteractiveBrokers::SWIG socket timeout
#
#   Make set setSelectTimeout works
#
#   Bug ID: #88097 - https://rt.cpan.org/Ticket/Display.html?id=88097
#   Reported on: 2013-08-25
#
#   Copyright (c) 2010-2014 Jason McManus
#

use Data::Dumper;
use Test::More tests => 5;
use strict;
use warnings;
$|=1;

# Ours
use lib 't/inc';

###
### Vars
###

use vars qw( $TRUE $FALSE $VERSION );

$VERSION = '0.13';
*TRUE    = \1;
*FALSE   = \0;

my( $obj, $handler );
my $SYMBOL = 'MSFT';

###
### Tests
###

BEGIN {
    use_ok( 'Finance::InteractiveBrokers::SWIG' ) || print "Bail out!";
    use_ok( 'Finance::InteractiveBrokers::SWIG::IBAPI' ) || print "Bail out!";
    use_ok( 'TestEventHandler') || print 'Bail out!';
}

$handler = TestEventHandler->new( api_version => '9.64' );
$obj = Finance::InteractiveBrokers::SWIG->new(
    handler => $handler,
);


##########################################################################
# Regression Test: setSelectTimeout(+int) works
# Expected: PASS

eval {
    $obj->setSelectTimeout(42);
};
my $e = $@;
note( $e );
is( $e, '', 'No exception thrown when using setSelectTimeout(42)' );

##########################################################################
# Regression Test: setSelectTimeout(-int) works
# Expected: PASS

eval {
    $obj->setSelectTimeout(-42);
};
$e = $@;
note( $e );
is( $e, '', 'No exception thrown when using setSelectTimeout(-42)' );

# Always return true
1;

__END__
