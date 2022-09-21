##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/EventTarget.pm
## Version v0.2.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/11
## Modified 2022/09/20
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::EventTarget;
BEGIN
{
    use strict;
    use warnings;
    # Changed inheritance from Module::Generic to HTML::Object::Element, because I need modules like
    # HTML::Object::DOM::TextTrack that inherits from EventTarget to also have the parent method provided
    # by the core module HTML::Object::Element
    use parent qw( HTML::Object::Element );
    use vars qw( $PACK_SUB_RE $SIGNALS $VERSION );
    use HTML::Object::EventListener;
    use Scalar::Util ();
    use Want;
    our $PACK_SUB_RE = qr/^(((?<pack>[a-zA-Z\_]\w*(?:\:\:\w+)*)\:\:)?(?<sub>\w+))$/;
    # Hash reference of signal to array of object to remove their listeners
    our $SIGNALS = {};
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1 unless( CORE::exists( $self->{_init_strict_use_sub} ) );
    $self->{_exception_class} = 'HTML::Object::Exception' unless( CORE::exists( $self->{_exception_class} ) );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{event_listeners} = {};
    return( $self );
}

sub addEventListener
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || return( $self->error( "No event listener type was provided." ) );
    my $callback = shift( @_ ) || return( $self->error( "No event listener callback was provided." ) );
    return( $self->error( "Event listener type \"$type\" contains illegal characters. It should contain only alphanumeric and _ characters." ) ) if( $type !~ /^\w+$/ );
    $type = lc( $type );
    if( !ref( $callback ) && $callback =~ /$PACK_SUB_RE/ )
    {
        my( $pack, $sub ) = @+{qw( pack sub )};
        $pack ||= caller;
        if( my $ref = $pack->can( $sub ) )
        {
            $callback = $ref;
        }
        else
        {
            return( $self->error( "Unknown subroutine \"$callback\" in package \"$pack\"." ) );
        }
    }
    return( $self->error( "Event listener callback is not a code reference." ) ) if( ref( $callback ) ne 'CODE' );
    my $opts = $self->_get_args_as_hash( @_ );
    my @ok_params = qw( capture once passive signal debug );
    my $params = {};
    @$params{ @ok_params } = CORE::delete( @$opts{ @ok_params } );
    my $post_processing;
    $post_processing = CORE::delete( $opts->{post_processing} ) if( CORE::exists( $opts->{post_processing} ) && ref( $opts->{post_processing} ) eq 'CODE' );
    if( scalar( keys( %$opts ) ) )
    {
        warnings::warn( "Unrecognised options: '", join( "', '", sort( keys( %$opts ) ) ), "'\n" ) if( warnings::enabled( 'HTML::Object' ) );
    }
    $params->{capture} //= 0;
    $params->{once}    //= 0;
    $params->{passive} //= 0;
    my $key = join( ';', $type, Scalar::Util::refaddr( $callback ), $params->{capture} );
    $self->{event_listeners} = {} if( !CORE::exists( $self->{event_listeners} ) );
    my $repo = $self->{event_listeners};
    my $debug = CORE::delete( $params->{debug} ) || 0;
    my $eh = HTML::Object::EventListener->new(
        type    => $type,
        code    => $callback,
        options => $params,
        element => $self,
        debug   => $debug,
    ) || return( $self->pass_error( HTML::Object::EventListener->error ) );
    if( $params->{signal} && $params->{signal} =~ /^\w+$/ )
    {
        $SIG{ $params->{signal} } = \&_signal_remove_listeners;
        $SIGNALS->{ $params->{signal} } = [] if( !CORE::exists( $SIGNALS->{ $params->{signal} } ) );
        push( @{$SIGNALS->{ $params->{signal} }}, $eh );
    }
    $repo->{ $type } = {} if( !CORE::exists( $repo->{ $type } ) );
    $repo->{ $type }->{sequence} = $self->new_array if( !CORE::exists( $repo->{ $type }->{sequence} ) );
    $repo->{ $type }->{ $key } = $eh;
    if( $repo->{ $type }->{sequence}->has( $key ) )
    {
        $repo->{ $type }->{sequence}->remove( $key );
    }
    $repo->{ $type }->{sequence}->push( $key );
    # Call any post-processing callback if necessary.
    # Those are used so that event monitoring can be enabled upon setting event handlers and not before, on some data like array or scalar
    # See HTML::Object::LDOM::List for example
    if( defined( $post_processing ) )
    {
        $post_processing->( $eh );
    }
    return( $eh );
}

