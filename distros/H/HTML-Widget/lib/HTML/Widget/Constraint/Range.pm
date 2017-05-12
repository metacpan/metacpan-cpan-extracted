package HTML::Widget::Constraint::Range;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

use Scalar::Util qw(looks_like_number);

__PACKAGE__->mk_accessors(qw/minimum maximum/);

*min = \&minimum;
*max = \&maximum;

=head1 NAME

HTML::Widget::Constraint::Range - Range Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Range', 'foo' );
    $c->min(23);
    $c->max(30);

=head1 DESCRIPTION

Range Constraint.

=head1 METHODS

=head2 maximum

Arguments: $max_value

=head2 minimum

Arguments: $min_value

=head2 validate

=cut

sub validate {
    my ( $self, $value ) = @_;

    return 1 if !defined $value || $value eq '';

    my $minimum = $self->minimum;
    my $maximum = $self->maximum;
    my $failed  = 0;

    $failed++ if !looks_like_number($value);

    if ( !$failed && defined $minimum ) {
        $failed++ unless ( $value >= $minimum );
    }
    if ( !$failed && defined $maximum ) {
        $failed++ unless ( $value <= $maximum );
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
