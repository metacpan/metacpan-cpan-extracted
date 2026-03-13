##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Body/InCore.pm
## Version v0.1.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/07
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
# NOTE: Mail::Make::Body::InCore package
# Body held entirely in memory as a scalar.
package Mail::Make::Body::InCore;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Mail::Make::Body );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.1.1';
}

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    $self->{_data}            = '';
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    if( defined( $data ) )
    {
        # Accept scalar reference or plain scalar
        if( $self->_is_scalar( $data ) )
        {
            $self->{_data} = $$data;
        }
        elsif( !ref( $data ) )
        {
            $self->{_data} = $data;
        }
        else
        {
            return( $self->error( "Mail::Make::Body::InCore->new requires a scalar or scalar reference, got: " . $self->_str_val( $data ) ) );
        }
    }
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    return( \$self->{_data} );
}

sub is_in_core { return(1); }

sub length
{
    my $self = shift( @_ );
    use bytes;
    return( CORE::length( $self->{_data} ) );
}

# Returns an in-memory filehandle opened for reading
sub open
{
    my $self = shift( @_ );
    # Copy to avoid closing over a reference to internal data
    my $data = $self->{_data};
    # If the scalar has the UTF-8 flag set (wide characters), encode it to a byte string
    # before opening the in-memory filehandle, otherwise Perl will refuse with
    # "Strings with code points over 0xFF may not be mapped into in-memory file handles".
    utf8::encode( $data ) if( utf8::is_utf8( $data ) );
    CORE::open( my $fh, '<', \$data ) ||
        return( $self->error( "Cannot open in-core body for reading: $!" ) );
    return( $fh );
}

sub purge
{
    my $self = shift( @_ );
    $self->{_data} = '';
    return( $self );
}

# Allow direct assignment of data after construction
sub set
{
    my $self = shift( @_ );
    my $data = shift( @_ );
    if( $self->_is_scalar( $data ) )
    {
        $self->{_data} = $$data;
    }
    elsif( !ref( $data ) )
    {
        $self->{_data} = $data;
    }
    else
    {
        return( $self->error( "Data must be a plain scalar or scalar reference." ) );
    }
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Body::InCore - In-Memory Body for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Body::InCore;
    my $body = Mail::Make::Body::InCore->new( "Hello, World!\n" ) ||
        die( Mail::Make::Body::InCore->error );
    my $fh = $body->open || die( $body->error );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

Holds mail body content in memory as a plain Perl scalar. Accepts a plain scalar or a scalar reference at construction time.

=head1 CONSTRUCTOR

=head2 new( $data )

Accepts either a plain scalar or a scalar reference. Returns the object, or sets an error and returns C<undef>.

=head1 METHODS

=head2 as_string

Returns a scalar reference to the internal data.

=head2 is_in_core

Returns true (1).

=head2 length

Returns the byte length of the stored data.

=head2 open

Returns a read-only in-memory filehandle.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make::Body::File>, L<Mail::Make::Body>, L<Mail::Make>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
