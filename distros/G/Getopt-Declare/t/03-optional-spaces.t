#!perl

use lib 'lib';
use strict;
use warnings;
use Test::More tests => 31;

BEGIN { use_ok( 'Getopt::Declare' ); }


# Testing optional whitespaces

my ($spec, $args);
my ($val1, $val2) = (1, 10);


#------------------------------------------------------------------------------#

# No optional whitespaces

$spec = q{ --lines<start>..<stop>	Lines };

@ARGV = ( "--lines$val1..$val2" ); test_lines(1);

#------------------------------------------------------------------------------#

# Some optional whitespaces

$spec = q{ --lines <start>-<stop>	Lines };

@ARGV = ( "--lines$val1-$val2" ); test_lines(1);

@ARGV = ( "--lines", "$val1-$val2" ); test_lines();

#------------------------------------------------------------------------------#

# All whitespaces optional

$spec = q{ --lines <start> - <stop>	Lines };

@ARGV = ( "--lines", $val1, "-", $val2 ); test_lines(1);

@ARGV = ( "--lines", $val1, "-$val2" ); test_lines();

@ARGV = ( "--lines$val1", "-$val2" ); test_lines();

@ARGV = ( "--lines$val1-$val2" ); test_lines();

@ARGV = ( "--lines", "$val1-$val2" ); test_lines();

@ARGV = ( "--lines", "$val1-", $val2 ); test_lines();

@ARGV = ( "--lines$val1-", "$val2" ); test_lines();

#------------------------------------------------------------------------------#


sub test_lines {
  my ($print) = @_;
  my $desc;
  $desc = $spec if $print;
  ok $args = Getopt::Declare->new($spec), $desc;
  is $args->{'--lines'}{'<start>'}, $val1;
  is $args->{'--lines'}{'<stop>'}, $val2;
  return 1;
}

