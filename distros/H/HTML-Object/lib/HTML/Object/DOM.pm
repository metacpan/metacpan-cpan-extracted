##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM.pm
## Version v0.5.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2024/05/04
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object );
    use vars qw( @EXPORT_OK %EXPORT_TAGS $SCREEN $WINDOW $TAG_TO_CLASS $GLOBAL_DOM $VERSION );
    use HTML::Object::DOM::Closing;
    use HTML::Object::DOM::Comment;
    use HTML::Object::DOM::Declaration;
    use HTML::Object::DOM::Document;
    use HTML::Object::DOM::Element;
    use HTML::Object::DOM::Space;
    use HTML::Object::DOM::Text;
    use HTML::Object::DOM::Screen;
    use HTML::Object::DOM::Window;
    use Scalar::Util ();
    use constant {
        # For HTML::Object::DOM::Node
        DOCUMENT_POSITION_IDENTICAL     => 0,
        DOCUMENT_POSITION_DISCONNECTED  => 1,
        DOCUMENT_POSITION_PRECEDING     => 2,
        DOCUMENT_POSITION_FOLLOWING     => 4,
        DOCUMENT_POSITION_CONTAINS      => 8,
        DOCUMENT_POSITION_CONTAINED_BY  => 16,
        DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC => 32,
        
        ELEMENT_NODE                    => 1,
        ATTRIBUTE_NODE                  => 2,
        TEXT_NODE                       => 3,
        CDATA_SECTION_NODE              => 4,
        # Deprecated
        ENTITY_REFERENCE_NODE           => 5,
        # Deprecated
        ENTITY_NODE                     => 6,
        PROCESSING_INSTRUCTION_NODE     => 7,
        COMMENT_NODE                    => 8,
        DOCUMENT_NODE                   => 9,
        DOCUMENT_TYPE_NODE              => 10,
        DOCUMENT_FRAGMENT_NODE          => 11,
        NOTATION_NODE                   => 12,
        # non-standard addition, because we distinguish space from text
        SPACE_NODE                      => 13,
        
        # For HTML::Object::DOM::Element::Media
        # There is no data yet. Also, readyState is HAVE_NOTHING.
        NETWORK_EMPTY       => 0,
        # HTMLMediaElement is active and has selected a resource, but is not using the network.
        NETWORK_IDLE        => 1,
        # The browser is downloading HTMLMediaElement data.
        NETWORK_LOADING     => 2,
        # No HTMLMediaElement src found.
        NETWORK_NO_SOURCE   => 3,
        
        # For HTML::Object::DOM::Element::Track
        # Indicates that the text track's cues have not been obtained.
        NONE                => 0,
        # Indicates that the text track is loading and there have been no fatal errors encountered so far. Further cues might still be added to the track by the parser.
        LOADING             => 1,
        # Indicates that the text track has been loaded with no fatal errors.
        LOADED              => 2,
        # Indicates that the text track was enabled, but when the user agent attempted to obtain it, this failed in some way. Some or all of the cues are likely missing and will not be obtained.
        ERROR               => 3,
        
        # For HTML::Object::Event
        # NONE            => 0,
        CAPTURING_PHASE     => 1,
        AT_TARGET           => 2,
        BUBBLING_PHASE      => 3,
        
        CANCEL_PROPAGATION  => 1,
        CANCEL_IMMEDIATE_PROPAGATION => 2,
        
        # HTML::Object::DOM::NodeFilter
        # Shows all nodes.
        SHOW_ALL                    => 4294967295,
        # Shows Element nodes.
        SHOW_ELEMENT                => 1,
        # Shows attribute Attr nodes.
        SHOW_ATTRIBUTE              => 2,
        # Shows Text nodes.
        SHOW_TEXT                   => 4,
        # Shows CDATASection nodes.
        SHOW_CDATA_SECTION          => 8,
        # Legacy, no more used.
        SHOW_ENTITY_REFERENCE 	    => 16,
        # Legacy, no more used.
        SHOW_ENTITY                 => 32,
        # Shows ProcessingInstruction nodes.
        SHOW_PROCESSING_INSTRUCTION => 64,
        # Shows Comment nodes.
        SHOW_COMMENT                => 128,
        # Shows Document nodes.
        SHOW_DOCUMENT               => 256,
        # Shows DocumentType nodes.
        SHOW_DOCUMENT_TYPE          => 512,
        # Shows DocumentFragment nodes.
        SHOW_DOCUMENT_FRAGMENT 	    => 1024,
        # Legacy, no more used.
        SHOW_NOTATION               => 2048,
        # Show spaces
        SHOW_SPACE                  => 4096,
        
        FILTER_ACCEPT               => 1,
        FILTER_REJECT               => 2,
        FILTER_SKIP                 => 3,
        
        # HTML::Object::DOM::XPathResult
        # A result set containing whatever type naturally results from evaluation of the expression. Note that if the result is a node-set then UNORDERED_NODE_ITERATOR_TYPE is always the resulting type.
        ANY_TYPE                        => 0,
        # A result containing a single number. This is useful for example, in an XPath expression using the count() function.
        NUMBER_TYPE                     => 1,
        # A result containing a single string.
        STRING_TYPE                     => 2,
        # A result containing a single boolean value. This is useful for example, in an XPath expression using the not() function.
        BOOLEAN_TYPE                    => 3,
        # A result node-set containing all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.
        UNORDERED_NODE_ITERATOR_TYPE    => 4,
        # A result node-set containing all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.
        ORDERED_NODE_ITERATOR_TYPE      => 5,
        # A result node-set containing snapshots of all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.
        UNORDERED_NODE_SNAPSHOT_TYPE    => 6,
        # A result node-set containing snapshots of all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.
        ORDERED_NODE_SNAPSHOT_TYPE      => 7,
        # A result node-set containing any single node that matches the expression. The node is not necessarily the first node in the document that matches the expression.
        ANY_UNORDERED_NODE_TYPE         => 8,
        # A result node-set containing the first node in the document that matches the expression.
        FIRST_ORDERED_NODE_TYPE         => 9,
    };
    our @EXPORT_OK = qw(
        screen window
        
        DOCUMENT_POSITION_IDENTICAL
        DOCUMENT_POSITION_DISCONNECTED
        DOCUMENT_POSITION_PRECEDING
        DOCUMENT_POSITION_FOLLOWING
        DOCUMENT_POSITION_CONTAINS
        DOCUMENT_POSITION_CONTAINED_BY
        DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
        
        ELEMENT_NODE
        ATTRIBUTE_NODE
        TEXT_NODE
        CDATA_SECTION_NODE
        ENTITY_REFERENCE_NODE
        ENTITY_NODE
        PROCESSING_INSTRUCTION_NODE
        COMMENT_NODE
        DOCUMENT_NODE
        DOCUMENT_TYPE_NODE
        DOCUMENT_FRAGMENT_NODE
        NOTATION_NODE
        SPACE_NODE
        
        NETWORK_EMPTY NETWORK_IDLE NETWORK_LOADING NETWORK_NO_SOURCE
        NONE LOADING LOADED ERROR
        CAPTURING_PHASE AT_TARGET BUBBLING_PHASE CANCEL_PROPAGATION CANCEL_IMMEDIATE_PROPAGATION
        
        SHOW_ALL SHOW_ELEMENT SHOW_ATTRIBUTE SHOW_TEXT SHOW_CDATA_SECTION 
        SHOW_ENTITY_REFERENCE SHOW_ENTITY SHOW_PROCESSING_INSTRUCTION SHOW_COMMENT 
        SHOW_DOCUMENT SHOW_DOCUMENT_TYPE SHOW_DOCUMENT_FRAGMENT SHOW_NOTATION SHOW_SPACE
        FILTER_ACCEPT FILTER_REJECT FILTER_SKIP
        
        ANY_TYPE NUMBER_TYPE STRING_TYPE BOOLEAN_TYPE
        UNORDERED_NODE_ITERATOR_TYPE ORDERED_NODE_ITERATOR_TYPE
        UNORDERED_NODE_SNAPSHOT_TYPE ORDERED_NODE_SNAPSHOT_TYPE
        ANY_UNORDERED_NODE_TYPE FIRST_ORDERED_NODE_TYPE
    );
    our %EXPORT_TAGS = (
        event   => [qw(
            NONE LOADING LOADED ERROR
            CAPTURING_PHASE AT_TARGET BUBBLING_PHASE CANCEL_PROPAGATION CANCEL_IMMEDIATE_PROPAGATION
        )],
        filter  => [qw(
            SHOW_ALL SHOW_ELEMENT SHOW_ATTRIBUTE SHOW_TEXT SHOW_CDATA_SECTION 
            SHOW_ENTITY_REFERENCE SHOW_ENTITY SHOW_PROCESSING_INSTRUCTION SHOW_COMMENT 
            SHOW_DOCUMENT SHOW_DOCUMENT_TYPE SHOW_DOCUMENT_FRAGMENT SHOW_NOTATION SHOW_SPACE
            FILTER_ACCEPT FILTER_REJECT FILTER_SKIP
        )],
        # HTML::Object::DOM::Element::Media
        media   => [qw( NETWORK_EMPTY NETWORK_IDLE NETWORK_LOADING NETWORK_NO_SOURCE )],
        # HTML::Object::DOM::Node
        node    => [qw(
            DOCUMENT_POSITION_IDENTICAL
            DOCUMENT_POSITION_DISCONNECTED
            DOCUMENT_POSITION_PRECEDING
            DOCUMENT_POSITION_FOLLOWING
            DOCUMENT_POSITION_CONTAINS
            DOCUMENT_POSITION_CONTAINED_BY
            DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
        
            ELEMENT_NODE
            ATTRIBUTE_NODE
            TEXT_NODE
            CDATA_SECTION_NODE
            ENTITY_REFERENCE_NODE
            ENTITY_NODE
            PROCESSING_INSTRUCTION_NODE
            COMMENT_NODE
            DOCUMENT_NODE
            DOCUMENT_TYPE_NODE
            DOCUMENT_FRAGMENT_NODE
            NOTATION_NODE
            SPACE_NODE
        )],
        track   => [qw( NONE LOADING LOADED ERROR )],
        xpath   => [qw(
            ANY_TYPE NUMBER_TYPE STRING_TYPE BOOLEAN_TYPE
            UNORDERED_NODE_ITERATOR_TYPE ORDERED_NODE_ITERATOR_TYPE
            UNORDERED_NODE_SNAPSHOT_TYPE ORDERED_NODE_SNAPSHOT_TYPE
            ANY_UNORDERED_NODE_TYPE FIRST_ORDERED_NODE_TYPE
        )],
    );
    $EXPORT_TAGS{all} = [@EXPORT_OK];
    our $SCREEN = HTML::Object::DOM::Screen->new;
    our $WINDOW;
    # An hash reference map to lowercase HTML tag name to perl class, for those who have special classes, otherwise the fallback is HTML::Object::Element.
    our $TAG_TO_CLASS = {};
    our $GLOBAL_DOM;
    our $VERSION = 'v0.5.0';
};

