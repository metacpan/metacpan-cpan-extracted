use strict;
use warnings;

package DZT::Sample2;

sub return_arrayref_of_values_passed {
    my $invocant = shift;
    return \@_;
}

1;

=head1 NAME

DZT::Sample2 - another sample of stuff

=head1 DESCRIPTION

Bar the bar

=cut
