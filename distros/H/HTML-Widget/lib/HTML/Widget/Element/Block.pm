package HTML::Widget::Element::Block;

use warnings;
use strict;
use base 'HTML::Widget::Element::NullContainer';
use NEXT;
use Carp qw/croak/;

__PACKAGE__->mk_classaccessor(
    block_container_class => 'HTML::Widget::BlockContainer' );

__PACKAGE__->mk_accessors(qw/type wrap_sub/);

=head1 NAME

HTML::Widget::Element::Block - Block Level Element

=head1 SYNOPSIS

    my $e = $widget->element( 'Block', 'div' );
    $e->value('bar');

=head1 DESCRIPTION

Block Level Element.  Base class for HTML::Widget::Element::Fieldset

=head1 METHODS

=head2 new

Returns a new Block element.  Not usually required, use
$widget->element() or $block->element() to create a new Block element
within an existing widget or element.

=cut

sub new {
    return shift->NEXT::new(@_)->type('div');
}

=head2 type

Default value is div, to create a <div> container. Can be changed to 
create a tag of any type.

=head2 element

Add a new element, nested within this Block. See L<HTML::Widget/element> 
for full documentation.

=head2 push_content

Add previously-created elements to the end of this block's elements.

=head2 unshift_content

Add previously-created elements to the start of this block's elements.

=head2 block_container

Creates a new block container object of type $self->block_container_class. 
Defaults to L<HTML::Widget::BlockContainer>.

=cut

sub block_container {
    my ( $self, $attributes ) = @_;
    my $class = $self->block_container_class
        || 'HTML::Widget::BlockContainer';
    my $file = $class . ".pm";
    $file =~ s{::}{/}g;
    eval { require $file };
    croak "Unable to load block container class $class: $@" if $@;

    return $class->new( { passive => $self->passive, %$attributes } );
}

=head2 block_container_class

Sets the class to be used by $self->block_container.  Can be called as a
class or instance method.

=cut 

sub block_container_class {
    my ($self) = shift;

    if ( not $_[0] and @_ >= 1 ) {
        delete $self->{block_container_class};
    }

    return $self->_block_container_class_accessor(@_);
}

=head2 containerize

Containerize the block and all its contained elements for later
rendering. Uses HTML::Widget::BlockContainer by default, but this can
be over-ridden on a class or instance basis via
L<block_container_class>.

=cut

sub containerize {
    my ( $self, $w, $value, $error, $args ) = @_;

    # NB: block-level HTML::Element generated here
    my %attrs;
    unless ( $self->{_anonymous} ) {
        $attrs{id} = $self->id($w);
    }
    my $e = HTML::Element->new( $self->type, %attrs );

    my @pre_content  = $self->_pre_content_elements($w);
    my @post_content = $self->_post_content_elements($w);

    local $w->{attributes}->{id} = $self->id($w);

    my @content = $w->_containerize_elements( $self->content, $args );

    $e->attr( $_ => ${ $self->attributes }{$_} )
        for ( keys %{ $self->attributes } );

    return $self->block_container( {
            element      => $e,
            content      => \@content,
            pre_content  => \@pre_content,
            post_content => \@post_content,
            wrap_sub     => $self->wrap_sub,
            name         => $self->name,
        } );
}

sub _pre_content_elements  { return (); }
sub _post_content_elements { return (); }

=head2 get_elements

    my @elements = $self->get_elements;
    
    my @elements = $self->get_elements( type => 'Textfield' );
    
    my @elements = $self->get_elements( name => 'username' );

Returns a list of all elements added to the widget.

If a 'type' argument is given, only returns the elements of that type.

If a 'name' argument is given, only returns the elements with that name.

=head2 get_element

    my $element = $self->get_element;
    
    my $element = $self->get_element( type => 'Textfield' );
    
    my $element = $self->get_element( name => 'username' );

Similar to get_elements(), but only returns the first element in the list.

Accepts the same arguments as get_elements().

=head2 find_elements

Similar to get_elements(), and has the same alternate forms, but performs a
recursive search through itself and child elements.

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Michael Gray, C<mjg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
