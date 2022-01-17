##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/VideoTrack.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/28
## Modified 2021/12/28
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::VideoTrack;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::EventTarget );
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
    # If set, this should be the same as the id in HTML::Object::DOM::Element::Track
    $self->{id}     = undef;
    $self->{kind}   = $kind;
    $self->{label}  = $label;
    $self->{language}   = $lang;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property id inherited

# Note: property kind inherited

# Note: property label inherited

# Note: property language inherited

# Note: property
sub selected : lvalue { return( shift->_set_get_boolean({
    field => 'selected',
    callbacks => 
    {
        add => sub
        {
            my $me = shift( @_ );
            my $parent;
            if( ( $parent = $me->parent ) && ( my $coderef = $parent->can( '_update_selected' ) ) )
            {
                $coderef->( $parent, $me );
            }
        }
    }
}, @_ ) ); }

# Note: property
sub sourceBuffer { return; }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::VideoTrack - HTML Object DOM VideoTrack Class

=head1 SYNOPSIS

    use HTML::Object::DOM::VideoTrack;
    my $track = HTML::Object::DOM::VideoTrack->new || 
        die( HTML::Object::DOM::VideoTrack->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The C<VideoTrack> interface represents a single video track from a <video> element.

To get a C<VideoTrack> for a given media element, use the element's L<videoTracks|HTML::Object::DOM::Element::Media/videoTracks> property, which returns a L<VideoTrackList|HTML::Object::DOM::VideoTrackList> object from which you can get the individual tracks contained in the media:

    my $el = $doc->querySelector('video');
    my $tracks = $el->videoTracks;
    my $firstTrack = $tracks->[0];

Scan through all of the media's video tracks, activating the first video track that is in the user's preferred language (taken from a variable userLanguage).

    for( my $i = 0; $i < $tracks->length; $i++ )
    {
        if( $tracks->[$i]->language eq $userLanguage )
        {
            $tracks->[$i]->selected = 1; # true
            last;
        }
    });

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::VideoTrack |
    +-----------------------+     +---------------------------+     +-------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::EventTarget>

=head2 id

Sets or gets a string which uniquely identifies the track within the media. This ID can be used to locate a specific track within a video track list by calling C<VideoTrackList>.getTrackById(). The ID can also be used as the fragment part of the URL if the media supports seeking by media fragment per the Media Fragments URI specification.

Returns the ID as a L<scalar object|Module::Generic::Scalar>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/id>

=head2 kind

A string specifying the category into which the track falls. For example, the main video track would have a kind of C<main>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/kind>

=head2 label

A string providing a human-readable label for the track. For example, a track whose kind is C<sign> might have a label of "A sign-language interpretation". This string is empty if no label is provided.

Example:

    use Module::Generic::Array;
    sub getTrackList
    {
        my $el = shift( @_ );
        my $trackList = Module::Generic::Array->new;
        my $wantedKinds = [qw( main alternative commentary )];

        $el->videoTracks->forEach(sub
        {
            my $track = shift( @_ );
            if( $wantedKinds->includes( $track->kind ) )
            {
                $trackList->push({
                    id    => $track->id,
                    kind  => $track->kind,
                    label => $track->label
                });
            }
        });
        return( $trackList );
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/label>

=head2 language

A string specifying the video track's primary language, or an empty string if unknown. The language is specified as a BCP 47 (L<RFC 5646|https://datatracker.ietf.org/doc/html/rfc5646>) language code, such as C<en-US> or C<ja-JP>.

Returns the language as a L<scalar object|Module::Generic::Scalar>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/language>

=head2 selected

A boolean value which controls whether or not the video track is active. Only a single video track can be active at any given time, so setting this property to true for one track while another track is active will make that other track inactive.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/selected>

=head2 sourceBuffer

This always returns C<undef> under perl.

Normally, under JavaScript, this is the C<SourceBuffer> that created the track. Returns C<undef> if the track was not created by a C<SourceBuffer> or the C<SourceBuffer> has been removed from the C<MediaSource.sourceBuffers> attribute of its parent media source.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/sourceBuffer>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::EventTarget>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
