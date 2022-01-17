##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/EventListener.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/11
## Modified 2021/12/11
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::EventListener;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{element} = undef;
    $self->{type} = undef;
    $self->{code} = undef;
    $self->{options} = {};
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self->error( "No callback has been set for this event listener." ) ) if( !$self->{code} );
    return( $self );
}

sub capture { return( shift->options->{capture} ); }

sub code { return( shift->_set_get_code( 'code', @_ ) ); }

sub element { return( shift->_set_get_object_without_init( 'element', 'HTML::Object::Element', @_ ) ); }

sub handleEvent { return( shift->code( @_ ) ); }

sub options { return( shift->_set_get_hash_as_mix_object( 'options', @_ ) ); }

sub remove
{
    my $self = shift( @_ );
    my $elem = $self->element || 
        return( $self->error({
            message => "No element object found in our event listener!",
            class => 'HTML::Object::SyntaxError',
        }) );
    my $type = $self->type || 
        return( $self->error({
            message => "No event type found in our event listener!",
            class => 'HTML::Object::SyntaxError',
        }) );
    my $code = $self->code ||
        return( $self->error({
            message => "No event callabck found in our event listener!",
            class => 'HTML::Object::SyntaxError',
        }) );
    my $opts = $self->options;
    $opts->{capture} //= 0;
    $self->message( 4, "Removing our event listener of type '$type' from element with tag '", $elem->tag, "' with code '$code' and capture value '$opts->{capture}'" );
    $elem->removeEventListener( $type, $code, { capture => $opts->{capture} });
    return( $self );
}

sub type { return( shift->_set_get_scalar_as_object( 'type', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::EventListener - HTML Object Event Listener Class

=head1 SYNOPSIS

    use HTML::Object::EventListener;
    my $handler = HTML::Object::EventListener->new || 
        die( HTML::Object::EventListener->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module implements an L<HTML::Object> event listener. It is instantiated by the L<addEventListener|HTML::Object::EventTarget/addEventListener> method

=head1 CONSTRUCTOR

=head2 new

Provided with an hash or hash reference of options and this will instantiate a new even listener and return the object.

It takes the same options as the methods listed below.

=head1 METHODS

=head2 capture

Sets or get the C<capture> boolean value for this event listener.

=head2 code

Same as L</handleEvent>

=head2 element

Sets or gets the L<HTML::Object::Element> object to which is attached this event listener.

=head2 handleEvent

Set or get an anonymous subroutine or a reference to a subroutine that is called whenever an event of the specified type occurs.

=head2 options

Set or get an hash reference of options for this event handler. Those options are the same as the ones passed to L<HTML::Object::EventTarget/addEventListener>

=head2 remove

A convenient alternative method to L<HTML::Object::EventTarget/removeEventListener>. It takes no parameter and calls L<HTML::Object::EventTarget/removeEventListener> with all the necessary parameters, hassle free.

It returns the current event listener object upon success, and C<undef> upon error and then set an L<error|Module::Generic/error>

=head2 type

Set or get the type of event this object is for.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::EventTarget>, L<HTML::Object::Event>, L<HTML::Object::EventListener>

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/Events/Event_handlers>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
