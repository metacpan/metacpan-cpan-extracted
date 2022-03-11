##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Event.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/11
## Modified 2021/12/11
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Event;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use Nice::Try;
    use Time::HiRes ();
    use constant {
        NONE            => 0,
        CAPTURING_PHASE => 1,
        AT_TARGET       => 2,
        BUBBLING_PHASE  => 3,
        
        CANCEL_PROPAGATION  => 1,
        CANCEL_IMMEDIATE_PROPAGATION => 2,
        
        ABORT           => 1,
        BLUR            => 2,
        CLICK           => 4,
        CHANGE          => 16,
        DBLCLICK        => 32,
        DRAGDDROP       => 64,
        ERROR           => 128,
        FOCUS           => 256,
        KEYDOWN         => 512,
        KEYPRESS        => 1024,
        KEYUP           => 2048,
        LOAD            => 4096,
        MOUSEDOWN       => 8192,
        MOUSEMOVE       => 16384,
        MOUSEOUT        => 32768,
        MOUSEOVER       => 65536,
        MOUSEUP         => 131072,
        MOVE            => 262144,
        RESET           => 524288,
        RESIZE          => 1048576,
        SELECT          => 2097152,
        SUBMIT          => 4194304,
        UNLOAD          => 8388608,
    };
    our @EXPORT_OK   = qw(
        NONE CAPTURING_PHASE AT_TARGET BUBBLING_PHASE CANCEL_PROPAGATION CANCEL_IMMEDIATE_PROPAGATION
        ABORT BLUR CLICK CHANGE DBLCLICK DRAGDDROP ERROR FOCUS KEYDOWN KEYPRESS KEYUP LOAD 
        MOUSEDOWN MOUSEMOVE MOUSEOUT MOUSEOVER MOUSEUP MOVE RESET RESIZE SELECT SUBMIT UNLOAD
    );
    our %EXPORT_TAGS = (
        'all' => [qw(
            NONE CAPTURING_PHASE AT_TARGET BUBBLING_PHASE
            CANCEL_PROPAGATION CANCEL_IMMEDIATE_PROPAGATION
            ABORT BLUR CLICK CHANGE DBLCLICK DRAGDDROP ERROR FOCUS KEYDOWN KEYPRESS KEYUP LOAD 
            MOUSEDOWN MOUSEMOVE MOUSEOUT MOUSEOVER MOUSEUP MOVE RESET RESIZE SELECT SUBMIT UNLOAD
        )],
        'events'=> [qw(
            ABORT BLUR CLICK CHANGE DBLCLICK DRAGDDROP ERROR FOCUS KEYDOWN KEYPRESS KEYUP LOAD 
            MOUSEDOWN MOUSEMOVE MOUSEOUT MOUSEOVER MOUSEUP MOVE RESET RESIZE SELECT SUBMIT UNLOAD
        )],
        'phase' => [qw( NONE CAPTURING_PHASE AT_TARGET BUBBLING_PHASE )]
    );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || return( $self->error( "No event type was provided." ) );
    $self->{bubbles}            = 1;
    $self->{cancelable}         = 1;
    # Property that, if set to true, will be checked to stop events handlers and propagation
    $self->{cancelled}          = 0;
    $self->{composed}           = 0;
    $self->{currentTarget}      = undef;
    $self->{defaultPrevented}   = 0;
    $self->{detail}             = {};
    $self->{eventPhase}         = NONE;
    $self->{isTrusted}          = 1;
    # array of html element for which their event handler will be called
    $self->{path}               = [];
    $self->{target}             = undef;
    $self->{timeStamp}          = Time::HiRes::time();
    $self->{type}               = $type;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    # Our immediate caller is new() in Module::Generic, so we skip that
    my( $pack, $file, $line ) = caller(1);
    my $sub = [caller(2)]->[3];
    $self->{package} = $pack;
    $self->{file} = $file;
    $self->{line} = $line;
    $self->{subroutine} = $sub;
    return( $self );
}

