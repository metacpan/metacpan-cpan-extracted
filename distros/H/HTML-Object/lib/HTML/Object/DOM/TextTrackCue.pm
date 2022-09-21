##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/TextTrackCue.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/27
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::TextTrackCue;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
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
sub endTime : lvalue { return( shift->_set_get_number( 'endtime', @_ ) ); }

# Note: property
sub id : lvalue { return( shift->_set_get_scalar_as_object( 'id', @_ ) ); }

# Note: property
sub pauseOnExit : lvalue { return( shift->_set_get_boolean( 'pauseonexit', @_ ) ); }

# Note: property
sub startTime : lvalue { return( shift->_set_get_number( 'starttime', @_ ) ); }

# Note: property
sub track : lvalue { return( shift->_set_get_object_without_init( 'track', 'HTML::Object::DOM::TextTrack', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::TextTrackCue - HTML Object DOM TextTrack Cue Class

=head1 SYNOPSIS

    use HTML::Object::DOM::TextTrackCue;
    my $this = HTML::Object::DOM::TextTrackCue->new || 
        die( HTML::Object::DOM::TextTrackCue->error, "\n" );

    my $video = $doc->getElementById('myVideo');
    var $caption = $video->addTextTrack('caption');
    $caption->addCue(new HTML::Object::DOM::VTTCue("Test text", 01.000, 04.000,"","","",true));

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class is inherited by L<HTML::Object::DOM::VTTCue> and is part of a collection with L<HTML::Object::DOM::TextTrackCueList>

C<TextTrackCue> is an abstract class which is used as the basis for the various derived cue types, such as L<VTTCue|HTML::Object::DOM::VTTCue>; you will instead work with those derived types. These cues represent strings of text presented for some duration of time during the performance of a L<TextTrack|HTML::Object::DOM::TextTrack>. The cue includes the start time (the time at which the text will be displayed) and the end time (the time at which it will be removed from the display), as well as other information.

=head1 PROPERTIES

=head2 endTime

A double that represents the video time that the cue will stop being displayed, in seconds.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';

    my $cue1 = HTML::Object::DOM::VTTCue->new(0.1, 0.9, 'Hildy!');
    say( $cue1->endTime ); # 0.9
    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCue/endTime>

=head2 id

A string that identifies the cue.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';

    my $cue1 = HTML::Object::DOM::VTTCue->new(0, 0.9, 'Hildy!');
    $cue1->id = 'first';
    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCue/id>

=head2 pauseOnExit

A boolean for whether the video will pause when this cue stops being displayed.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCue/pauseOnExit>

=head2 startTime

A double that represents the video time that the cue will start being displayed, in seconds.

Example:

    my $video = $doc->querySelector('video');
    my $track = $video->addTextTrack("captions", "Captions", "en");
    $track->mode = 'showing';

    my $cue1 = HTML::Object::DOM::VTTCue->new(0.1, 0.9, 'Hildy!');
    say( $cue1->startTime ); # 0.1
    $track->addCue( $cue1 );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCue/startTime>

=head2 track

The L<TextTrack|HTML::Object::DOM::TextTrack> that this cue belongs to, or C<undef> if it does not belong to any.

Example:

    my $video = $doc->querySelector('video');
    my $captiontrack = $video->addTextTrack("captions", "Captions", "en");
    $captiontrack->mode = 'showing';

    my $cue1 = HTML::Object::DOM::VTTCue->new(0, 0.9, 'Hildy!');
    $captiontrack->addCue( $cue1 );
    say( $cue1->track ); # a TextTrack object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCue/track>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCue>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
