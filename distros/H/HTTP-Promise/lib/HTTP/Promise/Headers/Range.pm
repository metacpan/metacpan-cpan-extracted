##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/Range.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/08
## Modified 2022/05/08
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::Range;
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
    $self->{ranges} = [];
    $self->{unit}   = 'bytes';
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my( $unit, $ref );
        if( $self->_is_array( $this ) )
        {
            $ref = $this;
        }
        else
        {
            return( $self->error( "Bad argument provided '$this'. You can provide either an array reference or a string." ) ) if( ref( $this ) && !overload::Method( $this, '""' ) );
            $this =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
            if( $this =~ s/^([a-zA-Z][a-zA-Z\_]+)[[:blank:]\h]*=[[:blank:]\h]*// )
            {
                $unit = $1;
            }
            $ref = [split( /[[:blank:]\h]*,[[:blank:]\h]*/, "$this" )];
        }
        my $ranges = $self->new_array;
        foreach( @$ref )
        {
            my( $start, $end ) = split( /[[:blank:]\h]*-[[:blank:]\h]*/ );
            $start = undef if( !length( $start ) );
            $end   = undef if( !length( $end ) );
            my $range = HTTP::Promise::Headers::Range::StartEnd->new( $start, $end );
            $ranges->push( $range );
        }
        $self->ranges( $ranges );
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Range' );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    # In the sprintf, we use %s and not %d, because start or end may be undef, and it would inadvertently result in 0
    return( $self->unit->scalar . '=' . $self->ranges->map(sub{ sprintf( '%s-%s', ( $_->start // '' ), ( $_->end // '' ) ); })->join( ', ' )->scalar );
}

sub new_range { HTTP::Promise::Headers::Range::StartEnd->new( @_ ) };

sub ranges { return( shift->_set_get_array_as_object( 'ranges', @_ ) ); }

sub unit { return( shift->_set_get_scalar_as_object( 'unit', @_ ) ); }

{
    package
        HTTP::Promise::Headers::Range::StartEnd;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
    };
    use strict;
    use warnings;
    
    sub init
    {
        my $self = shift( @_ );
        my @args = @_;
        @$self{qw( start end )} = splice( @_, 0, 2 );
        return( $self->SUPER::init( @_ ) );
    }
    
    sub end { return( shift->_set_get_number( 'end', @_ ) ); }
    
    sub start { return( shift->_set_get_number( 'start', @_ ) ); }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::Range - Range Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::Range;
    my $range = HTTP::Promise::Headers::Range->new || 
        die( HTTP::Promise::Headers::Range->error, "\n" );
    $range->unit( 'bytes' ):
    $range->ranges->push( $range->new_range( 200, 1000 ) );
    my $start = $range->ranges->first->start; # 200
    my $end = $range->ranges->first->end; # 1000
    $range->ranges->push( $range->new_range( 1001, 2000 ) );
    say $range->as_string;
    # or
    say "$range";
    # bytes=200-1000, 1001-2000

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The Range HTTP request header indicates the part of a document that the server should return.

Example:

    # Getting multiple ranges
    Range: bytes=200-1000, 2000-6576, 19000-
    # The last 500 bytes
    Range: bytes=0-499, -500

    Range: bytes=200-
    Range: bytes=200-1000
    Range: bytes=200-1000, 1001-2000
    Range: bytes=200-1000, 1001-2000, 2001-3000
    Range: bytes=-4321

=head1 METHODS

=head2 as_string

Returns a string representation of the C<Range> object.

=head2 new_range

Provided with a start and and offset, and this will return a new C<HTTP::Promise::Headers::Range::StartEnd> object.

This object has two methods: C<start> and C<end> each capable of setting or returning its value, which may be C<undef>

=head2 ranges

Sets or gets the L<array object|Module::Generic::Array> that contains all the C<HTTP::Promise::Headers::Range::StartEnd> objects. Thus you can use all the methods from L<Module::Generic::Array> to manipulate the range objects.

=head2 unit

The unit in which ranges are specified. This is usually C<bytes>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc7233, section 3.1|https://tools.ietf.org/html/rfc7233#section-3.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Range>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