sub dispatchEvent
{
    my $self = shift( @_ );
    my $event = shift( @_ ) || return( $self->error( "No event object was provided." ) );
    return( $self->error( "Event object provided ($event) is not an HTML::Object::Event" ) ) if( !$self->_is_a( $event => 'HTML::Object::Event' ) );
    $event->target( $self );
    
    my $type = $event->type || return( $self->error( "The event has no type associated with it!" ) );
    $type = lc( $type );
    my $can_cancel = $event->cancelable;
    return( $self ) if( $can_cancel && $event->cancelled );
    # from current element to top one
    my $path = $event->composedPath;
    $event->eventPhase( $event->CAPTURING_PHASE );
    # Go from top to our element, i.e. reverse
    $path->reverse->foreach(sub
    {
        my $node = shift( @_ );
        $event->currentTarget( $node );
        $node->handleEvent( $event ) || do
        {
        };
        if( $can_cancel && $event->cancelled )
        {
            return;
        }
        # Make sure to return true to keep looping
        return(1);
    });
    return( $self ) if( $can_cancel && $event->cancelled >= $event->CANCEL_IMMEDIATE_PROPAGATION );
    $event->eventPhase( $event->AT_TARGET );
    $event->currentTarget( $self );
    $self->handleEvent( $event );
    return( $self ) if( $can_cancel && $event->cancelled >= $event->CANCEL_PROPAGATION );
    # This event does not bubble, so we do nothing more
    return( $self ) if( !$event->bubbles );
    $event->eventPhase( $event->BUBBLING_PHASE );
    # Now, go from our element to the top one
    $path->for(sub
    {
        my( $i, $node ) = @_;
        # Skip the first one which is us.
        return(1) if( $i == 0 );
        $event->currentTarget( $node );
        $node->handleEvent( $event ) || do
        {
        };
        if( $can_cancel && $event->cancelled )
        {
            return;
        }
        # Make sure to return true to keep looping
        return(1);
    });
    return( $self );
}

sub event_listeners { return( shift->_set_get_hash( 'event_listeners', @_ ) ); }

sub getEventListeners
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    return( $self->error( "No event type propoded to get its event listeners." ) ) if( !defined( $type ) || !CORE::length( $type ) );
    $self->{event_listeners} = {} if( !CORE::exists( $self->{event_listeners} ) );
    my $repo = $self->{event_listeners};
    return if( !scalar( keys( %$repo ) ) );
    $repo->{ $type } = {} if( !CORE::exists( $repo->{ $type } ) );
    $repo->{ $type }->{sequence} = $self->new_array if( !CORE::exists( $repo->{ $type }->{sequence} ) );
    my $results = $self->new_array;
    $repo->{ $type }->{sequence}->foreach(sub
    {
        my $key = shift( @_ );
        $results->push( $repo->{ $type }->{ $key } ) if( CORE::exists( $repo->{ $type }->{ $key } ) && $self->_is_a( $repo->{ $type }->{ $key } => 'HTML::Object::EventListener' ) );
    });
    return( $results );
}

