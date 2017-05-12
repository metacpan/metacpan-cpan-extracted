use strict;
use warnings;
package DZT::Sample;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;

__END__

=head1 SYNOPSIS

This is the synopsis in I<italic>.

=head1 DESCRIPTION

This is the description in B<bold>.

=head1 FUNCTIONS

Some functions are listed here
