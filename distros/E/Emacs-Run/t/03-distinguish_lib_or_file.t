# Test file created outside of h2xs framework.
# Run this like so: `perl 03-lib_or_file.t'
#   doom@kzsu.stanford.edu     2008/04/21 19:24:23

use warnings;
use strict;
$|=1;
use Data::Dumper;
use File::Copy qw( copy );
use File::Basename qw( fileparse basename dirname );
use File::Spec;
use List::Util qw( first );
use Test::More;
use Test::Differences;

use FindBin qw( $Bin );
use lib "$Bin/../lib";
use lib "$Bin/lib";

# Globals
my $DEBUG = 0;  # TODO set to 0 before ship
my $CHOMPALOT = 1;
my $CLASS   = 'Emacs::Run';
my $devnull = File::Spec->devnull;

my $emacs_found;
eval {
  $emacs_found = qx{ emacs --version 2>$devnull };
};
if($@) {
  $emacs_found = '';
  print STDERR "Problem with qx of emacs: $@\n" if $DEBUG;
}

if( not( $emacs_found ) ) {
  plan skip_all => 'emacs was not found in PATH';
} else {
  plan tests => 10;
}

use_ok( $CLASS );

ok(1, "Traditional: If we made it this far, we're ok.");

{
  my $test_name = "Testing basic creation of object of $CLASS";
  my $obj  = $CLASS->new();
  my $type = ref( $obj );
  is( $type, $CLASS, $test_name );
}


{#4-#10
  my $test_name = "Testing lib_or_file method";
  my $er = Emacs::Run->new();

  my @test_cases =
    ( [ '/tmp/conquer_world.el' ,                  'file' ],
      [ 'conquer_world',                           'lib'  ],
      [ '/home/charlie_mccarthy/exterminate.el',   'file' ],
      [ 'exterminate',                             'lib'  ],
      [ 'exterminate-exterminate',                 'lib'  ],
      [ 'lone.el',                                 'file' ],
      [ 'lone',                                    'lib'  ],
    );

  foreach my $pair (@test_cases) {
    my $case     = $pair->[0];
    my $expected = $pair->[1];

    my $result = $er->lib_or_file( $case );
    is( $result, $expected, "$test_name for case $case");
  }
}
