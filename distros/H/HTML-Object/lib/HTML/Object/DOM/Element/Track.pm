##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Track.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Track;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :track );
    use constant {
        # Indicates that the text track's cues have not been obtained.
        NONE                => 0,
        # Indicates that the text track is loading and there have been no fatal errors encountered so far. Further cues might still be added to the track by the parser.
        LOADING             => 1,
        # Indicates that the text track has been loaded with no fatal errors.
        LOADED              => 2,
        # Indicates that the text track was enabled, but when the user agent attempted to obtain it, this failed in some way. Some or all of the cues are likely missing and will not be obtained.
        ERROR               => 3,
    };
    our @EXPORT_OK = qw( NONE LOADING LOADED ERROR );
    our %EXPORT_TAGS = (
        all => [qw( NONE LOADING LOADED ERROR )],
    );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'track' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property default
sub default : lvalue { return( shift->_set_get_property( { attribute => 'default', is_boolean => 1 }, @_ ) ); }

# Note: property kind
sub kind : lvalue { return( shift->_set_get_property( 'kind', @_ ) ); }

# Note: property label
sub label : lvalue { return( shift->_set_get_property( 'label', @_ ) ); }

sub oncuechange : lvalue { return( shift->on( 'cuechange', @_ ) ); }

# Note: property readyState read-only
sub readyState : lvalue { return( shift->_set_get_number( 'readystate', @_ ) ); }

# Note: property src is inherited

# Note: property srclang
sub srclang : lvalue { return( shift->_set_get_property( 'srclang', @_ ) ); }

