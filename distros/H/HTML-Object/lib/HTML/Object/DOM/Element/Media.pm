##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Media.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Media;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( @EXPORT_OK %EXPORT_TAGS $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :media );
    use HTML::Object::DOM::TrackEvent;
    use constant {
        # For HTML::Object::DOM::Element::Media
        # There is no data yet. Also, readyState is HAVE_NOTHING.
        NETWORK_EMPTY       => 0,
        # HTMLMediaElement is active and has selected a resource, but is not using the network.
        NETWORK_IDLE        => 1,
        # The browser is downloading HTMLMediaElement data.
        NETWORK_LOADING     => 2,
        # No HTMLMediaElement src found.
        NETWORK_NO_SOURCE   => 3,
    };
    our @EXPORT_OK = qw( NETWORK_EMPTY NETWORK_IDLE NETWORK_LOADING NETWORK_NO_SOURCE );
    our %EXPORT_TAGS = (
        all => [qw( NETWORK_EMPTY NETWORK_IDLE NETWORK_LOADING NETWORK_NO_SOURCE )],
    );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{ended}  = 0;
    $self->{paused} = 1;
    $self->{sinkid} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_callback_off} = 0;
    $self->{_exception_class} = 'HTML::Object::MediaError';
    $self->{tag} = 'media' if( !CORE::length( "$self->{tag}" ) );
    $self->_set_get_internal_attribute_callback( controlslist => sub
    {
        my( $this, $val ) = @_;
        my $list;
        return if( !( $list = $this->{_controlslist_list} ) );
        # $list->debug( $self->debug );
        $list->update( $val );
    });
    return( $self );
}

sub addTextTrack
{
    my $self = shift( @_ );
    my $list = $self->textTracks;
    $self->_load_class( 'HTML::Object::DOM::TextTrack' ) || return( $self->pass_error );
    my $new  = HTML::Object::DOM::TextTrack->new( @_ ) || 
        return( $self->pass_error( HTML::Object::DOM::TextTrack->error ) );
    $list->push( $new );
    # There is no parent, because a TextTrack parent is actually a HTML::Object::DOM::Element::Track object
    # and here we only add a TextTrack object directly.
    # $new->parent( $self );
    return( $self );
}

# Note: property
sub audioTracks : lvalue { return( shift->_set_get_property( 'audiotracks', @_ ) ); }

# Note: property
sub autoplay : lvalue { return( shift->_set_get_property( { attribute => 'autoplay', is_boolean => 1 }, @_ ) ); }

# Note: property read-only
sub buffered { return; }

sub canPlayType { return; }

sub captureStream { return; }

# Note: property
sub controller { return; }

# Note: property
sub controls : lvalue { return( shift->_set_get_property( { attribute => 'controls', is_boolean => 1 }, @_ ) ); }

# Note: property read-only
sub controlsList
{
    my $self = shift( @_ );
    unless( $self->{_controlslist_list} )
    {
        my $controls  = $self->attr( 'controlslist' );
        require HTML::Object::TokenList;
        $self->{_controlslist_list} = HTML::Object::TokenList->new( $controls, element => $self, attribute => 'controlslist', debug => $self->debug ) ||
            return( $self->pass_error( HTML::Object::TokenList->error ) );
    }
    return( $self->{_controlslist_list} );
}

# Note: property crossOrigin inherited

# Note: property read-only currentSrc inherited

# Note: property
sub currentTime : lvalue { return( shift->_set_get_number({
    field => 'currentTime',
    callbacks =>
    {
        add => sub{ shift->_trigger_event_for( timeupdate => 'HTML::Object::Event', bubbles => 0, cancellable => 0 ) },
    }
}, @_ ) ); }

# Note: property
sub defaultMuted : lvalue { return( shift->_set_get_property( { attribute => 'muted', is_boolean => 1 }, @_ ) ); }

# Note: property
sub defaultPlaybackRate : lvalue { return( shift->_set_get_number( 'defaultplaybackrate', @_ ) ); }

# Note: property
sub disableRemotePlayback : lvalue { return( shift->_set_get_property( { attribute => 'disableremoteplayback', is_boolean => 1 }, @_ ) ); }

# Note: property
sub duration : lvalue { return( shift->_set_get_number({
    field => 'duration',
    callbacks => {
        add => sub{ shift->_trigger_event_for( durationchange => 'HTML::Object::Event', bubbles => 0, cancellable => 0 ) },
    }
}, @_ ) ); }

# Note: property read-only
sub ended : lvalue { return( shift->_set_get_boolean( 'ended', @_ ) ); }

# Note: property read-only error is inherited from Module::Generic

sub fastSeek { return; }

# TODO: Maybe do some interesting stuff loading a new file? However, since we cannot do much with audio or video under perl, there is not uch prospect as far as I can tell.
sub load { return; }

