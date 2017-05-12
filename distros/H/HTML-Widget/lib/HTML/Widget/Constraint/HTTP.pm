package HTML::Widget::Constraint::HTTP;

use warnings;
use strict;
use base 'HTML::Widget::Constraint::Regex';

=head1 NAME

HTML::Widget::Constraint::HTTP - HTTP Constraint

=head1 SYNOPSIS

    my $c = $widget->constraint( 'HTTP', 'foo' );

=head1 DESCRIPTION

HTTP URL Constraint.

=head1 METHODS

=head2 regex

Provides a regex to validate a HTTP/HTTPS URI.

=cut

sub regex {qr/^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