# Note: Property
sub bubbles : lvalue { return( shift->_set_get_boolean( 'bubbles', @_ ) ); }

# Note: Property
sub cancelable : lvalue { return( shift->_set_get_boolean( 'cancelable', @_ ) ); }

# Note: Property
sub cancellable : lvalue { return( shift->_set_get_boolean( 'cancelable', @_ ) ); }

# Note: Property
sub canceled  : lvalue { return( shift->_set_get_number( 'cancelled', @_ ) ); }

# Note: Property
sub cancelled  : lvalue { return( shift->_set_get_number( 'cancelled', @_ ) ); }

# Note: Property
sub composed : lvalue { return( shift->_set_get_boolean( 'composed', @_ ) ); }

sub composedPath
{
    my $self = shift( @_ );
    # already set
    return( $self->path ) if( !$self->path->is_empty );
    my $target = $self->target;
    return( $self->error( "No target element is set yet!" ) ) if( !$target );
    my $original_target = $target;
    my $path   = $self->path;
    while( $target->parentNode )
    {
        $path->push( $target );
        $target = $target->parentNode;
    }
    my $doc = $original_target->root;
    $path->push( $doc ) if( $doc );
    # Module::Generic::Array object
    return( $path );
}

# Note: Property
sub currentTarget : lvalue { return( shift->_set_get_lvalue( 'currentTarget', @_ ) ); }

# Note: Property
sub defaultPrevented : lvalue { return( shift->_set_get_boolean( 'defaultPrevented', @_ ) ); }

# Note : Property from CustomEvent, but we add it here as a standard
sub detail : lvalue { return( shift->_set_get_hash_as_mix_object( 'detail', @_ ) ); }

sub dispatch
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( $self->error({
        message => "No element was provided to dispatch this event to.",
        class => 'HTML::Object::SyntaxError',
    }) );
    return( $self->error({
        message => "Object provided is not a node object (HTML::Object::DOM::Node)",
        class => 'HTML::Object::SyntaxError',
    }) ) if( !$self->_is_a( $elem => 'HTML::Object::DOM::Node' ) );
    return( $elem->dispatchEvent( $self ) );
}

# Note: Property
sub eventPhase : lvalue { return( shift->_set_get_lvalue( 'eventPhase', @_ ) ); }

sub file { return( shift->_set_get_scalar( 'file', @_ ) ); }

# Note: Property
sub isTrusted : lvalue { return( shift->_set_get_boolean( 'isTrusted', @_ ) ); }

sub line { return( shift->_set_get_scalar( 'line', @_ ) ); }

sub package { return( shift->_set_get_scalar( 'package', @_ ) ); }

sub path { return( shift->_set_get_array_as_object( 'path', @_ ) ); }

# Note: preventDefault does nothing, except set defaultPrevented to true
sub preventDefault
{
    my $self = shift( @_ );
    $self->defaultPrevented(1);
    return( $self );
}

sub setTimestamp
{
    my $self = shift( @_ );
    my $now  = scalar( @_ ) ? shift( @_ ) : Time::HiRes::time();
    try
    {
        my $dt;
        unless( $self->_is_a( $now => 'DateTime' ) )
        {
            $dt = DateTime->from_epoch( epoch => $now );
        }
        return( $self->_set_get_datetime( timeStamp => $dt ) );
    }
    catch( $e )
    {
        return( $self->error( "Error setting event timestamp: $e" ) );
    }
}

sub stopImmediatePropagation
{
    my $self = shift( @_ );
    $self->cancelled( CANCEL_IMMEDIATE_PROPAGATION );
    return( $self );
}

sub stopPropagation
{
    my $self = shift( @_ );
    $self->cancelled( CANCEL_PROPAGATION );
    return( $self );
}

sub subroutine { return( shift->_set_get_scalar( 'subroutine', @_ ) ); }

# Note: Property
sub target { return( shift->_set_get_object_without_init( 'target', 'HTML::Object::Element', @_ ) ); }

