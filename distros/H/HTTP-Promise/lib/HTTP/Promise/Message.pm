##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Message.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/21
## Modified 2022/03/21
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Message;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $DEBUG $ERROR $AUTOLOAD $CRLF $HTTP_VERSION );
    use Data::UUID;
    require HTTP::Promise::Headers;
    use Nice::Try;
    use URI;
    our $CRLF = "\015\012";
    # HTTP/1.0, HTTP/1.1, HTTP/2
    our $HTTP_VERSION  = qr/(?<http_protocol>HTTP\/(?<http_version>(?<http_vers_major>[0-9])(?:\.(?<http_vers_minor>[0-9]))?))/;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my( $headers, $content );
    if( @_ == 1 && ref( $_[0] ) eq 'HASH' )
    {
        my $opts = shift( @_ );
        ( $headers, $content ) = CORE::delete( @$opts{qw( headers content )} );
        @_ = %$opts;
    }
    elsif( @_ >= 1 &&
           ( $self->_is_array( $_[0] ) || 
             $self->_is_a( $_[0], 'HTTP::Promise::Headers' ) || 
             $self->_is_a( $_[0], 'HTTP::Headers' ) ||
             # HTTP::Promise::Message->new( undef, "some\ncontent" );
             !defined( $_[0] )
           ) )
    {
        $headers = shift( @_ );
        # Odd number of arguments and following argument is not an hash; or
        # next argument is an hash
        # this means the next parameter is the content
        # $r->init( $headers, $content, name1 => value1, name2 => value2 );
        # $r->init( $headers, $content, { name1 => value1, name2 => value2 } );
        # First value must be either not a ref or a ref that stringifies
        if( ( !ref( $_[0] ) || 
              ( ref( $_[0] ) && overload::Method( $_[0] => '""' ) ) ||
              ( $self->_is_a( $_[0] => 'HTTP::Promise::Body' ) ) ||
              ( $self->_is_a( $_[0] => 'HTTP::Promise::Body::Form' ) )
            ) &&
            (
                @_ == 1 ||
                # Odd number of parameters and the second one is not an hash ref:
                # e.g.: $content, name1 => value1, name2 => value2
                ( @_ > 2 && ( @_ % 2 ) && ref( $_[1] ) ne 'HASH' ) || 
                # 2 params left and the second one is an hash reference:
                # e.g.: $content, { name1 => value1, name2 => value2 }
                ( @_ == 2 && ref( $_[1] ) eq 'HASH' )
            )
        )
        {
            $content = shift( @_ );
        }
    }
    elsif( @_ && ref( $_[0] ) ne 'HASH' )
    {
        return( $self->error( "Bad header argument: ", $_[0] ) );
    }
    
    if( defined( $headers ) )
    {
        if( $self->_is_a( $headers, 'HTTP::Promise::Headers' ) || $self->_is_a( $headers, 'HTTP::Headers' ) )
        {
            $headers = $headers->clone;
            $headers = bless( $headers => 'HTTP::Promise::Headers' );
        }
        elsif( $self->_is_array( $headers ) )
        {
            $headers = HTTP::Promise::Headers->new( @$headers );
        }
        else
        {
            return( $self->error( "Unknown headers value passed. I was expecting an HTTP::Promise::Headers, or HTTP::Headers object or an array reference, but instead I got '$headers' (", overload::StrVal( $headers ), ")." ) );
        }
    }
    else
    {
        $headers = HTTP::Promise::Headers->new;
    }
    
    if( defined( $content ) )
    {
        $self->_utf8_downgrade( $content ) || return( $self->pass_error );
    }
    
    # $self->{content}        = $content;
    $self->{entity}         = undef unless( CORE::exists( $self->{entity} ) );
    $self->{headers}        = $headers;
    $self->{protocol}       = undef unless( exists( $self->{protocol} ) );
    $self->{version}        = '' unless( exists( $self->{version} ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    my $ent = $self->entity;
    unless( $ent )
    {
        $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->pass_error );
        $ent = HTTP::Promise::Entity->new( headers => $headers, debug => $self->debug );
        $self->entity( $ent );
    }
    $ent->http_message( $self );
    $ent->debug( $self->debug );
    $headers->debug( $self->debug );
    
    # Even if it is zero bytes big, we still create the body
    # If a $content was provided, we store it in a in-memory body
    # If the user
    if( defined( $content ) )
    {
        if( $self->_is_a( $content => [qw( HTTP::Promise::Body HTTP::Promise::Body::Form )] ) )
        {
            $ent->body( $content ) || return( $self->pass_error( $ent->error ) );
        }
        else
        {
            my $body = $ent->new_body( string => \$content );
            return( $self->pass_error( $ent->error ) ) if( !defined( $body ) );
            $ent->body( $body );
        }
        # If Content-Encoding is set, then set is_encoded to true
        if( $headers->content_encoding->length )
        {
            $ent->is_encoded(1);
        }
    }
    # There is no parts in this object. Everything is held in HTTP::Promise::Entity
    # $self->{_parts} = [];
    return( $self );
}

sub add_content
{
    my $self = shift( @_ );
    if( defined( $_[0] ) )
    {
        $self->_utf8_downgrade( $self->_is_scalar( $_[0] ) ? ${$_[0]} : $_[0] ) ||
            return( $self->pass_error );
    }
    my( $ent, $body );
    unless( $ent = $self->entity )
    {
        $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->pass_error );
        $ent = HTTP::Promise::Entity->new( debug => $self->debug );
    }
    
    $body = $ent->body;
    if( $body )
    {
        return( $self->error( "Unable to append to an entity body other than a HTTP::Promise::Body::Scalar" ) ) if( !$self->_is_a( $body => 'HTTP::Promise::Body::Scalar' ) );
        $body->append( $_[0] );
    }
    else
    {
        $body = $ent->new_body( string => $_[0] ) ||
            return( $self->pass_error( $ent->error ) );
        $ent->body( $body );
    }
    return( $body );
}

sub add_content_utf8
{
    my( $self, $buff )  = @_;
    utf8::upgrade( $buff );
    utf8::encode( $buff );
    return( $self->add_content( $buff ) );
}

