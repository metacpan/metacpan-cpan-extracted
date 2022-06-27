##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/Generic.pm
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
package HTTP::Promise::Headers::Generic;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION $QV_ELEMENT $QV_VALUE );
    use Encode ();
    use URI::Escape::XS ();
    use Want;
    use overload (
        '""'    => 'as_string',
        'bool'  => sub{1},
        # No fallback on purpose
    );
    # Accept: audio/*; q=0.2, audio/basic
    our $QV_ELEMENT = qr/(?:[^\;\,]+)/;
    our $QV_VALUE   = qr/(?:0(?:\.[0-9]{0,3})?|1(?:\.0{0,3})?)/;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub as_string { return( shift->value ); }

sub field_name { return( shift->_set_get_scalar( '_name', @_ ) ); }

sub uri_escape_utf8 { return( URI::Escape::XS::uri_escape( Encode::encode( 'UTF-8', $_[1] ) ) ); }

# By default and superseded by inheriting classes such as Content-Type that has more
# elaborate value with parameters
sub value { return( shift->_set_get_scalar( '_value', @_ ) ); }

sub _field_name { return( shift->_set_get_scalar( '_name', @_ ) ); }

# rfc2231 <https://tools.ietf.org/html/rfc2231>
sub _filename_decode
{
    my $self = shift( @_ );
    my $fname = shift( @_ );
    $self->_load_class( 'HTTP::Promise::Headers' ) || return( $self->pass_error );
    my( $new_fname, $charset, $lang ) = HTTP::Promise::Headers->decode_filename( $fname );
    if( defined( $new_fname ) )
    {
        $fname = $new_fname;
    }
    return( wantarray() ? ( $fname, $charset, $lang ) : $fname );
}

# rfc2231 <https://tools.ietf.org/html/rfc2231>
sub _filename_encode
{
    my $self = shift( @_ );
    my $fname = shift( @_ );
    my $lang = shift( @_ );
    if( $fname =~ /[^\x00-\x7f]/ )
    {
        $lang = '' if( !defined( $lang ) );
        return( sprintf( "UTF-8'${lang}'%s", $self->uri_escape_utf8( $fname ) ) );
    }
    # Nothing to be done. We return undef on purpose to indicate nothing was done
    return;
}

sub _hv { return( shift->_set_get_object_without_init( '_hv', 'Module::Generic::HeaderValue', @_ ) ); }

sub _hv_as_string
{
    my $self = shift( @_ );
    my $hv = $self->_hv;
    return( '' ) if( !$hv );
    return( $hv->as_string( @_ ) );
}

sub _get_header_value_object
{
    my $self = shift( @_ );
    $self->_load_class( 'Module::Generic::HeaderValue' ) ||
        return( $self->pass_error );
    my $hv = Module::Generic::HeaderValue->new( shift( @_ ) ) ||
        return( $self->pass_error( Module::Generic::HeaderValue->error ) );
    return( $hv );
}

sub _make_boundary { return( Data::UUID->new->create_str ); }

sub _new_hv
{
    my $self = shift( @_ );
    $self->_load_class( 'Module::Generic::HeaderValue' ) || return( $self->pass_error );
    return( Module::Generic::HeaderValue->new( @_ ) );
}

sub _new_qv_object
{
    my $self = shift( @_ );
    my $o = HTTP::Promise::Field::QualityValue->new( @_ );
    return( $self->pass_error( HTTP::Promise::Field::QualityValue->error ) ) if( !defined( $o ) );
    return( $o );
}

sub _parse_header_value
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "No header value was provided to parse." ) ) if( !defined( $this ) || !length( "$this" ) );
    $self->_load_class( 'Module::Generic::HeaderValue' ) ||
        return( $self->pass_error );
    my $hv = Module::Generic::HeaderValue->new_from_header( $this, @_ ) ||
        return( $self->pass_error( Module::Generic::HeaderValue->error ) );
    return( $hv );
}

