##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/AudioTrack.pm
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
package HTML::Object::DOM::AudioTrack;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::MediaTrack );
    use vars qw( $VERSION );
    use HTML::Object::Exception;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

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
    # If set, this should be the same as the id in HTML::Object::DOM::Element::Track
    $self->{id}     = undef;
    $self->{kind}   = $kind;
    $self->{label}  = $label;
    $self->{language}   = $lang;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property
sub enabled : lvalue { return( shift->_set_get_boolean( 'enabled', @_ ) ); }

# Note: property id inherited

# Note: property kind inherited

# Note: property label inherited

# Note: property language inherited

# Note: property
sub sourceBuffer { return; }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::AudioTrack - HTML Object DOM AudioTrack Class

=head1 SYNOPSIS

    use HTML::Object::DOM::AudioTrack;
    my $audio = HTML::Object::DOM::AudioTrack->new || 
        die( HTML::Object::DOM::AudioTrack->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<AudioTrack> interface represents a single audio track from one of the HTML media elements, <audio> or <video>.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------------+     +-------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::MediaTrack | --> | HTML::Object::DOM::AudioTrack |
    +-----------------------+     +---------------------------+     +-------------------------------+     +-------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::MediaTrack>

=head2 enabled

A boolean value which controls whether or not the audio track's sound is enabled. Setting this value to false mutes the track's audio.

Example:

    sub swapCommentaryMain
    {
        my $videoElem = $doc->getElementById( 'main-video' );
        my $audioTrackMain;
        my $audioTrackCommentary;

        $videoElem->audioTracks->forEach(sub
        {
            my $track = shift( @_ );
            if( $track->kind == 'main' )
            {
                $audioTrackMain = $track;
            }
            elsif( $track->kind == 'commentary' )
            {
                $audioTrackCommentary = $track;
            }
        });

        if( $audioTrackMain && $audioTrackCommentary )
        {
            my $commentaryEnabled = $audioTrackCommentary->enabled;
            $audioTrackCommentary->enabled = $audioTrackMain->enabled;
            $audioTrackMain->enabled = $commentaryEnabled;
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/enabled>

=head2 id

A string which uniquely identifies the track within the media. This ID can be used to locate a specific track within an audio track list by calling C<AudioTrackList>.getTrackById(). The ID can also be used as the fragment part of the URL if the media supports seeking by media fragment per the Media Fragments URI specification.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/id>

=head2 kind

A string specifying the category into which the track falls. For example, the main audio track would have a kind of "main".

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/kind>

=head2 label

A string providing a human-readable label for the track. For example, an audio commentary track for a movie might have a label of "Commentary with director John Q. Public and actors John Doe and Jane Eod." This string is empty if no label is provided.

Example:

    use Module::Generic::Array;
    sub getTrackList
    {
        my $el = shift( @_ );
        my $trackList = Module::Generic::Array->new;
        my $wantedKinds = [
            "main", "alternative", "main-desc", "translation", "commentary"
        ];

        $el->audioTracks->forEach(sub
        {
            my $track = shift( @_ );
            if( $wantedKinds->includes( $track->kind ) )
            {
                $trackList->push({
                    id => $track->id,
                    kind => $track->kind,
                    label => $track->label
                });
            }
        });
        return( $trackList );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/label>

=head2 language

A string specifying the audio track's primary language, or an empty string if unknown. The language is specified as a BCP 47 (RFC 5646) language code, such as "en-US" or "pt-BR".

Example:

    use Module::Generic::Array;
    sub getAvailableLanguages
    {
        my $el = shift( @_ );
        my $trackList = Module::Generic::Array->new;
        my $wantedKinds = [
            "main", "translation"
        ];

        $el->audioTracks->forEach(sub
        {
            my $track = shift( @_ );
            if( $wantedKinds->includes( $track->kind ) )
            {
                $trackList->push({
                    id => $track->id,
                    kind => $track->kind,
                    language => $track->language
                });
            }
        });
        return( $trackList );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/language>

=head2 sourceBuffer

The C<SourceBuffer> that created the track. Returns C<undef> if the track was not created by a C<SourceBuffer> or the C<SourceBuffer> has been removed from the C<MediaSource>.sourceBuffers attribute of its parent media source.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/sourceBuffer>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::MediaTrack>

=head1 EXAMPLE

    use feature 'signatures';
    my $sfx = HTML::Object::DOM::Element::Audio->new( 'sfx.wav' );
    my $sounds = $sfx->addTextTrack( 'metadata' );

    # add sounds we care about
    sub addFX( $start, $end, $name )
    {
        my $cue = HTML::Object::DOM::VTTCue->new( $start, $end, '' );
        $cue->id = $name;
        $cue->pauseOnExit = 1; # true
        $sounds->addCue( $cue );
    }
    addFX( 12.783, 13.612, 'dog bark' );
    addFX( 13.612, 15.091, 'kitten mew' );

    sub playSound( $id )
    {
        $sfx->currentTime = $sounds->getCueById( $id )->startTime;
        $sfx->play();
    }

    # play a bark as soon as we can
    $sfx->oncanplaythrough = sub
    {
        playSound( 'dog bark' );
    }
    # meow when the user tries to leave,
    # and have the browser ask them to stay
    $doc->onbeforeunload = sub
    {
        my $e = shift( @_ );
        playSound( 'kitten mew' );
        $e->preventDefault();
    }

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
