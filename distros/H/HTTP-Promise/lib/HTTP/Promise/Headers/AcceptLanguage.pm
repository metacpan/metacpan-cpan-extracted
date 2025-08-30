##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/AcceptLanguage.pm
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
package HTTP::Promise::Headers::AcceptLanguage;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTTP::Promise' );
    use parent qw( HTTP::Promise::Headers::Accept );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Accept-Language' );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::AcceptLanguage - Accept-Language Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::AcceptLanguage;
    my $ac = HTTP::Promise::Headers::AcceptLanguage->new || 
        die( HTTP::Promise::Headers::AcceptLanguage->error, "\n" );
    my $ac = HTTP::Promise::Headers::AcceptLanguage->new( 'fr-FR, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' ) || 
        die( HTTP::Promise::Headers::AcceptLanguage->error, "\n" );
    $ac->add( fr' );
    $ac->add( 'ja-JP' => 0.7 );
    $h->accept( $ac->as_string ); Accept: fr, ja-JP;q=0.7
    # or
    $h->accept( "$ac" );
    my $qv_elements = $ac->elements;
    my $obj = $ac->get( 'ja-JP' );
    # change the weight
    $obj->value( 0.3 );
    $ac->remove( 'fr' );
    my $sorted_objects = $ac->sort;
    my $asc_sorted = $ac->sort(1);
    # Returns a Module::Generic::Array object
    my $ok = $ac->match( [qw( fr ja-JP en en-GB en-US )] );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its features from L<HTTP::Promise::Headers::Accept>

The following description is taken from Mozilla documentation.

    Accept-Language: da, en-gb;q=0.8, en;q=0.7
    Accept-Language: fr-FR, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5

=head1 METHODS

See L<HTTP::Promise::Headers::Accept>

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

L<HTTP::AcceptLanguage>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
