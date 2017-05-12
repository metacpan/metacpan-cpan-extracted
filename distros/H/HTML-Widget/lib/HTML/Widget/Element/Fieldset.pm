package HTML::Widget::Element::Fieldset;

use warnings;
use strict;
use base 'HTML::Widget::Element::Block';
use NEXT;

__PACKAGE__->mk_accessors('legend');

=head1 NAME

HTML::Widget::Element::Fieldset - Fieldset Element

=head1 SYNOPSIS

    my $fs = $widget->element( 'Fieldset', 'address' );
    $fs->element( 'Textfield', 'street' );
    $fs->element( 'Textfield', 'town' );

=head1 DESCRIPTION

Fieldset Element.  Container element creating a fieldset which can contain
other Elements.

=head1 METHODS

=head2 new

=cut

sub new {
    return shift->NEXT::new(@_)->type('fieldset')->class('widget_fieldset');
}

=head2 legend

Set a legend for this fieldset.

=cut

sub _pre_content_elements {
    my ( $self, $w ) = @_;
    return () unless $self->legend;

    my %args;
    $args{id} = $self->id($w) . "_legend" if defined $self->name;
    my $l = HTML::Element->new( 'legend', %args );

    $l->push_content( $self->legend );
    return ($l);
}

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Michael Gray, C<mjg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
