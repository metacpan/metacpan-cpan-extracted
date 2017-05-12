package HTML::Widget::Filter::HTMLEscape;

use warnings;
use strict;
use base 'HTML::Widget::Filter';

=head1 NAME

HTML::Widget::Filter::HTMLEscape - HTML Escaping Filter

=head1 SYNOPSIS

    my $f = $widget->filter( 'HTMLEscape', 'foo' );

=head1 DESCRIPTION

HTML Escaping Filter.

=head1 METHODS

=head2 filter

=cut

sub filter {
    my ( $self, $value ) = @_;
    return unless defined $value;
    $value =~ s/&(?!(amp|lt|gt|quot);)/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/\"/&quot;/g;
    return $value;
}

=head1 BUGS

L<HTML::Element> now checks for, and refuses to escape already-escaped 
characters. This means that if you wish to double-escape characters, you must 
now do it yourself.

=head1 AUTHOR

Lyo Kato, C<lyo.kato@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