# Note: property
sub loop : lvalue { return( shift->_set_get_property( { attribute => 'loop', is_boolean => 1 }, @_ ) ); }

# Note: property read-only
sub mediaKeys { return; }

# Note: property
sub muted : lvalue { return( shift->_set_get_boolean( 'muted', @_ ) ); }

# Note: property read-only
sub networkState : lvalue { return( shift->_set_get_number( 'networkstate', @_ ) ); }

sub onabort : lvalue { return( shift->on( 'abort', @_ ) ); }

sub oncanplay : lvalue { return( shift->on( 'canplay', @_ ) ); }

sub oncanplaythrough : lvalue { return( shift->on( 'canplaythrough', @_ ) ); }

sub ondurationchange : lvalue { return( shift->on( 'durationchange', @_ ) ); }

sub onemptied : lvalue { return( shift->on( 'emptied', @_ ) ); }

sub onencrypted : lvalue { return( shift->on( 'encrypted', @_ ) ); }

sub onended : lvalue { return( shift->on( 'ended', @_ ) ); }

sub onerror : lvalue { return( shift->on( 'error', @_ ) ); }

sub onloadeddata : lvalue { return( shift->on( 'loadeddata', @_ ) ); }

sub onloadedmetadata : lvalue { return( shift->on( 'loadedmetadata', @_ ) ); }

sub onloadstart : lvalue { return( shift->on( 'loadstart', @_ ) ); }

sub onpause : lvalue { return( shift->on( 'pause', @_ ) ); }

sub onplay : lvalue { return( shift->on( 'play', @_ ) ); }

sub onplaying : lvalue { return( shift->on( 'playing', @_ ) ); }

sub onprogress : lvalue { return( shift->on( 'progress', @_ ) ); }

sub onratechange : lvalue { return( shift->on( 'ratechange', @_ ) ); }

sub onseeked : lvalue { return( shift->on( 'seeked', @_ ) ); }

sub onseeking : lvalue { return( shift->on( 'seeking', @_ ) ); }

sub onstalled : lvalue { return( shift->on( 'stalled', @_ ) ); }

sub onsuspend : lvalue { return( shift->on( 'suspend', @_ ) ); }

sub ontimeupdate : lvalue { return( shift->on( 'timeupdate', @_ ) ); }

sub onvolumechange : lvalue { return( shift->on( 'volumechange', @_ ) ); }

sub onwaiting : lvalue { return( shift->on( 'waiting', @_ ) ); }

sub onwaitingforkey : lvalue { return( shift->on( 'waitingforkey', @_ ) ); }

sub pause
{
    my $self = shift( @_ );
    $self->{_callback_off} = 1;
    $self->paused(1);
    $self->{_callback_off} = 0;
    $self->_trigger_event_for( pause => 'HTML::Object::Event', bubbles => 0, cancellable => 0 );
    return( $self )
}

# Note: property read-only
sub paused : lvalue { return( shift->_set_get_boolean({
    field => 'paused',
    callbacks => {
        add => sub
        {
            my $self = shift( @_ );
            return if( $self->{_callback_off} );
            $self->_trigger_event_for( paused => 'HTML::Object::Event', bubbles => 0, cancellable => 0 );
        }
    }
}, @_ ) ); }

sub play
{
    my $self = shift( @_ );
    $self->{_callback_off} = 1;
    $self->paused(0);
    $self->{_callback_off} = 0;
    $self->_trigger_event_for( play => 'HTML::Object::Event', bubbles => 0, cancellable => 0 );
    return( $self );
}

# Note: property
sub playbackRate : lvalue { return( shift->_set_get_number({
    field => 'playbackrate',
    callbacks =>
    {
        add => sub{ return( shift->_trigger_event_for( ratechange => 'HTML::Object::Event', bubbles => 0, cancellable => 0 ) ); },
    }
}, @_ ) ); }

# Note: property read-only
sub played { return; }

# Note: property
sub preload : lvalue { return( shift->_set_get_property( 'preload', @_ ) ); }

# Note: property
sub preservesPitch : lvalue { return( shift->_set_get_boolean( 'preservespitch', @_ ) ); }

# Note: property read-only
sub readyState : lvalue { return( shift->_set_get_number( 'readystate', @_ ) ); }

