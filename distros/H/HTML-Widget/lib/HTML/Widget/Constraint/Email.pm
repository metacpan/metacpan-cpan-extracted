package HTML::Widget::Constraint::Email;

use warnings;
use strict;
use base 'HTML::Widget::Constraint';
use Email::Valid;

=head1 NAME

HTML::Widget::Constraint::Email - Email Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Email', 'foo' );

=head1 DESCRIPTION

Email Constraint.

=head1 METHODS

=head2 validate

=cut

sub validate {
    my ( $self, $value ) = @_;
    return 1 unless $value;
    return 0 unless Email::Valid->address( -address => $value );
    return 1;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