# rfc7231, section 5.3.1
# <https://tools.ietf.org/html/rfc7231#section-5.3.1>
sub _parse_quality_value
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    return( $self->error( "No header value was provided to parse." ) ) if( !defined( $str ) || !length( "$str" ) );
    # No blank
    $str =~ s/[[:blank:]\h]]+//g;
    my $choices = $self->new_array;
    # Credits: HTTP::AcceptLanguage from Kazuhiro Osawa
    for my $def ( split( /,[[:blank:]\h]*/, $str ) )
    {
        my( $element, $quality ) = $def =~ /\A($QV_ELEMENT)(?:;[[:blank:]\h]*[qQ]=($QV_VALUE))?\z/;
        # rfc7231, section 5.3.1:
        # "If no "q" parameter is present, the default weight is 1."
        # rfc7231, section 5.3.5
        # "no value is the same as q=1"
        # $quality = 1 unless( defined( $quality ) );
        # next unless( $element && $quality > 0 );
        next unless( $element );
        my $qv = $self->_new_qv_object( $element => $quality );
        $choices->push( $qv );
    }
    return( $choices );
}

sub _qstring_join
{
    my $self = shift( @_ );
    my @parts = ();
    foreach my $s ( @_ )
    {
        $s =~ s/^"//;
        $s =~ s/(?!\\)"$//;
        $s =~ s/(?!\\)\"/\\"/g;
        push( @parts, qq{"${s}"} );
    }
    return( join( ', ', @parts ) );
}

# Returns an array of tokens that were initially surrounded by double quotes, and
# separated by comma even if they contained double quotes inside.
# Example for Clear-Site-Data header field:
# "cache", "cookies", "storage", "executionContexts"
# "cache\"", "oh "la" la", "storage\", \"", "executionContexts"
sub _qstring_split
{
    my $self = shift( @_ );
    my $str = shift( @_ );
    my @parts = split( /(?<=(?<!\\)\")[[:blank:]\h]*,[[:blank:]\h]*(?=\")/, $str );
    for( @parts )
    {
        #substr( $_, 0, 1, '' );
        #substr( $_, -1, 1, '' );
        # s/^"|"$//g;
        s/^"//;
        s/"$//;
    }
    return( @parts );
}

sub _qv_add
{
    my $self = shift( @_ );
    my( $elem, $val ) = @_;
    my $qv = HTTP::Promise::Field::QualityValue->new( $elem => $val ) ||
        return( $self->pass_error( HTTP::Promise::Field::QualityValue->error ) );
    $self->elements->push( $qv );
    return( $qv );
}

sub _qv_as_string
{
    my $self = shift( @_ );
    my $all = $self->elements;
    return( '' ) if( $all->is_empty );
    my $res = $all->map(sub{ $_->as_string });
    return( $res->join( ', ' )->scalar );
}

sub _qv_elements { return( shift->_set_get_object_array_object( '_qv_elements', 'HTTP::Promise::Field::QualityValue', @_ ) ); }

sub _qv_get
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "No a property name to get was provided." ) ) if( !defined( $this ) || !length( "$this" ) );
    my $all = $self->elements;
    if( $self->_is_a( $this => 'HTTP::Promise::Field::QualityValue' ) )
    {
        my $pos = $all->pos( $this );
        return( $all->[$pos] ) if( defined( $pos ) );
    }
    else
    {
        foreach( @$all )
        {
            return( $_ ) if( $_->element eq $this );
        }
    }
    return( '' );
}

sub _qv_match
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( '' ) if( !defined( $this ) || !length( "$this" ) );
    $this = [split( /(?:[[:blank:]]+|[[:blank:]]*\,[[:blank:]]*)/, "$this" )] if( !$self->_is_array( $this ) && ( !ref( $this ) || overload::Method( $this => '""' ) ) );
    return( $self->error( "Invalid argument provided. Provide either an array reference or a string or something that stringifies." ) ) if( !$self->_is_array( $this ) );
    my $ordered = [map( lc( $_ ), @$this )];
    return( '' ) if( !scalar( @$ordered ) );
    my $acceptables = $self->can( 'sort' ) ? $self->sort : $self->_qv_sort;
    my $ok = $self->new_array;
    my $seen = {};
    foreach my $e ( @$acceptables )
    {
        my $e_lc = $e->element->lc;
        if( $e->element->index( '*' ) != -1 )
        {
            my $wildcard_ok = $self->_qv_match_wildcard( $e_lc => $ordered, $this );
            return( $self->pass_error ) if( !defined( $wildcard_ok ) );
            $ok->push( $wildcard_ok->list ) if( !$wildcard_ok->is_empty );
        }
        else
        {
            for( my $i = 0; $i < scalar( @$ordered ); $i++ )
            {
                if( $e_lc eq $ordered->[$i] )
                {
                    # We'll return the caller's original value, not the lowercase one we use for comparison
                    $ok->push( $this->[$i] );
                }
            }
        }
    }
    return( $ok->unique );
}

