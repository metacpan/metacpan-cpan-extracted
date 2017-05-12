package HTML::Widget::Element::Button;

use warnings;
use strict;
use base 'HTML::Widget::Element';
use NEXT;

__PACKAGE__->mk_accessors(
    qw/value content type _src height width
        retain_default/
);

# alias
*label = \&value;

=head1 NAME

HTML::Widget::Element::Button - Button Element

=head1 SYNOPSIS

    $e = $widget->element( 'Button', 'foo' );
    $e->value('bar');

=head1 DESCRIPTION

Button Element.

=head1 METHODS

=head2 new

=cut

sub new {
    return shift->NEXT::new(@_)->type('button');
}

=head2 value

=head2 label

The value of this Button element. Is also used by the browser as the 
button label.

L</label> is an alias for L</value>.

=head2 content

If set, the element will use a C<button> tag rather than an C<input> 
tag.

The value of C<content> will be used between the C<button> tags, unescaped.
This means that any html markup may be used to display the button.

=head2 type

Valid values are C<button>, C<submit>, C<reset> and C<image>.

=head2 src

If set, the element will be rendered as an image button, using this url as 
the image.

Automatically sets L</type> to C<image>.

=cut

sub src {
    my $self = shift;

    $self->type('image') if @_;

    return $self->_src(@_);
}

=head2 retain_default

If true, overrides the default behaviour, so that after a field is missing 
from the form submission, the xml output will contain the default value, 
rather than be empty.

=head2 render

=head2 containerize

=cut

sub containerize {
    my ( $self, $w, $value, $errors, $args ) = @_;

    $value = ref $value eq 'ARRAY' ? shift @$value : $value;

    $value = $self->value
        if ( not defined $value )
        and $self->retain_default || not $args->{submitted};

    my $i;
    my %args = (
        type  => $self->type,
        value => $value,
    );

    $args{src}    = $self->src    if defined $self->src;
    $args{height} = $self->height if defined $self->height;
    $args{width}  = $self->width  if defined $self->width;

    if ( defined $self->content && length $self->content ) {
        $i = $self->mk_tag( $w, 'button', \%args );
        $i->push_content(
            HTML::Element->new( '~literal', text => $self->content ) );
    }
    else {
        $i = $self->mk_input( $w, \%args );
    }

    return $self->container( { element => $i } );
}

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Marcus Ramberg, C<mramberg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
