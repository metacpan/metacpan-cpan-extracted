##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/Link.pm
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
package HTTP::Promise::Headers::Link;
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
    $self->{anchor} = undef;
    $self->{rel}    = undef;
    $self->{title}  = undef;
    $self->{uri}    = undef;
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $str = shift( @_ );
        return( $self->error( "No value was provided for Link field." ) ) if( !defined( $str ) || !length( "$str" ) );
        my $params = $self->_get_args_as_hash( @_ );
        my $hv = $self->_parse_header_value( $str ) ||
            return( $self->pass_error );
        $hv->params( $params ) if( scalar( keys( %$params ) ) );
        $self->_hv( $hv );
    }
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Link' );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( [qw( rel title title* anchor )] ) ); }

# sub as_string
# {
#     my $self = shift( @_ );
#     my $uri = $self->uri || return( '' );
#     my $rel = $self->rel;
#     return( "<${uri}>; rel=\"${rel}\"" ) if( $rel );
#     return( "<${uri}>" );
# }

sub anchor { return( shift->_set_get_param( anchor => @_ ) ); }

sub link
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $link = shift( @_ );
        $link =~ s/^\<|(?<!\\)\>$//g;
        my $link2 = qq{<${link}>};
        my $hv = $self->_hv;
        if( $hv )
        {
            $hv->value( $link2 );
        }
        else
        {
            $hv = $self->_new_hv( $link2 ) || return( $self->pass_error );
            $self->_hv( $hv );
        }
        return( $link );
    }
    else
    {
        # No header value object, means there is just nothing set yet
        my $hv = $self->_hv || return( '' );
        my $link = $hv->value_data;
        $link =~ s/^\<|(?<!\\)\>$//g;
        return( $link );
    }
}

sub param { return( shift->_set_get_param( @_ ) ); }

sub params { return( shift->_set_get_params( @_ ) ); }

sub rel { return( shift->_set_get_param( rel => @_ ) ); }

sub title
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $title, $lang ) = @_;
        if( !defined( $title ) )
        {
            $self->params->delete( 'title' );
            $self->params->delete( 'title*' );
        }
        else
        {
            $lang //= $self->title_lang;
            if( my $enc = $self->_filename_encode( $title, $lang ) )
            {
                $self->_set_get_param( 'title*' => $enc ) || return( $self->pass_error );
            }
            else
            {
                $self->_set_get_qparam( title => $title );
            }
        }
    }
    else
    {
        my $v = $self->_set_get_qparam( 'title' );
        if( !defined( $v ) || !length( $v ) )
        {
            if( $v = $self->_set_get_param( 'title*' ) )
            {
                my( $f_charset, $f_lang );
                ( $v, $f_charset, $f_lang ) = $self->_filename_decode( $v );
                $self->title_charset( $f_charset );
                $self->title_lang( $f_lang );
            }
        }
        return( $v );
    }
}

sub title_charset
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->error( "Only supported charset is 'utf-8'." ) ) if( lc( $v ) ne 'utf-8' && lc( $v ) ne 'utf8' );
        # Convenience
        $v = 'utf-8' if( lc( $v ) eq 'utf8' );
        $v = uc( $v );
        return( $self->_set_get_scalar_as_object( 'title_charset', $v ) );
    }
    return( $self->_set_get_scalar_as_object( 'title_charset' ) );
}

