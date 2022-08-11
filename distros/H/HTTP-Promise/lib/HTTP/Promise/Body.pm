##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Entity/Body.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/19
## Modified 2022/04/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Body;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use HTTP::Promise::Exception;
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub as_lines
{
    my $self = shift( @_ );
    my $io = $self->open( 'r' ) || return( $self->pass_error );
    my $lines = $self->new_array;
    local $_;
    while( defined( $_ = $io->getline ) )
    {
        $lines->push( $_ );
    }
    $io->close;
    return( $lines );
}

# Very dangerous to use indiscriminately when dealing with large data stored on file
sub as_string
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $str = $self->new_scalar;
    my $params = {};
    for( qw( binmode debug ) )
    {
        $params->{ $_ } = $opts->{ $_ } if( exists( $opts->{ $_ } ) && $opts->{ $_ } );
    }
    my $io = $self->open( 'r', ( scalar( keys( %$params ) ) ? $params : () ) ) || return( $self->pass_error );
    my( $buff, $nread );
    while( $nread = $io->read( $buff, 8192 ) )
    {
        $$str .= $buff;
    }
    return( $str );
}

# sub binmode { return( shift->_set_get_boolean( 'binmode', @_ ) ); }

sub data { return( shift->as_string( @_ ) ); }

sub dup { return( shift->clone( @_ ) ); }

# sub open { return; }

sub path { return; }

sub print
{
    my $self = shift( @_ );
    my $fh   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $nread;

    # Get output filehandle, and ensure that it's a printable object
    return( $self->error( "Filehandle provided ($fh) is not a proper filehandle and its not a HTTP::Promise::IO object." ) ) if( !$self->_is_glob( $fh ) && !$self->_is_a( $fh => 'HTTP::Promise::IO' ) );

    my $params = {};
    $params->{binmode} = $opts->{binmode} if( exists( $opts->{binmode} ) && $opts->{binmode} );
    # Write it
    my $buff = '';
    my $io = $self->open( 'r', ( scalar( keys( %$params ) ) ? $params : () ) ) || return( $self->pass_error );
    while( $nread = $io->read( $buff, 8192 ) )
    {
        print( $fh $buff ) || return( $self->error( "Unable to write to filehandle '$fh': $!" ) );
    }
    $io->close;
    return( defined( $nread ) );
}

sub purge { return; }

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited


# NOTE: HTTP::Promise::Body::File package
package HTTP::Promise::Body::File;
BEGIN
{
    use strict;
    use warnings;
    use Module::Generic::File;
    use parent -norequire, qw( HTTP::Promise::Body Module::Generic::File );
    use vars qw( $EXCEPTION_CLASS );
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
};

use strict;
use warnings;

sub new { return( shift->Module::Generic::File::new( @_ ) ); }

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->Module::Generic::File::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub path { return( shift->filename( @_ ) ); }

sub purge { return( shift->unlink ); }

sub FREEZE { CORE::return( CORE::shift->Module::Generic::File::FREEZE( @_ ) ); }

sub STORABLE_freeze { CORE::return( CORE::shift->Module::Generic::File::STORABLE_freeze( @_ ) ); }

# NOTE: sub STORABLE_thaw is inherited

# NOTE: sub THAW is inherited


# NOTE: HTTP::Promise::Body::Scalar package
package HTTP::Promise::Body::Scalar;
BEGIN
{
    use strict;
    use warnings;
    use Module::Generic::Scalar;
    use parent -norequire, qw( HTTP::Promise::Body Module::Generic::Scalar );
    use vars qw( $EXCEPTION_CLASS );
    use overload (
        '""'    => sub{ $_[0] },
        bool    => sub{1},
        fallback => 1,
    );
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
};

use strict;
use warnings;

# sub new { return( shift->Module::Generic::Scalar::new( @_ ) ); }
sub new
{
    my $this = shift( @_ );
    my $new = $this->Module::Generic::Scalar::new( @_ );
    return( $this->pass_error( $this->Module::Generic::Scalar::error ) ) if( !defined( $new ) );
    return( $new );
}