# Note: property track read-only
sub track
{
    my $self = shift( @_ );
    return( $self->{track} ) if( defined( $self->{track} ) && ref( $self->{track} ) );
    $self->_load_class( 'HTML::Object::DOM::TextTrack' ) || return( $self->pass_error );
    my $kind  = $self->kind;
    my $label = $self->label;
    my $lang  = $self->srclang;
    my $track = HTML::Object::DOM::TextTrack->new( $kind, $label, $lang, 
    {
        id      => $self->id,
        debug   => $self->debug,
    });
    return( $self->pass_error( HTML::Object::DOM::TextTrack->error ) ) if( !defined( $track ) );
    $track->parent( $self );
    return( $self->{track} = $track );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Track - HTML Object DOM Track Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Track;
    my $track = HTML::Object::DOM::Element::Track->new || 
        die( HTML::Object::DOM::Element::Track->error, "\n" );

    my $video = $doc->getElementsByTagName('video')->[0];
    # or
    my $video = $doc->createElement('video');
    $video->controls = 1; # true
    # Source 1
    my $source1 = $doc->createElement('source');
    $source1->src = 'https://example.org/some/where/videos/video.webm';
    # Source 2
    my $source2 = $doc->createElement('source');
    $source2->src = 'https://example.org/some/where/videos/video.mp4';
    # Track 1
    my $track1 = $doc->createElement('track');
    $track1->kind = 'subtitles';
    $track1->src = 'subtitles-en.vtt';
    $track1->label = 'English captions';
    $track1->srclang = 'en';
    $track1->type = 'text/vtt';
    $track1->default = 1; # true
    # Track 2
    my $track2 = $doc->createElement('track');
    $track2->kind = 'subtitles';
    $track2->src = 'subtitles-fr.vtt';
    $track2->label = 'Sous-titres Français';
    $track2->srclang = 'fr';
    $track2->type = 'text/vtt';
    # Track 3
    my $track3 = $doc->createElement('track');
    $track3->kind = 'subtitles';
    $track3->src = 'subtitles-ja.vtt';
    $track3->label = '日本語字幕';
    $track3->srclang = 'ja'";
    $track3->type = 'text/vtt';
    # Append everything
    $video->appendChild( $source1 );
    $video->appendChild( $source2 );
    $video->appendChild( $track1 );
    $video->appendChild( $track2 );
    $video->appendChild( $track3 );
    my $p = $doc->createElement('p');
    $p->textContent = q{This browser does not support the video element.};
    $video->appendChild( $p );

    <video controls="">
        <source src="https://example.org/some/where/videos/video.webm" type="video/webm" />
        <source src="https://example.org/some/where/videos/video.mp4" type="video/mp4" />
        <track src="subtitles-en.vtt" label="English captions" kind="subtitles" srclang="en" default />
        <track src="subtitles-fr.vtt" label="Sous-titres Français" kind="subtitles" srclang="fr" />
        <track src="subtitles-ja.vtt" label="日本語字幕" kind="subtitles" srclang="ja" />
        <p>This browser does not support the video element.</p>
    </video>

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface represents an HTML C<<track>> element within the DOM. This element can be used as a child of either C<<audio>> or C<<video>> to specify a text track containing information such as closed captions or subtitles.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Track |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 default

A boolean value reflecting the C<default> attribute, indicating that the track is to be enabled if the user's preferences do not indicate that another track would be more appropriate.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/default>

=head2 kind

Is a string that reflects the C<kind> HTML attribute, indicating how the text track is meant to be used. Possible values are: subtitles, captions, descriptions, chapters, or metadata.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/kind>

=head2 label

Is a string that reflects the C<label> HTML attribute, indicating a user-readable title for the track.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/label>

=head2 readyState

Returns an unsigned short that show the readiness state of the track. Below are the possible constant values.
You can export and use those constants by calling either of the following:

    use HTML::Object::DOM::Element::Track qw( :all );
    # or
    use HTML::Object::DOM qw( :track );

See L</CONSTANTS> for the constants that can be exported and used.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/readyState>

=head2 src

Is a string that reflects the src HTML attribute, indicating the address of the text track data.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/src>

=head2 srclang

Is a string that reflects the srclang HTML attribute, indicating the language of the text track data.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/srclang>

=head2 track

Returns C<TextTrack> is the track element's text track data.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/track>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

For example, C<cuechange> event listeners can be set also with C<oncuechange> method:

    $e->oncuechange(sub{ # do something });
    # or as an lvalue method
    $e->oncuechange = sub{ # do something };

=head2 cuechange

Under perl, this event is not triggered obviously, but you can trigger it yourself.

Under JavaScript, this is sent when the underlying L<TextTrack|HTML::Object::DOM::TextTrack> has changed the currently-presented cues. This event is always sent to the L<TextTrack|HTML::Object::DOM::TextTrack> but is also sent to the L<HTML::Object::DOM::Element::Track> if one is associated with the track.
You may also use the C<oncuechange> event handler to establish a handler for this event.

Example:

    $track->addEventListener( cuechange => sub
    {
        my $cues = $track->activeCues; # array of current $cues
    });

    $track->oncuechange = sub
    {
        my $cues = $track->activeCues; # array of current $cues
    }

Another example:

    my $textTrackElem = $doc->getElementById( 'texttrack' );

    $textTrackElem->addEventListener( cuechange => sub
    {
        my $cues = $event->target->track->activeCues;
    });

or

    $textTrackElem->oncuechange = sub
    {
        my $cues = $_->target->track->activeCues;
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement/cuechange_event>

=head1 CONSTANTS

The following constants can be exported and used, such as:

    use HTML::Object::DOM::Element::Track qw( :all );
    # or directly from HTML::Object::DOM
    use HTML::Object::DOM qw( :track );

=over 4

=item NONE (0)

Indicates that the text track's cues have not been obtained.

=item LOADING (1)

Indicates that the text track is loading and there have been no fatal errors encountered so far. Further cues might still be added to the track by the parser.

=item LOADED (2)

Indicates that the text track has been loaded with no fatal errors.

=item ERROR (3)

Indicates that the text track was enabled, but when the user agent attempted to obtain it, this failed in some way. Some or all of the cues are likely missing and will not be obtained.

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLTrackElement>, L<Mozilla documentation on track element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/track>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
