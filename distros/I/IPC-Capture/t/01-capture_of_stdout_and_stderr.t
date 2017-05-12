# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IPC-Capture.t'

#########################

use warnings;
use strict;
$|=1;
use Data::Dumper;
use Test::More;
use Test::Differences;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use lib "$Bin/lib";

plan tests=> 14;

my $DEBUG = 0;
my $CHOMPALOT = 1;
my $PERL = $^X;

my $CLASS = 'IPC::Capture';
use_ok( $CLASS );

{#3
  my $test_name = "Testing basic creation of object of type $CLASS";
  my $obj  = $CLASS->new();
  my $type = ref( $obj );
  is( $type, $CLASS, $test_name );
}

{#4-#8
  my $test_name = q{ Testing method "run" with way "qx" };
  my $test_cmd = "$PERL $Bin/bin/yammer_to_stderr_and_stdout";

  my $ic = $CLASS->new({way=>'qx'});

  my @filters =
    ( 'stdout_only',
      'stderr_only',
      'all_output',
      'all_separated',
    );

  foreach my $od ( @filters ) {
    $ic->set_filter( $od );
    my $output = $ic->run( $test_cmd );
    my $expected = expectorant( $od );

    if ($CHOMPALOT) {
      chompalot( \$output );
      chompalot( \$expected );
    }

    if( not( ref( $output ) ) ) {
      eq_or_diff( $output, $expected,
                  "$test_name with filter $od");
    } elsif( ref( $output ) eq 'ARRAY' ) {
      is_deeply(\$output, \$expected,
                "$test_name with filter $od (whole)");

      eq_or_diff( $output->[0], $expected->[0],
                "$test_name with filter $od (stdout)");

      eq_or_diff( $output->[1], $expected->[1],
                "$test_name with filter $od (stderr)");
    }
  }
}

{#9-#14
  my $test_name = "Testing method run using way ipc_cmd";
  my $test_cmd = "$PERL $Bin/bin/yammer_to_stderr_and_stdout";

  my $ic = $CLASS->new({way=>'ipc_cmd'});

  my @filters =
    ( 'stdout_only',
      'stderr_only',
      'all_output',
      'all_separated',
    );

  foreach my $od ( @filters ) {
    $ic->set_filter( $od );
    my $output = $ic->run( $test_cmd );
    my $expected = expectorant( $od );

    if ($CHOMPALOT) {
      chompalot( \$output );
      chompalot( \$expected );
    }

    if( not( ref( $output ) ) ) {
      eq_or_diff( $output, $expected,
                  "$test_name with filter $od");
    } elsif( ref( $output ) eq 'ARRAY' ) {
      is_deeply(\$output, \$expected,
                "$test_name with filter $od (whole)");

      eq_or_diff( $output->[0], $expected->[0],
                "$test_name with filter $od (stdout)");

      eq_or_diff( $output->[1], $expected->[1],
                "$test_name with filter $od (stderr)");
    }
  }
}


# set up expected output for different filter settings
sub expectorant {
  my $od = shift;

  my $all =<<"ALL";
1: (O): hello out there
1: <e>: hello err there
2: (O): hello out there
2: <e>: hello err there
3: (O): hello out there
3: <e>: hello err there
4: (O): hello out there
4: <e>: hello err there
5: (O): hello out there
5: <e>: hello err there
6: (O): hello out there
6: <e>: hello err there
ALL

  my $err = join "\n", grep { /<e>/ } split "\n", $all;
  my $out = join "\n", grep { /\(O\)/ } split "\n", $all;
  my $sep = [ $out, $err ];

  if ($od eq 'stdout_only') {
    return $out;
  } elsif ($od eq 'stderr_only') {
    return $err;
  } elsif ($od eq 'all_output') {
    return $all;
  } elsif ($od eq 'all_separated') {
    return $sep;
  }
}

# remove spurious line-endings on captures (to get comparisons to match)
sub chompalot {
  my $target = shift;

  my $reps = 3;
  if ( ref(${ $target }) eq 'ARRAY' ) {
    for (1..$reps) {
      chomp( ${ $target }->[0] );
    };
    for (1..$reps) {
      chomp( ${ $target }->[1] );
    };
  } else {

    for (1..$reps) {
      chomp( ${ $target } ) if defined( ${ $target } );
    }
  }
}
