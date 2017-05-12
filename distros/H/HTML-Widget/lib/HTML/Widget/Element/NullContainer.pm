package HTML::Widget::Element::NullContainer;

use warnings;
use strict;
use base 'HTML::Widget::Element';
use NEXT;
use Carp qw/croak/;

__PACKAGE__->mk_accessors(qw/content/);

*elem = \&element;

=head1 NAME

HTML::Widget::Element::NullContainer - Null Container Element

=head1 SYNOPSIS

    my $e = $widget->element( 'NullContainer');
    $e->element('Textfield', 'bar');

=head1 DESCRIPTION

NullContainer Level Element.  Base class for HTML::Widget::Element::Block
May also be useful for canned subwidgets.

See L<HTML::Widget::Element::Block> for documentation of most methods.

=head1 METHODS

=head2 new

Sets L<HTML::Widget::Element/allow_filter> to false, so that filters added 
by C<< $widget->filter_all >> won't be applied to Span elements.

Sets L<HTML::Widget::Element/allow_constraint> to false, so that constraints 
added by C<< $widget->constraint_all >> won't be applied to Span elements.

=cut

sub new {
    my $self = shift->NEXT::new(@_);

    $self->allow_filter(0)->allow_constraint(0)->content( [] );

    return $self;
}

=head2 elem

=head2 element

Arguments: $type, $name, \%attributes

Return Value: $element

See L<HTML::Widget/element> for details.

=cut

sub element {
    my ( $self, $type, $name, $attrs ) = @_;

    my $abs = $type =~ s/^\+//;
    $type = "HTML::Widget::Element::$type" unless $abs;

    my $element = HTML::Widget->_instantiate( $type, { name => $name } );

    $element->{_anonymous} = 1 if !defined $name;

    $self->push_content($element);

    if ( defined $attrs ) {
        eval { $element->attributes->{$_} = $attrs->{$_} for keys %$attrs; };
        croak "attributes argument must be a hash-reference: $@" if $@;
    }

    return $element;
}

=head2 push_content

=cut

sub push_content {
    push @{ shift->content }, @_;
}

=head2 unshift_content

=cut

sub unshift_content {
    unshift @{ shift->content }, @_;
}

=head2 containerize

=cut

sub containerize {
    my ( $self, $w, $value, $error, $args ) = @_;

    local $w->{attributes}->{id} = $self->id($w);

    my @content = $w->_containerize_elements( $self->content, $args );

    return HTML::Widget::NullContainer->new( {
            passive => $self->passive,
            element => 1,
            content => \@content,
            name    => $self->name,
        } );
}

=head2 id

=cut

sub id {
    my ( $self, $w ) = @_;
    return $w->name if $self->{_anonymous};
    my $name = $self->name();
    if ( $name =~ s/^_implicit_// ) {

        # $name is left set to the name of the
        # original parent widget of this element, as set by
        # H::W::_setup_implicit_subcontainer.
    }
    return $w->name . '_' . $name;
}

=head2 get_elements

=cut

sub get_elements {
    my ( $self, %opt ) = @_;

    return $self->_match_elements( $self->content, \%opt );
}

=head2 get_element

=cut

sub get_element {
    my ( $self, %opt ) = @_;

    return ( $self->get_elements(%opt) )[0];
}

=head2 find_elements

=cut

sub find_elements {
    my ( $self, %opt ) = @_;

    my @elements = ($self);
    push @elements, map { $_->find_elements(%opt) } @{ $self->content };

    return $self->_match_elements( \@elements, \%opt );
}

sub _match_elements {
    my ( $self, $elements, $opt ) = @_;

    if ( exists $opt->{type} ) {
        my $type = "HTML::Widget::Element::$opt->{type}";

        return grep { $_->isa($type) } @$elements;
    }
    elsif ( exists $opt->{name} ) {
        my $name = $opt->{name};

        return grep { $_->name and $_->name eq $name } @$elements;
    }

    return @$elements;
}

=head2 prepare

See L<HTML::Widget::Element/prepare>

=cut

sub prepare {
    my ( $self, $w ) = @_;
    map { $_->prepare($w) } @{ $self->content };
}

=head2 init

See L<HTML::Widget::Element/init>

=cut

sub init {
    my ( $self, $w ) = @_;
    for my $element ( @{ $self->content } ) {
        $element->init($w) unless $element->{_initialized};
        $element->{_initialized}++;
    }
}

=head2 process

See L<HTML::Widget::Element/process>

=cut

sub process {
    my ( $self, $params, $uploads ) = @_;
    my $errors;
    for my $element ( @{ $self->content } ) {
        my $er = $element->process( $params, $uploads );
        push @$errors, @$er if $er;
    }
    return $errors;
}

=head1 SEE ALSO

L<HTML::Widget::Element>

=head1 AUTHOR

Michael Gray, C<mjg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

package HTML::Widget::NullContainer;

use warnings;
use strict;
use base 'HTML::Widget::Container';

__PACKAGE__->mk_accessors(qw/content/);

sub _build_element {
    my $self = shift;
    return ( map { $_->as_list } @{ $self->content } );
}

1;
