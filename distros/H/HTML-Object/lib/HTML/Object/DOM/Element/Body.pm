##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Body.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/05
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Body;
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
    $self->{tag} = 'body' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property aLink obsolete
sub aLink { return; }

# Note: property background obsolete
sub background { return; }

# Note: property bgColor obsolete
sub bgColor { return; }

# Note: property link obsolete
sub link { return; }

sub onafterprint : lvalue { return( shift->on( 'afterprint', @_ ) ); }

sub onbeforeprint : lvalue { return( shift->on( 'beforeprint', @_ ) ); }

sub onbeforeunload : lvalue { return( shift->on( 'beforeunload', @_ ) ); }

sub onhashchange : lvalue { return( shift->on( 'hashchange', @_ ) ); }

sub onlanguagechange : lvalue { return( shift->on( 'languagechange', @_ ) ); }

sub onmessage : lvalue { return( shift->on( 'message', @_ ) ); }

sub onmessageerror : lvalue { return( shift->on( 'messageerror', @_ ) ); }

sub onoffline : lvalue { return( shift->on( 'offline', @_ ) ); }

sub ononline : lvalue { return( shift->on( 'online', @_ ) ); }

sub onpagehide : lvalue { return( shift->on( 'pagehide', @_ ) ); }

sub onpageshow : lvalue { return( shift->on( 'pageshow', @_ ) ); }

sub onpopstate : lvalue { return( shift->on( 'popstate', @_ ) ); }

sub onrejectionhandled : lvalue { return( shift->on( 'rejectionhandled', @_ ) ); }

sub onresize : lvalue { return( shift->on( 'resize', @_ ) ); }

sub onstorage : lvalue { return( shift->on( 'storage', @_ ) ); }

sub onunhandledrejection : lvalue { return( shift->on( 'unhandledrejection', @_ ) ); }

sub onunload : lvalue { return( shift->on( 'unload', @_ ) ); }

# Note: property text obsolete
sub text { return; }

# Note: property vLink obsolete
sub vLink { return; }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Body - HTML Object DOM Body Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Body;
    my $body = HTML::Object::DOM::Element::Body->new || 
        die( HTML::Object::DOM::Element::Body->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Body |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 DESCRIPTION

The L<HTML::Object::DOM::Element::Body> interface provides special properties (beyond those inherited from the regular L<HTML::Object::DOM::Element> interface) for manipulating C<<body>> elements.

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head1 OBSOLETE PROPERTIES

Those properties all return C<undef>

=head2 aLink

Is a string that represents the color of active hyperlinks.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/aLink>

=head2 background

Is a string that represents the description of the location of the background image resource. Note that this is not an URI, though some older version of some browsers do expect it.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/background>

=head2 bgColor

Is a string that represents the background color for the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/bgColor>

=head2 link

Is a string that represents the color of unvisited links.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/link>

=head2 text

Is a string that represents the foreground color of text.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/text>

=head2 vLink

Is a string that represents the color of visited links.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/vLink>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 EVENT HANDLERS

Below are the event handlers you can use and that are implemented in this interface. However, it is up to you to fire those related events.

=head2 onafterprint

Is an event handler representing the code to be called when the afterprint event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onafterprint>

=head2 onbeforeprint

Is an event handler representing the code to be called when the beforeprint event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeprint>

=head2 onbeforeunload

Is an event handler representing the code to be called when the beforeunload event is raised.

Example:

    use HTML::Object::DOM qw( window );
    window->addEventListener( beforeunload => sub
    {
        # Cancel the event
        # If you prevent default behavior in Mozilla Firefox prompt will always be shown
        $e->preventDefault();
        # Chrome requires returnValue to be set
        $e->returnValue = '';
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeunload>

=head2 onhashchange

Is an event handler representing the code to be called when the hashchange event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onhashchange>

=head2 onlanguagechange

Is an event handler representing the code to be called when the languagechange event is raised.

Example:

    object->onlanguagechange = function;

    window->onlanguagechange = sub
    {
        say( 'languagechange event detected!' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onlanguagechange>

=head2 onmessage

Is an event handler called whenever an object receives a message event.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onmessage>

=head2 onmessageerror

Is an event handler called whenever an object receives a messageerror event.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onmessageerror>

=head2 onoffline

Is an event handler representing the code to be called when the offline event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/onoffline>

=head2 ononline

Is an event handler representing the code to be called when the online event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/ononline>

=head2 onpagehide

Is an event handler representing the code to be called when the pagehide event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/onpagehide>

=head2 onpageshow

Is an event handler representing the code to be called when the pageshow event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement/onpageshow>

=head2 onpopstate

Is an event handler representing the code to be called when the popstate event is raised.

Example:

    window->onpopstate = sub
    {
        my $event = shift( @_ );
        say( "location: " . $doc->location . ", state: " . JSON->new->encode( $event->state ) );
    };

    $history->pushState({page => 1}, "title 1", "?page=1");
    $history->pushState({page => 2}, "title 2", "?page=2");
    $history->replaceState({page => 3}, "title 3", "?page=3");
    $history->back(); # alerts "location: https://example.org/example.html?page=1, state => {"page" => 1}"
    $history->back(); # alerts "location: https://example.org/example.html, state: null
    $history->go(2);    # alerts "location: https://example.org/example.html?page=3, state => {"page" =>3}

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onpopstate>

=head2 onrejectionhandled

An event handler representing the code executed when the C<rejectionhandled> event is raised, indicating that a C<Promise> was rejected and the rejection has been handled.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onrejectionhandled>

=head2 onresize

Is an event handler representing the code to be called when the C<resize> event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onresize>

=head2 onstorage

Is an event handler representing the code to be called when the storage event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onstorage>

=head2 onunhandledrejection

An event handler representing the code executed when the unhandledrejection event is raised, indicating that a Promise was rejected but the rejection was not handled.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onunhandledrejection>

=head2 onunload

Is an event handler representing the code to be called when the unload event is raised.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onunload>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBodyElement>, L<Mozilla documentation on anchor element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/body>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
