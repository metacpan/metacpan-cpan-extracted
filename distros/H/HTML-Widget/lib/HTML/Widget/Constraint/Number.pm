package HTML::Widget::Constraint::Number;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';
use Scalar::Util qw( looks_like_number );

=head1 NAME

HTML::Widget::Constraint::Number - Number Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Number', 'foo' );

=head1 DESCRIPTION

Number Constraint.

=head1 METHODS

=head2 validate

=cut

sub validate {
    my ( $self, $value ) = @_;

    return 1 if !defined $value || $value eq '';

    return looks_like_number($value);
}

=head1 AUTHOR

Carl Franks C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
