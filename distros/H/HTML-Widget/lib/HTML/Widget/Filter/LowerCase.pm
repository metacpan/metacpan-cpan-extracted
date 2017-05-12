package HTML::Widget::Filter::LowerCase;

use warnings;
use strict;
use base 'HTML::Widget::Filter';

=head1 NAME

HTML::Widget::Filter::LowerCase - Lower Case Filter

=head1 SYNOPSIS

    my $f = $widget->filter( 'LowerCase', 'foo' );

=head1 DESCRIPTION

Lower Case Filter.

=head1 METHODS

=head2 filter

=cut

sub filter {
    my ( $self, $value ) = @_;
    return lc $value;
}

=head1 AUTHOR

Lyo Kato, C<lyo.kato@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
