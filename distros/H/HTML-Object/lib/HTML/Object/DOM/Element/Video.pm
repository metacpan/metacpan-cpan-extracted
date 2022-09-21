##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Video.pm
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
package HTML::Object::DOM::Element::Video;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element::Media );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :video );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'video' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property autoPictureInPicture
sub autoPictureInPicture : lvalue { return( shift->_set_get_property({ attribute => 'autopictureinpicture', is_boolean => 1 }, @_ ) ); }

# Note: property disablePictureInPicture
sub disablePictureInPicture : lvalue { return( shift->_set_get_property({ attribute => 'disablepictureinpicture', is_boolean => 1 }, @_ ) ); }

sub getVideoPlaybackQuality { return; }

# Note: property height is inherited

sub onenterpictureinpicture : lvalue { return( shift->on( 'enterpictureinpicture', @_ ) ); }

sub onleavepictureinpicture : lvalue { return( shift->on( 'leavepictureinpicture', @_ ) ); }

# Note: property poster
sub poster : lvalue { return( shift->_set_get_property({ attribute => 'poster', is_uri => 1 }, @_ ) ); }

sub requestPictureInPicture { return; }

# Note: property videoHeight read-only
sub videoHeight : lvalue { return( shift->_set_get_number( 'videoheight', @_ ) ); }

# Note: property videoWidth read-only
sub videoWidth : lvalue { return( shift->_set_get_number( 'videowidth', @_ ) ); }

