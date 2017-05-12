package HTML::Widget::Element::Textfield;

use warnings;
use strict;
use base 'HTML::Widget::Element';

__PACKAGE__->mk_accessors(qw/comment label value retain_default/);
__PACKAGE__->mk_attr_accessors(qw/size maxlength/);

=head1 NAME

HTML::Widget::Element::Textfield - Textfield Element

=head1 SYNOPSIS

    my $e = $widget->element( 'Textfield', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->size(23);
    $e->maxlength(42);
    $e->value('bar');

=head1 DESCRIPTION

Textfield Element.

=head1 METHODS

=head2 retain_default

If true, overrides the default behaviour, so that after a field is missing 
from the form submission, the xml output will contain the default value, 
rather than be empty.

=head2 containerize

=cut

sub containerize {
    my ( $self, $w, $value, $errors, $args ) = @_;

    $value = $self->value
        if ( not defined $value )
        and $self->retain_default || not $args->{submitted};

    $value = ref $value eq 'ARRAY' ? shift @$value : $value;

    my $l = $self->mk_label( $w, $self->label, $self->comment, $errors );
    my $i = $self->mk_input( $w, { type => 'text', value => $value }, $errors );
    my $e = $self->mk_error( $w, $errors );

    return $self->container( { element => $i, error => $e, label => $l } );
}

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
