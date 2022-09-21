##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/TextTrackCueList.pm
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
package HTML::Object::DOM::TextTrackCueList;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::List );
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

sub forEach { return( shift->children->foreach( @_ ) ); }

sub getCueById
{
    my $self = shift( @_ );
    my $id   = shift( @_ );
    return if( !defined( $id ) || !CORE::length( "$id" ) );
    foreach my $e ( @$self )
    {
        if( Scalar::Util::blessed( $e ) && 
            $e->isa( 'HTML::Object::DOM::TextTrackCue' ) )
        {
            my $e_id = $e->attr( 'id' );
            return( $e ) if( defined( $e_id ) && $id eq $e_id );
        }
    }
    return;
}

# Note: property length is inherited from Module::Generic::Array

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::TextTrackCueList - HTML Object DOM TextTrack Cue List Class

=head1 SYNOPSIS

    use HTML::Object::DOM::TextTrackCueList;
    my $list = HTML::Object::DOM::TextTrackCueList->new || 
        die( HTML::Object::DOM::TextTrackCueList->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<TextTrackCueList> represents a dynamically updating list of C<TextTrackCue> objects.

It inherits from L<HTML::Object::DOM::List>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +-------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::List | --> | HTML::Object::DOM::TextTrackCueList |
    +-----------------------+     +---------------------------+     +-------------------------+     +-------------------------------------+

=head1 PROPERTIES

=head2 length

An unsigned long that is the number of cues in the list.

Example:

    my $video = $doc->getElementById( 'video' );
    $video->onplay = sub
    {
        say( $video->textTracks->[0]->cues->length ) # 5;
    };

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCueList/length>

=head1 METHODS

=head2 forEach

This is an alias for L<Module::Generic::Array/foreach>

=head2 getCueById

Returns the first L<TextTrackCue|HTML::Object::DOM::TextTrackCue> object with the identifier passed to it.

Example:

    my $video = $doc->getElementById( 'video' );
    $video->onplay = sub
    {
        say( $video->textTracks->[0]->cues->getCueById( 'second' ) ) # a VTTCue object;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCueList/getCueById>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/TextTrackCueList>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