# Works for language and content-type and content-encoding
sub _qv_match_wildcard
{
    my $self = shift( @_ );
    # $proposals contain the value offered in lower case, whereas $original contains
    # the original value and we return our value from there. Both $proposals and $original
    # are of the same size.
    my( $acceptable, $proposals, $original, $seen ) = @_;
    return( $self->error( "Bad arguments. Usage: \$h->_qv_match_wildcard( \$acceptable, \$proposals, \$original )" ) ) unless( @_ == 3 );
    return( $self->error( "This is not a wildcard acceptable value." ) ) if( $acceptable->index( '*' ) == -1 );
    return( $self->error( "Proposed values must be an array reference." ) ) unless( $self->_is_array( $proposals ) );
    return( $self->error( "Original array of proposed values must be an array reference." ) ) unless( $self->_is_array( $original ) );
    my $ok = $self->new_array;
    if( $acceptable->index( '/' ) != -1 )
    {
        my( $main, $sub ) = $acceptable->element->split( qr/\// );
        for( my $i = 0; $i < scalar( @$proposals ); $i++ )
        {
            my $supported = $proposals->[$i];
            my( $this_main, $this_sub ) = split( /\//, "$supported", 2 );
            if( $main eq '*' )
            {
                if( $sub eq '*' )
                {
                    $ok->push( $original->[$i] );
                }
                else
                {
                    $ok->push( $original->[$i] ) if( $this_sub eq $sub );
                }
            }
            elsif( $main eq $this_main )
            {
                if( $sub eq '*' )
                {
                    $ok->push( $original->[$i] );
                }
                else
                {
                    $ok->push( $original->[$i] ) if( $this_sub eq $sub );
                }
            }
        }
    }
    # simply return the proposal value since anything goes
    else
    {
        $ok->push( $original->[0] );
    }
    return( $ok );
}

sub _qv_remove
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    my $all = $self->elements;
    if( $self->_is_a( $this => 'HTTP::Promise::Field::QualityValue' ) )
    {
        return( $all->delete( $this ) );
    }
    else
    {
        my $e;
        for( my $i = 0; $i < scalar( @$all ); $i++ )
        {
            if( $all->[$i]->element eq "$this" )
            {
                $e = $all->splice( $i, 1 );
                last;
            }
        }
        return( $e );
    }
}

sub _qv_sort
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{asc} = 0 if( !exists( $opts->{asc} ) );
    my $all = $self->elements;
    my $sorted = $opts->{asc}
        ? $all->sort(sub{ ( $_[0]->value // 1 ) <=> ( $_[1]->value // 1 ) })
        : $all->sort(sub{ ( $_[1]->value // 1 ) <=> ( $_[0]->value // 1 ) });
    $self->elements( $sorted );
    return( $sorted );
}

sub _set_get_param_boolean
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    my $hv = $self->_hv || return( $self->error( "Header value object could not be found!" ) );
    if( @_ )
    {
        my $v = shift( @_ );
        if( $v )
        {
            $hv->param( $name => undef );
        }
        else
        {
            $hv->params->delete( $name );
        }
    }
    return( $hv->param( $name ) );
}

sub _set_get_param
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    my $hv = $self->_hv;
    # If the HeaderValue object is not een set, and the caller just want to retrieve the 
    # value of a property, we return an empty string (undef is for errors)
    return( '' ) if( !scalar( @_ ) && !$hv );
    return( $self->error( "Header value object (Module::Generic::HeaderValue) could not be found!" ) ) if( !$hv );
    if( @_ )
    {
        $hv->param( $name => shift( @_ ) );
    }
    return( $hv->param( $name ) );
}

sub _set_get_params
{
    my $self = shift( @_ );
    my $hv = $self->_hv || return( $self->error( "Header value object could not be found!" ) );
    my $params = $hv->params;
    if( @_ )
    {
        while( my( $n, $v ) = splice( @_, 0, 2 ) )
        {
            $params->set( $n => $v );
        }
    }
    else
    {
        return( $params );
    }
}

sub _set_get_properties_as_string
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $sep  = $opts->{separator} || $opts->{sep} || ',';
    my $eq   = $opts->{equal} || '=';
    my $params = $self->params;
    my $props = $self->properties;
    my $quotes = {};
    $quotes = $self->_needs_quotes if( $self->can( '_needs_quotes' ) );
    my @res = ();
    no overloading '""';
    foreach( @$params )
    {
        if( !exists( $props->{ $_ } ) )
        {
            # warnings::warn( "Property is in our stack, but not in our repository of properties, skipping.\n" ) if( warnings::enabled( ref( $self ) ) );
            # warn( "Property is in our stack, but not in our repository of properties, skipping.\n" ) if( $self->_warnings_is_enabled );
            warn( "Property \"$_\" is in our stack, but not in our repository of properties, skipping.\n" );
            next;
        }
        # If the property exists in our repo, but has no value it is a boolean
        push( @res, defined( $props->{ $_ } ) ? sprintf( "$_${eq}%s", ( $quotes->{ $_ } ? '"' : '' ) . $props->{ $_ } . ( $quotes->{ $_ } ? '"' : '' ) ) : $_ );
    }
    return( join( "${sep} ", @res ) );
}

# Used by Cache-Control
sub _set_get_property_boolean
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    my $params = $self->params;
    my $props = $self->properties;
    my $pos = $params->pos( $prop );
    if( @_ )
    {
        my $bool = shift( @_ );
        if( defined( $pos ) )
        {
            if( defined( $bool ) && $bool )
            {
                # Nothing to do, it is already there
                # Making sure we have it in our properties hash as well
                $props->{ $prop } = undef;
            }
            # Undefined or false properties get removed
            else
            {
                $params->splice( $pos, 1 );
                $props->delete( $prop );
            }
        }
        # Not there yet
        else
        {
            if( defined( $bool ) && $bool )
            {
                $params->push( $prop );
                $props->{ $prop } = undef;
            }
            # Nothing to do, it is not there yet
            # Still make sure it is removed from the properties hash as well
            else
            {
                $props->delete( $prop );
            }
        }
        return( $bool );
    }
    else
    {
        return( defined( $pos ) ? 1 : 0 );
    }
}

# Used by Cache-Control, Expect-CT
sub _set_get_property_number
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    if( @_ )
    {
        my $v = shift( @_ );
        return( $self->error( "The value provided for property \"${prop}\" is not a number." ) ) if( defined( $v ) && !$self->_is_integer( $v ) );
        return( $self->_set_get_property_value( $prop => $v ) );
    }
    return( $self->_set_get_property_value( $prop ) );
}

# Used by Expect-CT
sub _set_get_property_value
{
    my $self = shift( @_ );
    my $prop = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{needs_quotes} //= 0;
    $opts->{maybe_boolean} //= 0;
    my $params = $self->params;
    my $props = $self->properties;
    my $pos = $params->pos( $prop );
    if( @_ )
    {
        my $v = shift( @_ );
        if( !defined( $v ) )
        {
            $self->params->splice( $pos, 1 ) if( defined( $pos ) );
            return( $self->properties->delete( $prop ) );
        }
        
        # Not there yet, add the value
        if( !defined( $pos ) )
        {
            $params->push( $prop ) if( !$opts->{maybe_boolean} || ( $opts->{maybe_boolean} && $v ) );
            if( exists( $opts->{maybe_boolean} ) && $opts->{maybe_boolean} )
            { 
                if( $v == 1 )
                {
                    $props->{ $prop } = undef;
                }
                elsif( !$v )
                {
                    $props->delete( $prop );
                }
                else
                {
                    $props->{ $prop } = $v;
                }
            }
            else
            {
                $props->{ $prop } = $v;
            }
        }
        else
        {
            if( exists( $opts->{maybe_boolean} ) && $opts->{maybe_boolean} )
            {
                if( !$v )
                {
                    $params->splice( $pos, 1 );
                    $props->delete( $prop );
                }
                elsif( $v == 1 )
                {
                    $props->{ $prop } = undef;
                }
                else
                {
                    $props->{ $prop } = $v;
                }
            }
            else
            {
                $props->{ $prop } = $v;
            }
        }
        # Used for non-standard properties during stringification
        if( $opts->{needs_quotes} && $self->can( '_needs_quotes' ) )
        {
            $self->_needs_quotes->set( $prop => 1 );
        }
        return( $v );
    }
    else
    {
        if( defined( $pos ) )
        {
            return(
                $opts->{maybe_boolean}
                    ? defined( $pos ) ? 1 : 0
                    : $props->{ $prop }
            );
        }
        return( '' );
    }
}

# Same as _set_get_param but with surrounding double quotes
sub _set_get_qparam
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    my $hv = $self->_hv || return( $self->error( "Header value object could not be found!" ) );
    my $v;
    if( @_ )
    {
        $v = shift( @_ );
        $v =~ s/^\"//;
        $v =~ s/(?<!\\)\"$//;
        $hv->param( $name => qq{"${v}"} );
    }
    else
    {
        $v = $hv->param( $name );
        return( '' ) if( !defined( $v ) || !length( "$v" ) );
        $v =~ s/^\"//;
        $v =~ s/(?<!\\)\"$//;
    }
    return( $v );
}