# Adding part will automatically makes it a multipart/form-data if not set already
# There is no such thing as multipart/mixed in HTTP
sub add_part
{
    my $self = shift( @_ );
    my $ent = $self->entity;
    my $headers = $self->headers;
    unless( $ent )
    {
        $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->pass_error );
        $ent = HTTP::Promise::Entity->new( headers => $headers, debug => $self->debug );
        $self->entity( $ent );
    }
    if( ( $self->content_type || '' ) !~ m,^multipart/, )
    {
        $ent->make_multipart( 'form-data' ) || return( $self->pass_error( $ent->error ) );
    }
    # elsif( $self->_parts->is_empty && ( $self->entity && $self->entity->body && !$self->entity->body->is_empty ) )
    elsif( $ent->parts->is_empty && ( $ent->body && !$ent->body->is_empty ) )
    {
        # Should really use HTTP::Promise::Entity->make_multipart
        $self->_make_parts;
    }
    elsif( $self->content_type->index( 'boundary' ) == -1 )
    {
        my $ct = $headers->new_field( 'Content-Type' => $self->content_type );
        $ct->boundary( $self->make_boundary );
        $self->content_type( $ct );
    }
    
    my @new = ();
    my $name;
    for( my $i = 0; $i < scalar( @_ ); $i++ )
    {
        my $this = $_[$i];
        # If this is a string or a scalar reference
        if( defined( $this ) && 
            ( !ref( $this ) || ( $self->_is_scalar( $this ) && overload::Method( $this => '""' ) ) ) )
        {
            $name = $this;
            next;
        }
        
        # Either a HTTP::Promise::Request, or a HTTP::Promise::Response, or even a HTTP::Promise::Message
        unless( $self->_is_a( $this => 'HTTP::Promise::Entity' ) )
        {
            return( $self->error( "Part object provided (", overload::StrVal( $this ), ") is neither a HTTP::Promise::Entity or a HTTP::Promise::Message object." ) ) if( !$self->_is_a( $this => 'HTTP::Promise::Message' ) );
            my $part_ent = $this->entity;
            unless( $part_ent )
            {
                $part_ent = HTTP::Promise::Entity->new( headers => $this->headers, debug => $self->debug ) ||
                    return( $self->pass_error );
                $this->entity( $part_ent );
            }
            $part_ent->name( $name ) if( defined( $name ) );
            push( @new, $part_ent );
            undef( $name );
            next;
        }
        $this->name( $name ) if( defined( $name ) );
        undef( $name );
        push( @new, $this );
    }
    
    $ent->parts->push( @new );
    return( $self );
}

sub as_string
{
    my( $self, $eol ) = @_;
    $eol = $CRLF unless( defined( $eol ) );
    my $ent = $self->entity;
    # If there is no entity, we just print the headers and that's it.
    return( $ent ? $ent->as_string( $eol ) : join( $eol, $self->start_line( $eol ), $self->headers->as_string( $eol ) ) . $eol );
}

sub boundary { return( shift->headers->boundary ); }

sub can
{
    my( $self, $method ) = @_;

    if( my $own_method = $self->SUPER::can( $method ) )
    {
        return( $own_method );
    }

    my $headers = ref( $self ) ? $self->headers : 'HTTP::Promise::Headers';
    my $trace = '';
    my $debug = $self->debug // 0;
    $trace = $self->_get_stack_trace if( $debug >= 4 );
    if( $headers->can( $method ) )
    {
        # We create the function here so that it will not need to be
        # autoloaded or recreated the next time.
        no strict 'refs';
        eval( <<EOT );
sub $method { return( shift->headers->$method( \@_ ) ); }
EOT
        my $ref = $self->UNIVERSAL::can( $method ) || die( "AUTOLOAD inconsistency error for dynamic sub \"$method\"." );
        return( $ref );
    }
    else
    {
    }
    return;
}

sub clear
{
    my $self = shift( @_ );
    $self->headers->clear;
    $self->entity->body->empty if( $self->entity && $self->entity->body );
    # $self->_parts->reset;
    $self->entity->parts->reset if( $self->entity );
    return;
}

sub clone
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{clone_entity} //= 1;
    # my $new = $self->new( [], undef );
    my $new = $self->SUPER::clone;
    my $new_headers;
    my $ent;
    if( ( $ent = $self->entity ) && $opts->{clone_entity} )
    {
        my $new_ent = $ent->clone( clone_message => 0 );
        $new_headers = $new_ent->headers;
        $new_ent->http_message( $new );
        $new->entity( $new_ent );
    }
    else
    {
        $new_headers = $self->headers->clone;
    }
    $new->headers( $new_headers );
    my $proto = $self->protocol;
    my $vers  = $self->version;
    $new->protocol( "$proto" ) if( defined( $proto ) && length( $proto ) );
    $new->version( "$vers" ) if( defined( $vers ) && length( $vers ) );
    $new->debug( $self->debug );
    return( $new );
}

sub content
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $has_ref = 0;
        for( @_ )
        {
            next unless( defined( $_ ) );
            return( $self->error( "I was expecting a string or a scalar reference, but instead got ", ref( $_ ) ) ) if( ref( $_ ) && !$self->_is_scalar( $_ ) );
            # This affects how we set the content
            $has_ref++ if( $self->_is_scalar( $_ ) );
            $self->_utf8_downgrade( $self->_is_scalar( $_ ) ? $$_ : $_ ) ||
                return( $self->pass_error );
        }
        # $self->_parts->reset;
        my $ent = $self->entity;
        unless( $ent )
        {
            my $headers = $self->headers;
            $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->pass_error );
            $ent = HTTP::Promise::Entity->new( headers => $headers, debug => $self->debug );
            $self->entity( $ent );
        }
        my $body = $ent->body;
        unless( $body )
        {
            $body = $ent->new_body( string => '' );
            return( $self->pass_error( $ent->error ) ) if( !defined( $body ) );
            # $ent->body( $body ) || return( $self->pass_error( $ent->error ) );
            my $rv = $ent->body( $body );
            if( !defined( $rv ) )
            {
            }
            return( $self->pass_error( $ent->error ) ) if( !defined( $rv ) );
        }
        
        my $io = $body->open( '+>', { binmode => 'raw', autoflush => 1 } ) ||
            return( $self->pass_error( $body->error ) );
        if( $has_ref > 1 )
        {
            for( @_ )
            {
                $io->print( $self->_is_scalar( $_ ) ? $$_ : $_ ) || return( $self->pass_error( $io->error ) );
            }
        }
        else
        {
            $io->print( ( @_ == 1 && $self->_is_scalar( $_[0] ) ) ? ${$_[0]} : @_ ) || return( $self->pass_error( $io->error ) );
        }
        $io->close;
        $ent->parts->reset;
        return( $body );
    }
    else
    {
        my $ent = $self->entity;
        return( '' ) if( !$ent );
        my $body = $ent->body;
        return( '' ) if( !$body );
        # This is a real bad idea if the body is huge...
        # NOTE: content() returns a scalar object (Module::Generic::Scalar)
        return( $body->as_string );
    }
}

