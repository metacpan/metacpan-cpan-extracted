##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Body/Form.pm
## Version v0.2.1
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/18
## Modified 2024/02/06
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Body::Form;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic::Hash );
    use vars qw( $VERSION );
    # use Nice::Try;
    use URL::Encode::XS ();
    our $VERSION = 'v0.2.1';
};

use strict;
use warnings;

sub new
{
    my $this = shift( @_ );
    if( @_ )
    {
        my $data = shift( @_ );
        if( ref( $data ) eq 'HASH' )
        {
            return( $this->SUPER::new( $data, @_ ) );
        }
        elsif( !ref( $data ) || 
               ( ref( $data ) ne 'HASH' && overload::Method( $data => '""' ) ) )
        {
            my $ref = $this->decode_to_hash( "${data}" ) ||
                return( $this->pass_error );
            return( $this->SUPER::new( $ref, @_ ) );
        }
        else
        {
            return( $this->error( "Unsupported data type '", ref( $data ), "'." ) );
        }
    }
    else
    {
        return( $this->SUPER::new );
    }
}

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_form_data
{
    my $self = shift( @_ );
    my $hash = {};
    my $keys = $self->keys->sort;
    $self->_load_class( 'HHTP::Promise::Body::Form' ) || return( $self->pass_error );
    my $form = HHTP::Promise::Body::Form->new;
    foreach my $n ( @$keys )
    {
        my $v = $self->{ $n };
        if( $self->_is_array( $v ) )
        {
            foreach my $v2 ( @$v )
            {
                my $e = $self->_is_a( $v2 => 'HTTP::Promise::Body::Form::Field' ) 
                    ? $v2
                    : $form->new_field(
                        name => $n,
                        body => $v2,
                    );
                if( exists( $form->{ $n } ) )
                {
                    $form->{ $n } = [$form->{ $n }] unless( $self->_is_array( $form->{ $n } ) );
                    push( @{$form->{ $n }}, $e );
                }
                else
                {
                    $form->{ $n } = $e;
                }
            }
        }
        else
        {
            my $e = $self->_is_a( $v => 'HTTP::Promise::Body::Form::Field' ) 
                ? $v
                : $form->new_field(
                    name => $n,
                    body => $v,
                );
            if( exists( $form->{ $n } ) )
            {
                $form->{ $n } = [$form->{ $n }] unless( $self->_is_array( $form->{ $n } ) );
                push( @{$form->{ $n }}, $e );
            }
            else
            {
                $form->{ $n } = $e;
            }
        }
    }
    return( $form );
}

sub as_string
{
    my $self = shift( @_ );
    my $keys = [];
    if( @_ && $self->_is_array( $_[0] ) )
    {
        $keys = shift( @_ );
    }
    else
    {
        $keys = $self->keys->sort;
    }
    my @pairs = ();
    # try-catch
    local $@;
    eval
    {
        $self->_tie_object->enable(1);
        foreach my $n ( @$keys )
        {
            my $v = $self->{ $n };
            if( ref( $v ) eq 'ARRAY' )
            {
                foreach my $v2 ( @$v )
                {
                    if( $self->_is_a( $v2 => 'HTTP::Promise::Body::Form::Field' ) )
                    {
                        $v2 = $v2->body->as_string( binmode => 'utf-8' );
                    }
                    warn( "Found a value, within an array for item '$n', that is a reference, but does not stringifies.\n" ) if( ref( $v2 ) && !overload::Method( $v2 => '""' ) && $self->_is_warnings_enabled );
                    push( @pairs, join( '=', $n, URL::Encode::XS::url_encode_utf8( "$v2" ) ) );
                }
            }
            else
            {
                if( $self->_is_a( $v => 'HTTP::Promise::Body::Form::Field' ) )
                {
                    $v = $v->body->as_string( binmode => 'utf-8' );
                }
                warn( "Found a value, for item '$n', that is a reference, but does not stringifies.\n" ) if( ref( $v ) && !overload::Method( $v => '""' ) && $self->_is_warnings_enabled );
                push( @pairs, join( '=', $n, URL::Encode::XS::url_encode_utf8( "$v" ) ) );
            }
        }
    };
    if( $@ )
    {
        return( $self->error( "Error while Trying to url-encode ", scalar( @$keys ), " form elements: $@" ) );
    }
    return( join( '&', @pairs ) );
}

sub decode { return( shift->decode_to_array( @_ ) ); }

sub decode_string
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    warn( "No data to url-decode was provided.\n" ) if( ( !defined( $data ) || !length( "$data" ) ) && $self->_is_warnings_enabled );
    return( $self->error( "Invalid parameter provided. You can only pass a string or an object that stringifies." ) ) if( ref( $data ) && !overload::Method( $data => '""' ) );
    my $decoded;
    # try-catch
    local $@;
    eval
    {
        $decoded = URL::Encode::XS::url_decode_utf8( "${data}" );
    };
    if( $@ )
    {
        return( $self->error( "Error while Trying to url-decode ", length( $data ), " bytes of data: $@" ) );
    }
    return( $decoded );
}

