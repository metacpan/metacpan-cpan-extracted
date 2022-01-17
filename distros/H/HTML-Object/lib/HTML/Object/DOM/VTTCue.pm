##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/VTTCue.pm
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
package HTML::Object::DOM::VTTCue;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::TextTrackCue );
    use HTML::Object::Exception;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    return( $self->error({
        message => sprintf( "At least 3 arguments required, but only %d passed", scalar( @_ ) ),
        class => 'HML::Object::TypeError',
    }) ) if( scalar( @_ ) < 3 );
    my $start = shift( @_ );
    my $end   = shift( @_ );
    my $text  = shift( @_ );
    return( $self->error({
        message => "start argument provided is not a number",
        class => 'HML::Object::TypeError',
    }) ) if( !$self->_is_number( $start ) );
    return( $self->error({
        message => "end argument provided is not a number",
        class => 'HML::Object::TypeError',
    }) ) if( !$self->_is_number( $end ) );
    $self->{positionalign}  = 'auto';
    $self->{startTime}      = $start;
    $self->{endTime}        = $end;
    $self->{text}           = $text;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property
sub align : lvalue { return( shift->_set_get_scalar_as_object( 'align', @_ ) ); }

sub endTime : lvalue { return( shift->_set_get_scalar_as_object( 'endTime', @_ ) ); }

sub getCueAsHTML
{
    my $self = shift( @_ );
    $self->_load_class( 'HTML::Object::DOM::DocumentFragment' ) || return( $self->pass_error );
    my $frag = HTML::Object::DOM::DocumentFragment->new;
    my $text = $frag->new_text( value => $self->{text} ) || return( $self->pass_error( $frag->error ) );
    $frag->appendChild( $text );
    return( $frag );
}

# Note: property
sub line : lvalue { return( shift->_set_get_scalar_as_object( 'line', @_ ) ); }

# Note: property
sub lineAlign : lvalue { return( shift->_set_get_scalar_as_object( 'linealign', @_ ) ); }

# Note: property
sub position : lvalue { return( shift->_set_get_scalar_as_object( 'position', @_ ) ); }

# Note: property
sub positionAlign : lvalue { return( shift->_set_get_scalar_as_object( 'positionalign', @_ ) ); }

# Note: property
sub region : lvalue { return( shift->_set_get_object_without_init( 'region', 'HTML::Object::DOM::VTTRegion', @_ ) ); }

# Note: property
sub size : lvalue { return( shift->_set_get_number( 'size', @_ ) ); }

# Note: property
sub snapToLines : lvalue { return( shift->_set_get_boolean( 'snaptolines', @_ ) ); }

sub startTime : lvalue { return( shift->_set_get_scalar_as_object( 'startTime', @_ ) ); }

# Note: property
sub text : lvalue { return( shift->_set_get_scalar_as_object( 'text', @_ ) ); }

