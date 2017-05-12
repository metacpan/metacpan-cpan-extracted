# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Getopt-Plus

This package tests the commify function

=cut

use FindBin 1.42 qw( $Bin );
use Test 1.13 qw( ok plan );

use lib $Bin;
use test qw( DATA_DIR
             evcheck );

BEGIN {
  # 1 for compilation test,
  plan tests  => 9,
       todo   => [],
}

# ----------------------------------------------------------------------------

use Getopt::Plus qw( commify );

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

ok commify('1'),          '1',           'commify ( 1)';
ok commify('100'),        '100',         'commify ( 2)';
ok commify('1000'),       '1,000',       'commify ( 3)';
ok commify('100000'),     '100,000',     'commify ( 4)';
ok commify('1000000'),    '1,000,000',   'commify ( 5)';
ok commify('10.45'),      '10.45',       'commify ( 6)';
ok commify('1000.45'),    '1,000.45',    'commify ( 7)';
ok commify('99999.4578'), '99,999.457,8','commify ( 8)';

# ----------------------------------------------------------------------------
