##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Link.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/22
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Link;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :link );
    # There are a few properties and methods that are common to AnchorElement class, so
    # instead of re-writing them, we re-use those from AnchorElement.
    require HTML::Object::DOM::Element::Anchor;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'link' if( !CORE::length( "$self->{tag}" ) );
    $self->_set_get_internal_attribute_callback( rel => sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_rel_list} ) );
        # $list->debug( $self->debug );
        $list->update( $val );
    });
    $self->_set_get_internal_attribute_callback( sizes => sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_sizes_list} ) );
        # $list->debug( $self->debug );
        $list->update( $val );
    });
    return( $self );
}

# Note: property
sub as : lvalue { return( shift->_set_get_property( 'as', @_ ) ); }

# Note: property crossOrigin inherited

# Note: property disabled inherited

# Note: property href inherited

# Note: property hreflang inherited

# Note: property
sub media : lvalue { return( shift->_set_get_property( 'media', @_ ) ); }

# Note: property referrerPolicy inherited

# Note: property rel inherited

# Note: property relList inherited

# Note: property
sub sizes
{
    my $self = shift( @_ );
    unless( $self->{_sizes_list} )
    {
        my $sizes  = $self->attr( 'sizes' );
        require HTML::Object::TokenList;
        $self->{_sizes_list} = HTML::Object::TokenList->new( $sizes, element => $self, attribute => 'sizes', debug => $self->debug ) ||
            return( $self->pass_error( HTML::Object::TokenList->error ) );
    }
    return( $self->{_sizes_list} );
}

# TODO: make call to this method return a CSS::Object
# Note: property
sub sheet { return; }

# Note: property type inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Link - HTML Object DOM Link Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Link;
    my $link = HTML::Object::DOM::Element::Link->new || 
        die( HTML::Object::DOM::Element::Link->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<LinkElement> interface represents reference information for external resources and the relationship of those resources to a document and vice-versa (corresponds to <link> element; not to be confused with <a>, which is represented by L<HTML::Object::DOM::Element::Anchor>). This object inherits all of the properties and methods of the L<HTML::Object::DOM::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Link |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::DOM::Element>

=head2 as

A string representing the type of content being loaded by the HTML link.

Example:

    <link rel="preload" href="myFont.woff2" as="font"
      type="font/woff2" crossorigin="anonymous">

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/as>

=head2 crossOrigin

A string that corresponds to the CORS setting for this link element. See CORS settings attributes for details.

Example:

    <link rel="preload" href="myFont.woff2" as="font"
      type="font/woff2" crossorigin="anonymous">

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/crossOrigin>

=head2 disabled

A boolean value which represents whether the link is disabled; currently only used with style sheet links.

If the boolean value provided is false, the disabled property will be removed altogether. If it is true, it will be set to an empty value.

Example:

    my $link = $doc->createElement( 'link' );
    $link->disabled = 1;
    # <link disabled="" />
    $link->disabled = 0;
    # <link />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/disabled>

=head2 href

A string representing the URI for the target resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/href>

=head2 hreflang

A string representing the language code for the linked resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/hreflang>

=head2 media

A string representing a list of one or more media formats to which the resource applies.

Example:

    <link href="print.css" rel="stylesheet" media="print" />
    <link href="mobile.css" rel="stylesheet" media="screen and (max-width: 600px)" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/media>

=head2 referrerPolicy

A string that reflects the referrerpolicy HTML attribute indicating which referrer to use.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/referrerPolicy>

=head2 rel

A string representing the forward relationship of the linked resource from the document to the resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/rel>

=head2 relList

Read-only.

A L<HTML::Object::TokenList> that reflects the rel HTML attribute, as a L<list of tokens|HTML::Object::DOM::TokenList>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/relList>

=head2 sizes

Read-only.

A L<HTML::Object::TokenList> that reflects the sizes HTML attribute, as a L<list of tokens|HTML::Object::DOM::TokenList>.

    <link rel="apple-touch-icon-precomposed" sizes="114x114"
          href="apple-icon-114.png" type="image/png">

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/sizes>

=head2 sheet

Read-only.

This currently always returns C<undef>. Maybe in the future this would return a L<CSS::Object> object.

Normally, under JavaScript environment, this would return the L<StyleSheet object|https://developer.mozilla.org/en-US/docs/Web/API/CSSStyleSheet> associated with the given element, or C<undef> if there is none.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/sheet> and also the L<CSSObject documentation|https://developer.mozilla.org/en-US/docs/Web/API/CSSStyleSheet>

=head2 type

A string representing the MIME type of the linked resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement/type>

=head1 METHODS

No specific method; inherits methods from its parent, L<HTML::Object::DOM::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLLinkElement>, L<specification on link|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/link>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
