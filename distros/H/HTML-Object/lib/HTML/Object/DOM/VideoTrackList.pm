##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/VideoTrackList.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/28
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::VideoTrackList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::List );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{selectedindex} = -1;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub addEventListener { return( shift->SUPER::addEventListener({
        addtrack    => { 
            add     => { property => 'children', type => 'add', event => 'addtrack', callback => sub
                {
                    my( $event, $ref ) = @_;
                    $event->track( $ref->{added} ) if( $ref->{added} );
                }},
        },
        change      => {
            add     => { property => 'selected', type => 'add', event => 'change' },
            remove  => { property => 'selected', type => 'remove', event => 'change' },
        },
        removetrack => {
            remove  => { property => 'children', type => 'remove', event => 'removetrack', callback => sub
                {
                    my( $event, $ref ) = @_;
                    $event->track( $ref->{removed} ) if( $ref->{removed} );
                }},
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

# Note: property
sub selectedIndex : lvalue { return( shift->_set_get_number({
    field => 'selectedindex',
    callbacks =>
    {
        add => '_on_selectedindex_change',
        remove => '_on_selectedindex_change',
    }
}, @_ ) ); }

# Note: property selectedindex
sub selectedindex : lvalue { return( shift->selectedIndex( @_ ) ); }

sub _on_children_add { return( shift->_trigger_event_for( addtrack => 'HTML::Object::DOM::TrackEvent' ) ); }

sub _on_children_remove { return( shift->_trigger_event_for( removetrack => 'HTML::Object::DOM::TrackEvent' ) ); }

sub _on_selectedindex_change { return( shift->_trigger_event_for( change => 'HTML::Object::DOM::TrackEvent' ) ); }

# Get called by HTML::Object::DOM::VideoTrack->selected
sub _update_selected
{
    my $self = shift( @_ );
    my $track = shift( @_ );
    my $pos = $self->children->index( $track );
    $self->selectedIndex( $pos ) if( defined( $pos ) );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::VideoTrackList - HTML Object DOM VideoTrackList Class

=head1 SYNOPSIS

    use HTML::Object::DOM::VideoTrackList;
    my $list = HTML::Object::DOM::VideoTrackList->new || 
        die( HTML::Object::DOM::VideoTrackList->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<VideoTrackList> interface is used to represent a list of the video tracks contained within a <video> element, with each track represented by a separate C<VideoTrack> object in the list.

It inherits from L<HTML::Object::EventTarget>.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::List | --> | HTML::Object::DOM::VideoTrackList |
    +-----------------------+     +---------------------------+     +-------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::List>

=head2 length

The number of tracks in the list.

Example:

    my $videoElem = $doc->querySelector( 'video' );
    my $numVideoTracks = 0;
    if( $videoElem->videoTracks )
    {
        $numVideoTracks = $videoElem->videoTracks->length;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/length>

=head2 selectedIndex

Sets or gets a number. Under perl, this is not set automatically. It is up to you to set this to whatever number you see fit.

Under JavaScript, this is the index of the currently selected track, if any, or −1 otherwise.

It returns the number as an L<object|Module::Generic::Number>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/selectedIndex>

=head2 selectedindex

Alias for L</selectedIndex>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::List>

=head2 addEventListener

Calls and returns the value from addEventListenerCalls in the ancestor class L<HTML::Object::DOM::List>

=head2 children

Returns an L<array object|Module::Generic::Array> of this element's children.

=head2 forEach

This is an alias for L<Module::Generic::Array/foreach>

=head2 getTrackById

Returns the C<VideoTrack> found within the C<VideoTrackList> whose id matches the specified string. If no match is found, C<undef> is returned.

Example:

    my $theTrack = $VideoTrackList->getTrackById( $id );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/getTrackById>

=head1 EVENTS

Events fired are of class L<HTML::Object::DOM::TrackEvent>

=head2 addtrack

Fired when a new video track has been added to the L<media element|HTML::Object::DOM::Element::Video>. Also available via the L</onaddtrack> property.

Example:

    my $videoElement = $doc->querySelector('video');

    $videoElement->videoTracks->addEventListener( addtrack => sub
    {
        my $event = shift( @_ );
        say( "Video track: ", $event->track->label, " added" );
    });

    my $videoElement = $doc->querySelector('video');

    $videoElement->videoTracks->onaddtrack = sub
    {
        my $event = shift( @_ );
        say( "Video track: ", $event->track->label, " added" );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/addtrack_event>

=head2 change

Fired when a video track has been made active or inactive. Also available via the L</onchange> property.

Example:

    my $videoElement = $doc->querySelector( 'video' );
    $videoElement->videoTracks->addEventListener( change => sub
    {
        say( "'", $event->type, "' event fired" );
    });

    # changing the value of 'selected' will trigger the 'change' event
    my $toggleTrackButton = $doc->querySelector( '.toggle-$track' );
    $toggleTrackButton->addEventListener( click => sub
    {
        my $track = $videoElement->videoTracks->[0];
        $track->selected = !$track->selected;
    });

    my $videoElement = $doc->querySelector( 'video' );
    $videoElement->videoTracks->onchange = sub
    {
        my $event = shift( @_ );
        say( "'", $event->type, "' event fired" );
    };

    # changing the value of 'selected' will trigger the 'change' event
    my $toggleTrackButton = $doc->querySelector( '.toggle-$track' );
    $toggleTrackButton->addEventListener( click => sub
    {
        my $track = $videoElement->videoTracks->[0];
        $track->selected = !$track->selected;
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/change_event>

=head2 removetrack

Fired when a new video track has been removed from the media element. Also available via the L</onremovetrack> property.

Example:

    my $videoElement = $doc->querySelector( 'video' );

    $videoElement->videoTracks->addEventListener( removetrack => sub
    {
        my $event = shift( @_ );
        say( "Video track: ", $event->track->label, " removed" );
    });

    my $videoElement = $doc->querySelector( 'video' );

    $videoElement->videoTracks->onremovetrack = sub
    {
        my $event = shift( @_ );
        say( "Video track: ", $event->track->label, " removed" );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/removetrack_event>

=head1 EVENT HANDLERS

=head2 onaddtrack

An event handler to be called when the L</addtrack> event is fired, indicating that a new video track has been added to the media element.

Example:

    $doc->querySelector('video')->videoTracks->onaddtrack = sub
    {
        my $event = shift( @_ );
        addToTrackList( $event->track );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/onaddtrack>

=head2 onchange

An event handler to be called when the change event occurs — that is, when the value of the selected property for a track has changed, due to the track being made active or inactive.

Example:

    my $trackList = $doc->querySelector( 'video' )->videoTracks;
    $trackList->onchange = sub
    {
        my $event = shift( @_ );
        $trackList->forEach(sub
        {
            my $track = shift( @_ );
            updateTrackSelectedButton( $track->id, $track->selected );
        });
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/onchange>

=head2 onremovetrack

An event handler to call when the removetrack event is sent, indicating that a video track has been removed from the media element.

Example:

    $doc->querySelector( 'my-video' )->videoTracks->onremovetrack = sub
    {
        $myTrackCount = $doc->querySelector( 'my-video' )->videoTracks->length;
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList/onremovetrack>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrackList>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
