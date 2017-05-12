package HTML::Widget::Constraint::Integer;

use warnings;
use strict;
use base 'HTML::Widget::Constraint::Regex';

=head1 NAME

HTML::Widget::Constraint::Integer - Integer Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Integer', 'foo' );

=head1 DESCRIPTION

Integer Constraint.

=head1 METHODS

=head2 regex

Provides a regex to validate unsigned integers.

=cut

sub regex {qr/^[0-9]*$/}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
