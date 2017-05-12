package HTML::Widget::Constraint::String;

use warnings;
use strict;
use base 'HTML::Widget::Constraint::Regex';

=head1 NAME

HTML::Widget::Constraint::String - String Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'String', 'foo' );

=head1 DESCRIPTION

String Constraint.

=head1 METHODS

=head2 regex

Provides a regex to validate word characters.

=cut

sub regex {qr/^\w*$/}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
