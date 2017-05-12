package HTML::Widget::Constraint::ASCII;

use warnings;
use strict;
use base 'HTML::Widget::Constraint::Regex';

=head1 NAME

HTML::Widget::Constraint::ASCII - ASCII Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'ASCII', 'foo' );

=head1 DESCRIPTION

ASCII Constraint.

=head1 METHODS

=head2 regex

Provides a regex to validate ASCII text.

=cut

sub regex {qr/^[\x20-\x7E]*$/}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