sub title_lang { return( shift->_set_get_scalar_as_object( 'title_lang', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::Link - Link Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::Link;
    my $link = HTTP::Promise::Headers::Link->new || 
        die( HTTP::Promise::Headers::Link->error, "\n" );
    my $uri = $link->link;
    $link->link( 'https://example.org' );
    $link->rel( 'preconnect' );
    $h->link( "$link" );
    # Link: <https://example.org>; rel="preconnect"
    $link->title( 'Foo' );
    $link->anchor( '#bar' );
    $cd->params( rel => 'preconnect', anchor => 'bar' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The HTTP Link entity-header field provides a means for serializing one or more links in HTTP headers. It is semantically equivalent to the HTML C<link> element.

Example:

    Link: <https://example.com>; rel="preconnect"; title="Foo"; anchor="#bar"

=head1 METHODS

=head2 anchor

Sets or gets the C<anchor> property.

=head2 as_string

Returns a string representation of the C<Link> object.

=head2 rel

Sets or gets the C<relationship> of the C<Link> as a scalar.

=head2 link

Sets or gets an URI. It returns the URI value (not an object).

When you set this value, it will be automatically surrounded by C<< <> >>

=head2 param

Sets or gets an arbitrary C<Link> property.

Note that if you use this, you bypass other specialised method who do some additional processing, so be mindful.

=head2 params

Sets or gets multiple arbitrary C<Link> properties at once.

If called without any arguments, this returns the L<hash object|Module::Generic::Hash> used to store the C<Link> properties.

=head2 title

Without any argument, this returns the string containing the original title of the link. The C<title> is always optional.

If the property C<title*> is set instead, then it will be decoded and used instead, and the value for L</title_charset> and L</title_lang> will be set.

When setting the title value, this takes an optional language iso 639 code (see L<rfc5987|https://tools.ietf.org/html/rfc5987> and L<rfc2231|https://tools.ietf.org/html/rfc2231>).
If the title contains non ascii characters, it will be automatically encoded according to L<rfc5987|https://tools.ietf.org/html/rfc5987>. and the property C<title*> set instead. That property, by rfc standard, takes precedence over the C<title> one.

See L<rfc8288, section 3|https://tools.ietf.org/html/rfc8288#section-3> for more information.

The language provided, if any, will be used then.

For example:

    $h->link( 'https://www.example.com' );
    $h->rel( 'preconnect' );
    $h->title( q{Foo} );
    say "$h";
    # <https://www.example.com>; rel="preconnect"; title="Foo"

    $h->link( 'https://www.example.com' );
    $h->rel( 'previous' );
    $h->title( q{「お早う」小津安二郎} );
    say "$h";
    # https://www.example.com; rel="previous"; title*="UTF-8''%E3%81%8A%E6%97%A9%E3%81%86%E3%80%8D%E5%B0%8F%E6%B4%A5%E5%AE%89%E4%BA%8C%E9%83%8E"
 
    $h->link( 'https://www.example.com' );
    $h->rel( 'previous' );
    $h->title( q{「お早う」小津安二郎}, 'ja-JP' );
    say "$h";
    # https://www.example.com; rel="previous"; title*="UTF-8'ja-JP'%E3%81%8A%E6%97%A9%E3%81%86%E3%80%8D%E5%B0%8F%E6%B4%A5%E5%AE%89%E4%BA%8C%E9%83%8E"

    # Using default value
    $h->title_lang( 'ja-JP' );
    $h->link( 'https://www.example.com' );
    $h->rel( 'previous' );
    $h->title( q{「お早う」小津安二郎}, 'ja-JP' );
    say "$h";
    # https://www.example.com; rel="previous"; title*="UTF-8'ja-JP'%E3%81%8A%E6%97%A9%E3%81%86%E3%80%8D%E5%B0%8F%E6%B4%A5%E5%AE%89%E4%BA%8C%E9%83%8E"

    $headers->header( Link => "$h" );

The C<Link> header value would then contain a property C<title*> (with the trailing wildcard).

=head2 title_charset

Sets or gets the encoded title charset.

This is used when the title contains non-ascii characters, such as Japanese, Korean, or Cyrillic.
Although theoretically one can set any character set, by design this only accepts C<UTF-8> (case insensitive).

This is set automatically when calling L</title>. You actually need to call L</title> first to have a value set.

Returns a L<scalar object|Module::Generic::Scalar> containing the title charset.

=head2 title_lang

Sets or gets the encoded title language. This takes an iso 639 language code (see L<rfc1766|https://tools.ietf.org/html/rfc1766>).

This is set automatically when calling L</title>. You actually need to call L</title> first to have a value set.

Returns a L<scalar object|Module::Generic::Scalar> containing the title language.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc8288, section 3|https://tools.ietf.org/html/rfc8288#section-3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Link>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