sub _set_get_value
{
    my $self = shift( @_ );
    my $hv = $self->_hv;
    if( @_ )
    {
        $hv->value( shift( @_ ) );
    }
    return( $hv->value_data );
}

# NOTE: HTTP::Promise::Field::QualityValue class
{
    package
        HTTP::Promise::Field::QualityValue;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        use overload (
            '""'    => 'as_string',
            'bool'  => sub{1},
        );
    };
    
    sub as_string
    {
        my $self = shift( @_ );
        my $elem = $self->element;
        my $val = $self->value;
        return( $elem ) if( !defined( $val ) || !length( "${val}" ) );
        return( "${elem};q=${val}" );
    }
    
    sub init
    {
        my $self = shift( @_ );
        my $elem = shift( @_ );
        return( $self->error( "No element was provided for this quality value." ) ) if( !defined( $elem ) || !length( "$elem" ) );
        my $val  = shift( @_ );
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        $self->element( $elem );
        $self->value( $val );
        return( $self );
    }
    
    sub element { return( shift->_set_get_scalar_as_object( 'element', @_ ) ); }
    
    sub value { return( shift->_set_get_number( 'value', @_ ) ); }
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::Generic - Generic HTTP Header Class

=head1 SYNOPSIS

    package HTTP::Promise::Header::MyHeader;
    use strict;
    use warnings;
    use parent qw( HTTP::Promise::Headers::Generic );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is a generic module to be inherited by HTTP header modules. See for example: L<HTTP::Promise::Headers::AcceptEncoding>, L<HTTP::Promise::Headers::AcceptLanguage>, L<HTTP::Promise::Headers::Accept>, L<HTTP::Promise::Headers::AltSvc>, L<HTTP::Promise::Headers::CacheControl>, L<HTTP::Promise::Headers::ClearSiteData>, L<HTTP::Promise::Headers::ContentDisposition>, L<HTTP::Promise::Headers::ContentRange>, L<HTTP::Promise::Headers::ContentSecurityPolicy>, L<HTTP::Promise::Headers::ContentSecurityPolicyReportOnly>, L<HTTP::Promise::Headers::ContentType>, L<HTTP::Promise::Headers::Cookie>, L<HTTP::Promise::Headers::ExpectCT>, L<HTTP::Promise::Headers::Forwarded>, L<HTTP::Promise::Headers::Generic>, L<HTTP::Promise::Headers::KeepAlive>, L<HTTP::Promise::Headers::Link>, L<HTTP::Promise::Headers::Range>, L<HTTP::Promise::Headers::ServerTiming>, L<HTTP::Promise::Headers::StrictTransportSecurity>, L<HTTP::Promise::Headers::TE>

