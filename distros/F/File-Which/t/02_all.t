use strict;
use warnings;
use Env qw( @PATH );
use Test::More tests => 6;
use File::Spec ();
use File::Which qw(which where);

# Where is the test application
my $test_bin = File::Spec->catdir( 'corpus', $^O =~ /^(MSWin32|dos|os2)$/ ? 'test-bin-win' : 'test-bin-unix' );
ok( -d $test_bin, 'Found test-bin' );

# Set up for running the test application
@PATH = ($test_bin);
push @PATH, File::Spec->catdir( 'corpus', 'test-bin-win' ) if $^O =~ /^(cygwin|msys)$/;
unless (
  File::Which::IS_VMS
  or
  File::Which::IS_MAC
  or
  File::Which::IS_DOS
) {
  my $all = File::Spec->catfile( $test_bin, 'all' );
  chmod 0755, $all;
}

my @result = which('all');
like( $result[0], qr/all/i, 'Found all' );
ok( scalar(@result), 'Found at least one result' );

# Should have as many elements.
is(
  scalar(@result),
  scalar(where('all')),
  'Scalar which result matches where result',
);

my $zero = which '0';

ok(
  $zero,
  "zero = $zero"
);
  
my $empty_string = which '';

is(
  $empty_string,
  undef,
  "empty string"
);