sub decode_to_array
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    # warn( "No data to url-decode was provided.\n" ) if( ( !defined( $data ) || !length( "$data" ) ) && $self->_is_warnings_enabled );
    warn( "No data to url-decode was provided.\n" ) if( ( !defined( $data ) || !length( "$data" ) ) && $self->_is_warnings_enabled );
    return( $self->error( "Invalid parameter provided. You can only pass a string or an object that stringifies." ) ) if( ref( $data ) && !overload::Method( $data => '""' ) );
    my $ref;
    # try-catch
    local $@;
    eval
    {
        $ref = URL::Encode::XS::url_params_flat( "${data}" );
    };
    if( $@ )
    {
        return( $self->error( "Error while Trying to url-decode ", length( $data ), " bytes of data: $@" ) );
    }
    return( $ref );
}

sub decode_to_hash
{
    my $self = shift( @_ );
    my $ref = $self->_is_array( $_[0] ) ? shift( @_ ) : $self->decode_to_array( @_ );
    return( $self->pass_error ) if( !defined( $ref ) );
    my $hash = {};
    while( my( $n, $v ) = splice( @$ref, 0, 2 ) )
    {
        if( exists( $hash->{ $n } ) )
        {
            $hash->{ $n } = [ $hash->{ $n } ] unless( ref( $hash->{ $n } ) eq 'ARRAY' );
            push( @{$hash->{ $n }}, $v );
        }
        else
        {
            $hash->{ $n } = $v;
        }
    }
    return( $hash );
}

# TODO: This is redundant with code in as_string. as_string should be revamped to call encode()
sub encode
{
    my $self = shift( @_ );
    my $ref = shift( @_ );
    return( $self->error( "Invalid argument provided. I was expecting an array or an hash reference." ) ) if( ref( $ref ) ne 'ARRAY' && ref( $ref ) ne 'HASH' );
    # Work on a copy
    my $this = ref( $ref ) eq 'ARRAY' ? [@$ref] : [%$ref];
    return( '' ) if( !scalar( @$this ) );
    my $rv;
    my @pairs = ();
    # try-catch
    local $@;
    eval
    {
        while( my( $n, $v ) = splice( @$this, 0, 2 ) )
        {
            if( ref( $v ) eq 'ARRAY' )
            {
                foreach my $v2 ( @$v )
                {
                    if( $self->_is_a( $v2 => 'HTTP::Promise::Body::Form::Field' ) )
                    {
                        $v2 = $v2->body->as_string( binmode => 'utf-8' );
                    }
                    warn( "Found a value, within an array for item '$n', that is a reference, but does not stringifies.\n" ) if( ref( $v2 ) && !overload::Method( $v2 => '""' ) && $self->_is_warnings_enabled );
                    push( @pairs, join( '=', $n, URL::Encode::XS::url_encode_utf8( "$v2" ) ) );
                }
            }
            else
            {
                if( $self->_is_a( $v => 'HTTP::Promise::Body::Form::Field' ) )
                {
                    $v = $v->body->as_string( binmode => 'utf-8' );
                }
                warn( "Found a value, for item '$n', that is a reference, but does not stringifies.\n" ) if( ref( $v ) && !overload::Method( $v => '""' ) && $self->_is_warnings_enabled );
                push( @pairs, join( '=', $n, URL::Encode::XS::url_encode_utf8( "$v" ) ) );
            }
        }
        $rv = join( '&', @pairs );
    };
    if( $@ )
    {
        return( $self->error( "Error while Trying to url-encode ", scalar( @$this ), " elements provided: $@" ) );
    }
    return( $rv );
}

sub encode_string
{
    my $self = shift( @_ );
    my $encoded;
    # try-catch
    local $@;
    eval
    {
        $encoded = URL::Encode::XS::url_encode_utf8( shift( @_ ) );
    };
    if( $@ )
    {
        return( $self->error( "Error while trying to url-encode: $@" ) );
    }
    return( $encoded );
}

sub error
{
    my $self = shift( @_ );
    $self->_tie_object->enable(0);
    return( $self->SUPER::error( @_ ) );
}

sub length { return( CORE::length( shift->as_string ) ); }

sub open
{
    my $self = shift( @_ );
    my $encoded = $self->as_string;
    return( $self->pass_error ) if( !defined( $encoded ) );
    my $s = $self->new_scalar( \$encoded ) || 
        return( $self->pass_error );
    my $io = $s->open( @_ ) ||
        return( $self->pass_error( $s->error ) );
    return( $io );
}

sub pass_error
{
    my $self = shift( @_ );
    $self->_tie_object->enable(0);
    return( $self->SUPER::pass_error( @_ ) );
}

