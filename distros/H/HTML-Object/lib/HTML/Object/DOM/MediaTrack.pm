##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/MediaTrack.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/30
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::MediaTrack;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::EventTarget );
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

# Note: property
sub id : lvalue { return( shift->_set_get_scalar_as_object( 'id', @_ ) ); }

# Note: property
sub kind : lvalue { return( shift->_set_get_scalar_as_object( 'kind', @_ ) ); }

# Note: property
sub label : lvalue { return( shift->_set_get_scalar_as_object( 'label', @_ ) ); }

# Note: property
sub language : lvalue { return( shift->_set_get_scalar_as_object( 'language', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::MediaTrack - HTML Object

=head1 SYNOPSIS

    use HTML::Object::DOM::MediaTrack;
    my $this = HTML::Object::DOM::MediaTrack->new || 
        die( HTML::Object::DOM::MediaTrack->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This is a shared interface for L<HTML::Object::DOM::AudioTrack> and L<HTML::Object::DOM::VideoTrack>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::MediaTrack |
    +-----------------------+     +---------------------------+     +-------------------------------+

=head1 METHODS

=head2 id

A string which uniquely identifies the track within the media. This ID can be used to locate a specific track within an audio track list by calling C<AudioTrackList>.getTrackById(). The ID can also be used as the fragment part of the URL if the media supports seeking by media fragment per the Media Fragments URI specification.

See also L<Mozilla documentation for audio id|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/id> and See also L<Mozilla documentation for video id|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/id>

=head2 kind

A string specifying the category into which the track falls. For example, the main audio track would have a kind of "main".

See also L<Mozilla documentation for audio kind|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/kind> and L<Mozilla documentation for video kind|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/kind>

=head2 label

A string providing a human-readable label for the track. For example, an audio commentary track for a movie might have a label of "Commentary with director John Q. Public and actors John Doe and Jane Eod." This string is empty if no label is provided.

See also L<Mozilla documentation for audio label|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/label> and L<Mozilla documentation for vide label|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/label>

=head2 language

A string specifying the audio track's primary language, or an empty string if unknown. The language is specified as a BCP 47 (RFC 5646) language code, such as "en-US" or "pt-BR".

See also L<Mozilla documentation for audio language|https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/language> and L<Mozilla documentation for video language|https://developer.mozilla.org/en-US/docs/Web/API/VideoTrack/language>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::DOM::AudioTrack>, L<HTML::Object::DOM::VideoTrack>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
