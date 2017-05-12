# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Getopt::Plus

This package tests the output_suffix use of Getopt::Plus

=cut

use Env                        qw( @PATH );
use File::Spec::Functions  1.1 qw( catdir catfile );
use FindBin               1.42 qw( $Bin );
use Test                  1.13 qw( ok plan );

use lib $Bin;
use test  qw( DATA_DIR
              PERL
              evcheck );
use test2 qw( simple_run_test );

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

unshift @PATH, catdir $Bin, 'bin';

ok 1, 1, 'compilation';

=head2 Tests 2-4: main

Run 

  test-script-3 blibble.bax

It should produce output that is 

  IN: data/blibble.bax
  OUT: blibble.bar
  OUT: blibble.foo

confirming the arguments to main.

( 1) Check that the command ran okay
( 2) Check that no other files were produced.
( 3) Check that the output matches

=cut

my $test_file = catfile DATA_DIR, 'blibble.bax';

my ($out, $err) = ('') x 2;#
my $expect = <<"END";
IN: $test_file
OUT: blibble.bar
OUT: blibble.foo
END

simple_run_test(runargs => [[PERL, -S => 'test-script-3', $test_file],
                            '>', \$out, '2>', \$err],
                name    => 'main',
                errref  => \$err);
ok $out, $expect,                                                 'main ( 3)';

# ----------------------------------------------------------------------------