sub print
{
    my( $self, $fh ) = @_;
    my $nread;
    # Get output filehandle, and ensure that it's a printable object:
    $fh ||= select;
    return( $self->error( "Filehandle provided ($fh) is not a proper filehandle and its not a HTTP::Promise::IO object." ) ) if( !$self->_is_glob( $fh ) && !$self->_is_a( $fh => 'HTTP::Promise::IO' ) );
    my $encoded = $self->as_string;
    return( $self->pass_error ) if( !defined( $encoded ) );
    $fh->print( $encoded ) || return( $self->error( "Unable to print on given filehandle '$fh': $!" ) );
    return(1);
}

sub _is_warnings_enabled { return( warnings::enabled( $_[0] ) ); }

# NOTE: FREEZE is inherited

# NOTE: STORABLE_freeze is inherited

# NOTE: STORABLE_thaw is inherited

# NOTE: THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Body::Form - x-www-form-urlencoded Data Class

=head1 SYNOPSIS

    use HTTP::Promise::Body::Form;
    my $form = HTTP::Promise::Body::Form->new;
    my $form = HTTP::Promise::Body::Form->new( $hash_ref );
    my $form = HTTP::Promise::Body::Form->new( q{e%3Dmc2} );
    die( HTTP::Promise::Body::Form->error, "\n" ) if( !defined( $form ) );

=head1 VERSION

    v0.2.1

=head1 DESCRIPTION

This class represents C<x-www-form-urlencoded> HTTP body. It inherits from L<Module::Generic::Hash>

This is different from a C<multipart/form-data>. For this, please check the module L<HTTP::Promise::Body::Form::Data>

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

As an historical note, C<x-www-form-urlencoded> is not an rfc-defined standard, and differs from URI encoding defined by L<rfc3986|https://tools.ietf.org/html/rfc3986> in that it uses C<+> to represent whitespace. It was L<defined back then by Mosaic|https://web.archive.org/web/19961220100435/http://www.ncsa.uiuc.edu/SDG/Software/Mosaic/Docs/fill-out-forms/overview.html> as a non-standard way of encoding form data. This also L<this historical note|http://1997.webhistory.org/www.lists/www-talk.1993q3/0812.html> and this L<Stackoverflow discussion|https://stackoverflow.com/questions/42276418/why-does-x-www-form-urlencoded-begin-with-x-www-when-other-standard-content>.

=head1 METHODS

L<HTTP::Promise::Body::Form> inherits all the methods from L<Module::Generic::Hash>, and adds or override the following ones.

=head2 as_form_data

This returns a new L<HTTP::Promise::Body::Form::Data> object based on the current data, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 as_string

This returns a properly urlencoded representation of the name-value pairs stored in this hash object.

Each value will be encoded into utf8 before being urlencoded. This is all done fast with L<URL::Encode::XS>

=head2 decode

Provided with an C<x-www-form-urlencoded> string and this will return a decoded string taking under account utf8 characters.

    my $params = $form->decode( 'tengu=%E5%A4%A9%E7%8B%97' );
    # [ 'tengu', '天狗' ]

If an error occurs, this will set an L<error object|Module::Generic/error> and return C<undef>

=head2 decode_string

Provided with an url-encoded string, included utf-8 string, and this returns its corresponding decoded version.

    my $deity = $form->decode( '%E5%A4%A9%E7%8B%97' );

results in: C<天狗>

=head2 decode_to_array

Takes an C<x-www-form-urlencoded> string and returns an array reference of name-value pairs. If a name is seen more than once, its value will be an array reference.

If an error occurs, this will set an L<error object|Module::Generic/error> and return C<undef>

=head2 decode_to_hash

Takes an C<x-www-form-urlencoded> string or an array reference of name-value pairs and returns an hash reference of name-value pairs.

If a name is seen more than once, its value will be an array reference.

If an error occurs, this will set an L<error object|Module::Generic/error> and return C<undef>

=head2 encode

Takes an array reference or an hash reference and this returns a properly url-encoded string representation.

If an error occurs, this will set an L<error object|Module::Generic/error> and return C<undef>

=head2 encode_string

Takes a string and returns an encoded string. UTF-8 strings are ok too as long as they are in L<perl's internal representation|perlunicode>.

If an error occurs, this will set an L<error object|Module::Generic/error> and return C<undef>

=head2 length

Returns the number of keys currently set in this key-value pairs held in the object.

=head2 open

This encodes the key-pairs as C<x-www-form-urlencoded> by calling L</as_string>, which returns a new L<scalar object|Module::Generic::Scalar>, opens it, passing whatever arguments it received to L<Module::Generic::Scalar/open> and return the resulting object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>

=for Pod::Coverage pass_error

=head2 print

Provided with a valid filehandle, and this print the C<x-www-form-urlencoded> representation of the key-value pairs contained in this object, to the given filehandle, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Specifications|https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#url-encoded-form-data>, L<old rfc1867|https://tools.ietf.org/html/rfc1867.html>

L<rfc7578 on multipart/form-data|https://tools.ietf.org/html/rfc7578>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
