#!perl
use strict;
use warnings;

my $x = 1;
my $y = 2;
my $z = add(1, 2);
my $zz = subtract($x, $z);
print "Result is $zz!\n";

=head1 NAME

pod.pl - An example program with POD

=head1 SYNOPSIS

  # none

=head1 DESCRIPTION

No usage really, it's just to check out any embedded POD issues with
Devel::ebug.

=head1 SUBROUTINES

=head2 add

Add two integers together.

=cut

sub add {
  my($z, $x) = @_;
  my $c = $z + $x;
  return $c;
}

=head2 subtract

Subtract one number from another.

=cut

sub subtract {
  my($z, $x) = @_;
  my $c = $z - $x;
  return $c;
}

1;

__END__

=head2 AUTHOR

Me!

=cut