# NOTE: an outdated method since nowadays everyone use UTF-8
sub content_charset
{
    my $self = shift( @_ );
    my $ent = $self->entity;
    return( '' ) unless( $ent );
    return( $ent->content_charset );
}

sub content_ref
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->error( "Value provided is not a scalar reference." ) ) unless( $self->_is_scalar( $_[0] ) );
        return( $self->content( @_ ) );
    }
    else
    {
        my $content = $self->content;
        return( $content );
    }
}

sub decodable
{
    my $self = shift( @_ );
    local $@;
    $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->pass_error );
    my $all = HTTP::Promise::Stream->decodable( 'browser' ) ||
        return( $self->error( HTTP::Promise::Stream->pass_error ) );
    return( $all );
}

sub decode
{
    my $self = shift( @_ );
    my $headers = $self->headers;
    my $ce = $headers->content_encoding;
    return(1) if( !$ce || $ce->is_empty );
    my $ent = $self->entity || return(1);
    my $encodings = $ce->split( qr/[[:blank:]]*,[[:blank:]]*/ )->reverse->object;
    return(1) if( $encodings->is_empty );
    my $body = $ent->decode_body( $encodings ) || return( $self->pass_error( $ent->error ) );
    # Altering existing headers value is really really bad. This is done in HTTP::Message, 
    # but not in our class
    # $self->remove_header( qw( Content-Encoding Content-Length Content-MD5 ) );
    return(1);
}

sub decode_content
{
    my $self = shift( @_ );
    my $ent = $self->entity || return(0);
    my $opts = $self->_get_args_as_hash( @_ );
    my $body = $ent->body || return(0);
    return( $body ) if( !$ent->is_encoded );
    my $ce = $self->headers->content_encoding;
    if( $ce )
    {
        # object(9 is a noop to ensure an object is returned and not a list
        $body = $ent->decode_body( $ce->split( qr/[[:blank:]\h]*\,[[:blank:]\h]*/ )->reverse->object, ( scalar( keys( %$opts ) ) ? $opts : () ) ) || return( $self->pass_error( $ent->error ) );
        # $ent->is_decoded(1);
    }
    return( $body );
}