# TODO: removeTextTrack
sub removeTextTrack
{
    my $self = shift( @_ );
    my $obj  = shift( @_ );
    return( $self->error({
        message => "Value provided is not a HTML::Object::DOM::TextTrack object.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $obj => 'HTML::Object::DOM::TextTrack' ) );
    my $list = $self->textTracks;
    my $pos = $list->pos( $obj );
    return if( !defined( $pos ) );
    $list->splice( $pos, 1 );
    # There is no parent, because a TextTrack parent is actually a HTML::Object::DOM::Element::Track object
    # and here we only add or remove a TextTrack object directly.
    #  $obj->parent( undef );
    return( $obj );
}

# Note: property read-only
sub seekable { return; }

# Note: property read-only
sub seeking : lvalue { return( shift->_set_get_boolean( 'seeking', @_ ) ); }

sub seekToNextFrame { return; }

sub setMediaKeys { return; }

sub setSinkId { return( shift->_set_get_scalar_as_object( 'sinkid', @_ ) ); }

# Note: property read-only
sub sinkId : lvalue { return( shift->_set_get_scalar_as_object( 'sinkid', @_ ) ); }

# Note: property src inherited

# Note: property
sub srcObject { return; }

# Note: property read-only
sub textTracks { return( shift->_set_get_object( 'textTracks', 'HTML::Object::DOM::TextTrackList', @_ ) ); }

# Note: property read-only
sub videoTracks { return( shift->_set_get_object( 'textTracks', 'HTML::Object::DOM::VideoTrackList', @_ ) ); }

# Note: property
sub volume : lvalue { return( shift->_set_get_number({
    field => 'volume',
    callbacks =>
    {
        add => sub{ shift->_trigger_event_for( volumechange => 'HTML::Object::Event', bubbles => 0, cancellable => 0 ) },
    }
}, @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Media - HTML Object DOM Media Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Media;
    my $media = HTML::Object::DOM::Element::Media->new || 
        die( HTML::Object::DOM::Element::Media->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface adds to L<HTML::Object::DOM::Element> the properties and methods needed to support basic media-related capabilities that are common to L<audio|HTML::Object::DOM::Element::Audio> and L<video|HTML::Object::DOM::Element::Video>.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Media |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 audioTracks

A AudioTrackList that lists the AudioTrack objects contained in the element.

Example:

    my $video = $doc->getElementById("video");

    for( my $i = 0; $i < $video->audioTracks->length; $i += 1 )
    {
        $video->audioTracks->[$i]->enabled = 0; # false
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/audioTracks>

=head2 autoplay

A boolean value that reflects the C<autoplay> HTML attribute, indicating whether playback should automatically begin as soon as enough media is available to do so without interruption.

Note: Automatically playing audio when the user does not expect or desire it is a poor user experience and should be avoided in most cases, though there are exceptions. See the L<Mozilla Autoplay guide for media and Web Audio APIs|https://developer.mozilla.org/en-US/docs/Web/Media/Autoplay_guide> for more information. Keep in mind that browsers may ignore autoplay requests, so you should ensure that your code is not dependent on C<autoplay> working.

Example:

    <video id="video" autoplay="" controls>
        <source src="https://player.vimeo.com/external/250688977.sd.mp4?s=d14b1f1a971dde13c79d6e436b88a6a928dfe26b&profile_id=165">
    </video>

    # *** Disable autoplay (recommended) ***
    # false is the default value
    $doc->querySelector('#video')->autoplay = 0; # false
    # <video id="video" controls>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/autoplay>

=head2 buffered

This returns C<undef> under perl.

Normally, under JavaScript, this returns a C<TimeRanges> object that indicates the ranges of the media source that the browser has buffered (if any) at the moment the buffered property is accessed.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/buffered>

=head2 controller

This returns C<undef> under perl.

Normally, under JavaScript, this returns a C<MediaController> object that represents the media controller assigned to the element, or C<undef> if none is assigned.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/controller>

=head2 controls

Is a boolean that reflects the controls HTML attribute, indicating whether user interface items for controlling the resource should be displayed.

Example:

    my $obj = $doc->createElement('video');
    $obj->controls = 1; # true

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/controls>

=head2 controlsList

Returns a L<HTML::Object::TokenList> that helps the user agent select what controls to show on the media element whenever the user agent shows its own set of controls. The L<HTML::Object::TokenList> takes one or more of three possible values: C<nodownload>, C<nofullscreen>, and C<noremoteplayback>.

Example:

To disable the dowload button for HTML5 audio and video player:

    <audio controls controlsList="nodownload"><source src="song.mp3" type="audio/mpeg"></audio>

    <video controls controlsList="nodownload"><source src="video.mp4" type="video/mp4"></video>

Another example:

    <video controls controlsList="nofullscreen nodownload noremoteplayback"></video>

Using code:

    my $video = $doc->querySelector('video');
    $video->controls; # true
    $video->controlsList; # ["nofullscreen", "nodownload", "noremoteplayback"]
    $video->controlsList->remove('noremoteplayback');
    $video->controlsList; # ["nofullscreen", "nodownload"]
    $video->getAttribute('controlsList'); # "nofullscreen nodownload"

    # Actually, under perl, 'supports' always returns true
    $video->controlsList->supports('foo'); # false
    $video->controlsList->supports('noremoteplayback'); # true

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/controlsList>, L<Chromium documentation|https://developers.google.com/web/updates/2017/03/chrome-58-media-updates>

=head2 crossOrigin

A string indicating the CORS setting for this media element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/crossOrigin>

=head2 currentSrc

Returns a string with the absolute URL of the chosen media resource.

Example:

    my $obj = $doc->createElement('video');
    say($obj->currentSrc); # ""

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/currentSrc>

=head2 currentTime

This returns whatever number you set it to under perl, as a L<Module::Generic::Number> object.

Normally, under JavaScript, this returns a double-precision floating-point value indicating the current playback time in seconds; if the media has not started to play and has not been seeked, this value is the media's initial playback time. Setting this value seeks the media to the new time. The time is specified relative to the media's timeline.

Example:

    my $video = $doc->createElement('$video');
    say( $video->currentTime );
    $vide->currentTime = 35;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/currentTime>

=head2 defaultMuted

A Boolean that reflects the C<muted> HTML attribute, which indicates whether the media element's audio output should be muted by default.

Example:

    my $video = $doc->createElement('video');
    $video->defaultMuted = 1; # true
    say( $video->outerHTML ); # <video muted=""></video>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/defaultMuted>

=head2 defaultPlaybackRate

This returns whatever number you set it to under perl, as a L<Module::Generic::Number> object.

Normally, under JavaScript, this returns a double indicating the default playback rate for the media.

Example:

    my $obj = $doc->createElement('video');
    say($obj->defaultPlaybackRate); # 1

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/defaultPlaybackRate>

=head2 disableRemotePlayback

A boolean that sets or returns the remote playback state of the HTML attribute, indicating whether the media element is allowed to have a remote playback UI.

Example:

    my $obj = $doc->createElement('audio');
    # <audio></audio>
    $obj->disableRemotePlayback = 1; # true
    # <audio disableremoteplayback=""></audio>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/disableRemotePlayback>

=head2 duration

This returns whatever number you set it to under perl, as a L<Module::Generic::Number> object.

Normally, under JavaScript, this returns a read-only double-precision floating-point value indicating the total duration of the media in seconds. If no media data is available, the returned value is C<NaN>. If the media is of indefinite length (such as streamed live media, a WebRTC call's media, or similar), the value is C<+Infinity>.

Example:

    my $obj = $doc->createElement('video');
    say( $obj->duration ); # NaN

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/duration>

=head2 ended

Returns a Boolean that indicates whether the media element has finished playing.

Example:

    my $obj = $doc->createElement('video');
    say($obj->ended); # false

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/ended>

=head2 error

Read-only.

This returns a L<HTML::Object::MediaError> object for the most recent error, or C<undef> if there has not been an error.

Example:

    my $video = $doc->createElement('video');
    $video->onerror = sub
    {
        say( "Error " . $video->error->code . "; details: " . $video->error->message );
    }
    $video->src = 'https://example.org/badvideo.mp4';

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/error>

=head2 loop

A Boolean that reflects the C<loop> HTML attribute, which indicates whether the media element should start over when it reaches the end.

Example:

    my $obj = $doc->createElement('video');
    $obj->loop = 1; # true

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loop>

=head2 mediaKeys

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a L<MediaKeys object|https://developer.mozilla.org/en-US/docs/Web/API/MediaKeys> or C<undef>. L<MediaKeys|https://developer.mozilla.org/en-US/docs/Web/API/MediaKeys> is a set of keys that an associated L<HTML::Object::DOM::Element::Media> can use for decryption of media data during playback.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/mediaKeys>

=head2 muted

Is a boolean that determines whether audio is muted. true if the audio is muted and false otherwise. This does not affect the DOM.

Example:

    my $obj = $doc->createElement('video');
    say( $obj->muted ); # false

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/muted>

=head2 networkState

Set or get an integer (enumeration) indicating the current state of fetching the media over the network.

Example:

    <audio id="example" preload="auto">
        <source src="sound.ogg" type="audio/ogg" />
    </audio>

    # Export constants
    use HTML::Object::DOM::Element::Media qw( :all );
    my $obj = $doc->getElementById('example');
    $obj->addEventListener( playing => sub
    {
        if( $obj->networkState == NETWORK_LOADING )
        {
            # Still loading...
        }
    });

See L</CONSTANTS> below for the constants that can be exported and used.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/networkState>

=head2 paused

Returns a boolean that indicates whether the media element is paused. This is set to true if you use the L</pause> method and set to false when you use the L</play> method.

Example:

    my $obj = $doc->createElement('video');
    say( $obj->paused ); # true

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/paused>

=head2 playbackRate

This only sets or gets a number under perl environment.

Normally, under JavaScript, this is a double that indicates the rate at which the media is being played back.

Example:

    my $obj = $doc->createElement('video');
    say( $obj->playbackRate ); # Expected Output: 1

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/playbackRate>

=head2 played

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a L<TimeRanges object|https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges> that contains the ranges of the media source that the browser has played, if any.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/played>

=head2 preload

Is a string that reflects the C<preload> HTML attribute, indicating what data should be preloaded, if any. Possible values are: C<none>, C<metadata>, C<auto>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/preload>

=head2 preservesPitch

Under perl environment, this is just a boolean value you can set or get.

Under JavaScript environment, this is a boolean that determines if the pitch of the sound will be preserved. If set to false, the pitch will adjust to the speed of the audio. This is implemented with prefixes in Firefox (C<mozPreservesPitch>) and WebKit (C<webkitPreservesPitch>).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/preservesPitch>

=head2 readyState

Set or get an integer (enumeration) indicating the readiness state of the media.

Example:

    <audio id="example" preload="auto">
        <source src="sound.ogg" type="audio/ogg" />
    </audio>

    use HTML::Object::DOM::Element::Media qw( :all );
    my $obj = $doc->getElementById('example');
    $obj->addEventListener( loadeddata => sub
    {
        if( $obj->readyState >= NETWORK_LOADING )
        {
            $obj->play();
        }
    });

See L</CONSTANTS> for the constants that can be exported and used.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState>

=head2 seekable

This always returns C<undef> under perl.

Normally, under JavaScript, this returns a L<TimeRanges object|https://developer.mozilla.org/en-US/docs/Web/API/TimeRanges> that contains the time ranges that the user is able to seek to, if any.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seekable>

=head2 seeking

Under perl environment, this is just a boolean value you can set or get.

Under JavaScript environment, this is a boolean that indicates whether the media is in the process of seeking to a new position.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seeking>

=head2 sinkId

This returns C<undef> by default under perl. You can set a value using L</setSinkId>.

Normally, under JavaScript, this returns a string that is the unique ID of the audio device delivering output, or an empty string if it is using the user agent default. This ID should be one of the C<MediaDeviceInfo.deviceid> values returned from C<MediaDevices.enumerateDevices()>, id-multimedia, or id-communications.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/sinkId>

=head2 src

Is a string that reflects the C<src> HTML attribute, which contains the URL of a media resource to use.

Example:

    my $obj = $doc->createElement('video');
    say( $obj->src ); # ""

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/src>

=head2 srcObject

This always returns C<undef> under perl.

Normally, under JavaScript, this is a L<MediaStream|https://developer.mozilla.org/en-US/docs/Web/API/MediaStream> representing the media to play or that has played in the current L<HTML::Object::DOM::Element::Media>, or C<undef> if not assigned.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/srcObject>

=head2 textTracks

Read-only.

Returns the list of L<TextTrack|HTML::Object::DOM::TextTrack> objects contained in the element.

Example:

    <video controls poster="/images/sample.gif">
        <source src="sample.mp4" type="video/mp4">
        <source src="sample.ogv" type="video/ogv">
        <track kind="captions" src="sampleCaptions.vtt" srclang="en">
        <track kind="descriptions" src="sampleDescriptions.vtt" srclang="en">
        <track kind="chapters" src="sampleChapters.vtt" srclang="en">
        <track kind="subtitles" src="sampleSubtitles_de.vtt" srclang="de">
        <track kind="subtitles" src="sampleSubtitles_en.vtt" srclang="en">
        <track kind="subtitles" src="sampleSubtitles_ja.vtt" srclang="ja">
        <track kind="subtitles" src="sampleSubtitles_oz.vtt" srclang="oz">
        <track kind="metadata" src="keyStage1.vtt" srclang="en" label="Key Stage 1">
        <track kind="metadata" src="keyStage2.vtt" srclang="en" label="Key Stage 2">
        <track kind="metadata" src="keyStage3.vtt" srclang="en" label="Key Stage 3">
    </video>

    my $tracks = $doc->querySelector('video')->textTracks;

    # $tracks->length == 10
    for( my $i = 0, $L = $tracks->length; $i < $L; $i++ )
    {
        if( $tracks->[$i]->language eq 'en' )
        {
            say( $tracks->[$i] );
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/textTracks>

=head2 videoTracks

Read-only.

Returns the list of L<VideoTrack|HTML::Object::DOM::VideoTrack> objects contained in the element.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/videoTracks>

=head2 volume

Is a double indicating the audio volume, from 0.0 (silent) to 1.0 (loudest).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/volume>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 addTextTrack

Adds a L<text track|HTML::Object::DOM::TextTrack> (such as a track for subtitles) to a media element.

This takes a track C<kind>, C<label> and C<language> and returns a new L<HTML::Object::DOM::TextTrack> object.

Possible values for C<kind> are:

=over 4

=item caption

=item chapters

=item descriptions

=item metadata

=item subtitles

=back

C<label> is a string specifying the label for the text track. Is used to identify the text track for the users.

C<language> in iso 639 format (e.g. C<en-US> or C<ja-JP>).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/addTextTrack>

=head2 canPlayType

This always returns C<undef> under perl.

Normally, under JavaScript, given a string specifying a MIME media type (potentially with the codecs parameter included), C<canPlayType>() returns the string probably if the media should be playable, maybe if there's not enough information to determine whether the media will play or not, or an empty string if the media cannot be played.

Example:

    my $obj = $doc->createElement('video');
    say( $obj->canPlayType('video/mp4') ); # "maybe"

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canPlayType>

=head2 captureStream

This always returns C<undef> under perl.

Normally, under JavaScript, this returns C<MediaStream>, captures a stream of the media content.

Example:

    $doc->querySelector('.playAndRecord')->addEventListener( click => sub
    {
        my $playbackElement = $doc->getElementById("playback");
        my $captureStream = $playbackElement->captureStream();
        $playbackElement->play();
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/captureStream>

=head2 fastSeek

This always returns C<undef> under perl.

Normally, under JavaScript, this quickly seeks to the given time with low precision.

Example:

    my $myVideo = $doc->getElementById("myVideoElement");

    $myVideo->fastSeek(20);

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/fastSeek>

=head2 load

This always returns C<undef> under perl.

Normally, under JavaScript, this resets the media to the beginning and selects the best available source from the sources provided using the src attribute or the <source> element.

Example:

    my $mediaElem = $doc->querySelector("video");
    $mediaElem->load();

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/load>

=head2 pause

Under perl, this does not do anything particular except setting the L</paused> boolean value to true.

Pauses the media playback.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/pause>

=head2 play

This does not do anything in particular under perl, except setting the C<paused> boolean value to false.

Normally, under JavaScript, this begins playback of the media.

Example:

    use Nice::Try;
    my $videoElem = $doc->getElementById( 'video' );
    my $playButton = $doc->getElementById( 'playbutton' );

    $playButton->addEventListener( 'click', \&handlePlayButton, { capture => 0 });
    playVideo();

    sub playVideo
    {
        try
        {
            $videoElem->play();
            $playButton->classList->add( 'playing' );
        }
        catch($err)
        {
            $playButton->classList->remove( 'playing' );
        }
    }

    sub handlePlayButton
    {
        if( $videoElem->paused )
        {
            playVideo();
        }
        else
        {
            $videoElem->pause();
            $playButton->classList->remove( 'playing' );
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/play>

=head2 removeTextTrack

Provided with a L<HTML::Object::DOM::TextTrack> object and this will remove it.

It returns the L<HTML::Object::DOM::TextTrack> object upon success, or if it cannot be found, it returns C<undef>

=head2 seekToNextFrame

This always returns C<undef> under perl.

Normally, under JavaScript, this seeks to the next frame in the media. This non-standard, experimental method makes it possible to manually drive reading and rendering of media at a custom speed, or to move through the media frame-by-frame to perform filtering or other operations.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seekToNextFrame>

=head2 setMediaKeys

This always returns C<undef> under perl.

Normally, under JavaScript, this returns Promise. Sets the MediaKeys keys to use when decrypting media during playback.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/setMediaKeys>

=head2 setSinkId

This does not do anything particular under perl, except setting the value of L</sinkid>.

Normally, under JavaScript, this sets the ID of the audio device to use for output and returns a Promise. This only works when the application is authorized to use the specified device.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/setSinkId>

=head1 EVENTS

=head2 abort

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the resource was not fully loaded, but not as the result of an error.

Example:

    my $video = $doc->querySelector('video');
    my $videoSrc = 'https://example.org/path/to/video.webm';

    $video->addEventListener( abort => sub
    {
        say( "Abort loading: ", $videoSrc );
    });

    my $source = $doc->createElement('source');
    $source->setAttribute( src => $videoSrc );
    $source->setAttribute( type => 'video/webm' );

    $video->appendChild( $source );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/abort_event>

=head2 canplay

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the user agent can play the media, but estimates that not enough data has been loaded to play the media up to its end without having to stop for further buffering of content

Example:

    my $video = $doc->querySelector( 'video' );

    $video->addEventListener( canplay => sub
    {
        my $event = shift( @_ );
        say( 'Video can start, but not sure it will play through.' );
    });

    my $video = $doc->querySelector( 'video' );
    $video->oncanplay = sub
    {
        my $event = shift( @_ );
        say( 'Video can start, but not sure it will play through.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canplay_event>

=head2 canplaythrough

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the user agent can play the media, and estimates that enough data has been loaded to play the media up to its end without having to stop for further buffering of content.

Example:

    my $video = $doc->querySelector( 'video' );

    $video->addEventListener( canplaythrough => sub
    {
        my $event = shift( @_ );
        say( "I think I can play through the entire video without ever having to stop to buffer." );
    });

    my $video = $doc->querySelector( 'video' );

    $video->oncanplaythrough = sub
    {
        my $event = shift( @_ );
        say( "I think I can play through the entire video without ever having to stop to buffer." );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/canplaythrough_event>

=head2 durationchange

This is fired when the duration property has been updated.

Example:

    my $video = $doc->querySelector('video');
    $video->addEventListener( durationchange => sub
    {
        say( 'Not sure why, but the duration of the $video has changed.' );
    });

    my $video = $doc->querySelector('video');

    $video->ondurationchange = sub
    {
        say( 'Not sure why, but the duration of the video has changed.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/durationchange_event>

=head2 emptied

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the media has become empty; for example, when the media has already been loaded (or partially loaded), and the L<HTML::Object::DOM::Element::Media/load> method is called to reload it.

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( emptied => sub
    {
        say( 'Uh oh. The media is empty. Did you call load()?' );
    });

    my $video = $doc->querySelector('video');

    $video->onemptied = sub
    {
        say( 'Uh oh. The media is empty. Did you call load()?' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/emptied_event>

=head2 ended

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when playback stops when end of the media (<audio> or <video>) is reached or because no further data is available.

Example:

    my $obj = $doc->createElement('video');
    say( $obj->ended ); # false

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/ended_event>

=head2 error

Fired when the resource could not be loaded due to an error.

Example:

    my $videoElement = $doc->createElement( 'video' );
    $videoElement->onerror = sub
    {
        say( "Error " . $videoElement->error->code . "; details: " . $videoElement->error->message );
    }
    $videoElement->src = "https://example.org/bogusvideo.mp4";

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/error_event>

=head2 loadeddata

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the first frame of the media has finished loading.

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( loadeddata => sub
    {
        say( 'Yay! The readyState just increased to HAVE_CURRENT_DATA or greater for the first time.' );
    });

    my $video = $doc->querySelector('video');

    $video->onloadeddata = sub
    {
        say( 'Yay! The readyState just increased to HAVE_CURRENT_DATA or greater for the first time.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loadeddata_event>

=head2 loadedmetadata

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the metadata has been loaded

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( loadedmetadata => sub
    {
        say( 'The duration and dimensions of the media and tracks are now known.' );
    });

    my $video = $doc->querySelector('video');

    $video->onloadedmetadata = sub
    {
        say( 'The duration and dimensions of the media and tracks are now known.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loadedmetadata_event>

=head2 loadstart

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the browser has started to load a resource.

Example:

    <div class="example">
        <button type="button">Load video</button>
        <video controls width="250"></video>

        <div class="event-log">
            <label>Event log:</label>
            <textarea readonly class="event-log-contents"></textarea>
        </div>
    </div>

    use feature 'signatures';
    my $loadVideo = $doc->querySelector('button');
    my $video = $doc->querySelector('video');
    my $eventLog = $doc->querySelector('.event-log-contents');
    my $source;

    sub handleEvent( $event )
    {
        $eventLog->textContent = $eventLog->textContent . $event->type . "\n";
    }

    $video->addEventListener( 'loadstart', \&handleEvent);
    $video->addEventListener( 'progress', \&handleEvent);
    $video->addEventListener( 'canplay', \&handleEvent);
    $video->addEventListener( 'canplaythrough', \&handleEvent);

    $loadVideo->addEventListener( click => sub
    {
        if( $source )
        {
            $doc->location->reload();
        }
        else
        {
            $loadVideo->textContent = "Reset example";
            $source = $doc->createElement( 'source' );
            $source->setAttribute( 'src', 'https://example.org/some/where/media/examples/video.webm' );
            $source->setAttribute( 'type', 'video/webm' );
            $video->appendChild( $source );
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/loadstart_event>

=head2 pause

Fired when a request to pause play is handled and the activity has entered its paused state, most commonly occurring when the media's L<HTML::Object::DOM::Element::Media/pause> method is called.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/pause_event>

=head2 play

Fired when the paused property is changed from true to false, as a result of the L<HTML::Object::DOM::Element::Media/play> method, or the autoplay attribute

Example:

    use Nice::Try; # for the try{}catch block
    my $videoElem = $doc->getElementById( 'video' );
    my $playButton = $doc->getElementById( 'playbutton' );

    $playButton->addEventListener( click => \&handlePlayButton, { capture => 0 });
    playVideo();

    sub playVideo
    {
        try {
            $videoElem->play();
            $playButton->classList->add( 'playing' );
        } catch( $err ) {
            $playButton->classList->remove( 'playing' );
        }
    }

    sub handlePlayButton
    {
        if( $videoElem->paused )
        {
            playVideo();
        }
        else
        {
            $videoElem->pause();
            $playButton->classList->remove( 'playing' );
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/play_event>

=head2 playing

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when playback is ready to start after having been paused or delayed due to lack of data

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( playing =>sub
    {
        say( 'Video is no longer paused' );
    });

    my $video = $doc->querySelector('video');

    $video->onplaying = sub
    {
        say( 'Video is no longer paused.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/playing_event>

=head2 progress

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired periodically as the browser loads a resource.

Example:

    <div class="example">
        <button type="button">Load video</button>
        <video controls width="250"></video>

        <div class="event-log">
            <label>Event log:</label>
            <textarea readonly class="event-log-contents"></textarea>
        </div>
    </div>

    use feature 'signatures';
    my $loadVideo = $doc->querySelector('button');
    my $video = $doc->querySelector('video');
    my $eventLog = $doc->querySelector('.event-log-contents');
    my $source;

    sub handleEvent( $event )
    {
        $eventLog->textContent = $eventLog->textContent . $event->type . "\n";
    }

    $video->addEventListener( 'loadstart', \&handleEvent );
    $video->addEventListener( 'progress', \&handleEvent );
    $video->addEventListener( 'canplay', \&handleEvent );
    $video->addEventListener( 'canplaythrough', \&handleEvent );

    $loadVideo->addEventListener( click => sub
    {
        if( $source )
        {
            $doc->location->reload();
        }
        else
        {
            $loadVideo->textContent = "Reset example";
            $source = $doc->createElement('source');
            $source->setAttribute( 'src', 'https://example.org/some/where/video.mp4' );
            $source->setAttribute( 'type', 'video/mp4' );
            $video->appendChild( $source );
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/progress_event>

=head2 ratechange

This is fired when the playback rate has changed, i.e. when the property L</playbackRate> is changed.

Example:

    my $video = $doc->querySelector( 'video' );

    $video->addEventListener( 'ratechange' => sub
    {
        say( 'The playback rate changed.' );
    });

    my $video = $doc->querySelector('video');

    $video->onratechange = sub
    {
        say( 'The playback rate changed.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/ratechange_event>

=head2 seeked

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when a seek operation completes

Example:

    my $video = $doc->querySelector('video');
    $video->addEventListener( seeked => sub
    {
        say( 'Video found the playback position it was looking for.' );
    });
    my $video = $doc->querySelector( 'video' );
    $video->onseeked = sub
    {
        say( 'Video found the playback position it was looking for.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seeked_event>

=head2 seeking

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when a seek operation begins

Example:

    my $video = $doc->querySelector( 'video' );
    $video->addEventListener( seeking => sub
    {
        say( 'Video is seeking a new position.' );
    });
    my $video = $doc->querySelector( 'video' );
    $video->onseeking = sub
    {
        say( 'Video is seeking a new position.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/seeking_event>

=head2 stalled

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the user agent is trying to fetch media data, but data is unexpectedly not forthcoming.

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( stalled => sub
    {
        say( 'Failed to fetch data, but trying.' );
    });

    my $video = $doc->querySelector('video');

    $video->onstalled = sub
    {
        say( 'Failed to fetch data, but trying.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/stalled_event>

=head2 suspend

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when the media data loading has been suspended.

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( suspend => sub
    {
        say( 'Data loading has been suspended.' );
    });

    my $video = $doc->querySelector( 'video' );

    $video->onsuspend = sub
    {
        say( 'Data loading has been suspended.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/suspend_event>

=head2 timeupdate

Fired when the time indicated by the L</currentTime> property has been updated.

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( timeupdate => sub
    {
        say( 'The currentTime attribute has been updated. Again.' );
    });

    my $video = $doc->querySelector('video');

    $video->ontimeupdate = sub
    {
        say( 'The currentTime attribute has been updated. Again.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/timeupdate_event>

=head2 volumechange

Fired when the volume has changed, i.e. when the value for the L</volume> property has changed.

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( volumechange => sub
    {
        say( 'The volume changed.' );
    });

    my $video = $doc->querySelector('video');
    $video->onvolumechange = sub
    {
        say( 'The volume changed.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/volumechange_event>

=head2 waiting

This is not used under perl, but you can trigger that event yourself.

Under JavaScript, this is fired when playback has stopped because of a temporary lack of data.

Example:

    my $video = $doc->querySelector('video');

    $video->addEventListener( waiting => sub
    {
        say( 'Video is waiting for more data.' );
    });

    my $video = $doc->querySelector('video');
    $video->onwaiting = sub
    {
        say( 'Video is waiting for more data.' );
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/waiting_event>

=head1 EVENT HANDLERS

=head2 onencrypted

Sets the event handler called when the media is encrypted.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/onencrypted>

=head2 onwaitingforkey

Sets the event handler called when playback is blocked while waiting for an encryption key.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/onwaitingforkey>

=head1 CONSTANTS

The following constants can be exported and used, such as:

    use HTML::Object::DOM::Element::Media qw( :all );
    # or directly from HTML::Object::DOM
    use HTML::Object::DOM qw( :media );

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

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement>, L<Mozilla documentation on audio element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/audio>, L<Mozilla documentation on video element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video>, L<W3C specifications|https://html.spec.whatwg.org/multipage/media.html>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
