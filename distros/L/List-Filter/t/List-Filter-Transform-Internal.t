# Test file created outside of h2xs framework.
# Run this like so: `perl List-Filter-Transform-Internal.t'
#   doom@kzsu.stanford.edu     2007/05/24 05:31:04


use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 6 };
use FindBin qw($Bin);
use lib ("$Bin/../../../..");

my ($class);
BEGIN {
  $class = 'List::Filter::Transform::Internal'; # global definition
  use_ok( $class ); # {# 1 }
}

my $test_terms = [ [qr{pointy-haired \s+ boss}, 'ix', 'esteemed leader' ],
                   [qr{kill},                   '' , 'reward' ],
                   [qr{Kill},                   '' , 'Reward' ],
                   [qr{attack at midnight},     '' , 'go out for donuts' ],
                 ];

ok(1, "Traditional: We made it this far, we're ok.");  # {# 2 }

{# 3, 4
  my $testname = "Testing creation of a $class object";
  my $self = $class->new();
  isa_ok($self, $class, $testname);

  $testname = "Testing that $class object can";
  my @methods = qw(substitute);
  foreach my $method (@methods) {
    my $testcase = "$method";
    ok( $self->can( $method ), "$testname $testcase" );
  } # Note: can't get Test::More's "can_ok" to work (?)
}

{# 5, 6
  my $testname = "Using substitute method";
  my $self = $class->new();

  my $term = [qr{pointy-haired \s+ boss}, 'xi', 'esteemed leader' ];

  my $transformed = $self->substitute( "pointy-haired boss", $term );

  is( $transformed, 'esteemed leader', "$testname (lower-case original)");

  $transformed = $self->substitute( "Pointy-Haired Boss", $term );

  is( $transformed, 'esteemed leader', "$testname (capitalized original)");

}

