use strict;
use Math::Group::Thompson;
use Getopt::Std;

# Usage: perl cardball.pl -v [verbose] -r [radius] [g]
# where [radius] is a non-negative whole number
#       [verbose] is 0 or 1
#       [g] is an element of F
my %args;
getopts("r:v:",\%args);

# Check radius
if(!exists $args{r}) {
  die "\nUsage: perl cardball.pl -v [verbose] -r [radius] [g]\nYou don't specified a radius\n";
} elsif( $args{r} =~ /\D/ || $args{r} < 0) {
  die "\nUsage: perl cardball.pl -v [verbose] -r [radius] [g]\nThe radius is not a non-negative whole number\n";
}


# Check verbose
my $verbose = 0;
if(exists $args{v}) {
  $verbose = $args{v};
}

# Check the word in F
my $g;
if(!defined $ARGV[0] || $ARGV[0] =~ /[^ABCD]/) {
  $g = '';
} else {
  $g = $ARGV[0];
}

# Create Thompson group F object
my $F = Math::Group::Thompson->new( VERBOSE => $verbose );

# Calculate and print #B(r) or #(gB(r)-B(r))
if($g eq '') {
  print "\nCardinality B(".$args{r}.") : ".$F->cardBn($args{r})."\n";
} else {
  print "\nCardinality of ".$g."B(".$args{r}.") - B(".$args{r}.") : ".$F->cardBn($args{r},$g)."\n";
}
