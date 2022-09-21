##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/TrackEvent.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/29
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::TrackEvent;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Event );
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
    return( $self );
}

# Note: property read-only
sub track { return( shift->_set_get_object_without_init( 'track', '', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::TrackEvent - HTML Object DOM Track Event

=head1 SYNOPSIS

    use HTML::Object::DOM::TrackEvent;
    my $event = HTML::Object::DOM::TrackEvent->new( $type ) || 
        die( HTML::Object::DOM::TrackEvent->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<TrackEvent> interface, which is part of the HTML DOM specification, is used for events which represent changes to a set of available tracks on an HTML L<media element|HTML::Object::DOM::Element::Media>; these events are C<addtrack> and C<removetrack>.

Events based on TrackEvent are always sent to one of the media track list types:

=over 4

=item * Events involving video tracks are always sent to the L<VideoTrackList|HTML::Object::DOM::VideoTrackList> found in L<HTML::Object::DOM::Element::Media/videoTracks>

=item * Events involving audio tracks are always sent to the L<AudioTrackList|HTML::Object::DOM::AudioTrackList> specified in L<HTML::Object::DOM::Element::Media/audioTracks>

=item * Events affecting text tracks are sent to the L<TextTrackList object|HTML::Object::DOM::TextTrackList> indicated by L<HTML::Object::DOM::Element::Media/textTracks>.

=back

=head1 INHERITANCE

    +---------------------+     +-------------------------------+
    | HTML::Object::Event | --> | HTML::Object::DOM::TrackEvent |
    +---------------------+     +-------------------------------+

=head1 PROPERTIES

TrackEvent is based on L<Event|HTML::Object::Event>, so properties of L<Event|HTML::Object::Event> are also available on C<TrackEvent> objects.

=head2 track

Read-only.

This is a DOM track object this event is in reference to. If not C<undef>, this is always an object of one of the media track types: L<AudioTrack|HTML::Object::DOM::AudioTrack>, L<VideoTrack|HTML::Object::DOM::VideoTrack>, or L<TextTrack|HTML::Object::DOM::TextTrack>).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TrackEvent/track>

=head1 METHODS

TrackEvent has no methods of its own; however, it is based on L<Event|HTML::Object::Event>, so it provides the methods available on L<Event|HTML::Object::Event> objects.

=head1 EXAMPLE

    my $videoElem = $doc->querySelector( 'video' );

    $videoElem->videoTracks->addEventListener( 'addtrack', \&handleTrackEvent, { capture => 0 });
    $videoElem->videoTracks->addEventListener( 'removetrack', \&handleTrackEvent, { capture => 0 });
    $videoElem->audioTracks->addEventListener( 'addtrack', \&handleTrackEvent, { capture => 0 });
    $videoElem->audioTracks->addEventListener( 'removetrack', \&handleTrackEvent, { capture => 0 });
    $videoElem->textTracks->addEventListener( 'addtrack', \&handleTrackEvent, { capture => 0 });
    $videoElem->textTracks->addEventListener( 'removetrack', \&handleTrackEvent, { capture => 0 });

    sub handleTrackEvent
    {
        my $event = shift( @_ );
        my $trackKind;

        if( $event->target->isa( 'HTML::Object::DOM::VideoTrackList' ) )
        {
            $trackKind = 'video';
        }
        elsif( $event->target->isa( 'HTML::Object::DOM::AudioTrackList' ) )
        {
            $trackKind = 'audio';
        }
        elsif( $event->target->isa( 'HTML::Object::DOM::TextTrackList' ) )
        {
            $trackKind = 'text';
        }
        else
        {
            $trackKind = 'unknown';
        }

        my $type = $event->type;
        if( $type eq 'addtrack' )
        {
            say( "Added a $trackKind track" );
        }
        elsif( $type eq 'removetrack' )
        {
            say( "Removed a $trackKind track" );
        }
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TrackEvent>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
