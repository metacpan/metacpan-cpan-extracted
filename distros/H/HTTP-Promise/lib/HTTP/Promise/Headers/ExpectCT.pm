##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ExpectCT.pm
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
package HTTP::Promise::Headers::ExpectCT;
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
    $self->{params} = [];
    $self->{properties} = {};
    $self->{_needs_quotes} = { 'report-uri' => 1 };
    # Works like HTTP::Promise::Headers::CacheControl
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->_is_array( $this ) ? $this : [split( /[[:blank:]\h]*\,[[:blank:]\h]*/, "$this" )];
        my $params = $self->params;
        my $props = $self->properties;
        foreach my $pair ( @$ref )
        {
            my( $prop, $val ) = split( /=/, $pair, 2 );
            $val =~ s/^"|(?<!\\)"$//g if( defined( $val ) );
            $props->{ $prop } = $val;
            $params->push( $prop );
        }
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Expect-CT' );
    return( $self );
}

sub as_string { return( shift->_set_get_properties_as_string ); }

sub enforce { return( shift->_set_get_property_boolean( 'enforce', @_ ) ); }

sub max_age { return( shift->_set_get_property_number( 'max-age', @_ ) ); }

sub params { return( shift->_set_get_array_as_object( 'params', @_ ) ); }

sub properties { return( shift->_set_get_hash_as_mix_object( 'properties', @_ ) ); }

sub report_uri { return( shift->_set_get_property_value( 'report-uri', @_, ( @_ > 1 ? { needs_quotes => 1 } : () ) ) ); }

sub _needs_quotes { return( shift->_set_get_hash_as_mix_object( '_needs_quotes', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ExpectCT - Expect-CT Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ExpectCT;
    my $expect = HTTP::Promise::Headers::ExpectCT->new || 
        die( HTTP::Promise::Headers::ExpectCT->error, "\n" );
    $h->max_age(86400);
    $h->report_uri( 'https://foo.example.com/report' );
    $h->enforce(1);

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The C<Expect-CT> header lets sites opt in to reporting and/or enforcement of Certificate Transparency requirements, to prevent the use of misissued certificates for that site from going unnoticed.

For example:

    Expect-CT: max-age=86400, enforce, report-uri="https://foo.example.com/report"

=head1 METHODS

=head2 as_string

Returns a string representation of the C<Expect-CT> object.

=head2 enforce

This is optional.

This is a boolean property and takes a true or false value. If true, the property is set, and if false it is removed.

Signals to the user agent that compliance with the Certificate Transparency policy should be enforced (rather than only reporting compliance) and that the user agent should refuse future connections that violate its Certificate Transparency policy.

=head2 max_age

The number of seconds after reception of the Expect-CT header field during which the user agent should regard the host of the received message as a known Expect-CT host.

=head2 params

Returns the L<array object|Module::Generic::Array> used by this header field object containing all the properties set.

=head2 properties

Returns the L<hash object|Module::Generic::hash> used as a repository of properties.

=head2 report_uri

This is optional.

This takes an URI as a value. The URI where the user agent should report C<Expect-CT> failures.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc draft|https://tools.ietf.org/html/draft-ietf-httpbis-expect-ct-08> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Expect-CT>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
