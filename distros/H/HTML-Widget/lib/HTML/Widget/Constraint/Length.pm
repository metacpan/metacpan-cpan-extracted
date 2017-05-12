package HTML::Widget::Constraint::Length;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

__PACKAGE__->mk_accessors(qw/minimum maximum/);

*min = \&minimum;
*max = \&maximum;

=head1 NAME

HTML::Widget::Constraint::Length - Length Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Length', 'foo' );
    $c->min(23);
    $c->max(50);

=head1 DESCRIPTION

Length Constraint.

=head1 METHODS

=head2 maximum

Arguments: $max_value

=head2 minimum

Arguments: $min_value

=head2 validate

=cut

sub validate {
    my ( $self, $value ) = @_;

    # Return valid on an empty value
    return 1 unless defined($value);
    return 1 if ( $value eq '' );

    my $minimum = $self->minimum;
    my $maximum = $self->maximum;
    my $failed  = 0;
    if ($minimum) {
        $failed++ unless ( length($value) >= $minimum );
    }
    if ($maximum) {
        $failed++ unless ( length($value) <= $maximum );
    }
    return !$failed;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
