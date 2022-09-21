##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Audio.pm
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
package HTML::Object::DOM::Element::Audio;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element::Media );
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
    $self->{tag} = 'audio' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Audio - HTML Object DOM Audio Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Audio;
    my $audio = HTML::Object::DOM::Element::Audio->new || 
        die( HTML::Object::DOM::Element::Audio->error, "\n" );

    <h2>Audio inserted with JavaScript</h2>
    <div id="myAudio"></div>

    my $div = document.getElementById( 'myAudio' );
    # Create an element <audio>
    my $audio = document.createElement('audio');
    # Set the attributes of the video
    $audio->src = 'https://example.org/some/where/audio/audio.ogg';
    $audio->controls = 1; # true
    # Add the aido to <div>
    $div->appendChild( $audio );

Result:

    <h2>Audio inserted with JavaScript</h2>
    <div id="myAudio"></div>
        <audio src="https://example.org/some/where/audio/audio.ogg" controls=""></audio>
    </div>

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides access to the properties of <audio> elements, as well as methods to manipulate them.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Media | --> | HTML::Object::DOM::Element::Audio |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element::Media>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element::Media>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLAudioElement>, L<Mozilla documentation on audio element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/audio>, L<Wikipedia on audio file formats|https://en.wikipedia.org/wiki/Audio_file_format>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