# Note: property width is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Video - HTML Object DOM Video Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Video;
    my $video = HTML::Object::DOM::Element::Video->new || 
        die( HTML::Object::DOM::Element::Video->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties and methods for manipulating video objects. It also inherits properties and methods of L<HTML::Object::DOM::Element::Media> and L<HTML::Object::DOM::Element>.

    <video controls width="250">
        <source src="/some/where/video.webm" type="video/webm">
        <source src="/some/where/video.mp4" type="video/mp4">
        Sorry, your browser does not support embedded videos.
    </video>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Media | --> | HTML::Object::DOM::Element::Video |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element::Media>

=head2 autoPictureInPicture

The autoPictureInPicture property reflects the HTML attribute indicating whether the video should enter or leave picture-in-picture mode automatically when the user switches tab and/or applications. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/autoPictureInPicture>

=head2 disablePictureInPicture

The C<disablePictureInPicture> property reflects the HTML attribute indicating whether the user agent should suggest the picture-in-picture feature to users, or request it automatically. 

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/disablePictureInPicture>

=head2 height

Is a string that reflects the height HTML attribute, which specifies the height of the display area, in CSS pixels.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/height>

=head2 poster

Is a string that reflects the poster HTML attribute, which an URL for an image to be shown while the video is downloading. If this attribute is not specified, nothing is displayed until the first frame is available, then the first frame is shown as the poster frame.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/poster>

=head2 videoHeight

Under perl, this returns C<undef> by default, but you can set whatever number value you want.

Under JavaScript, this is read-only and returns an unsigned integer value indicating the intrinsic height of the resource in CSS pixels, or 0 if no media is available yet.

Example:

    my $v = $doc->getElementById("myVideo");

    $v->addEventListener( resize => sub
    {
        my $w = $v->videoWidth;
        my $h = $v->videoHeight;

        if( $w && $h )
        {
            $v->style->width = $w;
            $v->style->height = $h;
        }
    }, { capture => 0 });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/videoHeight>

=head2 videoWidth

Under perl, this is read-only and returns C<undef> by default, but you can set whatever number value you want.

Under JavaScript, this returns an unsigned integer value indicating the intrinsic width of the resource in CSS pixels, or 0 if no media is available yet.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/videoWidth>

=head2 width

Is a string that reflects the width HTML attribute, which specifies the width of the display area, in CSS pixels.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element::Media>

=head2 getVideoPlaybackQuality

Under perl, this always returns C<undef>.

Under JavaScript, this returns a C<VideoPlaybackQuality> object that contains the current playback metrics. This information includes things like the number of dropped or corrupted frames, as well as the total number of frames.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/getVideoPlaybackQuality>

=head2 requestPictureInPicture

Under perl, this always returns C<undef> obviously.

Under JavaScript, this requests that the user agent make video enters picture-in-picture mode

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/requestPictureInPicture>

=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

For example, C<enterpictureinpicture> event listeners can be set also with C<onenterpictureinpicture> method:

    $e->onenterpictureinpicture(sub{ # do something });
    # or as an lvalue method
    $e->onenterpictureinpicture = sub{ # do something };

=head2 enterpictureinpicture

Sent to a L<HTML::Object::DOM::Element::Video> when it enters Picture-in-Picture mode. The associated event handler is L<HTML::Object::DOM::Element::Video>.onenterpictureinpicture

Example:

    my $video = $doc->querySelector('#$video');
    my $button = $doc->querySelector('#$button');

    sub onEnterPip
    {
        say( "Picture-in-Picture mode activated!" );
    }

    $video->addEventListener( enterpictureinpicture => \&onEnterPip, { capture => 0 });

    $button->onclick = sub
    {
        $video->requestPictureInPicture();
    }

    my $video = $doc->querySelector('#$video');
    my $button = $doc->querySelector('#$button');

    sub onEnterPip
    {
        say( "Picture-in-Picture mode activated!" );
    }

    $video->onenterpictureinpicture = \&onEnterPip;

    $button->onclick = sub
    {
        $video->requestPictureInPicture();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/enterpictureinpicture_event>

=head2 leavepictureinpicture

Sent to a L<HTML::Object::DOM::Element::Video> when it leaves Picture-in-Picture mode. The associated event handler is L<HTML::Object::DOM::Element::Video>.onleavepictureinpicture

Example:

    my $video = $doc->querySelector('#$video');
    my $button = $doc->querySelector('#$button');

    sub onExitPip
    {
        say( "Picture-in-Picture mode deactivated!" );
    }

    $video->addEventListener( leavepictureinpicture => \&onExitPip, { capture => 0 });

    $button->onclick = sub
    {
        if( $doc->pictureInPictureElement )
        {
            $doc->exitPictureInPicture();
        }
    }

    my $video = $doc->querySelector('#$video');
    my $button = $doc->querySelector('#$button');

    sub onExitPip
    {
        say( "Picture-in-Picture mode deactivated!" );
    }

    $video->onleavepictureinpicture = \&onExitPip;

    $button->onclick = sub
    {
        if( $doc->pictureInPictureElement )
        {
            $doc->exitPictureInPicture();
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement/leavepictureinpicture_event>

=head1 EXAMPLE

    <h1>Ask a question at a given point in a video</h1>

    <p>The question is displayed after 10 seconds, if the answer given is correct, the video continues, if not it starts again from the beginning</p>

    <video id="myVideo" controls="">
        <source src="https://example.org/some/where/videos/video.mp4" />
        <source src="https://example.org/some/where/videos/video.webm" />
    </video>

    // This only works in a web browser, so this is intentionally in JavaScript
    // First identify the video in the DOM
    var myVideo = document.getElementById( 'myVideo' );
    myVideo.ontimeupdate = function()
    {
        // Remove the decimal numbers from the time
        var currentTime = Math.floor( myVideo.currentTime );
        if( currentTime == 10 )
        {
            myVideo.pause ();
            // Ask the question with a promt
            var r = prompt( "What is the video about?" );
            // check the answer
            if( r.toLowerCase() == "Example" )
            {
                myVideo.currentTime = 11; // Add a second otherwise the question will be displayed again;
                myVideo.play();
            }
            else
            {
                myVideo.currentTime = 0; // Put the video back to 0;
                myVideo.play();
            }
        }
    }

Example taken from L<EduTech Wiki|https://edutechwiki.unige.ch/en/HTML5_video_and_JavaScript>

Picture in Picture (a.k.a. PiP)

The W3C states that "the specification intends to provide APIs to allow websites to create a floating video window always on top of other windows so that users may continue consuming media while they interact with other content sites, or applications on their device."

    <video id="videoElement" controls="true" src="demo.mp4"></video>

    <!-- button will be used to toggle the PiP mode -->
    <button id="togglePipButton">Toggle Picture-in-Picture Mode!</button> 

Call L</requestPictureInPicture> on C<click> of C<togglePipButton> button element.

When the promise resolves, the browser will shrink the video into a mini window that the user can move around and position over other windows.

    let video = document.getElementById('videoElement');
    let togglePipButton = document.getElementById('togglePipButton');

    togglePipButton.addEventListener('click', async function (event) {
        togglePipButton.disabled = true; //disable toggle button while the event occurs
        try {
            // If there is no element in Picture-in-Picture yet, request for it
            if (video !== document.pictureInPictureElement) {
                await video.requestPictureInPicture();
            }
            // If Picture-in-Picture already exists, exit the mode
            else {
                await document.exitPictureInPicture();
            }

        } catch (error) {
            console.log(`Oh Horror! ${error}`);
        } finally {
            togglePipButton.disabled = false; //enable toggle button after the event
        }
    });

Check for Picture-in-Picture event changes 

    let video = document.getElementById('videoElement');
    video.addEventListener('enterpictureinpicture', function (event) {
        console.log('Entered PiP');
        pipWindow = event.pictureInPictureWindow;
        console.log(`Window size -  \n Width: ${pipWindow.width} \n Height: ${pipWindow.height}`); // get the width and height of PiP window
    });

    video.addEventListener('leavepictureinpicture', function (event) {
        console.log('Left PiP');
        togglePipButton.disabled = false;
    });

Example taken from L<https://dev.to/ananyaneogi/implement-picture-in-picture-on-the-web-17g8>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLVideoElement>, L<Mozilla documentation on video element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video>, L<W3C specifications for PiP|https://w3c.github.io/picture-in-picture/>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
