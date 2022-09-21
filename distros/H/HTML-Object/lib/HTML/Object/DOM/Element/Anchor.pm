##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Anchor.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/21
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Anchor;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object;
    use HTML::Object::DOM::Element::Shared qw( :anchor );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'a' if( !$self->tag );
    $self->{uri} = '';
    $self->_set_get_internal_attribute_callback( rel => sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_rel_list} ) );
        # $list->debug( $self->debug );
        $list->update( $val );
    });
    return( $self );
}

# Note: property download inherited

# Note: property hash inherited

# Note: property host inherited

# Note: property hostname inherited

# Note: property href inherited

# Note: property hreflang inherited

# Note: read-only property origin inherited

# Note: property password inherited

# Note: property pathname inherited

# Note: property port inherited

# Note: property protocol inherited

# Note: property referrerPolicy inherited

# Note: property rel inherited

# Note: property read-only relList inherited. Similar to HTML::Object::DOM::Element->classList

# Note: property search inherited

# Note: tabIndex is inherited from HTML::Object::DOM::Element

# Note: property target inherited

# Note: alias for textContent in HTML::Object::DOM::Node
# Note: property
sub text : lvalue { return( shift->textContent( @_ ) ); }

sub toString { return( shift->attr( 'href' ) ); }

# Note: property
sub type : lvalue { return( shift->_set_get_property( 'type', @_ ) ); }

