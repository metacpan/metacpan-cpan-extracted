##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/TextTrackList.pm
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
package HTML::Object::DOM::TextTrackList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::List );
    use vars qw( $VERSION );
    use Scalar::Util ();
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub addEventListener { return( shift->SUPER::addEventListener({
        addtrack    => { 
            add     => { property => 'children', type => 'add', event => 'addtrack' },
        },
        change      => {
            add     => { property => 'selected', type => 'add', event => 'change' },
            remove  => { property => 'selected', type => 'remove', event => 'change' },
        },
        removetrack => {
            remove  => { property => 'children', type => 'remove', event => 'removetrack' },
        },
    }, @_ ) ); }

sub children { return( shift->reset(@_)->_set_get_object_array_object({
    field => 'children',
    callbacks => 
    {
        add => '_on_children_add',
        remove => '_on_children_remove',
    }
}, 'HTML::Object::Element', @_ ) ); }

sub forEach { return( shift->children->foreach( @_ ) ); }

sub getTrackById
{
    my $self = shift( @_ );
    my $id   = shift( @_ );
    return if( !defined( $id ) || !CORE::length( "$id" ) );
    foreach my $e ( @$self )
    {
        if( Scalar::Util::blessed( $e ) && 
            $e->isa( 'HTML::Object::DOM::Element::Track' ) )
        {
            my $e_id = $e->attr( 'id' );
            return( $e ) if( defined( $e_id ) && $id eq $e_id );
        }
    }
    return;
}

# Note: property length is inherited

sub onaddtrack : lvalue { return( shift->on( 'addtrack', @_ ) ); }

sub onchange : lvalue { return( shift->on( 'change', @_ ) ); }

sub onremovetrack : lvalue { return( shift->on( 'removetrack', @_ ) ); }

sub _on_children_add
{
    my $self = shift( @_ );
    my( $pos, $ref ) = @_;
    my $track = $ref->[0];
    $self->_trigger_event_for( addtrack => {
        class => 'HTML::Object::DOM::TrackEvent',
        callback => sub
        {
            my $event = shift( @_ );
            $event->track( $track );
        }
    });
}

sub _on_children_remove
{
    my $self = shift( @_ );
    my( $pos, $ref ) = @_;
    my $track = $ref->[0];
    $self->_trigger_event_for( addtrack => {
        class => 'HTML::Object::DOM::TrackEvent',
        callback => sub
        {
            my $event = shift( @_ );
            $event->track( $track );
        }
    });
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::TextTrackList - HTML Object DOM Track List Class

=head1 SYNOPSIS

    use HTML::Object::DOM::TextTrackList;
    my $list = HTML::Object::DOM::TextTrackList->new || 
        die( HTML::Object::DOM::TextTrackList->error, "\n" );

Getting a video element's text track list:

    my $textTracks = $doc->querySelector( 'video' )->textTracks;

Monitoring track count changes:

    $textTracks->onaddtrack = \&updateTrackCount;
    $textTracks->onremovetrack = \&updateTrackCount;

    sub updateTrackCount
    {
        my $event = shift( @_ );
        my $trackCount = $textTracks->length;
        drawTrackCountIndicator( $trackCount );
    }

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<TextTrackList> interface is used to represent a list of the text tracks defined by the C<<track>> element, with each track represented by a separate textTrack object in the list. It inherits from L<HTML::Object::EventTarget>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::List | --> | HTML::Object::DOM::TextTrackList |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::List>

=head2 length

The number of tracks in the list.

Example:

    my $media = $doc->querySelector( 'video, audio' );
    my $numTextTracks = 0;

    if( $media->textTracks )
    {
        $numTextTracks = $media->textTracks->length;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/length>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::List>

=head2 addEventListener

Set a new event listener for the provided event type. See L<HTML::Object::EventTarget>

=head2 children

Set or get an L<array object|Module::Generic::Array> of elements. 

=head2 forEach

Provided with a callback code reference and this will call it for each child element.

See L<Module::Generic::Array/foreach>

=head2 getTrackById

Returns the L<TextTrack|HTML::Object::DOM::TextTrack> found within the C<TextTrackList> whose id matches the specified string. If no match is found, C<undef> is returned.

Example:

    my $theTrack = $TextTrackList->getTrackById( $id );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/getTrackById>

=head1 EVENTS

=head2 addtrack

Fired when a new text track has been added to the media element.
Also available via the onaddtrack property.

Example:

    my $mediaElement = $doc->querySelector( 'video, audio' );

    $mediaElement->textTracks->addEventListener( addtrack => sub
    {
        my $event = shift( @_ );
        say( "Text track: ", $event->track->label, " added" );
    });

    my $mediaElement = $doc->querySelector( 'video, audio' );

    $mediaElement->textTracks->onaddtrack = sub
    {
        my $event = shift( @_ );
        say( "Text track: ", $event->track->label, " added" );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/addtrack_event>

=head2 change

Fired when a text track has been made active or inactive.
Also available via the onchange property.

Example:

    my $mediaElement = $doc->querySelectorAll( 'video, audio' )->[0];
    $mediaElement->textTracks->addEventListener( change => sub
    {
        my $event = shift( @_ );
        say( "'", $event->type, "' event fired" );
    });

    my $mediaElement = $doc->querySelector( 'video, audio' );
    $mediaElement->textTracks->onchange = sub
    {
        say( "'", $event->type, "' event fired" );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/change_event>

=head2 removetrack

Fired when a new text track has been removed from the media element.
Also available via the onremovetrack property.

Example:

    my $mediaElement = $doc->querySelector( 'video, audio' );

    $mediaElement->textTracks->addEventListener( removetrack => sub
    {
        my $event = shift( @_ );
        say( "Text track: ", $event->track->label, " removed" );
    });

    my $mediaElement = $doc->querySelector( 'video, audio' );

    $mediaElement->textTracks->onremovetrack = sub
    {
        my $event = shift( @_ );
        say( "Text track: ", $event->track->label, " removed" );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/removeTrack_event>

=head1 EVENT HANDLERS

=head2 onaddtrack

An event handler to be called when the C<addtrack> event is fired, indicating that a new text track has been added to the media element.

Example:

    $doc->querySelector( 'video' )->textTracks->onaddtrack = sub
    {
        my $event = shift( @_ );
        addToTrackList( $event->track );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/onaddtrack>

=head2 onchange

An event handler to be called when the change event occurs.

Example:

    my $trackList = $doc->querySelector( 'video, audio' )->textTracks;

    $trackList->onchange = sub
    {
        my $event = shift( @_ );
         #.... do something
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/onchange>

=head2 onremovetrack

An event handler to call when the removetrack event is sent, indicating that a text track has been removed from the media element.

Example:

    $doc->querySelectorAll( 'video, audio' )->[0].textTracks->onremovetrack = sub
    {
        my $event = shift( @_ );
        myTrackCount = $doc->querySelectorAll( 'video, audio' )->[0]->textTracks->length;
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList/onremovetrack>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackList>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
