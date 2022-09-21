##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Area.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/26
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Area;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :area );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'area' if( !$self->tag );
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

# Note: property accessKey inherited

# Note: property alt inherited

# Note: property
sub coords : lvalue { return( shift->_set_get_property( 'coords', @_ ) ); }

# Note: property download inherited

# Note: property hash inherited

# Note: property host inherited

# Note: property hostname inherited

# Note: property href inherited

# Note: property
sub noHref : lvalue { return( shift->_set_get_property( { attribute => 'nohref', is_boolean => 1 }, @_ ) ); }

# Note: property origin inherited

# Note: property password inherited

# Note: property pathname inherited

# Note: property port inherited

# Note: property protocol inherited

# Note: property referrerPolicy inherited

# Note: property rel inherited

# Note: property relList inherited

# Note: property search inherited

# Note: property
sub shape : lvalue { return( shift->_set_get_property( 'shape', @_ ) ); }

# Note: tabIndex is inherited from HTML::Object::DOM::Element

# Note: property target inherited

sub toString { return( shift->attr( 'href' ) ); }

# Note: property username inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Area - HTML Object DOM Area Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Area;
    my $area = HTML::Object::DOM::Element::Area->new || 
        die( HTML::Object::DOM::Element::Area->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond those of the regular object L<HTML::Object::Element> interface it also has available to it by inheritance) for manipulating the layout and presentation of C<<area>> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Area |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 accessKey

Is a string containing a single character that switches input focus to the control.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/accessKey>

=head2 alt

Is a string that reflects the alt HTML attribute, containing alternative text for the element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/alt>

=head2 coords

Is a string that reflects the coords HTML attribute, containing coordinates to define the hot-spot region.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/coords>

=head2 download

Is a string indicating that the linked resource is intended to be downloaded rather than displayed in the browser. The value represent the proposed name of the file. If the name is not a valid filename of the underlying OS, browser will adapt it.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/download>

=head2 hash

