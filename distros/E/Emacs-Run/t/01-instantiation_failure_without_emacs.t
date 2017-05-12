#
#   doom@kzsu.stanford.edu     2009/08/26

use warnings;
use strict;
$|=1;
my $DEBUG = 0;  # TODO set to 0 before ship
use Data::Dumper;
use Test::More;
plan tests => 2;

use FindBin qw( $Bin ); #
use lib "$Bin/../lib";

# Globals
my $CLASS   = 'Emacs::Run';
use_ok( $CLASS );

{
  my $test_name = "Testing failure of $CLASS object creation with no emacs";
  my $emacs_not = 'gadzooks_gruntcakes_gadornika'; # don't tell me you have a binary named this
  my $obj  = $CLASS->new({ emacs_path => $emacs_not });
  is( $obj, undef, "$test_name");
}

