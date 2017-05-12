# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info

This package tests the absence of unwanted warnings of Log::Info

=cut

use FindBin 1.42 qw( $Bin );
use Test 1.13 qw( ok plan );
use File::Spec::Functions qw( rel2abs );

use lib $Bin;
use test  qw( PERL );
use test2 qw( -no-ipc-run runcheck );

BEGIN {
  # 1 for compilation test,
  plan tests  => 4,
       todo   => [],
}

# ----------------------------------------------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

=head2 Tests 2--4: double :trap import

Run

   perl -MLog::Info=:trap -MLog::Info=:trap -e ''

( 1) Check it ran ok (exit status zero)
( 2) Check nothing came on stdout
( 3) Check nothing came on stderr

=cut

{
  my ($out, $err) = ('') x 2;
  ok(runcheck([[PERL, '-MLog::Info=:trap', '-MLog::Info=:trap', -e => ''],
               '>', \$out, '2>', \$err],
              'double :trap import'),
     1,                                           'double :trap import (run)');
  ok $out, '',                                    'double :trap import (out)';
  ok $err, '',                                    'double :trap import (err)';
}

# ----------------------------------------------------------------------------