# Note: property
sub vertical : lvalue { return( shift->_set_get_scalar_as_object( 'vertical', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::VTTCue - HTML Object DOM VTTCue Class

=head1 SYNOPSIS

    use HTML::Object::DOM::VTTCue;
    my $cue = HTML::Object::DOM::VTTCue->new || 
        die( HTML::Object::DOM::VTTCue->error, "\n" );

    <video controls src="https://example.org/some/where/media/video.mp4"></video>

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';
    $track->addCue( new HTML::Object::DOM::VTTCue( 0, 0.9, 'Hildy!') ) ;
    $track->addCue( new HTML::Object::DOM::VTTCue( 1, 1.4, 'How are you?' ) );
    $track->addCue( new HTML::Object::DOM::VTTCue( 1.5, 2.9, 'Tell me, is the lord of the universe in?' ) );
    $track->addCue( new HTML::Object::DOM::VTTCue( 3, 4.2, 'Yes, he\'s in - in a bad humor' ) );
    $track->addCue( new HTML::Object::DOM::VTTCue( 4.3, 6, 'Somebody must\'ve stolen the crown jewels' ) );
    say( $track->cues );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This implements a C<VTTCue> object representing a cue which will be presented during the time span given.

The C<VTTCue> interface—part of the Web API for handling C<WebVTT> (text tracks on media presentations)—describes and controls the text track associated with a particular L<<track> element|HTML::Object::DOM::Element::Track>.

=head1 INHERITANCE

    +---------------------------------+     +---------------------------+
    | HTML::Object::DOM::TextTrackCue | --> | HTML::Object::DOM::VTTCue |
    +---------------------------------+     +---------------------------+

=head1 CONSTRUCTOR

=head2 new

C<VTTCue> takes 3 parameters: C<startTime>, C<endTime> and C<text>

=over 4

=item startTime

This is a double representing the initial text track cue start time. This is the time, given in seconds and fractions of a second, denoting the beginning of the range of the media data to which this cue applies. For example, if a cue is to be visible from 50 seconds to a one minute, five and a half seconds in the media's playback, C<startTime> will be 50.0.
C<endTime>

=item endTime

This is a double representing the ending time for this text track cue. This is the time at which the cue should stop being presented to the user, given in seconds and fractions thereof. Given the example cue mentioned under C<startTime>, the value of C<endTime> would be 65.5.
text

=item text

A string providing the text that will be shown during the time span indicated by C<startTime> and C<endTime>.

=back

=head1 PROPERTIES

=head2 align

Returns an enum representing the alignment of all the lines of text within the cue box.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->align = 'start';
    say( $cue1->align );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/align>

=head2 endTime

This is a double representing the ending time for this text track cue. This is the time at which the cue should stop being presented to the user, given in seconds and fractions thereof. Given the example cue mentioned under C<startTime>, the value of C<endTime> would be 65.5.
text

=head2 line

Returns the line positioning of the cue. This can be the string C<auto> or a number whose interpretation depends on the value of L</snapToLines>.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->line = '1';
    say( $cue1->line );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/line>

=head2 lineAlign

Returns an enum representing the alignment of the L</line>.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->lineAlign = 'center';
    say( $cue1->lineAlign );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/lineAlign>

=head2 position

Returns the indentation of the cue within the line. This can be the string C<auto> or a number representing the percentage of the L</region>, or the video size if L</region> is C<undef>.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->position = '2';
    say( $cue1->position );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/position>

=head2 positionAlign

Returns an enum representing the alignment of the cue. This is used to determine what the L</position> is anchored to. The default is C<auto>.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->positionAlign = 'line-right';
    say( $cue1->positionAlign );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/positionAlign>

=head2 region

A L<VTTRegion|HTML::Object::DOM::VTTRegion> object describing the video's sub-region that the cue will be drawn onto, or C<undef> if none is assigned.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    say( $cue1->region );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/region>

=head2 size

Returns a double representing the size of the cue, as a percentage of the video size.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->size = 50;
    say( $cue1->size );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/size>

=head2 snapToLines

Returns true if the L</line> attribute is an integer number of lines or a percentage of the video size.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->snapToLines = 1; # true
    say( $cue1->snapToLines );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/snapToLines>

=head2 startTime

This is a double representing the initial text track cue start time. This is the time, given in seconds and fractions of a second, denoting the beginning of the range of the media data to which this cue applies. For example, if a cue is to be visible from 50 seconds to a one minute, five and a half seconds in the media's playback, C<startTime> will be 50.0.
C<endTime>

=head2 text

Returns a string with the contents of the cue.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->text = 'new cue value';
    say( $cue1->text ) # 'new cue value';

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/text>

=head2 vertical

Returns an enum representing the cue writing direction.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    $cue1->vertical = 'rl';
    say( $cue1->vertical );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/vertical>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::Element>

=head2 getCueAsHTML

Returns the cue text as a L<HTML::Object::DOM::DocumentFragment>.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = "showing";

    my $cue1 = HTML::Object::DOM::VTTCue->new( 0, 0.9, 'Hildy!' );
    say( $cue1->getCueAsHTML() );

    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue/getCueAsHTML>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTCue>, L<W3C specifications|https://www.w3.org/TR/webvtt1/>, L<Specifications|https://w3c.github.io/webvtt/#the-vttcue-interface>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