use strict;
use warnings;

{
    # "If name is applet, bgsound, blink, isindex, keygen, multicol, nextid, or spacer, then return HTMLUnknownElement."
    # "If name is acronym, basefont, big, center, nobr, noembed, noframes, plaintext, rb, rtc, strike, or tt, then return HTMLElement."
    # "If name is listing or xmp, then return HTMLPreElement."
    # <https://html.spec.whatwg.org/multipage/dom.html#htmlunknownelement>
    $TAG_TO_CLASS = 
    {
    a           => 'HTML::Object::DOM::Element::Anchor',
    acronym     => 'HTML::Object::DOM::Element',
    # Deprecated
    applet      => 'HTML::Object::DOM::Element::Unknown',
    area        => 'HTML::Object::DOM::Element::Area',
    audio       => 'HTML::Object::DOM::Element::Audio',
    base        => 'HTML::Object::DOM::Element::Base',
    basefont    => 'HTML::Object::DOM::Element',
    # Deprecated
    bgsound     => 'HTML::Object::DOM::Element::Unknown',
    big         => 'HTML::Object::DOM::Element',
    # Deprecated
    blink       => 'HTML::Object::DOM::Element::Unknown',
    blockquote  => 'HTML::Object::DOM::Element::Quote',
    body        => 'HTML::Object::DOM::Element::Body',
    br          => 'HTML::Object::DOM::Element::BR',
    button      => 'HTML::Object::DOM::Element::Button',
    canvas      => 'HTML::Object::DOM::Element::Canvas',
    caption     => 'HTML::Object::DOM::Element::TableCaption',
    center      => 'HTML::Object::DOM::Element',
    col         => 'HTML::Object::DOM::Element::TableCol',
    colgroup    => 'HTML::Object::DOM::Element::TableCol',
    data        => 'HTML::Object::DOM::Element::Data',
    datalist    => 'HTML::Object::DOM::Element::DataList',
    details     => 'HTML::Object::DOM::Element::Details',
    dialog      => 'HTML::Object::DOM::Element::Dialog',
    div         => 'HTML::Object::DOM::Element::Div',
    dl          => 'HTML::Object::DOM::Element::DList',
    # "Firefox implements the HTMLSpanElement interface for this element."
    # <https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dt>
    dt          => 'HTML::Object::DOM::Element::Span',
    dd          => 'HTML::Object::DOM::Element',
    embed       => 'HTML::Object::DOM::Element::Embed',
    fieldset    => 'HTML::Object::DOM::Element::FieldSet',
    font        => 'HTML::Object::DOM::Element::Unknown',
    form        => 'HTML::Object::DOM::Element::Form',
    frame       => 'HTML::Object::DOM::Element::Unknown',
    frameset    => 'HTML::Object::DOM::Element::Unknown',
    head        => 'HTML::Object::DOM::Element::Head',
    h1          => 'HTML::Object::DOM::Element::Heading',
    h2          => 'HTML::Object::DOM::Element::Heading',
    h3          => 'HTML::Object::DOM::Element::Heading',
    h4          => 'HTML::Object::DOM::Element::Heading',
    h5          => 'HTML::Object::DOM::Element::Heading',
    h6          => 'HTML::Object::DOM::Element::Heading',
    hr          => 'HTML::Object::DOM::Element::HR',
    html        => 'HTML::Object::DOM::Element::HTML',
    iframe      => 'HTML::Object::DOM::Element::IFrame',
    image       => 'HTML::Object::DOM::Element::Image',
    input       => 'HTML::Object::DOM::Element::Input',
    # Deprecated
    isindex     => 'HTML::Object::DOM::Element::Unknown',
    # Deprecated
    keygen      => 'HTML::Object::DOM::Element::Unknown',
    label       => 'HTML::Object::DOM::Element::Label',
    legend      => 'HTML::Object::DOM::Element::Legend',
    li          => 'HTML::Object::DOM::Element::LI',
    'link'      => 'HTML::Object::DOM::Element::Link',
    listing     => 'HTML::Object::DOM::Element::Pre',
    'map'       => 'HTML::Object::DOM::Element::Map',
    marquee     => 'HTML::Object::DOM::Element::Marquee',
    media       => 'HTML::Object::DOM::Element::Media',
    menu        => 'HTML::Object::DOM::Element::Unknown',
    meta        => 'HTML::Object::DOM::Element::Meta',
    meter       => 'HTML::Object::DOM::Element::Meter',
    mod         => 'HTML::Object::DOM::Element::Mod',
    # Deprecated
    multicol    => 'HTML::Object::DOM::Element::Unknown',
    # Deprecated
    nextid      => 'HTML::Object::DOM::Element::Unknown',
    nobr        => 'HTML::Object::DOM::Element',
    noembed     => 'HTML::Object::DOM::Element',
    noframes    => 'HTML::Object::DOM::Element',
    object      => 'HTML::Object::DOM::Element::Object',
    ol          => 'HTML::Object::DOM::Element::OList',
    optgroup    => 'HTML::Object::DOM::Element::OptGroup',
    option      => 'HTML::Object::DOM::Element::Option',
    output      => 'HTML::Object::DOM::Element::Output',
    p           => 'HTML::Object::DOM::Element::Paragraph',
    param       => 'HTML::Object::DOM::Element::Param',
    picture     => 'HTML::Object::DOM::Element::Picture',
    plaintext   => 'HTML::Object::DOM::Element',
    pre         => 'HTML::Object::DOM::Element::Pre',
    progress    => 'HTML::Object::DOM::Element::Progress',
    quote       => 'HTML::Object::DOM::Element::Quote',
    'q'         => 'HTML::Object::DOM::Element::Quote',
    rb          => 'HTML::Object::DOM::Element',
    rtc         => 'HTML::Object::DOM::Element',
    script      => 'HTML::Object::DOM::Element::Script',
    'select'    => 'HTML::Object::DOM::Element::Select',
    slot        => 'HTML::Object::DOM::Element::Slot',
    source      => 'HTML::Object::DOM::Element::Source',
    # Deprecated
    spacert     => 'HTML::Object::DOM::Element::Unknown',
    span        => 'HTML::Object::DOM::Element::Span',
    strike      => 'HTML::Object::DOM::Element',
    style       => 'HTML::Object::DOM::Element::Style',
    table       => 'HTML::Object::DOM::Element::Table',
    td          => 'HTML::Object::DOM::Element::TableCell',
    th          => 'HTML::Object::DOM::Element::TableCell',
    'tr'        => 'HTML::Object::DOM::Element::TableRow',
    tbody       => 'HTML::Object::DOM::Element::TableSection',
    tfoot       => 'HTML::Object::DOM::Element::TableSection',
    thead       => 'HTML::Object::DOM::Element::TableSection',
    template    => 'HTML::Object::DOM::Element::Template',
    textarea    => 'HTML::Object::DOM::Element::TextArea',
    'time'      => 'HTML::Object::DOM::Element::Time',
    title       => 'HTML::Object::DOM::Element::Title',
    track       => 'HTML::Object::DOM::Element::Track',
    tt          => 'HTML::Object::DOM::Element',
    video       => 'HTML::Object::DOM::Element::Video',
    xmp         => 'HTML::Object::DOM::Element::Pre',
    };
}