# Note: Property
sub timeStamp : lvalue { return( shift->_set_get_datetime( 'timeStamp', @_ ) ); }

# Note: Property
sub type : lvalue { return( shift->_set_get_lvalue( 'type', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Event - HTML Object Event Class

=head1 SYNOPSIS

    use HTML::Object::Event;
    my $event = HTML::Object::Event->new || 
        die( HTML::Object::Event->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module represents an event which takes place in the DOM.

Of course, unlike a web browser environment, there is no user interaction here, so all event "fired" are triggered programatically.

Events are attached to L<HTML elements|HTML::Object::Element>

One L<element|HTML::Object::Element> can have several such L<handlers|HTML::Object::EventTarget>, even for the exact same event

=head1 CONSTRUCTOR

=head2 new

Provided with a type and an hash or hash reference of options and this creates a new L<HTML::Object::Event> object. An event created in this way is called a C<synthetic> event, as opposed to an event fired by the browser, and can be dispatched by a script.

It returns the new event object upon success, or upon error, returns C<undef> and sets an L<error|HTML::Object::Exception>

Parameters accepted:

=over 4

=item I<type>

This is a string representing the type of the event.

=item I<options hash or hash reference>

The options can have the following properties. All of them are optional. Each of them can be accessed or modified by they equivalent method listed below.

=over 8

=item I<bubbles>

A boolean value indicating whether the event bubbles. The default is true. 

When true, this means the event will be passed on from the element that triggered it on to its parent and its parent's parent and so on up to the top L<element|HTML::Object::DOM::Document>. This is the default behaviour. When set to false, the event will not bubble up.

=item I<cancelable>

A boolean value indicating whether the event can be cancelled. The default is true.

It can also be called as C<cancellable> for non-American speakers.

=item I<composed>

Because this is a perl environment, this value is always false, and discarded.

A boolean value indicating whether the event will trigger listeners outside of a shadow root (see L</composed> for more details). The default is C<false>.

=item I<detail>

An optional hash reference of arbitrary key-valu pairs that will be stored in the event object and can be later retrieved by the event handlers.

=back

=back

For example:

Create a look event that bubbles up and cannot be canceled

    my $evt = HTML::Object::Event->new( look => { bubbles => 1, cancelable => 0 } );
    $doc->dispatchEvent( $evt );

    # event can be dispatched from any element, not only the document
    $myDiv->dispatchEvent( $evt );

=head1 PROPERTIES

=head2 bubbles

Read-only

A boolean value indicating whether or not the event bubbles up through the DOM. Default to false

When true, this means the event will be passed on from the element that triggered it on to its parent and its parent's parent and so on up to the top L<element|HTML::Object::DOM::Document>. This is the default behaviour. When set to false, the event will not bubble up.

=head2 cancelable

Read-only

A boolean value indicating whether the event is cancelable. Default to true

It can also be called as C<cancellable> for non-American speakers.

=head2 canceled

Read-only

An integer value indicating whether the event has been canceled. Its value is 1 if it has been cancelled with L</stopPropagation> and 2 if it has been cancelled with L</stopImmediatePropagation>

It can also be called as C<cancelled> for non-American speakers.

=head2 cancellable

Alias for L</cancelable>

=head2 cancelled

Alias for L</canceled>

=head2 composed

Read-only

A boolean indicating whether or not the event can bubble across the boundary between the shadow DOM and the regular DOM. Default to false

Since this is a perl environment, this is always false, and its value is ignored.

=head2 currentTarget

Read-only

A reference to the currently registered L<target|HTML::Object::Element> for the event. This is the L<object|HTML::Object::Element> to which the event is currently slated to be sent. It's possible this has been changed along the way through retargeting.

=head2 defaultPrevented

Read-only

Indicates whether or not the call to L</preventDefault> canceled the event. Default to false

=head2 detail

Set or get an hash reference of arbitrary key-value pairs that will be stored in this event.

=head2 eventPhase

Read-only

Returns an integer value which specifies the current evaluation phase of the event flow. Possible values are: C<NONE> (0), C<CAPTURING_PHASE> (1), C<AT_TARGET> (2), C<BUBBLING_PHASE> (3).

You can export those constants in your namespace by calling L<HTML::Object::Event> like this:

    use HTML::Object::Event qw( NONE CAPTURING_PHASE AT_TARGET BUBBLING_PHASE );

or, more simply:

    use HTML::Object::Event ':phase';

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Event/eventPhase>

=head2 isTrusted

Read-only

Obviously, since this is a perl environment, this is always true, because although it would be script-generated, it is fair to say your own script is trustworthy.

Indicates whether or not the event was initiated by the browser (after a user click, for instance) or by a script (using an event creation method, for example).

=head2 path

Returns the computed elements path by L</composedPath>, as an L<array object|Module::Generic::Array>

=head2 target

Read-only

A reference to the L<object|HTML::Object::Element> to which the event was originally dispatched.

=head2 timeStamp

Read-only

The time at which the event was created (in milliseconds). By specification, this value is time since epoch using L<Time::HiRes>. This is actually a L<DateTime> object. L<DateTime> object supports nanoseconds.

=head2 type

Read-only

The case-insensitive type indentifying the event.

=head1 METHODS

=head2 composedPath

Returns the event's path (an array of objects on which listeners will be invoked).

=head2 dispatch

Provided with a L<node|HTML::Object::DOM::Node> and this will dispatch this event to the given C<node>.

It returns the value returned by L</HTML::Object::EventTarget/dispatchEvent>

=head2 file

Returns the file path where this event was called from.

=head2 line

Returns the line at which this event was called from.

=head2 package

Returns the package name where this event was called from.

=head2 preventDefault

This does nothing under perl, except set the value of L</defaultPrevented> to true.

Under JavaScript, this method is used to stop the browser’s default behavior when performing an action, such as checking a checkbox upon user click.

=head2 setTimestamp

Takes an optional unix timestamp or a L<DateTime> object, and this will set the event timestamp. If no argument is provided, this will resort to set the timestamp using L<Time::HiRes/time>, which provides a timestamp in milliseconds.

It returns a L<DateTime> object.

=head2 stopImmediatePropagation

For this particular event, prevent all other listeners from being called. This includes listeners attached to the same element as well as those attached to elements that will be traversed later (during the capture phase, for instance).

=head2 stopPropagation

Stops the propagation of events further along in the DOM.

=head2 subroutine

Returns the subroutine where this event was called from.

=head1 CONSTANTS

=head2 NONE (0)

The event is not being processed at this time.

=head2 CAPTURING_PHASE (1)

The event is being propagated through the target's ancestor objects. This process starts with the L<Document|HTML::Object::Document>, then the L<HTML html element|HTML::Object::Element>, and so on through the elements until the target's parent is reached. Event listeners registered for capture mode when L<HTML::Object::EventTarget/addEventListener> was called are triggered during this phase.

=head2 AT_TARGET (2)

The event has arrived at the event's target. Event listeners registered for this phase are called at this time. If L</bubbles> is false, processing the event is finished after this phase is complete.

=head2 BUBBLING_PHASE (3)

The event is propagating back up through the target's ancestors in reverse order, starting with the parent, and eventually reaching the containing L<document|HTML::Object::Document>. This is known as bubbling, and occurs only if L</bubbles> is true. Event listeners registered for this phase are triggered during this process.

=head2 CANCEL_PROPAGATION (1)

State of the propagation being cancelled.

    $event->stopPropagation();
    $event->cancelled == CANCEL_PROPAGATION;

=head2 CANCEL_IMMEDIATE_PROPAGATION (2)

State of immediate propagation being cancelled.

    $event->stopImmediatePropagation();
    $event->cancelled == CANCEL_IMMEDIATE_PROPAGATION;

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://developer.mozilla.org/en-US/docs/Web/API/Event>

L<https://developer.mozilla.org/en-US/docs/Web/Events/Creating_and_triggering_events>

L<https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events>

L<https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
