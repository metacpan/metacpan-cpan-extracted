##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/AcceptEncoding.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/06
## Modified 2022/05/06
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::AcceptEncoding;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Headers::Accept );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Accept-Encoding' );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::AcceptEncoding - Accept Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::AcceptEncoding;
    my $ac = HTTP::Promise::Headers::AcceptEncoding->new || 
        die( HTTP::Promise::Headers::AcceptEncoding->error, "\n" );
    my $ac = HTTP::Promise::Headers::AcceptEncoding->new( 'deflate, gzip;q=1.0, *;q=0.5' ) || 
        die( HTTP::Promise::Headers::AcceptEncoding->error, "\n" );
    $ac->add( 'br' );
    $ac->add( 'gzip' => 0.7 );
    $h->accept( $ac->as_string ); Accept: br, gzip;q=0.7
    # or
    $h->accept( "$ac" );
    my $qv_elements = $ac->elements;
    my $obj = $ac->get( 'br' );
    # change the weight
    $obj->value( 0.3 );
    $ac->remove( 'br' );
    my $sorted_objects = $ac->sort;
    my $asc_sorted = $ac->sort(1);
    # Returns a Module::Generic::Array object
    my $ok = $ac->match( [qw( br gzip )] );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its features and methods from L<HTTP::Promise::Headers::Accept>

The following description is taken from Mozilla documentation.

    Accept-Encoding: gzip
    Accept-Encoding: compress
    Accept-Encoding: deflate
    Accept-Encoding: br
    Accept-Encoding: identity
    Accept-Encoding: *

    // Multiple algorithms, weighted with the quality value syntax:
    Accept-Encoding: deflate, gzip;q=1.0, *;q=0.5
    Accept-Encoding: br;q=1.0, gzip;q=0.8, *;q=0.1
    Accept-Encoding: gzip, compress, br

=head1 METHODS

See L<HTTP::Promise::Headers::Accept>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