# *import = \&Exporter::import;

sub init
{
    my $self = shift( @_ );
    $self->{onload} = undef;
    $self->{onreadystatechange} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $win = $self->new_window( debug => $self->debug );
    $self->window( $win );
    return( $self );
}

sub current_parent { return( shift->_set_get_object_without_init( 'current_parent', 'HTML::Object::DOM::Node', @_ ) ); }

sub document { return( shift->_set_get_object( 'document', 'HTML::Object::DOM::Document', @_ ) ); }

sub get_definition
{
    my $self = shift( @_ );
    my $tag  = shift( @_ );
    return( $self->error( "No tag was provided to get its definition." ) ) if( !length( $tag ) );
    # Just to be sure
    $tag = lc( $tag );
    my $def = $self->SUPER::get_definition( $tag, @_ ) || return( $self->pass_error );
    $def->{class} = $TAG_TO_CLASS->{ $tag } if( CORE::exists( $TAG_TO_CLASS->{ $tag } ) );
    return( $def );
}

sub get_dom { return( $GLOBAL_DOM ); }

sub new_closing
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Closing->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Closing->error ) );
    return( $e );
}

sub new_comment
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Comment->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Comment->error ) );
    return( $e );
}

sub new_declaration
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Declaration->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Declaration->error ) );
    return( $e );
}