=head1 METHODS

=head2 as_string

Return a string representation of this header field object.

=head2 field_name

Sets or gets the object headers field name

=head2 uri_escape_utf8

Provided with some string and this returns the URI-escaped version of this using L<URI::Escape::XS>

=head2 value

By default and superseded by inheriting classes such as Content-Type that has more elaborate value with parameters

=head1 PRIVATE METHODS

=head2 _filename_decode

Provided with a filename, and this will decode it, if necessary, by calling L<HTTP::Promise::Headers/decode_filename>

It returns in list context the decoded filename, the character-set and language used and in scalar context the decoded filename.

If the filename did not need to be decoded, it will return the filename untouched, so this is quite safe to use.

See L<rfc2231|https://tools.ietf.org/html/rfc2231>

=head2 _filename_encode

Provided with a filename, and an optional language, and this will encode it, if necessary, following the L<rfc2231|https://tools.ietf.org/html/rfc2231>

If the filename did not need to be encoded, it returns C<undef>, so be sure to check for the return value.

See L<rfc2231|https://tools.ietf.org/html/rfc2231>

=head2 _hv

Sets or gets the L<header value object|Module::Generic::HeaderValue>

=head2 _hv_as_string

Returns the L<header value object|Module::Generic::HeaderValue> as a string, if a header value object is set, or an empty string otherwise.

=head2 _get_header_value_object

