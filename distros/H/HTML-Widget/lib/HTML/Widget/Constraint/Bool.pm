package HTML::Widget::Constraint::Bool;

use warnings;
use strict;
use base 'HTML::Widget::Constraint::Regex';

=head1 NAME

HTML::Widget::Constraint::IBool - Boolean Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'Bool', 'foo' );

=head1 DESCRIPTION

Boolean Constraint. Value must match C<0> or C<1>.

=head1 METHODS

=head2 regex

Provides a regex to validate unsigned integers.

=cut

sub regex {qr/^[01]$/}

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
