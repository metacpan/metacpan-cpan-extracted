##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/TextTrack.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/27
## Modified 2021/12/27
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::TextTrack;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::MediaTrack );
    use HTML::Object::Exception;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    return( $self->error({
        message => sprintf( "At least 1 argument required, but only %d passed", scalar( @_ ) ),
        class => 'HML::Object::TypeError',
    }) ) if( scalar( @_ ) < 3 );
    my $kind  = shift( @_ );
    my $label = shift( @_ );
    my $lang  = shift( @_ );
    return( $self->error({
        message => "kind argument provided is not a string",
        class => 'HML::Object::TypeError',
    }) ) if( $kind !~ /^\w+$/ );
    $self->{cues}   = [];
    # If set, this should be the same as the id in HTML::Object::DOM::Element::Track
    $self->{id}     = undef;
    $self->{kind}   = $kind;
    $self->{label}  = $label;
    $self->{language}   = $lang;
    $self->{mode}   = 'hidden';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property
sub activeCues { return( shift->_set_get_object( 'activecues', 'HTML::Object::DOM::TextTrackCueList', @_ ) ); }

sub addCue
{
    my $self = shift( @_ );
    my $cue  = shift( @_ ) || return( $self->error({
        message => "No cue object was provided.",
        class => 'HTML::Object::TypeError',
    }) );
    # HTML::Object::DOM::VTTCue inherits from HTML::Object::DOM::TextTrackCue
    return( $self->error({
        message => "Cue provided is not a HTML::Object::DOM::TextTrackCue object.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $cue => 'HTML::Object::DOM::TextTrackCue' ) );
    my $cues = $self->cues;
    my $pos = $cues->pos( $cue );
    if( !defined( $cue ) )
    {
        $cue->track( $self );
        $cues->push( $cue );
    }
    return( $self );
}

# Note: property
sub cues { return( shift->_set_get_object_array_object( 'cues', 'HTML::Object::DOM::TextTrackCueList', @_ ) ); }

# Note: property id inherited

# Note: property
sub inBandMetadataTrackDispatchType : lvalue { return( shift->_set_get_scalar_as_object( 'inbandmetadatatrackdispatchtype', @_ ) ); }

# Note: property kind inherited

# Note: property label inherited

# Note: property language inherited

# Note: property
sub mode : lvalue { return( shift->_set_get_scalar_as_object( 'mode', @_ ) ); }

# Note: method parent is used and inherited from HTML::Object::Element via HTML::Object::EventTarget

sub removeCue
{
    my $self = shift( @_ );
    my $cue  = shift( @_ ) || return( $self->error({
        message => "No cue object was provided.",
        class => 'HTML::Object::TypeError',
    }) );
    return( $self->error({
        message => "Cue provided is not a HTML::Object::DOM::TextTrackCue object.",
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $cue => 'HTML::Object::DOM::TextTrackCue' ) );
    my $cues = $self->cues;
    my $pos = $cues->pos( $cue );
    if( defined( $pos ) )
    {
        $cues->splice( $pos, 1 );
        $cue->track( undef );
        return( $cue );
    }
    return;
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::TextTrack - HTML Object DOM Text Track Class

=head1 SYNOPSIS

    use HTML::Object::DOM::TextTrack;
    my $track = HTML::Object::DOM::TextTrack->new || 
        die( HTML::Object::DOM::TextTrack->error, "\n" );

    <video controls>
        <source src="https://example.org/some/where/videos/video.webm" type="video/webm" />
        <source src="https://example.org/some/where/videos/video.mp4" type="video/mp4" />
        <track src="video-subtitles-en.vtt" label="English captions" kind="captions" srclang="en" default />
        <track src="video-subtitles-ja.vtt" label="日本語字幕" kind="captions" srclang="ja" />
        <p>This browser does not support the video element.</p>
    </video>

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<TextTrack> interface—part of the Web API for handling C<WebVTT> (text tracks on media presentations)—describes and controls the text track associated with a particular L<<track> element|HTML::Object::DOM::Element::Track>.

C<TextTrack> class is only a programmatic interface with no impact on the DOM whereas L<track element|HTML::Object::DOM::Element::Track> accesses and modifies the DOM and makes use of this programmatic interface with C<TextTrack> through its method L<HTML::Object::DOM::Element::Track/track>

This inherits from L<HTML::Object::DOM::MediaTrack>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------------+     +------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::MediaTrack | --> | HTML::Object::DOM::TextTrack |
    +-----------------------+     +---------------------------+     +-------------------------------+     +------------------------------+

=head1 CONSTRUCTOR

=head2 new

This takes a track C<kind>, C<label> and C<language> and this returns a new C<HTML::Object::DOM::TextTrack> object.

Possible values for C<kind> are:

=over 4

=item caption

=item chapters

=item descriptions

=item metadata

=item subtitles

=back

C<label> is a string specifying the label for the text track. Is used to identify the text track for the users.

C<language> in iso 639 format (e.g. C<en-US> or C<ja-JP>). Seel also L<rfc5646|https://datatracker.ietf.org/doc/html/rfc5646>

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::MediaTrack>

=head2 activeCues

Since there is no notion of 'active cues' under perl environment, you can access the L<TextTrackCueList object|HTML::Object::DOM::TextTrackCueList> this returns and add cues to it on your own.

Normally, under JavaScript, this returns a L<TextTrackCueList|HTML::Object::DOM::TextTrackCueList> object listing the currently active set of text track cues. Track cues are active if the current playback position of the media is between the cues' start and end times. Thus, for displayed cues such as captions or subtitles, the active cues are currently being displayed.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    say( $track->activeCues );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/activeCues>

=head2 cues

Read-only.

A L<TextTrackCueList|HTML::Object::DOM::TextTrackCueList> which contains all of the track's cues.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack('captions', 'Captions', 'en');
    $track->mode = 'showing';
    $track->addCue( HTML::Object::DOM::VTTCue->new(0, 0.9, 'Hildy!') );
    $track->addCue( HTML::Object::DOM::VTTCue->new(1, 1.4, 'How are you?') );
    say( $track->cues );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/cues>

=head2 id

A string which identifies the track, if it has one. If it does not have an ID, then this value is an empty string (""). If the C<TextTrack> is associated with a L<<track> element|HTML::Object::DOM::Element::Track>, then the track's ID matches the element's ID.

Normally this should be read-only, but by design you can change it; only be careful if you do so.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    say( $track->id );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/id>

=head2 inBandMetadataTrackDispatchType

Returns a string which indicates the track's in-band metadata track dispatch type.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    say( $track->inBandMetadataTrackDispatchType );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/inBandMetadataTrackDispatchType>

=head2 kind

Returns a string indicating what kind of text track the C<TextTrack> describes. It must be one of the permitted values.

Normally this should be read-only, but by design you can change it; only be careful if you do so.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    say( $track->kind );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/kind>

=head2 label

A human-readable string which contains the text track's label, if one is present; otherwise, this is an empty string (""), in which case a custom label may need to be generated by your code using other attributes of the track, if the track's label needs to be exposed to the user.

Normally this should be read-only, but by design you can change it; only be careful if you do so.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    say( $track->label );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/label>

=head2 language

A string which specifies the text language in which the text track's contents is written. The value must adhere to the format specified in RFC 5646: Tags for Identifying Languages (also known as BCP 47), just like the HTML lang attribute. For example, this can be "en-US" for United States English or "pt-BR" for Brazilian Portuguese.

Normally this should be read-only, but by design you can change it; only be careful if you do so.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en-US");
    $track->mode = 'showing';
    say( $track->language ); # en-US

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/language>

=head2 mode

A string specifying the track's current mode, which must be one of the permitted values. Changing this property's value changes the track's current mode to match. The default is C<disabled>, unless the C<<track>> element's default boolean attribute is specified, in which case the default mode is C<started>.

Possible values are: C<disabled>,  C<hidden>,  C<showing>, but you are free to use whatever your want of course.

Example:

    $doc->addEventListener( load => sub
    {
        my $trackElem = $doc->querySelector("track");
        my $track = $trackElem->track;

        $track->mode = 'showing';

        for( my $index = 0; index < $track->cues->length; index++ )
        {
            my $cue = $track->cues->[ $index ];
            $cue->pauseOnExit = 1; # true
        };
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/mode>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::MediaTrack>

=head2 addCue

Adds a cue (specified as a L<TextTrackCue object|HTML::Object::DOM::TextTrackCue>) to the track's list of cues.

When doing so, this will set the L<TextTrackCue object|HTML::Object::DOM::TextTrackCue> C<track> property to this object, and will also check it is not already added to avoid duplicates.

It returns the current C<TextTrack> object upon success or upon error it returns C<undef> and sets an L<error|Module::Generic/error>

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    $track->addCue( HTML::Object::DOM::VTTCue->new(0, 0.9, 'Hildy!') );
    $track->addCue( HTML::Object::DOM::VTTCue->new(1, 1.4, 'How are you?') );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/addCue>

=head2 removeCue

Removes a cue (specified as a L<TextTrackCue object|HTML::Object::DOM::TextTrackCue>) from the track's list of cues.

When doing so, this checks the object provided does exists among our cues or it returns C<undef> if it does not exist.

If found, it removes it from our cues, unset the cue's C<track> property.

It returns the removed C<TextTrackCue> object upon success or upon error it returns C<undef> and sets an L<error|Module::Generic/error>

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    my $cue = HTML::Object::DOM::VTTCue->new(0, 0.9, 'Hildy!');
    $track->addCue( $cue );
    $track->removeCue( $cue );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack/removeCue>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrack>, L<VideoJS documentation|https://docs.videojs.com/tutorial-text-tracks.html>, L<rfc5646 for language codes|https://datatracker.ietf.org/doc/html/rfc5646>>, L<W3C specificiations|https://html.spec.whatwg.org/multipage/media.html#texttrack>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
