#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use lib 't/lib';
use TestDeprecate;

use Devel::Deprecate 'deprecate';
use DateTime;

ok defined &deprecate, 'deprecate() should be exported to our namespace';

#
# Test errors
#

check { deprecate(1) };
like $CROAK,
        qr/^\Qdeprecate() called with odd number of elements in hash assignment/,
        'Calling deprecate() without an even-sized list should fail';

check { deprecate(1 => 1) };
like $CROAK,
        qr/^\Qdeprecate() called without a 'reason' argument/,
        'Calling deprecate() without a reason argument should fail';

check {
    deprecate(
        reason => 'Some reason',
        warn   => '2008-06-06',
        die    => '1998-06-06',
    );
};
like $CROAK,
        qr/^\Qdeprecate() die date (1998-06-06) must be after warn date (2008-06-06)/,
        'Calling deprecate() with a die date before a warn date should fail';

check {
    deprecate(
        reason => 'Some reason',
        warn   => '208-06-06',
        die    => '198-06-06',
    );
};
like $CROAK,
        qr/^\QCannot parse unknown date format (208-06-06)/,
        'Calling deprecate() with an unknown date format should fail';
