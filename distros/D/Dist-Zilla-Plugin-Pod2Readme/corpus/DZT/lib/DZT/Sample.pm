use strict;
use warnings;

package DZT::Sample;

sub return_arrayref_of_values_passed {
    my $invocant = shift;
    return \@_;
}

1;

=head1 NAME

DZT::Sample - a sample of stuff

=head1 DESCRIPTION

Foo the foo

=cut
