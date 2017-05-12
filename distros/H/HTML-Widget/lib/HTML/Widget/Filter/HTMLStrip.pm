package HTML::Widget::Filter::HTMLStrip;

use warnings;
use strict;
use base 'HTML::Widget::Filter';
use HTML::Scrubber;

__PACKAGE__->mk_accessors(qw/allow/);

=head1 NAME

HTML::Widget::Filter::HTMLStrip - HTML Strip Filter

=head1 SYNOPSIS

    my $f = $widget->filter( 'HTMLStrip', 'foo' )->allow( 'br', 'a' );

=head1 DESCRIPTION

HTML Strip Filter.

=head1 METHODS

=head2 allow

Accepts a list of HTML tags which shouldn't be stripped

=head2 filter

=cut

sub filter {
    my ( $self, $value ) = @_;
    my $allowed = $self->allow || [];
    my $scrubber = HTML::Scrubber->new( allow => $allowed );
    return $scrubber->scrub($value);
}

=head1 AUTHOR

Lyo Kato, C<lyo.kato@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