sub new_document
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Document->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Document->error ) );
    my $win = $self->window;
    $e->defaultView( $win );
    return( $e );
}

sub new_element
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Element->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Element->error ) );
    return( $e );
}

sub new_space
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Space->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Space->error ) );
    return( $e );
}

sub new_text
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Text->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Text->error ) );
    return( $e );
}

sub new_window
{
    my $self = shift( @_ );
    my $e = HTML::Object::DOM::Window->new( @_ ) ||
        return( $self->pass_error( HTML::Object::DOM::Window->error ) );
    $e->screen( $SCREEN );
    $WINDOW = $e unless( ref( $WINDOW ) );
    return( $e );
}

sub onload : lvalue { return( shift->_set_get_code( 'onload', @_ ) ); }

sub onreadystatechange : lvalue { return( shift->_set_get_code( 'onreadystatechange', @_ ) ); }

sub parseFromString { return( shift->parse_data( @_ ) ); }

sub screen { return( $SCREEN ); }

sub set_dom
{
    my( $this, $html ) = @_;
    if( defined( $html ) )
    {
        if( Scalar::Util::blessed( $html ) && $html->isa( 'HTML::Object::DOM::Document' ) )
        {
            $GLOBAL_DOM = $html;
        }
        elsif( CORE::length( $html ) )
        {
            $GLOBAL_DOM = $this->new->parse( $html );
        }
    }
    return( $this );
}