sub decoded_content
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{charset_strict} //= 0;
    my $old_fatal = $self->fatal;
    $self->fatal( $opts->{raise_error} ? 1 : 0 );
    my $body = $self->decode_content( ( scalar( keys( %$opts ) ) ? $opts : () ) );
    return( $self->pass_error ) if( !defined( $body ) );
    # There is no entity or no body
    if( !$body )
    {
        return( $self->new_scalar );
    }
    $self->fatal( $old_fatal );
    my $dummy = '';
    return( $opts->{ref} ? \$dummy : $dummy ) if( $body->is_empty );
    unless( $opts->{binmode} )
    {
        # Need to explicitly provide the body to get the encoding from, otherwise, io_encoding()
        # would get the default one, which might not yet be replaced with its decoded version.
        my $enc = $self->entity->io_encoding( body => $body, charset_strict => $opts->{charset_strict} );
        $opts->{binmode} = $enc if( $enc );
    }
    
    # Because of an edge case where open with :binmode(utf-8) layer does not decode properly \x{FF}
    # but Encode::decode( 'utf-8', $buff ) does, and since the body is loaded into a string
    # anyway, we first read the data as raw and then decode it with Encode
    my $binmode;
    if( exists( $opts->{binmode} ) && 
        length( $opts->{binmode} ) && 
        lc( substr( $opts->{binmode}, 0, 3 ) ) eq 'utf' )
    {
        $binmode = delete( $opts->{binmode} );
        $opts->{binmode} = 'raw';
    }
    my $content = $body->as_string( ( scalar( keys( %$opts ) ) ? $opts : () ) );
    if( defined( $binmode ) )
    {
        $self->_load_class( 'Encode' ) || return( $self->pass_error );
        try
        {
            $$content = Encode::decode( $binmode, $$content, ( Encode::FB_DEFAULT | Encode::LEAVE_SRC ) );
        }
        catch( $e )
        {
            return( $self->error( "Error decoding body content with character encoding '$binmode': $e" ) );
        }
    }
    
    # $content is a scalar object that stringifies
    if( $self->headers->content_is_xml )
    {
        # Get rid of the XML encoding declaration if present (\x{FEFF})
        $$content =~ s/^\N{BOM}//;
        if( $$content =~ m/^(?<decl>[[:blank:]\h\v]*<\?xml(.*?)\?>)/is )
        {
            substr( $$content, 0, length( $+{decl} ) ) =~ s{
                [[:blank:]\h\v]+
                encoding[[:blank:]\h\v]*=[[:blank:]\h\v]*
                (?<quote>["'])
                (?<encoding>(?>\\\g{quote}|(?!\g{quote}).)*+)
                \g{quote}
            }
            {}xmis;
        }
    }
    return( $content );
}

sub decoded_content_utf8
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{binmode} = 'utf-8';
    my $data = $self->decoded_content( $opts );
    if( $self->headers->content_is_xml )
    {
        # Get rid of the XML encoding declaration if present
        $$data =~ s/^\x{FEFF}//;
        
        if( $$data =~ /^(\s*<\?xml[^\x00]*?\?>)/ )
        {
            substr( $$data, 0, length($1)) =~ s/\sencoding\s*=\s*(["']).*?\1//;
        }
    }
    return( $data );
}

sub dump
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $content = '';
    my $ent = $self->entity;
    my $maxlen = $opts->{maxlength};
    $maxlen = 512 unless( defined( $maxlen ) );
    my $no_content = $opts->{no_content};
    $no_content = "(no content)" unless( defined( $no_content ) );
    if( $ent && $ent->body )
    {
        my $io = $ent->body->open( '<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $ent->error ) );
        my $bytes = $io->read( $content, $maxlen );
        return( $self->pass_error( $io->error ) ) if( !defined( $bytes ) );
        $io->close;
    }
    my $chopped = 0;
    if( length( $content ) )
    {
        if( $ent->body->length > $maxlen )
        {
            $content .= '...';
            $chopped = $ent->body->length - $maxlen;
        }
        $content =~ s/\\/\\\\/g;
        $content =~ s/\t/\\t/g;
        $content =~ s/\r/\\r/g;

        # no need for 3 digits in escape for these
        $content =~ s/([\0-\11\13-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

        $content =~ s/([\0-\11\13-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
        $content =~ s/([^\12\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

        # remaining whitespace
        $content =~ s/( +)\n/("\\40" x length($1)) . "\n"/eg;
        $content =~ s/(\n+)\n/("\\n" x length($1)) . "\n"/eg;
        $content =~ s/\n\z/\\n/;
        if( $content eq $no_content )
        {
            # escape our $no_content marker
            $content =~ s/^(.)/sprintf('\\x%02X',ord($1))/eg;
        }
    }
    else
    {
        $content = $no_content;
    }
    
    my @dump;
    push( @dump, $opts->{preheader} ) if( $opts->{preheader} );
    push( @dump, $self->headers->as_string, $content );
    push( @dump, "(+ $chopped more bytes not shown)" ) if( $chopped );

    my $dump = join( "\n", @dump, '' );
    $dump =~ s/^/$opts->{prefix}/gm if( $opts->{prefix} );

    print( $dump ) unless( defined( wantarray() ) );
    return( $dump );
}

sub encode
{
    my $self = shift( @_ );
    my $opts = $self->_get_args_as_hash( \@_, args_list => [qw( update_header )] );
    my( @enc ) = @_;
    $opts->{update_header} //= 1;

    return( $self->error( "Cannot encode multipart/* messages" ) ) if( $self->content_type =~ m,^multipart/, );
    return( $self->error( "Cannot encode message/* messages" ) ) if( $self->content_type =~ m,^message/, );
    my $headers = $self->headers;
    my $e = $headers->content_encoding->split( qr/[[:blank:]\h]*,[[:blank:]\h]*/ );
    my $source = 'argv';
    my $encodings;
    if( @enc )
    {
        $encodings = $self->new_array( \@enc );
    }
    else
    {
        $source = 'header';
        $encodings = $e;
    }
    # nothing to do
    return(1) if( !$encodings || $encodings->is_empty );
    my $ent = $self->entity || return(1);
    $encodings->unique(1);
    my $body = $ent->encode_body( $encodings ) || return( $self->pass_error( $ent->error ) );
    $ent->is_encoded(1);
    if( $opts->{update_header} )
    {
        if( $source eq 'argv' )
        {
            if( $e )
            {
                $e->push( $encodings->list );
            }
            else
            {
                $e = $encodings;
            }
            $e->unique(1);
        }
        $headers->content_encoding( $e->join( ', ' )->scalar );
        $headers->remove_header( qw( Content-Length Content-MD5 ) );
    }
    return(1);
}

sub entity { return( shift->_set_get_object_without_init( 'entity', 'HTTP::Promise::Entity', @_ ) ); }

sub header { return( shift->headers->header( @_ ) ); }

sub headers
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        if( $self->_is_a( $v, 'HTTP::Promise::Headers' ) )
        {
            $self->{headers} = $v;
        }
        elsif( $self->_is_a( $v, 'HTTP::Headers' ) )
        {
            my $h = $v->clone;
            $self->{headers} = bless( $h => 'HTTP::Promise::Headers' );
        }
        elsif( $self->_is_array( $v ) )
        {
            $self->{headers} = HTTP::Promise::Headers->new( @$v );
        }
        else
        {
            return( $self->error( "Bad value for headers. I was expecting either an array reference or a HTTP::Promise::Headers or a HTTP::Headers object and I got instead '", overload::StrVal( $v ), "'." ) );
        }
    }
    elsif( !$self->{headers} )
    {
        $self->{headers} = HTTP::Promise::Headers->new;
    }
    return( $self->{headers} );
}

sub headers_as_string { return( shift->headers->as_string( @_ ) ); }

sub is_encoding_supported
{
    my $self = shift( @_ );
    my $enc  = shift( @_ );
    return( $self->error( "No encoding provided." ) ) if( !defined( $enc ) || !length( $enc ) );
    $self->_load_class( 'HTTP::Promise::Stream' ) || return( $self->error );
    return( HTTP::Promise::Stream->supported( lc( $enc ) ) );
}

sub make_boundary
{
    my $self = shift( @_ );
    my $uuid = Data::UUID->new;
    my $boundary = $uuid->create_str;
    return( "$boundary" );
}

sub parse
{
    my $self = shift( @_ );
    my $str = shift( @_ );
    return( $self->error( "No http headers string was provided to parse." ) ) if( !defined( $str ) );
    my $opts = $self->_get_args_as_hash( @_ );
    $opts->{debug} = $self->debug if( !CORE::exists( $opts->{debug} ) && ref( $self ) );
    # Nothing to parse, we return a dummy object in line with legacy api of HTTP::Message
    if( !length( "${str}" ) )
    {
        return( HTTP::Promise::Message->new( { debug => $opts->{debug} } ) );
    }
    $self = HTTP::Promise::Message->new( { debug => $opts->{debug} } ) if( !ref( $self ) );
    $self->_load_class( 'HTTP::Promise::Parser' ) || return( $self->pass_error );
    my $p = HTTP::Promise::Parser->new( debug => $opts->{debug} );
    my $copy = $str;
    $copy =~ s/\r/\\r/g;
    $copy =~ s/\n/\\n/g;
    my $ent = $p->parse( \$str );
    if( !defined( $ent ) )
    {
        # We do not support the legacy way of accepting an HTTP message that has no header
        return( $self->pass_error( $p->error ) );
    }
    my $msg = $ent->http_message;
    unless( $msg )
    {
        my $headers = $ent->headers;
        $msg = HTTP::Promise::Message->new( $headers );
        $msg->entity( $ent );
    }
    return( $msg );
}

# NOTE: parts() will parse the current content and break it down into parts if applicable
# otherwise, it will simply return the array object $parts, which would be empty.
# It would be nice to come up with some efficient caching mechanism to avoid the if..elsif
# at the beginning of the subroutine.
sub parts
{
    my $self = shift( @_ );
    my $ent = $self->entity;
    if( $ent &&
        $ent->parts->is_empty && 
        $ent->body &&
        !$ent->body->is_empty )
    {
        $self->_make_parts || return( $self->pass_error );
    }
    elsif( $ent && 
           $ent->parts->is_empty &&
           $ent->body && 
           $ent->body->is_empty )
    {
        $ent->body( undef );
    }
    
    unless( $ent )
    {
        $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->_pass_error );
        $ent = HTTP::Promise::Entity->new( headers => $self->headers, debug => $self->debug ) ||
            return( $self->pass_error( HTTP::Promise::Entity->error ) );
        $self->entity( $ent );
    }
    
    # Parts have been provided, add them if suitable
    if( @_ )
    {
        my @parts = map{ $self->_is_array( $_ ) ? @$_ : $_ } @_;
        my $ct = $self->content_type || '';
        if( $ct =~ m,^message/, )
        {
            return( $self->error( "Only one part allowed for $ct content" ) ) if( @parts > 1 );
        }
        elsif( $ct !~ m,^multipart/, )
        {
            $self->remove_content_headers;
            $self->content_type( 'multipart/mixed' );
        }
        # $self->_parts( \@parts );
        $self->_load_class( 'HTTP::Promise::Entity' ) || return( $self->pass_error );
        my @new = ();
        for( @parts )
        {
            # Either a HTTP::Promise::Request, or a HTTP::Promise::Response, or even a HTTP::Promise::Message
            unless( $self->_is_a( $_ => 'HTTP::Promise::Entity' ) )
            {
                return( $self->error( "Part object provided (", overload::StrVal( $_ ), ") is neither a HTTP::Promise::Entity or a HTTP::Promise::Message object." ) ) if( !$self->_is_a( $_ => 'HTTP::Promise::Message' ) );
                my $ent = $_->entity;
                unless( $ent )
                {
                    $ent = HTTP::Promise::Entity->new( headers => $_->headers, debug => $self->debug ) ||
                        return( $self->pass_error );
                    $_->entity( $ent );
                }
                push( @new, $ent );
                next;
            }
            push( @new, $_ );
        }
        $ent->parts( \@new );
    }
    my $parts = $ent->parts;
    return( $parts );
}

sub protocol
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        $v =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
        if( $v =~ m,^${HTTP_VERSION}$, )
        {
            $self->version( $+{http_version} );
        }
        else
        {
            return( $self->error( "Bad protocol value \"$v\". It should be something like HTTP/1.1" ) );
        }
        return( $self->_set_get_scalar_as_object( protocol => $v ) );
    }
    return( $self->_set_get_scalar_as_object( 'protocol' ) );
}

# NOTE: This method is superseded by the one in HTTP::Promise::Request or HTTP::Promise::Response
sub start_line { return( '' ) }

sub version { return( shift->_set_get_number( 'version', @_ ) ); }

# NOTE: _make_parts() is different from HTTP::Promise::Entity::make_multipart() 
# This creates private parts attribute from current content (current entity body)
# whereas HTTP::Promise::Entity::make_multipart keeps and transforms the current content 
# into multipart representation.
sub _make_parts
{
    my $self = shift( @_ );
    my $type = $self->headers->type;
    # my $parts = $self->_parts;
    my $ent = $self->entity ||
        return( $self->error( "No entity object is set." ) );
    my $body = $ent->body;
    my $parts = $ent->parts;
    return( $parts ) unless( defined( $type ) && length( $type ) );
    my $toptype = lc( [split( '/', $type, 2 )]->[0] );
    # Nothing to do
    return( $parts ) if( !$body );
    if( $toptype eq 'multipart' )
    {
        # Now parse the raw data saved earlier
        my $fh = $body->open( '+<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $ent->body->error ) );
        $self->_load_class( 'HTTP::Promise::IO' ) || return( $self->pass_error );
        my $reader = HTTP::Promise::IO->new( $fh, max_read_buffer => 4096, debug => $self->debug ) ||
            return( $self->pass_error( HTTP::Promise::IO->error ) );
        $self->_load_class( 'HTTP::Promise::Parser' ) || return( $self->pass_error );
        my $parser = HTTP::Promise::Parser->new( debug => $self->debug );
    
        # Request body can be one of 3 types:
        # application/x-www-form-urlencoded
        # multipart/form-data
        # text/plain or other mime types
        # <https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST>
        my $part_ent = $parser->parse_multi_part( entity => $ent, reader => $reader ) ||
            return( $parser->pass_error );
        $ent->body( undef );
    }
    # See rfc7230, section 8.3.1
    # <https://tools.ietf.org/html/rfc7230#section-8.3.1>
    elsif( $type eq 'message/http' )
    {
        my $fh = $body->open( '+<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $ent->body->error ) );
        $self->_load_class( 'HTTP::Promise::IO' ) || return( $self->pass_error );
        my $reader = HTTP::Promise::IO->new( $fh, max_read_buffer => 4096, debug => $self->debug ) ||
            return( $self->pass_error( HTTP::Promise::IO->error ) );
        # "It is RECOMMENDED that all HTTP senders and recipients support, at a minimum, request-line lengths of 8000 octets."
        # Ref: <https://tools.ietf.org/html/rfc7230#section-3.1.1>
        # getline() returns a scalar object
        my $buff = $reader->getline( max_read_buffer => 8192 );
        return( $self->pass_error( $reader->error ) ) if( !defined( $buff ) );
        $self->_load_class( 'HTTP::Promise::Parser' ) || return( $self->pass_error );
        my $parser = HTTP::Promise::Parser->new( debug => $self->debug );
        my $def = $parser->looks_like_what( $buff );
        warn( "Part found of type message/http, but its content does not match a HTTP request or response.\n" ) if( !$def && warnings::enabled() );
        return( $self->pass_error( $parser->error ) ) if( !defined( $def ) );
        # Give back what we just read to the reader for later use
        $reader->unread( $buff );
        # We parse it even if it may be a defective message/http part
        my $sub_ent = $parser->parse( $fh, reader => $reader ) || return( $self->pass_error( $parser->error ) );
        if( $def )
        {
            my $headers = $sub_ent->headers;
            my $msg;
            if( $def->{type} eq 'request' )
            {
                $self->_load_class( 'HTTP::Promise::Request' ) || return( $self->pass_error );
                $msg = HTTP::Promise::Request->new( @$def{qw( method uri )}, $headers, { protocol => $def->{protocol}, version => $def->{http_version} } ) || return( $self->pass_error( HTTP::Promise::Request->error ) );
            }
            elsif( $def->{type} eq 'response' )
            {
                $self->_load_class( 'HTTP::Promise::Response' ) || return( $self->pass_error );
                $msg = HTTP::Promise::Response->new( @$def{qw( code status )}, $headers, { protocol => $def->{protocol}, version => $def->{http_version} } ) || return( $self->pass_error( HTTP::Promise::Response->error ) );
            }
            else
            {
                return( $self->error( "Something is wrong with the parser who returned HTTP message type '$def->{type}', which I do not recognise." ) );
            }
            
            $msg->entity( $sub_ent );
            $sub_ent->http_message( $msg );
        }
        $parts->set( $sub_ent );
        $ent->body( undef );
    }
    elsif( $toptype eq 'message' )
    {
        my $fh = $body->open( '+<', { binmode => 'raw' } ) ||
            return( $self->pass_error( $ent->body->error ) );
        my $parser = HTTP::Promise::Parser->new( debug => $self->debug );
        my $ent = $parser->parse( $fh ) || return( $self->pass_error( $parser->error ) );
        $parts->set( $ent );
        $ent->body( undef );
    }
    # Any other is not a multipart as per HTTP protocol
    return( $parts );
}

sub _set_content
{
    my $self = shift( @_ );
    $self->_utf8_downgrade( $_[0] ) || return( $self->pass_error );
    $self->content( $_[0] );
    $self->entity->parts->reset unless( !$self->entity || $_[1] );
}

sub _utf8_downgrade
{
    my $self = shift( @_ );
    try
    {
        if( defined( &utf8::downgrade ) )
        {
            utf8::downgrade( $_[0], 1 ) ||
                return( $self->error( 'HTTP::Message content must be bytes' ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error downgrading utf8 data: $e" ) );
    }
}

sub AUTOLOAD
{
    my( $package, $method ) = $AUTOLOAD =~ m/\A(.+)::([^:]*)\z/;
    my $code = $_[0]->can( $method );
    goto( &$code ) if( $code );
    # Give a chance to our parent AUTOLOAD to kick in
    $Module::Generic::AUTOLOAD = $AUTOLOAD;
    goto( &Module::Generic::AUTOLOAD );
}

# sub CARP_TRACE { return( shift->_get_stack_trace ); }

# avoid AUTOLOADing it
sub DESTROY { }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Message - HTTP Message Class

=head1 SYNOPSIS

    use HTTP::Promise::Message;
    my $this = HTTP::Promise::Message->new(
        [ 'Content-Type' => 'text/plain' ],
        'Hello world'
    ) || die( HTTP::Promise::Message->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents an HTTP message, and implements methods that are common to either a request or a response. This class is inherited by L<HTTP::Promise::Request> and L<HTTP::Promise::Response>. It difffers from L<HTTP::Promise::Entity> in that L<HTTP::Promise::Entity> represents en HTTP entity which is composed of headers and a body, and this can be embedded within another entity.

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

=head1 CONSTRUCTOR

=head2 new

This takes some parameters and instantiates a new L<HTTP::Promise::Message>.

Accepted parameters can be one of the followings:

=over 4

=item 1. an L<headers object|HTTP::Promise::Headers> and some content as a string or scalar reference.

    my $msg = HTTP::Promise::Message->new( HTTP::Promise::Headers->new(
            Content_Type => 'text/plain',
            Content_Encoding => 'gzip',
            Host: 'www.example.org',
        ),
        "Some content",
    );

    my $str = "Some content";
    my $hdr = HTTP::Promise::Headers->new(
        Content_Type => 'text/plain',
        Content_Encoding => 'gzip',
        Host: 'www.example.org',
    );
    my $msg = HTTP::Promise::Message->new( $hdr, \$str );

=item 2. an L<headers object|HTTP::Promise::Headers> and and L<HTTP::Promise::Body> or L<HTTP::Promise::Body::Form> object

    my $body = HTTP::Promise::Body::Scalar->new( "Some content" );
    my $hdr = HTTP::Promise::Headers->new(
        Content_Type => 'text/plain',
        Content_Encoding => 'gzip',
        Host: 'www.example.org',
    );
    my $msg = HTTP::Promise::Message->new( $hdr, $body );

Using the x-www-form-urlencoded class:

    my $body = HTTP::Promise::Body::Form->new({ name => '嘉納 治五郎', age => 22, city => 'Tokyo' });
    my $hdr = HTTP::Promise::Headers->new(
        Content_Type => 'text/plain',
        Content_Encoding => 'gzip',
        Host: 'www.example.org',
    );
    my $msg = HTTP::Promise::Message->new( $hdr, $body );

=item 3. an array reference of headers field-value pairs and some content as a string or scalar reference.

    my $msg = HTTP::Promise::Message->new([
            Content_Type => 'text/plain',
            Content_Encoding => 'gzip',
            Host: 'www.example.org',
        ],
        "Some content",
    );

=item 4. an hash reference of parameters

    my $hdr = HTTP::Promise::Headers->new(
        Content_Type => 'text/plain',
        Content_Encoding => 'gzip',
        Host: 'www.example.org',
    );
    my $msg = HTTP::Promise::Message->new({
        headers => $hdr,
        content => \$str,
        # HTP::Promise::Entity
        entity => $entity_object,
        debug => 4,
    });

=back

In any case, you can provide additional object options by providing an hash reference as the last argument, such as:

    my $msg = HTTP::Promise::Message->new([
            Content_Type => 'text/plain',
            Content_Encoding => 'gzip',
            Host: 'www.example.org',
        ],
        "Some content",
        {
        debug => 4,
        entity => $entity_object
        },
    );

If some content is provided, a new L<entity in-memory body object|HTTP::Promise::Body::Scalar> will be initiated

It returns the new http message object, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head1 METHODS

=head2 add_content

This takes a string or a scalar reference and append it to the current body if the body object is an L<HTTP::Promise::Body::File> or L<HTTP::Promise::Body::Scalar> object. This does not work for L<HTTP::Promise::Body::Form>. You would have to call yourself the class methods to add your key-value pairs.

The content thus provided is downgraded, which means it is flagged as being in perl's internal utf-8 representation. So you cannot use this method to add binary data. If you want to do so, you would need to use directly the body object methods. For example:

    my $io = $msg->entity->body->open( '>', { binmode => 'utf-8', autoflush => 1 }) ||
        die( $msg->entity->body->error );
    $io->print( $some_data ) || die( $io->error );
    $io->close;

This code works for either L<HTTP::Promise::Body::File> or L<HTTP::Promise::Body::Scalar>

If no entity, or body is set yet, it will create one automatically, and defaults to L<HTTP::Promise::Body::Scalar> for the body class.

It returns the entity body object, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 add_content_utf8

This is the same thing as L</add_content>, except it will encode in utf-8 the data provided, i.e. not perl's internal representation.

=head2 add_part

By default, this will check if the HTTP message C<Content-Type> is a multipart one, and if not, it will automatically set it to C<multipart/form-data> and transform the current HTTP message into the first part of a C<multipart/form-data>, and add after all the parts provided.

If the C<Content-Type> is already a multipart one, but has no part yet and has a body content, it will parse that content to build one or more parts from it.

When used for an HTTP request, C<multipart/form-data> is the only valid Content-Type for sending multiple data. L<rfc7578 in section 4.3|https://tools.ietf.org/html/rfc7578#section-4.3> states: "[RFC2388] suggested that multiple files for a single form field be transmitted using a nested "multipart/mixed" part. This usage is deprecated."

See also this L<Stackoverflow discussion|https://stackoverflow.com/questions/36674161/http-multipart-form-data-multiple-files-in-one-input/41204533#41204533> and L<this one too|https://stackoverflow.com/questions/51575746/http-header-content-type-multipart-mixed-causes-400-bad-request>

When used for an HTTP response, one can return either a C<multipart/form-data> or a C<multipart-mixed> HTTP message.

If you want to make an HTTP request, then you need to provide pairs of form-name-and part object (either a L<HTTP::Promise::Entity> or a L<HTTP::Promise::Message> object with an L<HTTP::Promise::Entity> set with L</entity>) OR a list of parts whose L<name attribute|HTTP::Promise::Entity/name> is set.

If you want to make an HTTP response, you can either return a C<multipart/form-data> by providing pairs of form-name-and part object as mentioned above, or a C<multipart/mixed> by providing a list of part object (either a L<HTTP::Promise::Entity> or a L<HTTP::Promise::Message> object with an L<HTTP::Promise::Entity> set with L</entity>).

For example:

    $m->add_part(
        file1 => $ent1,
        file2 => $ent2,
        first_name => $ent3,
        last_name => $ent4,
        # etc...
    );

or, using the L<name attribute|HTTP::Promise::Entity/name>:

    $ent1->name( 'file1' );
    $ent2->name( 'file2' );
    $ent3->name( 'first_name' );
    $ent4->name( 'last_name' );
    $m->add_part( $ent1, $ent2, $ent3, $ent4 );

Note that you can always set an L<entity name|HTTP::Promise::Entity/name>, and it will only be used if the HTTP message Content-Type is of type C<multipart/form-data>, unless you set yourself the C<Content-Disposition> header value.

It returns the current object, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 as_string

This takes an optional end-of-line terminator and returns a L<scalar object|Module::Generic::Scalar> representing the entire HTTP message.

The end-of-line terminator defaults to C<$CRLF>, which is a global variable of L<HTTP::Promise::Message>

=head2 boundary

This is a shortcut.

It returns the result returned by L<HTTP::Promise::Headers/boundary>

=head2 can

This behaves like L<UNIVERSAL/can>, with a twist.

Provided with a method name and this check if this is supported by L<HTTP::Promise::Message>, or in last resort by L<HTTP::Promise::Headers> and if the latter is true, it will alias the headers method to this namespace.

It returns the code reference of the requested method, or C<undef> if none could be found.

=head2 clear

Clears out the headers object by calling L<HTTP::Promise::Headers/clear>, empty the entity body, if any, and remove any part if any.

It does not return anything. This should be called in void context.

=head2 clone

This clones the current HTTP message and returns a new object.

=head2 content

Get or set the HTTP message body.

If one or more values are provided, they will be added to the newly created L<HTTP::Promise::Body> object.

You can provide as values one or more instance of either a string or a scalar reference.

For example:

    $m->content( \$string, 'Hello world', \$another_string );

It returns the newly set L<HTTP::Promise::Body> object upon success or, upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

When no argument is provided, this returns the L<HTTP::Promise::Body> object as a L<scalar object|Module::Generic::Scalar>.

Beware that the content returned might not be decoded if compression has been applied previously, or if compressed content was provided upon instantiation of the C<HTTP::Promise::Message> object, such as:

    my $m = HTTP::Promise::Message->new([
        'Content-Type' => 'text/plain',
        'Content-Encoding' => 'deflate, base64',
        ],
        '80jNyclXCM8vyklRBAA='
    );
    my $content = $m->content; # 80jNyclXCM8vyklRBAA=

But even with utf-8 content, such as:

    my $m = HTTP::Promise::Message->new([
        'Content-Type' => 'text/plain; charset=utf-8',
        ],
        "\x{E3}\x{81}\x{8A}\x{E6}\x{97}\x{A9}\x{E3}\x{81}\x{86}\x{EF}\x{BC}\x{81}\x{A}",
    );
    my $content = $m->content;

C<$content> would contain undecoded utf-8 bytes, i.e. not in perl's internal representation. Indeed, charset is never decoded. If you want the charset decoded content, use L</decoded_content>, which will guess the content charset to decode it into perl's internal representation. If you are sure this is utf-8, you can either call:

    my $decoded_content = $m->decoded_content( binmode => 'utf-8' );

or

    my $decoded_content = $m->decoded_content_utf8;

See L</decoded_content> for more information.

=head2 content_charset

This is a convenient method that calls L<HTTP::Promise::Entity/content_charset> and returns the result.

This method attempts at guessing the content charset of the entity body.

It returns a string representing the content charset, possibly empty if nothing was found, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 content_ref

This sets or gets the content as a scalar reference.

In assignment mode, this takes a scalar reference and pass it to L</content> and returns the L<body object|HTTP::Promise::Body>

Otherwise, this returns the content as L<scalar object|Module::Generic::Scalar>.

If an error occurs, this sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 decodable

This gets an L<array object|Module::Generic::Array> of all supported and installed decodings on the system, by calling L<HTTP::Promise::Stream/decodable>

=head2 decode

This decodes the HTTP message body and return true.

If there is no C<Content-Encoding> set, or the entity body is empty, or the entity body already has been decoded, this does nothing obviously. Otherwise, this calls L<HTTP::Promise::Entity/decode_body> passing it the encodings as an array reference.

If an error occurs, this sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 decode_content

This is similar to </decode>, except that it takes an hash or hash reference of options passed to L<HTTP::Promise::Entity/decode_body>, notably C<replace>, which if true will replace the body by its decoded version and if false will return a new body version representing the decoded body.

This returns the entity body object upon success, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

=head2 decoded_content

This takes an hash or hash reference of options and returns the decoded representation of the body, including charset.

This calls L</decode_content>, passing it the options provided, to decompress the entity body if necessary. Then, unless the C<binmode> option was provided, this calls L<HTTP::Promise::Entity/io_encoding> to guess the charset encoding, and set the C<binmode> option to it, if anything was found.

If the entity body is an xml file, any C<BOM> (Byte Order Mark) will be removed.

This returns the content as a L<scalar object|Module::Generic::Scalar>, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Supported options are:

=over 4

=item * C<binmode>

The L<PerlIO> encoding to apply to decode the data.

If not provided, this will be guessed by calling L<HTTP::Promise::Entity/io_encoding>

=item * C<charset_strict>

If true, this will returns an error if there is some issues with the content charset. By default, this is false, making it lenient, especially with malformed utf-8.

=item * C<raise_error>

When set to true, this will cause this method to die upon error. Default is false.

=back

=head2 decoded_content_utf8

This calls L</decoded_content>, but this sets the C<binmode> option to C<utf-8>.

It returns whatever L</decode_content> returns.

=head2 dump

This takes an hash or hash reference of options and either print the resulting dump on the C<STDOUT> in void content, or returns a string representation of the HTTP message, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Supported options are:

=over 4

=item * C<maxlength>

The maximum amount of body data in bytes to display.

=item * C<no_content>

The string to use when there is no entity body data.

=item * C<prefix>

A string to be added at the beginning of each line of the data returned.

=item * C<preheader>

An arbitrary string to add before the HTTP headers, typically the HTTP C<start line>

=back

    # Returns a string
    my $dump = $msg->dump;
    # Prints on the STDOUT the result
    $msg->dump;

=head2 encode

This takes an optional list of encoding and an optional hash or hash reference of options and encode the entity body and returns true, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

This will return an error if it is used on a multipart message or an C<message/*> such as C<message/http>.

Obviously this is a no-op if no encoding was found, or if the body is empty, or if the body is already marked L<as encoded|HTTP::Promise::Entity/is_encoded>

Supported options are:

=over 4

=item * C<update_header>

When true, this will set the C<Content-Encoding> with the encoding used to encode the entity body and remove the headers C<Content-Length> and C<Content-MD5>. Defaults to true.

=back

=head2 entity

Sets or gets the HTTP L<entity object|HTTP::Promise::Entity>

=head2 header

This is a shortcut by calling L<HTTP::Promise::Headers/header>

=head2 headers

Sets or gets the L<HTTP::Promise::Headers> object.

=head2 headers_as_string

This is a shortcut to call L<HTTP::Promise::Headers/as_string>

=head2 is_encoding_supported

Provided with an encoding and this returns true if the encoding is supported by L<HTTP::Promise::Stream>

=head2 make_boundary

Returns a newly generated boundary, which is basically a uuid generated by the XS module L<Data::UUID>

=head2 parse

Provided with a string and this will try to parse this HTTP message and returns the current message object if it was called with an HTTP message, or a new HTTP message if it was called as a class function, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

    my $msg = HTTP::Promise::Message->parse( $some_http_message ) ||
        die( HTTP::Promise::Message->error );
    
    $msg->parse( $some_http_message ) ||
        die( HTTP::Promise::Message->error );

=head2 parts

This returns the HTTP message entity parts as an L<array object|Module::Generic::Array> and returns it, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

If the HTTP message has a body with content and there is no part and the mime-type top type is C<multipart> or C<message>, this will first parse the body into parts. Thus you could do:

    my $msg = HTTP::Promise::Message->new([
        Content_Type => 'multipart/form-data; boundary="abcd"',
        Content_Encoding => 'gzip',
        Host => 'example.org',
    ], <<EOT );
    --abcd
    Content-Disposition: form-data; name="name"

    Jigoro Kano

    --abcd
    Content-Disposition: form-data; name="birthdate"

    1860-12-10
    --abcd--
    EOT

    my $parts = $msg->parts;

=head2 protocol

Sets or gets the HTTP protocol. This is typically something like C<HTTP/1.0>, C<HTTP/1.1>, C<HTTP/2>

Returns the HTTP protocol, if any was set, as a L<scalar object|Module::Generic::Scalar>, or upon error, sets an L<error|Module::Generic/error> and returns C<undef>.

Note that it may return C<undef> if no protocol was set. Errors are likely to occur when assigning an improper value.

=head2 start_line

This is a no-op since it is superseded by its inheriting classes L<HTTP::Promise::Request> and L<HTTP::Promise::Response>

=head2 version

Sets or gets the HTTP protocol version, something like C<1.0>, or C<1.1>, or maybe C<2>

This returns a L<number object|Module::Generic::Number>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
