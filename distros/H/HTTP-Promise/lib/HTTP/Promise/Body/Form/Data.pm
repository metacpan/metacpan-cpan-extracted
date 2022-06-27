##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Body/Form/Data.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/06/13
## Modified 2022/06/13
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Body::Form::Data;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Body::Form );
    use vars qw( $VERSION $CRLF );
    use Data::UUID;
    our $CRLF = "\015\012";
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{order} = [];
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $boundary = $opts->{boundary} ||= Data::UUID->new->create_str;
    my $eol  = $opts->{eol} || $CRLF;
    my $parts = $self->make_parts( $opts );
    return( $self->pass_error ) if( !defined( $parts ) );
    my $res = $self->new_scalar;
    for( @$parts )
    {
        my $part = $_->as_string( $eol ) . $eol;
        return( $self->pass_error( $_->error ) ) if( !defined( $part ) );
        $$res .= "--${boundary}" . $eol . $part;
    }
    $res .= "--${boundary}--${eol}" if( $res->length );
    return( $res );
}

sub as_urlencoded
{
    my $self = shift( @_ );
    my $hash = {};
    my $keys = $self->keys->sort;
    my $process = sub
    {
        my( $n, $v ) = @_;
        if( $self->_is_a( $v => 'HTTP::Promise::Body::Form::Field' ) )
        {
            my $this = $v;
            $v = $this->as_string( binmode => 'utf-8' );
            return( $self->pass_error( $this->error ) ) if( !defined( $v ) );
        }
        if( exists( $hash->{ $n } ) )
        {
            $hash->{ $n } = [$hash->{ $n }] if( ref( $hash->{ $n } ) ne 'ARRAY' );
            push( @{$hash->{ $n }}, $v );
        }
        else
        {
            $hash->{ $n } = $v;
        }
        return(1);
    };
    
    foreach my $n ( @$keys )
    {
        my $v = $self->{ $n };
        if( $self->_is_array( $v ) )
        {
            foreach my $v2 ( @$v )
            {
                $process->( $n, $v2 ) || return( $self->pass_error );
            }
        }
        else
        {
            $process->( $n, $v ) || return( $self->pass_error );
        }
    }
    $self->_load_class( 'HTTP::Promise::Body::Form' ) || return( $self->pass_error );
    my $form = HTTP::Promise::Body::Form->new( $hash ) ||
        return( $self->pass_error( HTTP::Promise::Body::Form->error ) );
    return( $form );
}

sub length { return( shift->Module::Generic::Hash::length ); }

sub make_parts
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $order = $self->order;
    my $keys = $self->_is_array( $opts->{fields} )
        ? $self->new_array( $opts->{fields} )
        : ( defined( $order ) && scalar( @$order ) )
            ? $order
            : $self->keys->sort;
    $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->pass_error );
    $self->_load_class( 'HTTP::Promise::Headers' ) || return( $self->pass_error );
    my $parts = $self->new_array;
    
    my $process = sub
    {
        my( $n, $v ) = @_;
        my( $headers, $body );
        if( $self->_is_a( $v => 'HTTP::Promise::Body::Form::Field' ) )
        {
            $headers = $v->headers || HTTP::Promise::Headers->new;
            $body = $v->body;
        }
        else
        {
            $headers = HTTP::Promise::Headers->new;
#             $body = HTTP::Promise::Entity->new_body( string => $v ) ||
#                 return( $self->pass_error( HTTP::Promise::Entity->error ) );
            $body = HTTP::Promise::Entity->new_body( string => $v );
            if( !defined( $body ) )
            {
                return( $self->pass_error( HTTP::Promise::Entity->error ) );
            }
        }
        my $dispo = $headers->content_disposition;
        my $cd = $dispo
            ? $headers->new_field( 'Content-Disposition' => $dispo )
            : $headers->new_field( 'Content-Disposition' );
        return( $self->pass_error( $headers->error ) ) if( !defined( $cd ) );
        $cd->disposition( 'form-data' );
        $cd->name( $n );
        if( $self->_is_a( $body => 'HTTP::Promise::Body::File' ) && 
            !$cd->filename )
        {
            my $basename = $body->basename;
            $cd->filename( $basename );
        }
        $headers->content_disposition( "$cd" );
        
        my $ent = HTTP::Promise::Entity->new( headers => $headers, body => $body ) ||
            return( $self->pass_error( HTTP::Promise::Entity->error ) );
        $ent->name( $n );
        return( $ent );
    };
    
    foreach my $n ( @$keys )
    {
        my $v = $self->{ $n };
        if( ref( $v ) eq 'ARRAY' )
        {
            foreach my $v2 ( @$v )
            {
                my $ent = $process->( $n, $v2 ) ||
                    return( $self->pass_error );
                $ent->name( $n );
                $parts->push( $ent );
            }
        }
        else
        {
            my $ent = $process->( $n, $v ) ||
                return( $self->pass_error );
            $ent->name( $n );
            $parts->push( $ent );
        }
    }
    return( $parts );
}    