sub window
{
    if( !scalar( @_ ) )
    {
        return( $WINDOW );
    }
    my $self = shift( @_ );
    if( Scalar::Util::blessed( $self ) )
    {
        if( $self->isa( 'HTML::Object::DOM' ) )
        {
            return( $self->_set_get_object( 'window', 'HTML::Object::DOM::Window', @_ ) );
        }
        else
        {
            die( "You cannot call window as a class function and passing it an object other than a HTML::Object::DOM::Window object.\n" ) unless( $self->isa( 'HTML::Object::DOM::Window' ) );
            $WINDOW = $self;
        }
    }
    else
    {
        die( "Unknown value (", overload::StrVal( $self ), ") provided to window() called as a HTML::Object::DOM class function\n" );
    }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM - HTML Object DOM Class

=head1 SYNOPSIS

    use HTML::Object::DOM;
    my $this = HTML::Object::DOM->new || die( HTML::Object::DOM->error, "\n" );

=head1 VERSION

    v0.5.0

=head1 DESCRIPTION

This module implement DOM-like interface to HTML objects and inherits from L<HTML::Object>, so you can call this module instead, to parse HTML data and it the resulting tree of objects will have DOM capabilities.

DOM stands for Document Object Model.

There are 2 divergences from the standard:

=over 4

=item 1. nodeName

L<nodeName|HTML::Object::DOM::Node/nodeName> returns the tag name in lower case instead of the upper case

=item 2. Space and text

This interface makes the difference between L<text|HTML::Object::DOM::Text> and L<space-only text|HTML::Object::DOM::Space> whereas the DOM standard specification treats both as a text node.

This leads to a new non-standard constant L<nodeType|HTML::Object::DOM::Node/nodeType> for space having a value C<SPACE_NODE> (13) and the non-standard constant C<SHOW_SPACE> in L<HTML::Object::DOM::NodeFilter>

=back

=head1 INHERITANCE

    +--------------+     +-------------------+
    | HTML::Object | --> | HTML::Object::DOM |
    +--------------+     +-------------------+

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of options and this returns a new L<HTML::Object::DOM> object. Options available are the same as the methods available.

=head1 METHODS

=head2 current_parent

This represent the parent for the current element being processed by the parser.

=head2 document

Set or get the L<element object|HTML::Object::DOM::Document> for the document.

=head2 get_definition

Provided with a tag name and this will return its corresponding L<hash reference|HTML::Object/dictionary> or C<undef> if there is no such tag or an L<error|Module::Generic/error> occurred somehow.

=head2 get_dom

Get the value for the global variable C<$GLOBAL_DOM>, which should be a L<HTML::Object::DOM::Document> object.

=head2 new_closing

Instantiates a new L<closing element|HTML::Object::DOM::Closing>, passing it any arguments received, and returns the new object.

=head2 new_comment

Instantiates a new L<comment element|HTML::Object::DOM::Comment>, passing it any arguments received, and returns the new object.

=head2 new_declaration

Instantiates a new L<declaration element|HTML::Object::DOM::Declaration>, passing it any arguments received, and returns the new object.

=head2 new_document

Instantiates a new L<document element|HTML::Object::DOM::Document>, passing it any arguments received, and returns the new object.

The new document object has its property C<defaultView> set to a new L<window object|HTML::Object::DOM::Window>

=head2 new_element

Instantiates a new L<element|HTML::Object::DOM::Element>, passing it any arguments received, and returns the new object.

=head2 new_space

Instantiates a new L<space element|HTML::Object::DOM::Space>, passing it any arguments received, and returns the new object.

=head2 new_text

Instantiates a new L<text element|HTML::Object::DOM::Text>, passing it any arguments received, and returns the new object.

=head2 new_window

Instantiates a new L<window object|HTML::Object::DOM::Window>, passing it any arguments received, and returns the new object.

=head2 onload

Set or get the code reference to be executed when the parsing of the html data has been completed.

The value of this code reference is provided to the new document when it is instantiated.

Upon execution, C<$_> is set to the L<HTML document object|HTML::Object::DOM::Document>, and a new event is passed of type C<readstate> and with the C<detail> property having the following data available:

=over 4

=item document

The L<document object|HTML::Object::DOM::Document>

=item state

The state of the document parsing.

=back

The event C<target> property is also set to the L<document object|HTML::Object::DOM::Document>.

=head2 onreadystatechange

Set or get the code reference to be executed whenever there is a change of state to the document. 3 states are available: C<loading>, C<interactive> and C<complete>

The value of this code reference is provided to the new document when it is instantiated.

Upon execution, C<$_> is set to the L<HTML document object|HTML::Object::DOM::Document>, and a new event is passed of type C<readstate> and with the C<detail> property having the following data available:

=over 4

=item document

The L<document object|HTML::Object::DOM::Document>

=item state

The state of the document parsing.

=back

The event C<target> property is also set to the L<document object|HTML::Object::DOM::Document>.

=head2 parseFromString

Provided with some HTML data, and this will parse it and return a new L<document object|HTML::Object::DOM::Document> or C<undef> if an L<error|Module::Generic/error> occurred.

=head2 screen

Returns the L<HTML::Object::DOM::Screen> object.

=head2 set_dom

Set the global variable C<$GLOBAL_DOM> which must be a L<HTML::Object::DOM::Document>

=head2 window

Set or get the L<window object|HTML::Object::DOM::Window> for this new parser and the L<document|HTML::Object::DOM::Document> it creates.

=head1 CONSTANTS

The following constants can be exported and used, such as:

    use HTML::Object::DOM qw( :event );
    # or directly
    use HTML::Object::Event qw( :all );

=over 4

=item NONE (0)

The event is not being processed at this time.

=item CAPTURING_PHASE (1)

The event is being propagated through the target's ancestor objects. This process starts with the L<Document|HTML::Object::Document>, then the L<HTML html element|HTML::Object::Element>, and so on through the elements until the target's parent is reached. Event listeners registered for capture mode when L<HTML::Object::EventTarget/addEventListener> was called are triggered during this phase.

=item AT_TARGET (2)

The event has arrived at the event's target. Event listeners registered for this phase are called at this time. If L</bubbles> is false, processing the event is finished after this phase is complete.

=item BUBBLING_PHASE (3)

The event is propagating back up through the target's ancestors in reverse order, starting with the parent, and eventually reaching the containing L<document|HTML::Object::Document>. This is known as bubbling, and occurs only if L</bubbles> is true. Event listeners registered for this phase are triggered during this process.

=item CANCEL_PROPAGATION (1)

State of the propagation being cancelled.

    $event->stopPropagation();
    $event->cancelled == CANCEL_PROPAGATION;

=item CANCEL_IMMEDIATE_PROPAGATION (2)

State of immediate propagation being cancelled.

    $event->stopImmediatePropagation();
    $event->cancelled == CANCEL_IMMEDIATE_PROPAGATION;

=back

For L<HTML::Object::DOM::Element::Media>:

    use HTML::Object::DOM qw( :media );
    # or directly from HTML::Object::DOM::Element::Media
    use HTML::Object::DOM::Element::Media qw( :all );

=over 4

=item NETWORK_EMPTY (0)

There is no data yet. Also, readyState is HAVE_NOTHING.

=item NETWORK_IDLE (1)

L<Media element|HTML::Object::DOM::Element::Media> is active and has selected a resource, but is not using the network.

=item NETWORK_LOADING (2)

The browser is downloading L<HTML::Object::DOM::Element::Media> data.

=item NETWORK_NO_SOURCE (3)

No L<HTML::Object::DOM::Element::Media> src found.

=back

For L<HTML::Object::DOM::Element::Track>:

    use HTML::Object::DOM qw( :track );
    # or directly from HTML::Object::DOM::Element::Track
    use HTML::Object::DOM::Element::Track qw( :all );

=over 4

=item NONE (0)

Indicates that the text track's cues have not been obtained.

Also used in L<HTML::Object::Event> to indicate the event is not being processed at this time.

=item LOADING (1)

Indicates that the text track is loading and there have been no fatal errors encountered so far. Further cues might still be added to the track by the parser.

=item LOADED (2)

Indicates that the text track has been loaded with no fatal errors.

=item ERROR (3)

Indicates that the text track was enabled, but when the user agent attempted to obtain it, this failed in some way. Some or all of the cues are likely missing and will not be obtained.

=back

For L<HTML::Object::DOM::Node>:

    use HTML::Object::DOM qw( :node );
    # or directly from HTML::Object::DOM::Node
    # Automatically exported
    use HTML::Object::DOM::Node;

=over 4

=item * DOCUMENT_POSITION_IDENTICAL (0 or in bits: 000000)

Elements are identical.

=item * DOCUMENT_POSITION_DISCONNECTED (1 or in bits: 000001)

No relationship, both nodes are in different documents or different trees in the same document.

=item * DOCUMENT_POSITION_PRECEDING (2 or in bits: 000010)

The specified node precedes the current node.

=item * DOCUMENT_POSITION_FOLLOWING (4 or in bits: 000100)

The specified node follows the current node.

=item * DOCUMENT_POSITION_CONTAINS (8 or in bits: 001000)

The otherNode is an ancestor of / contains the current node.

=item * DOCUMENT_POSITION_CONTAINED_BY (16 or in bits: 010000)

The otherNode is a descendant of / contained by the node.

=item * DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC (32 or in bits: 100000)

The specified node and the current node have no common container node or the two nodes are different attributes of the same node.

=back

And also the following constants:

=over 4

=item ELEMENT_NODE (1)

=item ATTRIBUTE_NODE (2)

=item TEXT_NODE (3)

=item CDATA_SECTION_NODE (4)

=item ENTITY_REFERENCE_NODE (5)

=item ENTITY_NODE (6)

=item PROCESSING_INSTRUCTION_NODE (7)

=item COMMENT_NODE (8)

=item DOCUMENT_NODE (9)

=item DOCUMENT_TYPE_NODE (10)

=item DOCUMENT_FRAGMENT_NODE (11)

=item NOTATION_NODE (12)

=item SPACE_NODE (13)

=back

For L<HTML::Object::DOM::NodeFilter>:

    use HTML::Object::DOM qw( :filter );
    # or directly from HTML::Object::DOM::NodeFilter
    # Exportable constants
    use HTML::Object::DOM::NodeFilter qw( :all );

=over 4

=item SHOW_ALL (4294967295)

Shows all nodes.

=item SHOW_ELEMENT (1)

Shows Element nodes.

=item SHOW_ATTRIBUTE (2)

Shows attribute L<Attribute nodes|HTML::Object::DOM::Attribute>.

=item SHOW_TEXT (4)

Shows Text nodes.

=item SHOW_CDATA_SECTION (8)

Will always returns nothing, because there is no support for xml documents.

=item SHOW_ENTITY_REFERENCE (16)

Legacy, no more used.

=item SHOW_ENTITY (32)

Legacy, no more used.

=item SHOW_PROCESSING_INSTRUCTION (64)

Shows ProcessingInstruction nodes.

=item SHOW_COMMENT (128)

Shows Comment nodes.

=item SHOW_DOCUMENT (256)

Shows Document nodes

=item SHOW_DOCUMENT_TYPE (512)

Shows C<DocumentType> nodes

=item SHOW_DOCUMENT_FRAGMENT (1024)

Shows L<HTML::Object::DOM::DocumentFragment> nodes.

=item SHOW_NOTATION (2048)

Legacy, no more used.

=item SHOW_SPACE (4096)

Show Space nodes. This is a non-standard extension under this perl framework.

=back

For L<HTML::Object::DOM::XPathResult>:

    use HTML::Object::DOM qw( :xpath );
    # or directly from HTML::Object::DOM::Element::Track
    # Automatically exported
    use HTML::Object::DOM::XPathResult;

=over 4

=item ANY_TYPE (0)

A result set containing whatever type naturally results from evaluation of the expression. Note that if the result is a node-set then C<UNORDERED_NODE_ITERATOR_TYPE> is always the resulting type.

=item NUMBER_TYPE (1)

A result containing a single number. This is useful for example, in an XPath expression using the count() function.

=item STRING_TYPE (2)

A result containing a single string.

=item BOOLEAN_TYPE (3)

A result containing a single boolean value. This is useful for example, in an XPath expression using the not() function.

=item UNORDERED_NODE_ITERATOR_TYPE (4)

A result node-set containing all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.

=item ORDERED_NODE_ITERATOR_TYPE (5)

A result node-set containing all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.

=item UNORDERED_NODE_SNAPSHOT_TYPE (6)

A result node-set containing snapshots of all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.

=item ORDERED_NODE_SNAPSHOT_TYPE (7)

A result node-set containing snapshots of all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.

=item ANY_UNORDERED_NODE_TYPE (8)

A result node-set containing any single node that matches the expression. The node is not necessarily the first node in the document that matches the expression.

=item FIRST_ORDERED_NODE_TYPE (9)

A result node-set containing the first node in the document that matches the expression. 

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model>

L<Mozilla documentation on HTML DOM API|https://developer.mozilla.org/en-US/docs/Web/API/HTML_DOM_API>

L<W3C standard|https://html.spec.whatwg.org/multipage/dom.html>, L<HTML elements specifications|https://html.spec.whatwg.org/>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
