##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ContentRange.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/07
## Modified 2022/05/07
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::ContentRange;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Headers::Generic );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{range_end}      = undef;
    $self->{range_start}    = undef;
    $self->{size}           = undef;
    $self->{unit}           = undef;
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $str = shift( @_ );
        if( $str =~ m,^(?<unit>\S+)[[:blank:]]+(?:(?:(?<start>\d+)-(?<end>\d+))|\*)/(?<size>\d+|\*), )
        {
            $self->unit( $+{unit} );
            $self->range_start( $+{start} ) if( defined( $+{start} ) && length( $+{start} ) );
            $self->range_end( $+{end} ) if( defined( $+{end} ) && length( $+{end} ) );
            $self->size( $+{size} ) if( defined( $+{size} ) && length( $+{size} ) );
        }
        else
        {
            return( $self->error( "Unsupported Content-Range value format '$str'." ) );
        }
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Content-Range' );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $unit = $self->unit || 'bytes';
    my $start = $self->range_start;
    my $end   = $self->range_end;
    my $size = $self->size;
    my @parts = ();
    if( defined( $start ) || defined( $end ) )
    {
        if( $start eq '*' && $end eq '*' )
        {
            push( @parts, '*' );
        }
        else
        {
            $start //= '*';
            $end   //= '*';
            push( @parts, "${start}-${end}" );
        }
    }
    else
    {
        push( @parts, '*' );
    }
    push( @parts, defined( $size ) ? $size : '*' );
    return( join( ' ', $unit, join( '/', @parts ) ) );
}

sub range_end { return( shift->_set_get_scalar_as_object( 'range_end', @_ ) ); }

sub range_start { return( shift->_set_get_scalar_as_object( 'range_start', @_ ) ); }

sub size { return( shift->_set_get_scalar_as_object( 'size', @_ ) ); }

sub start_end
{
    my $self = shift( @_ );
    my( $start, $end ) = @_;
    $self->range_start( $start );
    $self->range_end( $end // $start );
    return( $self );
}

sub unit { return( shift->_set_get_scalar_as_object( 'unit', @_ ) ); }

sub _set_get_number_or_wildcard
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || return( $self->error( "No property name was provided." ) );
    if( @_ )
    {
        my $v = shift( @_ );
        if( defined( $v ) )
        {
            return( $self->error( "Value provided for property \"${prop}\" is invalid. I was expecting either an integer or a wildcard." ) ) if( $v !~ /^\d+|\*$/ );
        }
        return( $self->_set_get_scalar_as_object( $prop => $v ) );
    }
    return( $self->_set_get_scalar_as_object( $prop ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ContentRange - Content-Range Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ContentRange;
    my $range = HTTP::Promise::Headers::ContentRange->new || 
        die( HTTP::Promise::Headers::ContentRange->error, "\n" );
    $range->unit( 'bytes' ):
    $range->range_start(500);
    $range->range_end(1000);
    $range->size(2048);
    say $range->as_string;
    # or
    say "$range";

    # 416 Range Not Satisfiable
    # <https://tools.ietf.org/html/rfc7233#section-4.4>
    $range->start_end( undef );
    $range->size(2048);
    say "$range";
    # bytes */2048

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following description is taken from Mozilla documentation.

    Content-Range: bytes 200-1000/67589
    # When the complete range is unknown:
    Content-Range: bytes 42-1233/*

    # The first 500 bytes:
    Content-Range: bytes 0-499/1234
    # The second 500 bytes:
    Content-Range: bytes 500-999/1234
    # All except for the first 500 bytes:
    Content-Range: bytes 500-1233/1234
    # The last 500 bytes:
    Content-Range: bytes 734-1233/1234
    # Unsatisfiable range value
    Content-Range: bytes */1234

=head1 METHODS

=head2 as_string

Returns a string representation of the object.

If both C<range-start> and C<range-end> properties are C<undef>, they will be replaced by a C<*> (wildcard)

If C<size> property is C<undef> it will be replaced by a C<*> (wildcard)

=head2 range_end

An integer in the given unit indicating the end position (zero-indexed & inclusive) of the requested range.

=head2 range_start

An integer in the given unit indicating the start position (zero-indexed & inclusive) of the request range.

=head2 size

The total length of the document (or '*' if unknown).

=head2 start_end

This is a convenience method to set both the C<range-start> and C<range-end> property.

=head2 unit

The unit in which ranges are specified. This is usually C<bytes>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

C<Accept-Range>, C<If-Range>, C<Range>

See L<rfc7233, section 4.2|https://tools.ietf.org/html/rfc7233#section-4.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Range>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