sub handleEvent
{
    my $self = shift( @_ );
    my $evt = shift( @_ ) || return( $self->error({
        message => "No event was provided to handle.",
        class => 'HTML::Object::SyntaxError',
    }) );
    return( $self->error({
        message => "Event object provided is not an event of class HTML::Object::Event or its descendants.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $evt => 'HTML::Object::Event' ) );
    return( $self ) if( $evt->cancelled );
    my $can_cancel = $evt->cancelable;
    
    my $repo = $self->{event_listeners};
    my $type = $evt->type || return( $self->error({
        message => "No event type was provided.",
        class => 'HTML::Object::SyntaxError',
    }) );
    return( $self ) if( !CORE::exists( $repo->{ $type } ) );
    return( $self->error({
        message => "Repository of event listener of type '$type' is not an hash reference!",
        class => 'HTML::Object::TypeError',
    }) ) if( ref( $repo->{ $type } ) ne 'HASH' );
    
    return( $self->error({
        message => "Could not find the 'sequence' property in the repository of event listeners.",
        class => 'HTML::Object::SyntaxError',
    }) ) if( !CORE::exists( $repo->{ $type }->{sequence} ) );
    return( $self->error({
        message => "Sequence property of event listeners for type '$type' is not a Module::Generic::Array object",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $repo->{ $type }->{sequence} => 'Module::Generic::Array' ) );

    $evt->currentTarget( $self );
    my $eventPhase = $evt->eventPhase;
    foreach my $key ( @{$repo->{ $type }->{sequence}} )
    {
        return( $self->error({
            message => "Empty key found in sequence repository.",
            class => 'HTML::Object::SyntaxError',
        }) ) if( !defined( $key ) || !CORE::length( $key ) );
        if( !CORE::exists( $repo->{ $type }->{ $key } ) )
        {
            return( $self->error({
                message => "Found an event listener of type '$type' with key '$key', but could not find its associated entry in the event listener repository.",
                class => 'HTML::Object::SyntaxError',
            }) );
        }
        my $listener = $repo->{ $type }->{ $key };
        if( !$self->_is_a( $listener => 'HTML::Object::EventListener' ) )
        {
            return( $self->error({
                message => "The event listener of type '$type' found is not an HTML::Object::EventListener object.",
                class => 'HTML::Object::TypeError',
            }) );
        }
        
        # check we are in the right phase
        if( ( $eventPhase eq $evt->AT_TARGET && $evt->target ne $self ) ||
            ( $eventPhase eq $evt->CAPTURING_PHASE && !$listener->capture ) ||
            ( $eventPhase eq $evt->BUBBLING_PHASE && $listener->capture ) )
        {
            next;
        }
        
        my $code = $listener->code;
        if( ref( $code ) ne 'CODE' )
        {
            # return( $self->error({
            #     message => "The handler for the event listener of type '$type' is not a code reference.",
            #     class => 'HTML::Object::TypeError',
            # }) );
            warnings::warn( "Warning only: the handler for the event listener of type '$type' is not a code reference.\n" ) if( warnings::enabled( 'HTML::Object' ) );
            next;
        }
        local $_ = $self;
        # Note: Should we catch a die, or let it die, if that were the case?
        $code->( $evt );
        last if( $can_cancel && $evt->cancelled == $evt->CANCEL_IMMEDIATE_PROPAGATION );
    }
    return( $self );
}

sub hasEventListener
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    $self->{event_listeners} = {} if( !CORE::exists( $self->{event_listeners} ) );
    my $repo = $self->{event_listeners};
    return( $self->new_number(0) ) if( !scalar( keys( %$repo ) ) );
    if( defined( $type ) && CORE::length( $type ) )
    {
        $repo->{ $type } = {} if( !CORE::exists( $repo->{ $type } ) );
        my $n = scalar( keys( %{$repo->{ $type }} ) );
        $n-- if( CORE::exists( $repo->{ $type }->{sequence} ) );
        return( $self->new_number( $n ) );
    }
    my $n = 0;
    foreach my $t ( keys( %$repo ) )
    {
        $n += scalar( keys( %{$repo->{ $t }} ) );
        $n-- if( CORE::exists( $repo->{ $t }->{sequence} ) );
    }
    return( $self->new_number( $n ) );
}

sub on : lvalue
{
    my $self = shift( @_ );
    my $event = shift( @_ );
    # Argument provided is a code reference
    my $has_arg = 0;
    my $arg;
    if( Want::want( qw( LVALUE ASSIGN ) ) )
    {
        ( $arg ) = Want::want( 'ASSIGN' );
        $has_arg = 'assign';
    }
    else
    {
        if( @_ )
        {
            $arg = shift( @_ );
            $has_arg++;
        }
    }

    if( !defined( $event ) || !CORE::length( $event ) )
    {
        my $error = "No event provided to set event handler.";
        if( $has_arg eq 'assign' )
        {
            $self->error( $error );
            my $dummy = 'dummy';
            return( $dummy );
        }
        return( $self->error( $error ) ) if( Want::want( 'LVALUE' ) );
        Want::rreturn( $self->error( $error ) );
    }
    
    if( $has_arg )
    {
        if( ref( $arg ) ne 'CODE' )
        {
            my $error = "Value provided is not a code reference.";
            if( $has_arg eq 'assign' )
            {
                $self->error( $error );
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->error( $error ) ) if( Want::want( 'LVALUE' ) );
            Want::rreturn( $self->error( $error ) );
        }
        my $eh = $self->addEventListener( $event => $arg ) || do
        {
            if( $has_arg eq 'assign' )
            {
                my $dummy = 'dummy';
                return( $dummy );
            }
            return( $self->pass_error ) if( Want::want( 'LVALUE' ) );
            Want::rreturn( $self->pass_error );
        };
        return( $eh ) if( Want::want( 'LVALUE' ) );
        Want::rreturn( $eh );
    }
    my $listeners = $self->getEventListeners( $event ) || do
    {
        if( $has_arg eq 'assign' )
        {
            my $dummy = 'dummy';
            return( $dummy );
        }
        return if( Want::want( 'LVALUE' ) );
        Want::rreturn;
    };
    return( $listeners->first ) if( Want::want( 'LVALUE' ) );
    Want::rreturn( $listeners->first );
}

sub removeEventListener
{
    my $self = shift( @_ );
    my $type = shift( @_ ) || return( $self->error( "No event listener type was provided." ) );
    my( $callback, $eh );
    if( $self->_is_a( $_[0] => 'HTML::Object::EventListener' ) )
    {
        $eh = shift( @_ );
        $callback = $eh->code;
    }
    else
    {
        $callback = shift( @_ ) || return( $self->error( "No event listener callback was provided." ) );
    }
    return( $self->error( "Event listener type \"$type\" contains illegal characters. It should contain only alphanumeric and _ characters." ) ) if( $type !~ /^\w+$/ );
    if( !ref( $callback ) && 
        $callback =~ /$PACK_SUB_RE/ )
    {
        my( $pack, $sub ) = @+{qw( pack sub )};
        $pack ||= caller;
        if( my $ref = $pack->can( $sub ) )
        {
            $callback = $ref;
        }
        else
        {
            return( $self->error( "Unknown subroutine \"$callback\" in package \"$pack\"." ) );
        }
    }
    return( $self->error( "Event listener callback is not a code reference. You can provide either an event listener object (HTML::Object::EventListener, or a reference to a subroutine, or a subroutine name such as MyPackage::my_sub." ) ) if( defined( $callback ) && ref( $callback ) ne 'CODE' );
    my $opts = $self->_get_args_as_hash( @_ );
    if( defined( $eh ) && !CORE::exists( $opts->{capture} ) )
    {
        $opts->{capture} = $eh->options->{capture};
    }
    my @ok_params = qw( capture );
    my $params = {};
    @$params{ @ok_params } = CORE::delete( @$opts{ @ok_params } );
    if( scalar( keys( %$opts ) ) )
    {
        warnings::warn( "Unrecognised options: '", join( "', '", sort( keys( %$opts ) ) ), "'\n" ) if( warnings::enabled( 'HTML::Object' ) );
    }
    $params->{capture} //= 0;
    my $key = join( ';', $type, Scalar::Util::refaddr( $callback ), $params->{capture} );
    $self->{event_listeners} = {} if( !CORE::exists( $self->{event_listeners} ) );
    my $repo = $self->{event_listeners};
    $repo->{ $type } = {} if( !CORE::exists( $repo->{ $type } ) );
    $eh = CORE::delete( $repo->{ $type }->{ $key } );
    $repo->{ $type }->{sequence} = $self->new_array if( !CORE::exists( $repo->{ $type }->{sequence} ) );
    $repo->{ $type }->{sequence}->remove( $key );
    return( $eh );
}

sub _signal_remove_listeners
{
    my $sig = shift( @_ ) || 
    do
    {
        warnings::warn( "Warning only: no signal was provided in HTML::Object::EventTarget::_signal_remove_listeners\n" ) if( warnings::enabled( 'HTML::Object' ) );
        return;
    };
    my $all = $SIGNALS->{ $sig };
    if( ref( $all ) eq 'ARRAY' )
    {
        $_->remove for( @$all );
    }
}

sub _trigger_event_for
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    my $class;
    if( index( $_[0], '::' ) != -1 )
    {
        $class = shift( @_ );
    }
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{class} //= '';
    $class //= $opts->{class} || 'HTML::Object::Event';
    $self->_load_class( $class ) || return( $self->pass_error );
    my $event = $class->new( $type, @_ ) || return( $self->error( $class->error ) );
    if( CORE::exists( $opts->{callback} ) && ref( $opts->{callback} ) eq 'CODE' )
    {
        local $_ = $event;
        $opts->{callback}->( $event );
    }
    $self->dispatchEvent( $event ) || return( $self->pass_error );
    return( $event );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::EventTarget - HTML Object Event Target Class

=head1 SYNOPSIS

    use HTML::Object::EventTarget;
    my $eh = HTML::Object::EventTarget->new(
        
    ) || die( HTML::Object::EventTarget->error, "\n" );

    $e->addEventListener( change => sub
    {
        my $event = shift( @_ ); # also available as $_
        # do something with that event (HTML::Object::Event)
    }, {capture => 0});

    $e->dispatchEvent( $event );

    my $event_handlers = $e->getEventListeners( 'click' );
    say "Found ", $Event_handlers->length, " event handlers";

    $e->handleEvent( $event );

    $e->on( click => sub
    {
        my $event = shift( @_ );
        # do something
    });
    # or
    sub onclick : lvalue { return( shift->on( 'click', @_ ) ); }
    $e->onclick = sub
    {
        my $event = shift( @_ );
        # do something
    };

    $e->removeEventListener( $event_listener_object );

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This modules represents an event target and handler. This is implemented by L<HTML::Object::Document> and L<HTML::Object::Element> and its descendants.

Of course, being perl, there is only limited support for events.

=head1 CONSTRUCTOR

=head2 new

Creates a new L<HTML::Object::EventTarget> object instance and returns it.

=head1 METHODS

=head2 addEventListener

Provided with a C<type>, a C<callback> and an optional hash or hash reference of C<options> and this will register an event handler (i.e. a callback subroutine) of a specific event type on the L<EventTarget|HTML::Object::Element>.

When an event is "fired", the C<callback> is called, and the L<event object|HTML::Object::Event> is passed as it sole argument. Also, C<$_> is set to the current L<element object|HTML::Object::Element> on which the event got triggered.

It returns the newly created L<HTML::Object::EventListener> upon success or L<perlfunc/undef> upon error and sets an L<error|Module::Generic/error>

Possible options are:

=over 4

=item I<capture>

A boolean value indicating that events of this type will be dispatched to the registered listener before being dispatched to any L<EventTarget|HTML::Object::Element> beneath it in the L<DOM|HTML::Object::Document> tree. 

Setting the capture flag controls whether an event listener is called in the Capture phase or Bubble phase.

For example:

    <div id="div1">
        <div id="div2"></div>
    </div>

    $div1->addEventListener('click', \&doSomething1, {capture => 1 });
    $div2->addEventListener('click', \&doSomething2, {capture => 0 });

Triggering a C<click> event on C<div2> yields the following[1]:

    $div2->trigger('click');

=over 4

=item 1. The C<click> event starts in the capturing phase. The event looks if any ancestor element of element2 has a onclick event handler for the capturing phase.

=item 2. The event finds one on C<div1>. C<doSomething1()> is executed.

=item 3. The event travels down to the target itself, no more event handlers for the capturing phase are found. The event moves to its bubbling phase and executes C<doSomething2()>, which is registered to C<div2> for the bubbling phase.

=item 4. The event travels upwards again and checks if any ancestor element of the target has an event handler for the bubbling phase. This is not the case, so nothing happens.

=back

The reverse would be:

    $div1->addEventListener('click', \&doSomething1, {capture => 0 });
    $div2->addEventListener('click', \&doSomething2, {capture => 0 });

=over 4

=item 1. The click event starts in the capturing phase. The event looks if any ancestor element of C<div2> has a onclick event handler for the capturing phase and doesn’t find any.

=item 2. The event travels down to the target itself. The event moves to its bubbling phase and executes C<doSomething2()>, which is registered to C<div2> for the bubbling phase.

=item 3. The event travels upwards again and checks if any ancestor element of the target has an event handler for the bubbling phase.

=item 4. The event finds one on C<div1>. Now C<doSomething1()> is executed.

=back

Setting an event listener like this:

    $div1->onclick = \&doSomething1;

would register it in the bubbling phase, i.e. equivalent to:

    $div1->addEventListener( click => \&doSomething1, { capture => 0 } );

[1] Koch, Peter-Paul "Event order" (Quirkcsmode) L<https://www.quirksmode.org/js/events_order.html>

See L<for more information|https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events#event_bubbling_and_capture> and L<this|https://www.quirksmode.org/js/events_order.html>

=item I<once>

A boolean value indicating that the listener should be invoked at most once after being added. If true, the listener would be automatically removed when invoked.

=item I<passive>

This, under perl, does nothing and thus always defaults to false.

Under JavaScript, this would be a boolean value that, if true, indicates that the function specified by listener will never call C<preventDefault()>. If a passive listener does call C<preventDefault()>, the user agent will do nothing other than generate a console warning. See Improving scrolling performance with passive listeners to learn more.

=item I<post_processing>

This is a non-standard addition and is a code reference (i.e. a subroutine reference or an anonymous subroutine) passed that will be called once the event handler has been set. It is passed the newly created L<event listener object|HTML::Object::EventListener>.

This is used by L<HTML::Object::DOM::List> for example, to enable event listening on array or scalar only when an event listener is registered. So, upon adding an event listener, this post-processing callback is called and this callback takes the appropriate step to start listening to a specific array or scalar.

=item I<signal>

A signal, such as C<ALRM>, C<INT>, or C<TERM>. The listener will be removed when the given C<signal> is called.

=back

Example:

    <table id="outside">
        <tr><td id="t1">one</td></tr>
        <tr><td id="t2">two</td></tr>
    </table>

    # Subroutine to change the content of $t2
    sub modifyText
    {
        my $t2 = $doc->getElementById("t2");
        if( $t2->firstChild->nodeValue eq "three" )
        {
            $t2->firstChild->nodeValue = "two";
        }
        else
        {
            $t2->firstChild->nodeValue = "three";
        }
    }

    # Add event listener to table
    my $el = $doc->getElementById("outside");
    $el->addEventListener("click", \&modifyText, { capture => 0 } );

Then, do:

    $el->trigger( 'click' );

You can also pass subroutine name that is in your package, or a fully qualified subroutine name. For example:

Assuming you are calling from the package My::Module, the following will search for a subroutine C<My::Module::my_callback>

    $el->addEventListener("click", 'my_callback', { capture => 0 } );

Or

    $el->addEventListener("click", 'My:Module::my_callback', { capture => 0 } );

If it does not exists, it will return C<undef> and set an L<error|HTML::Object::Exception>.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/addEventListener>

=head2 dispatchEvent

Provided with an L<event|HTML::Object::Event>, and this dispatches the event to this L<EventTarget|HTNL::Object::Element>.

It will first call L</composedPath> to get the branch from this current element to the top one, and will start from the top in the C<capture> phase, checking every element from top up to the current one and calls L</handleEvent>, which, in turn, will check if there are any listeners registered in this C<capture> phase, and if there are calls each listener's L<HTML::Object::EventListener/handleEvent>.

Then once the C<capture> phase is done, it executes the event listeners on the current L<element|HTML::Object::Element>, if any.

Then finally, if the event L<HTML::Object::Event/bubbles> property is true, it calls L</handleEvent> on each of the element starting from the current element's parent to the top one. L</handleEvent>, in turn, will check if there are any event listeners registereed for the element in question for the C<bubbling> phase and call their L<event handler|HTML::Object::EventListener/handleEvent>.

If the event property L<HTML::Object::Event/cancelable> is set to true and a handler cancelled it  at any point, then this whole process is interrupted.

The event L<current element|HTML::Object::Event/currentTarget> is set each time, so you can check that to find out which one has cancelled it.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/dispatchEvent>

L<See also|https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events#bubbling_and_capturing_explained>

=head2 event_listeners

Sets or gets an hash reference of all the event listeners registered.

=head2 getEventListeners

Provided with an event type, such as C<click>, and this returns all the L<event listener objects|HTML::Object::EventListener> registere for that event type in their order of registration. It returns an L<array object|Module::Generic::Array>

    my $listeners = $e->getEventListeners( 'click' );
    say "Found ", $listeners->length, " event listeners.";

=head2 handleEvent

Provided with an L<event|HTML::Object::Event> and this will process it via all the registered event listeners in the order they were registered.

It returns the current element object upon success, and upon error, it returns C<undef> and sets an L<error|Module::Generic/error>

=head2 hasEventListener

Provided with an optional event type and this returns the number of event listeners registered for the given type, if provided, or the total number of event listeners registered for all types.

=head2 on

This is a convenient method to set event listeners. It is to be called by a class, such as:

    sub onclick : lvalue { return( shift->on( 'click' @_ ) ); }

Then, you can set a C<click> event listener for this element:

    $e->onclick = sub
    {
        my $event = shift( @_ ); # Also available with $_
        # Do some work
    };
    # or
    $e->onclick(sub
    {
        my $event = shift( @_ ); # Also available with $_
        # Do some work
    });

=head2 removeEventListener

Provided with a event C<type>, a C<callback> code reference or a subroutine name (possibly including its package like C<MyPackage::my_sub>), or an L<event listener object|HTML::Object::EventListener>, and an hash or hash reference of options and this removes an event listener from the L<EventTarget|HTML::Object::Element>.

It returns the L<HTML::Object::EventListener> thus removed upon success or L<perlfunc/undef> upon error and sets an L<error|Module::Generic/error>

Possible options, to identify the event handler to remove, are:

=over 4

=item I<capture>

A boolean value indicating that events of this type will be dispatched to the registered listener before being dispatched to any L<EventTarget|HTML::Object::Element> beneath it in the L<DOM|HTML::Object::Document> tree. 

=back

For example:

    my $eh = $e->addEventListener( click => sub{ # do something }, { capture => 1, once => 1 });
    $eh->remove;
    # or
    $e->removeEventListener( click => $same_code_ref, { capture => 1 });

However, if the options provided differ from the ones initially set, it will not uniquely find the event handler. Only the C<capture> option is used to uniquely find the handler. For example:

This will fail to remove the handler, because the C<capture> parameter does not have the same value.

    $e->removeEventListener( click => $same_code, { capture => 0 });

This will fail to remove the handler, because the C<callback> value is not the same as the original.

    $e->removeEventListener( click => $some_other_code_ref, { capture => 1 });

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/EventTarget/removeEventListener>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://developer.mozilla.org/en-US/docs/Web/API/EventTarget>

L<https://developer.mozilla.org/en-US/docs/Web/Events/Event_handlers>

L<https://developer.mozilla.org/en-US/docs/Web/API/Event>

L<https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Building_blocks/Events>

L<https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers>

L<https://domevents.dev/> a very useful interactive playground app that enables learning about the behavior of the DOM Event system through exploration.

L<https://www.quirksmode.org/js/events_order.html> discussion of capturing and bubbling — an excellently detailed piece by Peter-Paul Koch.

L<https://www.quirksmode.org/js/events_access.html> discussion of the event object — another excellently detailed piece by Peter-Paul Koch.

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
