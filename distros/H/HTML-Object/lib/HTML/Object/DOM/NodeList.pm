##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/NodeList.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/01
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::NodeList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Array );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub forEach { return( shift->foreach( @_ ) ); }

sub item { return( shift->index( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::NodeList - HTML Object DOM NodeList Class

=head1 SYNOPSIS

    use HTML::Object::DOM::NodeList;
    my $list = HTML::Object::DOM::NodeList->new || 
        die( HTML::Object::DOM::NodeList->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

C<NodeList> objects are collections of L<nodes|HTML::Object::DOM::Node>, usually returned by properties such as L<HTML::Object::DOM::Node/childNodes> and methods such as L<HTML::Object::DOM::Document/querySelectorAll>.

=head1 PROPERTIES

=head2 length

The number of nodes in the C<NodeList>.

Example:

    # All the paragraphs in the document
    my $items = $doc->getElementsByTagName("p");

    # For each item in the list,
    # append the entire element as a string of HTML
    my $gross = "";
    for( my $i = 0; $i < $items->length; $i++ )
    {
        $gross += $items->[$i]->innerHTML;
    }
    # $gross is now all the HTML for the paragraphs

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeList/length>

=head1 METHODS

Inherits methods from its parent L<Module::Generic::Array>

=head2 forEach

Executes a provided code reference (reference to a subroutine or anonymous subroutine) once per C<NodeList> element, passing the element as an argument to the subroutine.

Example:

    my $node = $doc->createElement("div");
    my $kid1 = $doc->createElement("p");
    my $kid2 = $doc->createTextNode("hey");
    my $kid3 = $doc->createElement("span");

    $node->appendChild( $kid1 );
    $node->appendChild( $kid2 );
    $node->appendChild( $kid3 );

    my $list = $node->childNodes;
    $list->forEach(sub(currentValue, currentIndex, listObj)
    {
        my( $currentValue, $currentIndex, $listObj ) = @_;
        say( "$currentValue, $currentIndex, $_" );
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeList/forEach>

=head2 item

Returns an item in the list by its index, or C<undef> if the index is out-of-bounds.
An alternative to accessing nodeList[i] (which instead returns  undefined when i is out-of-bounds). This is mostly useful for non-JavaScript DOM implementations.

Example:

    my $tables = $doc->getElementsByTagName( 'table' );
    my $firstTable = $tables->item(1); # or $tables->[1] - returns the second table in the DOM

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeList/item>

=head2 keys

Returns an iterator, allowing code to go through all the keys of the key/value pairs contained in the collection. (In this case, the keys are numbers starting from 0.)

Example:

    my $node = $doc->createElement("div");
    my $kid1 = $doc->createElement("p");
    my $kid2 = $doc->createTextNode("hey");
    my $kid3 = $doc->createElement("span");

    $node->appendChild( $kid1 );
    $node->appendChild( $kid2 );
    $node->appendChild( $kid3 );

    my $list = $node->childNodes;

    # Using for..of
    foreach my $key ( $list->keys->list )
    {
        say( $key );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeList/keys>

=head2 values

Returns an iterator allowing code to go through all values (nodes) of the key/value pairs contained in the collection.

Example:

    my $node = $doc->createElement("div");
    my $kid1 = $doc->createElement("p");
    my $kid2 = $doc->createTextNode("hey");
    my $kid3 = $doc->createElement("span");

    $node->appendChild( $kid1 );
    $node->appendChild( $kid2 );
    $node->appendChild( $kid3 );

    my $list = $node->childNodes;

    # Using for..of
    foreach my $value ( $list->values )
    {
        say( $value );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeList/values>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/NodeList>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