# Note: property username inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Anchor - HTML Object DOM Link Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Anchor;
    my $link = HTML::Object::DOM::Element::Anchor->new || 
        die( HTML::Object::DOM::Element::Anchor->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This implements an HTML link element. It inherits from L<HTML::Object::DOM::Element>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Anchor |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

This class inherits properties from its parent, L<HTML::Object::DOM::Element>.

=head2 download

This indicates that the linked resource is intended to be downloaded rather than displayed in the browser. The value represent the proposed name of the file.

Note that you can put whatever you want here, but it does not mean the web browser will accept it and let alone act upon it. Research the reliability of this attribute first before relying on it.

Example:

    <a id="myAnchor" href="/some/where#nice">Nice spot</a>

    my $anchor = $doc->getElementById("myAnchor");
    $anchor->download = 'my_file.txt';
    # link is now:
    # <a id="myAnchor" href="/some/where#nice" download="nice_file.txt">Nice spot</a>

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/download>

=head2 hash

Is a string representing the fragment identifier, including the leading hash mark ('#'), if any, in the referenced URL.

Example:

    <a id="myAnchor" href="/some/where#nice">Examples</a>

    my $anchor = $doc->getElementById("myAnchor");
    $anchor->hash; # returns '#nice'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/hash>

=head2 host

Is a string representing the hostname and port (if it's not the default port) in the referenced URL.

Example:

    my $anchor = $document->createElement("a");

    $anchor->href = "https://example.org/some/where"
    $anchor->host = "example.org"

    $anchor->href = "https://example.org:443/some/where"
    $anchor->host = "example.org"
    # The port number is not included because 443 is the scheme's default port

    $anchor->href = "https://example.org:4097/some/where"
    $anchor->host = "example.org:4097"

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/host>

=head2 hostname

Is a string representing the hostname in the referenced URL.

Example:

    # An <a id="myAnchor" href="https://example.org/some/where"> element is in the document
    my $anchor = $doc->getElementById("myAnchor");
    $anchor->hostname; # returns 'example.org'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/hostname>

=head2 href

Is a string that is the result of parsing the href HTML attribute relative to the document, containing a valid URL of a linked resource.

    # An <a id="myAnchor" href="https://example.org/some/where"> element is in the document
    my $anchor = $doc->getElementById("myAnchor");
    $anchor->href; # returns 'https://example.org/some/where'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/href>

=head2 hreflang

Is a string that reflects the hreflang HTML attribute, indicating the language of the linked resource.

Example:

    <a href="https://example.org/ja-jp/some/where" hreflang="ja">マニュアル</a>
    var lang = document.getElementById("myAnchor").hreflang; # ja

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/hreflang>

=head2 origin

Read-only.

Returns a string containing the origin of the URL, that is its scheme, its domain and its port.

Example:

    # An <a id="myAnchor" href="https://example.org/some/where"> element is in the document
    my $anchor = $doc->getElementById("myAnchor");
    $anchor->origin; # returns 'https://example.org'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/origin>

=head2 password

Is a string containing the password specified before the domain name.

Example:

    # An <a id="myAnchor" href="https://anonymous:flabada@example.org/some/where"> is in the document
    my $anchor = $doc->getElementByID("myAnchor");
    $anchor->password; # returns 'flabada'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/password>

=head2 pathname

Is a string containing an initial '/' followed by the path of the URL, not including the query string or fragment.

    # An <a id="myAnchor" href="https://example.org/some/where"> element is in the document
    my $anchor = $doc->getElementById("myAnchor");
    $anchor->pathname; # returns '/some/where'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/pathname>

=head2 port

Is a string representing the port component, if any, of the referenced URL.

    # An <a id="myAnchor" href="https://example.org:443/some/where"> element is in the document
    my $anchor = $doc->getElementByID("myAnchor");
    $anchor->port; # returns '443'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/port>

=head2 protocol

Is a string representing the protocol component, including trailing colon (':'), of the referenced URL.

    # An <a id="myAnchor" href="https://example.org/some/where"> element is in the document
    my $anchor = $doc->getElementById("myAnchor");
    $anchor->protocol; # returns 'https:'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/protocol>

=head2 referrerPolicy

Is a string that reflects the referrerpolicy HTML attribute indicating which referrer to use.

A proper value is one of the following:

=over 4

=item no-referrer

The Referer header will be omitted entirely. No referrer information is sent along with requests.

=item no-referrer-when-downgrade

The URL is sent as a referrer when the protocol security level stays the same (e.g.HTTP→HTTP, HTTPS→HTTPS), but is not sent to a less secure destination (e.g. HTTPS→HTTP).

=item origin

Only send the origin of the document as the referrer in all cases. The document C<https://example.com/page.html> will send the referrer C<https://example.com/>.

=item origin-when-cross-origin

Send a full URL when performing a same-origin request, but only send the origin of the document for other cases.

=item same-origin

A referrer will be sent for same-site origins, but cross-origin requests will contain no referrer information.

=item strict-origin

Only send the origin of the document as the referrer when the protocol security level stays the same (e.g. HTTPS→HTTPS), but do not send it to a less secure destination (e.g. HTTPS→HTTP).

=item strict-origin-when-cross-origin (default)

This is the user agent's default behavior if no policy is specified. Send a full URL when performing a same-origin request, only send the origin when the protocol security level stays the same (e.g. HTTPS→HTTPS), and send no header to a less secure destination (e.g. HTTPS→HTTP).

=item unsafe-url

Send a full URL when performing a same-origin or cross-origin request. This policy will leak origins and paths from TLS-protected resources to insecure origins. Carefully consider the impact of this setting.

=back

Example:

    my $elt = $doc->createElement("a");
    my $linkText = $doc->createTextNode("My link");
    $elt->appendChild( $linkText );
    $elt->href = "https://example.org/ja-jp/";
    $elt->referrerPolicy = "no-referrer";

    my $div = $doc->getElementById("divAround");
    $div->appendChild( $elt ); # When clicked, the link will not send a referrer header.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/referrerPolicy>

=head2 rel

Is a string that reflects the rel HTML attribute, specifying the relationship of the target object to the linked object.

You can set whatever value you want, but standard values are:

=over 4

=item L<alternate|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-alternate>

=item L<author|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-author>

=item L<bookmark|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-bookmark>

=item L<help|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-help>

=item L<license|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-license>

=item L<manifest|https://developer.mozilla.org/en-US/docs/Web/HTML/Link_types/manifest>

=item L<next|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-next>

=item L<prev|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-prev>

=item L<search|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-search>

=item L<tag|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel#attr-tag>

=back

Example:

    my $anchors = $doc->getElementsByTagName("a");
    my $length = $anchors->length;
    for( my $i = 0; $i < $length; $i++ )
    {
        say( "Rel: " + anchors->[$i]->rel );
    }

could print:

    Re;: noopener noreferrer

The C<noopener> value prevents the newly opened page from controlling the page that delivered the traffic. This is because, in the case of C<target> attribute set to C<_blank>, for example, the newly opened page can access the current window object with the C<window.opener> property. This may also allow the new page to redirect the current page to a malicious URL. This makes the link behave as if window.opener were null and target="_parent" were set.

The C<noreferrer> value prevents the web browser from sending the referrer information to the target site. C<noreferrer> attribute has the same effect as C<noopener> and is well supported, but often both are used for when C<noopener> is not supported.

To mitigate this issue, you could do:

    # Replace 'example.org' by whatever your safe domain name is
    $doc->getElementsByTagName( 'a' )->foreach(sub
    {
        if( $_->href->host ne 'example.org' && 
            $_->hasAttribute( 'target' ) && 
            $_->getAttribute( 'target' ) eq '_blank' )
        {
            $_->relList->add( qw( noopener noreferrer ) );
        }
    });

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/rel>, L<Mozilla documentation on rel|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel>, L<StackOverflow discussion|https://stackoverflow.com/questions/57628890/why-people-use-rel-noopener-noreferrer-instead-of-just-rel-noreferrer>

L<W3C specification|https://html.spec.whatwg.org/multipage/links.html#link-type-noreferrer>

=head2 relList

Read-only.

Returns a L<TokenList|HTML::Object::TokenList> that reflects the rel HTML attribute, as a list of link types indicating the relationship between the resource represented by the <a> element and the current document.

The property itself is read-only, meaning you can not substitute the L<TokenList|HTML::Object::TokenList> with another one, but its contents can still be changed. 

Example:

    my $anchors = $doc->getElementsByTagName("a");
    my $length = $anchors->length;
    for( my $i = 0; $i < $length; $i++ )
    {
        my $list = $anchors->[$i]->relList;
        my $listLength = $list->length;
        say( "New anchor node found with", $listLength, "link types in relList." );
        for( my $j = 0; $j < $listLength; $j++ )
        {
            say( $list->[$j] );
        }
    }

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/relList>

=head2 search

Is a string representing the search element, including leading question mark ('?'), if any, of the referenced URL.

Example:

    # An <a id="myAnchor" href="/some/where?q=123"> element is in the document
    my $anchor = $doc->getElementById("myAnchor");
    $anchor->search; # returns '?q=123'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/search>

=head2 tabIndex

Is a long containing the position of the element in the tabbing navigation order for the current document.

See L<HTML::Object::DOM::Element/tabIndex>

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/tabIndex>

=head2 target

Is a string that reflects the target HTML attribute, indicating where to display the linked resource.

Example:

    $doc->getElementById("myAnchor")->target = "_blank";

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/target>

=head2 text

Is a string being a synonym for the L<HTML::Object::DOM::Node/textContent> property.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/text>

=head2 type

Is a string that reflects the type HTML attribute, indicating the MIME type of the linked resource.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/type>

=head2 username

Is a string containing the username specified before the domain name.

Example:

    # An <a id="myAnchor" href="https://anonymous:flabada@example.org/some/where"> element is in the document
    my $anchor = $doc->getElementByID("myAnchor");
    $anchor->username; # returns 'anonymous'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/username>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 toString

Returns a string containing the whole URL. It is a synonym for HTMLAnchorElement.href, though it can't be used to modify the value.

Example:

    # An <a id="myAnchor" href="https://example.org/some/where"> element is in the document
    my $anchor = $doc->getElementById("myAnchor");
    $anchor->toString(); # returns 'https://example.org/some/where'

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement/toString>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAnchorElement>, L<Mozilla documentation on anchor element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
