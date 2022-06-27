##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Body/Form/Field.pm
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
package HTTP::Promise::Body::Form::Field;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $self->{name}       = undef;
    return( $self->error( "No field name was provided." ) ) if( !exists( $opts->{name} ) || !defined( $opts->{name} ) || !length( $opts->{name} ) );
    my( $headers, $body );
    if( exists( $opts->{headers} ) )
    {
        if( $self->_is_a( $opts->{headers} => 'HTTP::Promise::Headers' ) )
        {
            $headers = $opts->{headers};
        }
        elsif( exists( $opts->{headers} ) && $self->_is_array( $opts->{headers} ) )
        {
            $self->_load_class( 'HTTP::Promise::Headers' ) || return( $self->pass_error );
            $headers = HTTP::Promise::Headers->new( @{$opts->{headers}} );
            return( $self->pass_error( HTTP::Promise::Headers->error ) ) if( !defined( $headers ) );
        }
        else
        {
            return( $self->error( "Unsupported data type '", ref( $opts->{headers} ), "' for field name $opts->{name}" ) );
        }
        delete( $opts->{headers} );
    }
    else
    {
        $self->_load_class( 'HTTP::Promise::Headers' ) || return( $self->pass_error );
        $headers = HTTP::Promise::Headers->new;
    }
    
    if( exists( $opts->{file} ) && $opts->{file} )
    {
        $self->_load_class( 'HTTP::Promise::Body' ) || return( $self->pass_error );
        $body = HTTP::Promise::Body::File->new( $opts->{file} ) ||
            return( $self->pass_error( HTTP::Promise::Body::File->error ) );
        delete( @$opts{qw( body file value )} );
    }
    elsif( exists( $opts->{value} ) )
    {
        $self->_load_class( 'HTTP::Promise::Body' ) || return( $self->pass_error );
        $body = HTTP::Promise::Body::Scalar->new( $opts->{value} ) ||
            return( $self->pass_error( HTTP::Promise::Body::Scalar->error ) );
        delete( @$opts{qw( body file value )} );
    }
    elsif( exists( $opts->{body} ) )
    {
        if( $self->_is_a( 'HTTP::Promise::Body' ) )
        {
            $body = $opts->{body};
        }
        elsif( $self->_is_a( $opts->{body} => 'Module::Generic::File' ) )
        {
            $self->_load_class( 'HTTP::Promise::Body' ) || return( $self->pass_error );
            $body = HTTP::Promise::Body::File->new( $opts->{body} ) ||
                return( $self->pass_error( HTTP::Promise::Body::File->error ) );
        }
        elsif( !ref( $opts->{body} ) || 
            $self->_is_scalar( $opts->{body} ) || 
            overload::Method( $opts->{body} => '""' ) )
        {
            $self->_load_class( 'HTTP::Promise::Body' ) || return( $self->pass_error );
            $body = HTTP::Promise::Body::Scalar->new( $opts->{body} ) ||
                return( $self->pass_error( HTTP::Promise::Body::Scalar->error ) );
        }
        else
        {
            return( $self->error( "Unsupported data '", ref( $opts->{body} ), "' for field name '$opts->{name}'" ) );
        }
        delete( $opts->{body} );
    }
    else
    {
        $self->_load_class( 'HTTP::Promise::Body' ) || return( $self->pass_error );
        $body = HTTP::Promise::Body::Scalar->new;
    }
    $self->{body}       = $body;
    $self->{headers}    = $headers;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( $opts ) || return( $self->pass_error );
    return( $self );
}

sub body { return( shift->_set_get_object_without_init( 'body', [qw( HTTP::Promise::Body HTTP::Promise::Body::Form )], @_ ) ); }

sub is_body_on_file
{
    my $self = shift( @_ );
    my $body = $self->body;
    return(0) if( !$body || $body->is_empty );
    return( $self->_is_a( $body => 'HTTP::Promise::Body::File' ) );
}

sub is_body_in_memory
{
    my $self = shift( @_ );
    my $body = $self->body;
    return(0) if( !$body || $body->is_empty );
    return( $self->_is_a( $body => 'HTTP::Promise::Body::Scalar' ) );
}

sub headers { return( shift->_set_get_object_without_init( 'headers', 'HTTP::Promise::Headers', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub value
{
    my $self = shift( @_ );
    my $body = $self->body || return( $self->error( "No body is set for this field '$self->{name}'" ) );
    my $data = $body->as_string( @_ );
    return( $self->pass_error( $body->error ) ) if( !defined( $data ) );
    return( $data );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Body::Form::Field - HTTP Form Field Class

=head1 SYNOPSIS

    use HTTP::Promise::Body::Form::Field;
    my $f = HTTP::Promise::Body::Form::Field->new(
        name => 'picture',
        file => '/some/where/image.png',
        headers => [ conten_type => 'image/png' ],
    );

    my $f = HTTP::Promise::Body::Form::Field->new(
        name => 'picture',
        # Module::Generic::File or HTTP::Promise::Body::File object are ok
        file => $file_object,
        headers => [ conten_type => 'image/png' ],
    );

    my $f = HTTP::Promise::Body::Form::Field->new(
        name => 'fullname',
        body => "John Doe",
    );

    my $f = HTTP::Promise::Body::Form::Field->new(
        name => 'fullname',
        body => \$some_content,
    );

    my $f = HTTP::Promise::Body::Form::Field->new(
        name => 'fullname',
        # HTTP::Promise::Body::Scalar object is ok too
        body => $body_object,
    );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a form field. This is used primarily in conjonction with L<HTTP::Promise::Body::Form::Data>

=head1 METHODS

=head2 body

Sets or gets the field L<body object|HTTP::Promise::Body>.

=head2 headers

Sets or gets an L<headers object|HTTP::Promise::Headers>

=head2 is_body_in_memory

Returns true if the field body is an L<HTTP::Promise::Body::Scalar> object, false otherwise.

=head2 is_body_on_file

Returns true if the field body is an L<HTTP::Promise::Body::File> object, false otherwise.

=head2 name

Sets or gets the field name as a L<scalar object|Module::Generic::Scalar>

=head2 value

This retrieves the field data as a new L<scalar object|Module::Generic::Scalar>, regardless if it the field C<body> is in memory or on file.

Whatever argument is provided, is passed through to L<HTTP::Promise::Body/as_string>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
