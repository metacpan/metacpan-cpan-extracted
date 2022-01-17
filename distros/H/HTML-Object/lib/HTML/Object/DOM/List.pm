##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/List.pm
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
package HTML::Object::DOM::List;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::EventTarget );
    use HTML::Object::Event;
    use Want;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{children} = [];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# This method is called from the package inheriting from us
# $def is a dictionary hash reference providing specifics in a crisp way about the types of events and related properties concerned
# Example:
# {
#     addtrack    => { 
#         add     => { property => 'children', type => 'add', event => 'addtrack' },
#     },
#     change      => {
#         add     => { property => 'selected', type => 'add', event => 'change' },
#         remove  => { property => 'selected', type => 'remove', event => 'change' },
#     },
#     removetrack => {
#         remove  => { property => 'children', type => 'remove', event => 'removetrack' },
#     },
# }
sub addEventListener
{
    my $self = shift( @_ );
    return( $self->error( "I was expecting 3 arguments, but got only ", scalar( @_ ), "." ) ) if( scalar( @_ ) < 3 );
    my $def  = shift( @_ );
    my $type = shift( @_ );
    my $code = shift( @_ );
    return( $self->error( "Dictionary provided is not an hash reference." ) ) if( !defined( $def ) || ref( $def ) ne 'HASH' );
    return( $self->error( "Event type provided contains illegal characters." ) ) if( !defined( $type ) || $type !~ /^\w+#/ );
    return( $self->error( "Callback is not a code reference." ) ) if( !defined( $code ) || !length( "$code" ) || ref( $code ) ne 'CODE' );
    # Before we enable the event listener we must make sure we are listening on events on relevant array or scalar
    if( CORE::exists( $def->{ $type } ) )
    {
        my $ref = $def->{ $event };
        # add or remove
        OP: foreach my $op ( keys( %$ref ) )
        {
            my $this = $ref->{ $op };
            for( qw( property type ) )
            {
                if( !CORE::exists( $this->{ $_ } ) || !defined( $this->{ $_ } ) || !CORE::length( $this->{ $_ } ) )
                {
                    warnings::warn( "Dictionary property \"$_\" is missing or empty.\n" ) if( warnings::enabled( 'HTML::Object' ) );
                    next OP;
                }
                elsif( $_ ne 'add' && $_ ne 'remove' )
                {
                    warnings::warn( "Unknown data listener type \"$_\"\n" );
                    next OP;
                }
            }
        
            my $subref = $self->can( $this->{property} );
            if( !defined( $subref ) )
            {
                warnings::warn( "This object class \"", ( ref( $self ) || $self ), "\" does not support method \"", $this->{property}, "\".\n" ) if( warnings::enabled( 'HTML::Object' ) );
                next;
            }
            my $data = $subref->( $self );
            if( !$self->_is_object( $data ) || !$data->can( 'callback' ) )
            {
                warnings::warn( "Object from class \"", ( ref( $data ) || $data ), "\" does not have a \"callback\" method.\n" ) if( warnings::enabled( 'HTML::Object' ) );
                next;
            }
            my $cb = $data->callback( $this->{type} );
            # Callback already exists
            next if( defined( $cb ) && ref( $cb ) );
            $data->callback( $this->{type} => sub
            {
                my $hash = shift( @_ );
                my $event = $self->_make_event( $event );
                if( CORE::exists( $this->{callback} ) && ref( $this->{callback} ) eq 'CODE' )
                {
                    $this->{callback}->( $self, { event => $event, added => $hash->{added}, removed => $hash->{removed}, type => $hash->{type} });
                }
                $self->dispatchEvent( $event );
            });
        }
    }
    return( $self->SUPER::addEventListener( $type => $code ) );
}

sub forEach { return( shift->children->foreach( @_ ) ); }

sub length { return( shift->children->length ); }

sub push { return( shift->children->push( @_ ) ); }

sub _make_event
{
    my $self = shift( @_ );
    my $type = shift( @_ );
    my $event = HTML::Object::Event->new( $type,
        bubbles => 0,
        cancellable => 0,
        target => $self,
    ) || return( $self->pass_error );
    return( $event );
}

sub AUTOLOAD
{
    my( $name ) = our $AUTOLOAD =~ /([^:]+)$/;
    my $self = shift( @_ );
    my $children = $self->children;
    die( "No method \"\$name\" in class \"", ( ref( $self ) || $self ), "\".\n" ) if( !$children );
    my $code = $children->can( $name );
    die( "No method \"\$name\" in class \"", ( ref( $children ) || $children ), "\".\n" ) if( !$code );
    eval( "sub $name { return( shift->children->$name( \@_ ) ); }\n\n" );
    return( $code->( $children, @_ ) );
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::List - HTML Object DOM List Abstract Class

=head1 SYNOPSIS

    package HTML::Object::DOM::VideoTrackList;
    use parent qw( HTML::Object::DOM::List );
    
    my $list = HTML::Object::DOM::VideoTrackList->new || d
        ie( HTML::Object::DOM::VideoTrackList->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is an abstract class designed to be inherited by L<HTML::Object::DOM::TextTrackCueList>, L<HTML::Object::DOM::TextTrackList> and L<HTML::Object::DOM::VideoTrackList>

It inherits from L<HTML::Object::EventTarget>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::List |
    +-----------------------+     +---------------------------+     +-------------------------+

=head1 METHODS

=head2 addEventListener

This is a variant from the usual C<addEventListener> from L<HTML::Object::EventTarget>. This method takes 3 arguments:

=over 4

=item 1. A dictionary hash reference

This dictionary contains a key for each event name and another hash reference as their value. That hash reference contains the following properties:

=over 8

=item callback

Optional property whose value is a code reference to be called after creating the event and before dispatching it with L<HTML::Object::EventTarget/dispatchEvent>. The purpose is to give it a chance to add some property value to the event like C<track> for L<HTML::Object::DOM::TrackEvent> fired by L<HTML::Object::DOM::TextTrackCueList>, L<HTML::Object::DOM::TextTrackList> and L<HTML::Object::DOM::VideoTrackList>

=item event

The event name.

=item property

The module property or method name.

=item type

The type of callback to set for this property. Possible values are: C<add> or C<remove>

=back

=item 2. An event type

=item 3. An event handler callback

=back

When C<addEventListener> is called, it will check if, for the given even type passed, there is an entry in the dictionary, and if there is it will enable an internal callback on the associated module property when there is any change to its underlying value.

This relies on L<Module::Generic::Array/callback> and L<Module::Generic::Scalar/callback>

That internal callback will be called when a change occurs, and will create an L<event|HTML::Object::Event> of type C<type> and call L<HTML::Object::EventTarget/dispatchEvent> passing it the newly created event.

If a C<callback> was specified in the dictionary for this event type, the callback code will be executed, and the whatever value added or removed will be passed to the callback as an hash reference and an hash property C<added> or C<removed> depending if the operation was to add or remove a value.

After having set this internal callback to monitor change, if any, this will call its parent L<addEventListener> to register the event listener.

=head2 forEach

Calls C<foreach> on the array object returned by L<HTML::Object::Element/children> method.

=head2 length

Returns the size of the list, starting from C<1>.

=head2 push

Provided with some data and they will be appended to this list object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::EventTarget>, L<HTML::Object::Event>, L<HTML::Object::DOM::TextTrackCueList>, L<HTML::Object::DOM::TextTrackCueList>, L<HTML::Object::DOM::VideoTrackList>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
