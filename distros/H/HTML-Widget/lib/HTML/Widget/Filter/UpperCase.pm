package HTML::Widget::Filter::UpperCase;

use warnings;
use strict;
use base 'HTML::Widget::Filter';

=head1 NAME

HTML::Widget::Filter::UpperCase - Upper Case Filter

=head1 SYNOPSIS

    my $f = $widget->filter( 'UpperCase', 'foo' );

=head1 DESCRIPTION

Upper Case Filter.

=head1 METHODS

=head2 filter

=cut

sub filter {
    my ( $self, $value ) = @_;
    return uc $value;
}

=head1 AUTHOR

Lyo Kato, C<lyo.kato@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