sub as_string { return( @_ > 1 ? shift->SUPER::as_string( @_ ) : $_[0]->new_scalar( $_[0] ) ); }

sub checksum_md5
{
    my $self = shift( @_ );
    $self->_load_class( 'Crypt::Digest::MD5' ) || return( $self->pass_error );
    return( Crypt::Digest::MD5::md5_hex( $$self ) );
}

sub error { return( shift->Module::Generic::Scalar::error( @_ ) ); }

sub pass_error { return( shift->Module::Generic::Scalar::pass_error( @_ ) ); }

sub purge { return( shift->Module::Generic::Scalar::reset( @_ ) ); }

sub set { return( shift->Module::Generic::Scalar::set( @_ ) ); }

sub FREEZE { return( shift->Module::Generic::Scalar::FREEZE( @_ ) ); }

# NOTE: sub STORABLE_freeze is inherited

# NOTE: sub STORABLE_thaw is inherited

sub THAW { return( shift->Module::Generic::Scalar::THAW( @_ ) ); }


# NOTE: HTTP::Promise::Body::InCore package
package HTTP::Promise::Body::InCore;
BEGIN
{
    use strict;
    use warnings;
    use parent -norequire, qw( HTTP::Promise::Body::Scalar );
    use vars qw( $EXCEPTION_CLASS );
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    # nothing
    if( !defined( $data ) ||
        # simple scalar or a scalar object
        ( !ref( $data ) || ( $self->_is_scalar( $data ) && overload::Method( $data => '""' ) ) ) ||
        # or a scalar reference
        ref( $data ) eq 'SCALAR' )
    {
        # pass through
    }
    elsif( $self->_is_array( $data ) )
    {
        $data = join( '', @$data );
    }
    else
    {
	    return( $self->error( "Data of type '", ref( $data ), "' is unsupported." ) );
    }
    $self->SUPER::init( $data, @_ ) || return( $self->pass_error );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Body - HTTP Message Body Class

=head1 SYNOPSIS

    use HTTP::Promise::Body;
    my $body = HTTP::Promise::Body->new || 
        die( HTTP::Promise::Body->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents an entity body.

Here is how it fits in overall relation with other classes.
                                                               
    +-------------------------+    +--------------------------+    
    |                         |    |                          |    
    | HTTP::Promise::Request  |    | HTTP::Promise::Response  |    
    |                         |    |                          |    
    +------------|------------+    +-------------|------------+    
                 |                               |                 
                 |                               |                 
                 |                               |                 
                 |  +------------------------+   |                 
                 |  |                        |   |                 
                 +--- HTTP::Promise::Message |---+                 
                    |                        |                     
                    +------------|-----------+                     
                                 |                                 
                                 |                                 
                    +------------|-----------+                     
                    |                        |                     
                    | HTTP::Promise::Entity  |                     
                    |                        |                     
                    +------------|-----------+                     
                                 |                                 
                                 |                                 
                    +------------|-----------+                     
                    |                        |                     
                    | HTTP::Promise::Body    |                     
                    |                        |                     
                    +------------------------+                     

=head1 METHODS

=head2 as_lines

Returns a new L<array object|Module::Generic::Array> containing the body lines.

=head2 as_string

Returns the body data as a L<scalar object|Module::Generic::Scalar>.

Be mindful about the size of the body before you load it all in memory. You can get the size of the body with C<< $body->length >>

=head2 data

This is just an alias for L</as_string>

=head2 dup

This is an alias for L<Module::Generic/clone>, which is inherited by this class.

=head2 path

This is a no-op and is superseded by inheriting classes.

=head2 print

Provided with a filehandle, or an L<HTTP::Promise::IO> object and an hash or hash reference of options and this will print the body data to and returns true if it was successful, or sets an L<error|Module::Generic/error> and returns C<undef>

=head2 purge

This is a no-op and is superseded by inheriting classes.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

L<Module::Generic::File>, L<Module::Generic::Scalar>, L<Module::Generic::File::IO>, L<Module::Generic::Scalar::IO>

L<PerlIO::scalar>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
