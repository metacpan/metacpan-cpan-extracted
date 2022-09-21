##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Template.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/09
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Template;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'template' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property content read-only
sub content : lvalue { return( shift->_lvalue({
    set => sub
    {
        my $self = shift( @_ );
        my $ref = shift( @_ );
        my $nodes = $self->_list_to_nodes( @$ref ) ||
            return( $self->pass_error );
        for( @$nodes )
        {
            $_->detach;
            $_->parent( $self );
        }
        my $children = $self->children;
        $children->set( $nodes );
        return( $self );
    },
    get => sub
    {
        my $self = shift( @_ );
        $self->_load_class( 'HTML::Object::DOM::DocumentFragment' ) ||
            return( $self->pass_error );
        my $children = $self->children;
        my $frag = HTML::Object::DOM::DocumentFragment->new;
        $frag->children->set( $children );
        return( $frag );
    }
}, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Template - HTML Object DOM Template Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Template;
    my $template = HTML::Object::DOM::Element::Template->new || 
        die( HTML::Object::DOM::Element::Template->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface enables access to the contents of an HTML C<template> element.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Template |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 content

Read-only.

A read-only L<DocumentFragment|HTML::Object::DOM::DocumentFragment> which contains the DOM subtree representing the <template> element's template contents.

Example:

    my $templateElement = $doc->querySelector('#foo');
    my $documentFragment = $templateElement->content->cloneNode(1); # pass true to cloneNode

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTemplateElement/content>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTemplateElement>, L<Mozilla documentation on template element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/template>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