This instantiates a new L<header value object|Module::Generic::HeaderValue>, passing it whatever arguments were provided, and return the new object.

=head2 _make_boundary

Returns a new boundary using L<Data::UUID>

=head2 _new_hv

Does the same thing as L</_get_header_value_object>

=head2 _new_qv_object

This instantiates a new quality value object using C<HTTP::Promise::Field::QualityValue>, passing it whatever arguments were provided, and return the new object.

=head2 _parse_header_value

Provided with a string, and this instantiates a new L<header value object|Module::Generic::HeaderValue>, by calling L<Module::Generic::HeaderValue/new_from_header> passing it the string and any other arguments that were provided, and return the new object.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _parse_quality_value

Provided with a string representing a quality value, and this will parse it and return a new L<array object|Module::Generic::Array>

See L<rfc7231, section 5.3.1|https://tools.ietf.org/html/rfc7231#section-5.3.1>

=head2 _qstring_join

Provided with a list of strings and this will ensure any special characters are escaped before returning them as one string separated by comma.

See also L</_qstring_split>

=head2 _qstring_split

Provided with a string, and this will split it by comma, mindful of any special characters.

It returns an array of the parts split.

=head2 _qv_add

Provided with an element and its value, and this will instantiate a new C<HTTP::Promise::Field::QualityValue> object and add it to the list of objects contained with the method C<elements> (implemented in each specific header module)

=head2 _qv_as_string

This takes the list of all elements contained with the method C<elements> (implemented in each specific header module) and returns them as a string separated by comma.

=head2 _qv_elements

Sets or gets the L<array object|Module::Generic::Array> containing the list of quality values.

=head2 _qv_get

Provided with a quality value element, and this returns its corresponding object if it exists, or an empty string otherwise.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _qv_match

Provided with a string, and this returns an L<array object|Module::Generic::Array> of matching quality value objects in their order of preference.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _qv_match_wildcard

This method is used to do the actual work of matching a requested value such as C<fr-FR> or <text/html> depending on the type of header, against the ones announced in the header.

For example:

    Accept: image/*
    Accept: text/html
    Accept: */*
    Accept: text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, */*;q=0.8

    Accept-Encoding: gzip

    Accept-Encoding: deflate, gzip;q=1.0, *;q=0.5

    Accept-Language: fr-FR, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5


This takes an "acceptable" L<scalar object|Module::Generic::Scalar>, an L<array object|Module::Generic::Array> of proposed quality-value objects, and an L<array object|Module::Generic::Array> of original proposed value, and possibly an hash reference of already seen object address.

It returns an L<array object|Module::Generic::Array> of matching quality-value objects.

=head2 _qv_remove

Provided with a quality-value string or object, and this will remove it from the list of elements.

It returns the element removed, or upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _qv_sort

This takes an optional hash or hash reference of options and returns an L<array object|Module::Generic::Array> of sorted element by their quality-value.

Supported options are:

=over 4

=item * C<asc>

Boolean. If true, the elements will be sorted in their ascending order, otherwise in their descending order.

=back

=head2 _set_get_param_boolean

In retrieval mode, this takes a header value parameter, and this returns its value.

In assignment mode, this takes a header value parameter, and a value, possibly C<undef> and assign it to the given parameter.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _set_get_param

In retrieval mode, this takes a header value parameter, and it returns its corresponding value.

In assignment mode, this takes a header value parameter, and a value and assign it.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _set_get_params

This takes a list of header-value parameter and their corresponding value and set them.

If no argument is provided, this returns the L<array object|Module::Generic::Array> containing all the header-value parameters.

=head2 _set_get_properties_as_string

This takes an hash or hash reference of options and returns the header-value parameters as a regular string.

Supported options are:

=over 4

=item * C<equal>

=item * C<separator> or C<sep>

=back

=head2 _set_get_property_boolean

This sets or gets a boolean value for the given header-value property.

It returns the boolean value for the given property.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _set_get_property_number

This sets or gets a number for the given header-value property.

It returns the number value for the given property.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _set_get_property_value

This sets or gets a value for the given header-value property.

It returns the value for the given property.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _set_get_qparam

Sets or gets a quality-value parameter. If a value is provided, any double quote found at the bginning or end are removed.

It returns the current value.

Upon error, this sets an L<error|Module::Generic/error> and returns C<undef>

=head2 _set_get_value

This sets or gets a header main value.

For example C<text/html> in C<text/html; charset=utf-8>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
