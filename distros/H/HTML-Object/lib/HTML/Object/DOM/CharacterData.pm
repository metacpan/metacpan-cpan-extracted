##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/CharacterData.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/20
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::CharacterData;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Node );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

# There is no constructor, because this is just an abstract interface to be inherited from by HTML::Object::DOM::Text, HTML::Object::DOM::Comment or HTML::Object::DOM::Space

sub after
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $pos = $parent->children->pos( $self );
    return( $self->error({
        message => "This CharacterData object cannot be found in its parent node.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    $self->_sanity_check_for_before_after( $list ) ||
        return( $self->pass_error );
    
    $parent->children->splice( $pos + 1, 0, $list->list );
    $list->foreach(sub
    {
        $_->parent( $parent );
    });
    $parent->reset(1);
    return( $self );
}

sub appendData { return( shift->value->append( @_ ) ); }

sub before
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $pos = $parent->children->pos( $self );
    return( $self->error({
        message => "This CharacterData object cannot be found in its parent node.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    my $list = $self->_get_from_list_of_elements_or_html( @_ );
    $self->_sanity_check_for_before_after( $list ) ||
        return( $self->pass_error );
    
    $list->foreach(sub
    {
        $parent->children->splice( $pos, 0, $_ );
        $_->parent( $parent );
        $pos++;
    });
    $parent->reset(1);
    return( $self );
}

# Note: property
sub data : lvalue { return( shift->_set_get_lvalue( 'value', @_ ) ); }

sub deleteData
{
    my $self = shift( @_ );
    my $offset = shift( @_ );
    my $len = shift( @_ );
    $offset = "$offset" if( ref( $offset ) && overload::Method( $offset, '""' ) );
    $len = "$len" if( ref( $len ) && overload::Method( $len, '""' ) );
    return( $self->error({
        message => "Offset value provided \"$offset\" is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $offset ) );
    return( $self->error({
        message => "Length value provided \"$len\" is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $len ) );
    $offset = int( $offset );
    $len = int( $len );
    return( $self->error({
        message => "Offset value is greater than the size of the CharacterData object.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $offset > $self->value->length );
    $self->value->substr( $offset, $len, '' );
    $self->reset(1);
    return( $self );
}

sub insertData
{
    my $self = shift( @_ );
    my $offset = shift( @_ );
    my $str = shift( @_ );
    # Nothing to do, stop here
    return( $self ) if( !defined( $str ) || !CORE::length( "$str" ) );
    $offset = "$offset" if( ref( $offset ) && overload::Method( $offset, '""' ) );
    $str = "$str";
    return( $self->error({
        message => "Offset value provided \"$offset\" is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $offset ) );
    $offset = int( $offset );
    return( $self->error({
        message => "Offset value is greater than the size of the CharacterData object.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $offset > $self->value->length );
    $self->value->substr( $offset, 0, $str );
    $self->reset(1);
    return( $self );
}

# Note: property
sub length { return( shift->value->length ); }

# Note: property
sub nextElementSibling
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $pos = $parent->children->pos( $self );
    return( $self->error({
        message => "This CharacterData object cannot be found in its parent node.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    return( $parent->children->index( $pos + 1 ) );
}

# Note: property
sub previousElementSibling
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $pos = $parent->children->pos( $self );
    return( $self->error({
        message => "This CharacterData object cannot be found in its parent node.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    return if( $pos <= 0 );
    return( $parent->children->index( $pos - 1 ) );
}

sub remove
{
    my $self = shift( @_ );
    my $parent = $self->parent || return;
    my $pos = $parent->children->pos( $self );
    return( $self->error({
        message => "This CharacterData object cannot be found in its parent node.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    $parent->children->splice( $pos, 1 );
    $parent->reset(1);
    return( $self );
}

sub replaceData
{
    my $self = shift( @_ );
    my $offset = shift( @_ );
    my $len = shift( @_ );
    my $str = shift( @_ );
    # It is ok to be provided an undefined value, but we convert it to an empty string
    # to prevent perl from triggering warnings.
    $str //= '';
    $offset = "$offset" if( ref( $offset ) && overload::Method( $offset, '""' ) );
    $len = "$len" if( ref( $len ) && overload::Method( $len, '""' ) );
    return( $self->error({
        message => "Offset value provided \"$offset\" is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $offset ) );
    return( $self->error({
        message => "Length value provided \"$len\" is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $len ) );
    $offset = int( $offset );
    $len = int( $len );
    $str = "$str";
    return( $self->error({
        message => "Offset value is greater than the size of the CharacterData object.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $offset > $self->value->length );
    $self->value->substr( $offset, $len, $str );
    $self->reset(1);
    return( $self );
}

sub replaceWith
{
    my $self = shift( @_ );
    my $parent = $self->parent || return( $self->error({
        message => "This CharacterData has no parent.",
        class => 'HTML::Object::HierarchyRequestError',
    }) );
    my $pos = $parent->children->pos( $self );
    my $list = _get_from_list_of_elements_or_html( @_ );
    return( $self->error({
        message => "This CharacterData object cannot be found in its parent node.",
        class => 'HTML::Object::HierarchyRequestError',
    }) ) if( !defined( $pos ) );
    # There is nothing to do
    return( $self ) if( $list->is_empty );
    $parent->children->splice( $pos, 1, $list->list );
    $list->foreach(sub
    {
        $_->parent( $parent );
    });
    $parent->reset(1);
    return( $self );
}

sub substringData
{
    my $self = shift( @_ );
    my $offset = shift( @_ );
    my $len = shift( @_ );
    $offset = "$offset" if( ref( $offset ) && overload::Method( $offset, '""' ) );
    $len = "$len" if( ref( $len ) && overload::Method( $len, '""' ) );
    return( $self->error({
        message => "Offset value provided \"$offset\" is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $offset ) );
    return( $self->error({
        message => "Length value provided \"$len\" is not an integer.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_integer( $len ) );
    $offset = int( $offset );
    $len = int( $len );
    return( $self->error({
        message => "Offset value is greater than the size of the CharacterData object.",
        class => 'HTML::Object::IndexSizeError',
    }) ) if( $offset > $self->value->length );
    return( $self->value->substr( $offset, $len ) );
}

sub _sanity_check_for_before_after
{
    my $self = shift( @_ );
    my $list = shift( @_ ) || return( $self->error( "No list of nodes was provided." ) );
    return( $self->error( "I was expecting an array object, but instead got '$list'." ) ) if( !$self->_is_a( $list => 'Module::Generic::Array' ) );
    my $parent = $self->parent;
    my $lineage = $self->lineage;
    if( !$list->intersect( $lineage )->is_empty )
    {
        return( $self->error({
            message => "One of the nodes provided is an ancestor of this CharacterData",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    foreach( @$list )
    {
        if( !$self->_is_a( $_ => 'HTML::Object::DOM::DocumentFragment' ) &&
            !$self->_is_a( $_ => 'HTML::Object::DOM::Element' ) &&
            !$self->_is_a( $_ => 'HTML::Object::DOM::CharacterData' ) )
        {
            return( $self->error({
                message => "A node provided (" . overload::StrVal( $_ ) . ") is neither a DocumentFragment, an Element nor a CharacterData object.",
                class => 'HTML::Object::HierarchyRequestError',
            }) );
        }
        elsif( $self->_is_a( $_ => 'HTML::Object::DOM::DocumentFragment' ) )
        {
            my $kids = $_->children;
            my $count = 0;
            foreach my $node ( @$kids )
            {
                ++$count if( $node->isa( 'HTML::Object::DOM::Element' ) );
                if( $count > 1 || $node->isa( 'HTML::Object::DOM::Text' ) )
                {
                    return( $self->error({
                        message => "More than one Element node was provided or a Text node was provided.",
                        class => 'HTML::Object::HierarchyRequestError',
                    }) );
                }
            }
        }
    }
    if( $self->isa( 'HTML::Object::DOM::Text' ) && $self->_is_a( $parent => 'HTML::Object::DOM::Document' ) )
    {
        return( $self->error({
            message => "This CharacterData object is a Text object, and our parent is a Document.",
            class => 'HTML::Object::HierarchyRequestError',
        }) );
    }
    return(1);
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::CharacterData - HTML Object Character Data Class

=head1 SYNOPSIS

    use parent qw( HTML::Object::DOM::CharacterData );
    # then implements additional properties and methods

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<CharacterData> abstract interface represents a L<Node object|HTML::Object::DOM::Node> that contains characters. This is an abstract interface, meaning there are not any objects of type CharacterData: it is implemented by other interfaces like L<Text|HTML::Object::DOM::Text>, L<Comment|HTML::Object::DOM::Comment>, L<Space|HTML::Object::DOM::Space> which are not abstract.

It inherits from L<Node|HTML::Object::DOM::Node>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::CharacterData |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+

=head1 PROPERTIES

This interface also inherits properties from its parents L<Node|HTML::Object::DOM::Node> and L<EventTarget|HTML::Object::EventTarget>.

=head2 data

Is a string representing the textual data contained in this object.

Example:

    <!-- This is an html comment !-->
    <output id="Result"></output>

    my $comment = $doc->body->childNodes->[1];
    my $output = $doc->getElementById('Result');
    $output->value = $comment->data;
    # output content would now be: This is an html comment !

Setting the content of a text node using data

    <span>Result: </span>Not set.

    my $span = $doc->getElementsByTagName('span')->[0];
    my $textnode = $span->nextSibling;
    $textnode->data = "This text has been set using textnode.data."

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data>

=head2 length

Read-only.

Returns a L<number|Module::Generic::Number> representing the size of the string contained in the object.

Example:

    Length of the string in the <code>Text</code> node: <output></output>

    use HTML::Object::DOM::Text;
    my $output = $doc->getElementsByTagName('output')->[0];
    my $textnode = HTML::Object::DOM::Text->new("This text has been set using textnode.data.");

    $output->value = $textnode->length;
    # Length of the string in the Text node: 43

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/length>

=head2 nextElementSibling

Read-only.

Returns the first Element that follows this node, and is a sibling, or C<undef> if this node was the last one in its parent's children list.

Example:

    TEXT
    <div id="div-01">Here is div-01</div>
    TEXT2
    <div id="div-02">Here is div-02</div>
    <pre>Here is the result area</pre>

    # Initially, set node to the Text node with `TEXT`
    my $node = $doc->getElementById('div-01')->previousSibling;
    my $result = "Next element siblings of TEXT:\n";
    while( $node )
    {
        $result .= $node->nodeName + "\n";
        # The first node is a CharacterData, the others Element objects
        $node = $node->nextElementSibling;
    }
    $doc->getElementsByTagName('pre')->[0]->textContent = $result;

would produce:

    TEXT
    Here is div-01
    TEXT2
    Here is div-02

    Next element siblings of TEXT:
    #text
    DIV
    DIV
    PRE
    SCRIPT

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/nextElementSibling>

=head2 previousElementSibling

Read-only.

Returns the first Element that precedes this node, and is a sibling, or C<undef> if this node was the first one in its parent's children list.

Example:

    <div id="div-01">Here is div-01</div>
    TEXT
    <div id="div-02">Here is div-02</div>
    SOME TEXT
    <div id="div-03">Here is div-03</div>
    <pre>Result</pre>

    # Initially set node to the Text node with `SOME TEXT`
    my $node = $doc->getElementById('div-02')->nextSibling;
    my $result = "Previous element siblings of SOME TEXT:\n";
    while( $node )
    {
        $result .= $node->nodeName + "\n";
        $node = $node->previousElementSibling;
    }
    $doc->getElementsByTagName('pre')->[0]->textContent = $result;

would produce:

    Here is div-01
    TEXT
    Here is div-02
    SOME TEXT
    Here is div-03

    Previous element siblings of SOME TEXT:
    #text
    DIV
    DIV

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/previousElementSibling>

=head1 METHODS

This interface also inherits methods from its parents, L<Node|HTML::Object::DOM::Node> and L<EventTarget|HTML::Object::EventTarget>.

=head2 after

Inserts a set of L<Node objects|HTML::Object::DON::Node> or strings in the children list of the C<CharacterData>'s parent, just after the C<CharacterData> object.

Strings are inserted as L<Text nodes|HTML::Object::DOM::Text>; the string is being passed as argument to the L<HTML::Object::DOM::Text> constructor.

It returns an C<HTML::Object::HierarchyRequestError> error when the new nodes cannot be inserted at the specified point in the hierarchy, that is if one of the following conditions is met:

=over 4

=item * If the insertion of one of the added node would lead to a cycle, that is if one of them is an ancestor of this C<CharacterData> node.

=item * If one of the added node is not a L<HTML::Object::DOM::DocumentFragment>, an L<HTML::Object::DOM::Element>, or a L<HTML::Object::DOM::CharacterData>.

=item * If this L<CharacterData node|HTML::Object::DOM::CharacterData> is actually a L<Text|HTML::Object::DOM::Text> node, and its parent is a L<Document|HTML::Object::DOM::Document>.

=item * If the parent of this L<CharacterData node|HTML::Object::DOM::CharacterData> is a L<Document|HTML::Object::DOM::Document> and one of the nodes to insert is a L<DocumentFragment|HTML::Object::DOM::DocumentFragment> with more than one L<Element|HTML::Object::DOM::Element> child, or that has a L<Text|HTML::Object::DOM::Text> child.

=back

Example:

    my $h1TextNode = $doc->getElementsByTagName('h1')->[0]->firstChild;
    $h1TextNode->after(" #h1");

    $h1TextNode->parentElement->childNodes;
    # NodeList [#text "CharacterData.after()", #text " #h1"]

    say $h1TextNode->data;
    # "CharacterData.after()"

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/after>

=head2 appendData

Provided with some string and this appends the given string to the L</data> string; when this method returns, data contains the concatenated string.

Example:

    <span>Result: </span>A text

    my $span = $doc->getElementsByTagName("span")->[0];
    my $textnode = $span->nextSibling;
    $textnode->appendData(" - appended text.");
    # span now contains:
    # Result: A text - appended text.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/appendData>

=head2 before

Inserts a set of L<Node objects|HTML::Object::DON::Node> or strings in the children list of the C<CharacterData>'s parent, just before the C<CharacterData> object.

It returns the same error as L</after>

Example:

    my $h1TextNode = $doc->getElementsByTagName('h1')->[0]->firstChild;
    $h1TextNode->before("h1# ");
    $h1TextNode->parentElement->childNodes;
    # NodeList [#text "h1# ", #text "CharacterData.before()"]

    say $h1TextNode.data;
    # "CharacterData.before()"

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/before>

=head2 deleteData

Provided with an C<offset> value as an integer and an C<amount> as a length, and this removes the specified C<amount> of characters, starting at the specified C<offset>, from the L</data> string; when this method returns, data contains the shortened string.

Example:

    <span>Result: </span>A long string.

    my $span = $doc->getElementsByTagName("span")->[0];
    my $textnode = $span->nextSibling;
    $textnode->deleteData(1, 5);
    # span now contains:
    # Result: A string.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/deleteData>

=head2 insertData

Provided with an C<offset> value as an integer and a string, and this inserts the specified characters, at the specified C<offset>, in the L</data> string; when this method returns, data contains the modified string.

    <span>Result: </span>A string.

    my $span = $doc->getElementsByTagName("span")->[0];
    my $textnode = $span->nextSibling;
    $textnode->insertData(2, "long ");
    # span now contains:
    # Result: A long string.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/insertData>

=head2 remove

Removes the object from its parent children list.

    <span>Result: </span>A long string.

    my $span = $doc->getElementsByTagName("span")->[0];
    my $textnode = $span->nextSibling;
    # Removes the text
    $textnode->remove();
    # span now contains:
    # Result:

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/remove>

=head2 replaceData

    $e->replaceData($offset, $count, $data);

Provided with an C<offset> value as an integer, an C<amount> as a length, and a string, and this replaces the specified C<amount> of characters, starting at the specified C<offset>, with the specified C<string>; when this method returns, data contains the modified string.

    <span>Result: </span>A long string.

    my $span = $doc->getElementsByTagName("span")->[0];
    my $textnode = $span->nextSibling;

    $textnode->replaceData(2, 4, "replaced");
    # span now contains:
    # Result: A replaced string.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/replaceData>

=head2 replaceWith

    $e->replaceWith( $node1, 'some text', $node2 );

Provided with a list of L<node objects|HTML::Object::DOM::Node> or strings and this replaces the characters in the children list of its parent with the supplied set of L<node objects|HTML::Object::DOM::Node> or strings.

This returns an C<HTML::Object::HierarchyRequestError> when the node cannot be inserted at the specified point in the hierarchy.

Example:

    <p id="myText">Some text</p>

    my $text = $doc->getElementById('myText')->firstChild;
    my $em = $doc->createElement("em");
    $em->textContent = "Italic text";
    # Replace `Some text` by `Italic text`
    $text->replaceWith( $em );

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/replaceWith>

=head2 substringData

Provided with an C<offset> value as an integer, an C<amount> as a length, and this returns a string containing the part of L</data> of the specified C<length> and starting at the specified C<offset>.

This is effectively similar to perl's L<perlfunc/substr>

Returns a new L<scalar object|Module::Generic::Scalar>

It returns a C<HTML::Object::IndexSizeError> error if C<offset> + C<amount> is larger than the length of the contained data.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/substringData>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