sub new_field
{
    my $self = shift( @_ );
    $self->_load_class( 'HTTP::Promise::Body::Form::Field' ) || return( $self->pass_error );
    my $f = HTTP::Promise::Body::Form::Field->new( @_ ) ||
        return( $self->pass_error( HTTP::Promise::Body::Form::Field->error ) );
    return( $f );
}

sub open
{
    my $self = shift( @_ );
    my $s = $self->as_string;
    return( $self->pass_error ) if( !defined( $s ) );
    my $io = $s->open( @_ ) ||
        return( $self->pass_error( $s->error ) );
    return( $io );
}

sub order { return( shift->_set_get_array_as_object( 'order', @_ ) ); }

sub print
{
    my( $self, $fh ) = @_;
    my $nread;
    # Get output filehandle, and ensure that it's a printable object:
    $fh ||= select;
    return( $self->error( "Filehandle provided ($fh) is not a valid filehandle." ) ) if( !$self->_is_glob( $fh ) );
    my $encoded = $self->as_string;
    return( $self->pass_error ) if( !defined( $encoded ) );
    print( $fh $$encoded ) || return( $self->error( "Unable to print on given filehandle '$fh': $!" ) );
    return(1);
}

sub _is_warnings_enabled { return( warnings::enabled( $_[0] ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Body::Form::Data - A multipart/form-data Representation Class

=head1 SYNOPSIS

    use HTTP::Promise::Body::Form;
    my $form = HTTP::Promise::Body::Form::Data->new;
    my $form = HTTP::Promise::Body::Form::Data->new({
        fullname => 'Jigoro Kano',
        location => HTTP::Promise::Body::Form::Data->new_field(
            name => 'location',
            value => 'Tokyo',
        ),
        picture => HTTP::Promise::Body::Form::Data->new_field(
            name => 'picture',
            file => '/some/where/file.txt',
        ),
    });
    my $form = HTTP::Promise::Body::Form::Data->new( $hash_ref );
    my $form = HTTP::Promise::Body::Form::Data->new( q{e%3Dmc2} );
    die( HTTP::Promise::Body::Form->error, "\n" ) if( !defined( $form ) );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a C<form-data> content as key-value pairs and is designed to make construction and manipulation of C<multipart/form-data> easier. It inherits from L<HTTP::Promise::Body::Form>

For C<x-www-form-urlencoded>, use L<HTTP::Promise::Body::Form> instead.

Each key represents a C<form-data> field and its value can either be a simple string or a C<HTTP::Promise::Body::Form::Field> object.

C<multipart/form-data> is the only valid Content-Type for sending multiple data. L<rfc7578 in section 4.3|https://tools.ietf.org/html/rfc7578#section-4.3> states: "[RFC2388] suggested that multiple files for a single form field be transmitted using a nested "multipart/mixed" part. This usage is deprecated."

See also this L<Stackoverflow discussion|https://stackoverflow.com/questions/36674161/http-multipart-form-data-multiple-files-in-one-input/41204533#41204533> and L<this one too|https://stackoverflow.com/questions/51575746/http-header-content-type-multipart-mixed-causes-400-bad-request>

=head1 CONSTRUCTOR

=head2 new

This takes an optional data, and some options and returns a new L<HTTP::Promise::Body::Form> object.

Acceptable data are:

=over 4

=item An hash reference

=item An url encoded string

=back

If a string is provided, it will be automatically decoded into an hash of name-value pairs. When a name is found more than once, its values are added as an array reference.

    my $form = HTTP::Promise::Body->new( 'name=John+Doe&foo=bar&foo=baz&foo=' );

Would result in a C<HTTP::Promise::Body::Form> object containing:

    name => 'John Doe', foo => ['bar', 'baz', '']

=head1 METHODS

L<HTTP::Promise::Body::Form> inherits all the methods from L<Module::Generic::Hash>, and adds or override the following ones.

=head2 as_string

Provided with an hash or hash reference of options and this returns a L<scalar object|Module::Generic::Scalar> of the C<form-data> properly formatted as multipart elements.

Be mindful of the size of the parts and that this is not cached, so each time this is called, it creates the parts.

Supported options are:

=over 4

=item * C<boundary>

A string used as a part delimiter. Note, however, that even if you provide this value, it will not replace the C<boundary> value of a C<HTTP::Promise::Body::Form::Field> C<Content-Disposition> field if it is set.

If this is not provided, a new one will be automatically generated using L<Data::UUID/create_str>

=item * C<eol>

The end-of-line terminator. This defaults to C<\015\012>

=item * C<fields>

An array reference of form field names. This is used to set the order of appearance.

If not provided, it will default to alphabetic order.

=back

=head2 as_urlencoded

This returns a new L<HTTP::Promise::Body::Form> object based on the current data, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 make_parts

This takes an hash or hash reference of options and creates L<entity part objects|HTTP::Promise::Entity> and returns them as an L<array object|Module::Generic::Array>

Supported options are:

=over 4

=item * C<boundary>

A string used as a part delimiter. Note, however, that even if you provide this value, it will not replace the C<boundary> value of a C<HTTP::Promise::Body::Form::Field> C<Content-Disposition> field if it is set.

If this is not provided, a new one will be automatically generated using L<Data::UUID/create_str>

=back

=head2 make_parts

Provided with an hash or hash reference of options and this returns an L<array object|Module::Generic::Array> of L<parts|HTTP::Promise::Entity>

Note that at this point, the body is not encoded and the C<Content-Length> is not added. You can use L<HTTP::Promise::Entity/encode_body> on each part to encode a form part value.

Supported options are:

=over 4

=item * C<fields>

An array reference of form field names. This is used to set the order of appearance.

If not provided, it will default to alphabetic order.

=back

=head2 new_field

This takes an hash or hash reference of options and returns the new C<HTTP::Promise::Body::Form::Data> object, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Supported options are:

=over 4

=item * C<headers>

This is optional. Either as L<HTTP::Promise::Headers> object or as an array reference.

=item * C<name>

Field name

=item * C<value>

Field value as a string, scalar reference or a L<file object|Module::Generic::File>

=back

=head2 open

This transform all the C<form-data> elements into a proper C<multipart/form-data> using L</as_string> and returns a new L<Module::Generic::Scalar::IO> object.

It then opens the scalar passing L<Module::Generic::Scalar/open> whatever arguments were provided and returns an L<Module::Generic::Scalar::IO> object.

=head2 order

Sets or gets an L<array object|Module::Generic::Array> of form fields in the desired order of appearance when stringified.

=head2 print

Provided with a valid filehandle, and this print the C<form-data> representation of the form fields and their values, to the given filehandle, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

L<Module::Generic::Scalar>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
