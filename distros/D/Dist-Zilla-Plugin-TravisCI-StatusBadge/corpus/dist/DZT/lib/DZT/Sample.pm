use strict;
use warnings;
package DZT::Sample;

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;

__END__

=head1 NAME

DZT::Sample - a module

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is the description.