Is a string containing the fragment identifier (including the leading hash mark (#)), if any, in the referenced URL.

Example:

    <map name="infographic">
        <area id="circle" shape="circle" coords="130,136,60"
        href="https://example.org/#ExampleSection" alt="Documentation" />
    </map>

    <img usemap="#infographic" src="/some/where/info.png" alt="Infographic" />

    my $area = $doc->getElementById('circle');
    $area->hash; # returns '#ExampleSection'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/hash>

=head2 host

Is a string containing the hostname and port (if it's not the default port) in the referenced URL.

Example:

    my $area = $doc->createElement('area');

    $area->href = 'https://example.org/some/where';
    $area->host == 'example.org';

    $area->href = "https://example.org:443/some/where";
    $area->host == 'example.org';
    # The port number is not included because 443 is the scheme's default port

    $area->href = "https://example.org:4097/some/where";
    $area->host == 'example.org:4097';

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/host>

=head2 hostname

Is a string containing the hostname in the referenced URL.

Example:

    # An <area id="myArea" href="https://example.org/some/where"> element is in the document
    my $area = $doc->getElementById('myArea');
    $area->hostname; # returns 'example.org'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/hostname>

=head2 href

Is a string containing that reflects the href HTML attribute, containing a valid URL of a linked resource.

Example:

    # An <area id="myArea" href="https://example.org/some/where"> element is in the document
    my $area = $doc->getElementById("myArea");
    $area->href; # returns 'https://example.org/some/where'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/href>

=head2 noHref

Is a boolean flag indicating if the area is inactive (true) or active (false). This is an HTML attribute.

Example:

    <map name="SampleMap">
        <area shape="rect" coords="1,1,83,125" alt="rectangle" nohref="">
        <area shape="circle" coords="234,57,30" alt="circle" href="#">
        <area shape="poly" coords="363,37,380,40,399,35,420,47,426,63,423,78,430,94,409,90,395,92,379,84,371,67,370,57" alt="polygon" href="#">
    </map>
    
See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/noHref>

=head2 origin

Read-only.

Returns a string containing the origin of the URL, that is its scheme, its domain and its port.

Example:

    # An <area id="myArea" href="https://example.org/some/where"> element is in the document
    my $area = $doc->getElementById("myArea");
    $area->origin; # returns 'https://example.org'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/origin>

=head2 password

Is a string containing the password specified before the domain name.

Example:

    # An <area id="myArea" href="https://anonymous:flabada@example.org/some/where"> is in the document
    my $area = $doc->getElementByID("myArea");
    $area->password; # returns 'flabada'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/password>

=head2 pathname

Is a string containing the path name component, if any, of the referenced URL.

Example:

    # An <area id="myArea" href="/some/where"> element is in the document
    my $area = $doc->getElementById("myArea");
    $area->pathname; # returns '/some/where'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/pathname>

=head2 port

Is a string containing the port component, if any, of the referenced URL.

Example:

    # An <area id="myArea" href="https://example.org:443/some/where"> element is in the document
    my $area = $doc->getElementByID("myArea");
    $area->port; # returns '443'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/port>

=head2 protocol

Is a string containing the protocol component (including trailing colon ':'), of the referenced URL.

Example:

    # An <area id="myArea" href="https://example.org/some/where"> element is in the document
    my $area = $doc->getElementById("myArea");
    $area->protocol; # returns 'https:'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/protocol>

=head2 referrerPolicy

Is a string that reflects the referrerpolicy HTML attribute indicating which referrer to use when fetching the linked resource.

Example:

    <img usemap="#mapAround" width="100" height="100" src="/img/logo@2x.png" />
    <map id="myMap" name="mapAround" />>

    my $elt = $doc->createElement("area");
    $elt->href = "/img2.png";
    $elt->shape = "rect";
    $elt->referrerPolicy = "no-referrer";
    $elt->coords = "0,0,100,100";
    my $map = $doc->getElementById("myMap");

    $map->appendChild($elt);
    # When clicked, the area's link will not send a referrer header.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/referrerPolicy>

=head2 rel

Is a string that reflects the rel HTML attribute, indicating relationships of the current document to the linked resource.

Example:

    my $areas = $doc->getElementsByTagName("area");
    my $length = $areas->length;
    for( my $i = 0; $i < $length; $i++ )
    {
        say("Rel: " + $areas->[$i]->rel);
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/rel>

=head2 relList

Returns a L<HTML::Object::TokenList> that reflects the rel HTML attribute, indicating relationships of the current document to the linked resource, as a list of tokens.

Example:

    my $areas = $doc->getElementsByTagName("area");
    my $length = $areas->length;

    for( my $i = 0; $i < $length; $i++ )
    {
        my $list = $areas->[$i]->relList;
        my $listLength = $list->length;
        say( "New area found." );
        for( my $j = 0; $j < $listLength; $j++ )
        {
            say( $list->[$j] );
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/relList>

=head2 search

Is a string containing the search element (including leading question mark '?'), if any, of the referenced URL.

Example:

    # An <area id="myArea" href="/some/where?q=123"> element is in the document
    my $area = $doc->getElementById("myArea");
    $area->search; # returns '?q=123'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/search>

=head2 shape

Is a string that reflects the shape HTML attribute, indicating the shape of the hot-spot, limited to known values.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/shape>

=head2 tabIndex

Is a long containing the element's position in the tabbing order.

Example:

    my $b1 = $doc->getElementById('button1');
    $b1->tabIndex = 1;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/tabIndex>

=head2 target

Is a string that reflects the target HTML attribute, indicating the browsing context in which to open the linked resource.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/target>

=head2 username

Is a string containing the username specified before the domain name.

Example:

    # An <area id="myArea" href="https://anonymous:flabada@example.org/some/where"> element is in the document
    my $area = $doc->getElementByID("myArea");
    $area->username; # returns 'anonymous'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/username>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 toString

Returns a string containing the whole URL of the script executed in the Worker. It is a synonym for L<HTML::Object::DOM::Element::Area/href>.

Example:

    # An <area id="myArea" href="/some/where"> element is in the document
    my $area = $doc->getElementById("myArea");
    $area->toString(); # returns 'https://example.org/some/where'

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement/toString>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAreaElement>, L<Mozilla documentation on area element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/area>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
