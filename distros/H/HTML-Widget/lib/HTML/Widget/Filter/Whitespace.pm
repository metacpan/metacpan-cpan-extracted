package HTML::Widget::Filter::Whitespace;

use warnings;
use strict;
use base 'HTML::Widget::Filter';

=head1 NAME

HTML::Widget::Filter::Whitespace - Whitespace Filter

=head1 SYNOPSIS

    my $f = $widget->filter( 'Whitespace', 'foo' );

=head1 DESCRIPTION

Whitespace Filter.

=head1 METHODS

=head2 filter

=cut

sub filter {
    my ( $self, $value ) = @_;
    $value =~ s/\s+//g;
    return $value;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
