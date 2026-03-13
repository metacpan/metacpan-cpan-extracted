##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Headers.pm
## Version v0.9.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Headers;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS $SUPPORTED $CRLF );
    use Mail::Make::Exception;
    use Mail::Make::Headers::ContentDisposition;
    use Mail::Make::Headers::ContentTransferEncoding;
    use Mail::Make::Headers::ContentType;
    use Mail::Make::Headers::Generic;
    use Mail::Make::Headers::MessageID;
    use Mail::Make::Headers::Subject;
    use MM::Table ();
    use MM::Const qw( :table );
    # use Wanted;
    our $CRLF             = "\015\012";
    our $EXCEPTION_CLASS  = 'Mail::Make::Exception';
    # Maps normalised header name (lowercase, no hyphens) to typed class
    our $SUPPORTED =
    {
        contentdisposition          => 'Mail::Make::Headers::ContentDisposition',
        contenttransferencoding     => 'Mail::Make::Headers::ContentTransferEncoding',
        contenttype                 => 'Mail::Make::Headers::ContentType',
        messageid                   => 'Mail::Make::Headers::MessageID',
        subject                     => 'Mail::Make::Headers::Subject',
    };
    our $VERSION = 'v0.9.0';
};

use strict;
use warnings;

my $header_fields_canonical =
{
    'from'                      => 'From',
    'to'                        => 'To',
    'cc'                        => 'Cc',
    'bcc'                       => 'Bcc',
    'reply-to'                  => 'Reply-To',
    'sender'                    => 'Sender',
    'subject'                   => 'Subject',
    'date'                      => 'Date',
    'message-id'                => 'Message-ID',
    'in-reply-to'               => 'In-Reply-To',
    'references'                => 'References',
    'return-path'               => 'Return-Path',
    'received'                  => 'Received',
    'mime-version'              => 'MIME-Version',
    'content-type'              => 'Content-Type',
    'content-transfer-encoding' => 'Content-Transfer-Encoding',
    'content-disposition'       => 'Content-Disposition',
    'content-id'                => 'Content-ID',
    'content-description'       => 'Content-Description',
};

my $header_fields_order =
{
    'return-path'               => 10,
    'received'                  => 20,
    'date'                      => 30,
    'from'                      => 40,
    'sender'                    => 50,
    'reply-to'                  => 60,
    'to'                        => 70,
    'cc'                        => 80,
    'bcc'                       => 90,
    'message-id'                => 100,
    'in-reply-to'               => 110,
    'references'                => 120,
    'subject'                   => 130,
    'mime-version'              => 200,
    'content-type'              => 210,
    'content-transfer-encoding' => 220,
    'content-disposition'       => 230,
    'content-id'                => 240,
    'content-description'       => 250,
};
my $fqdn_re = qr/\A[A-Za-z0-9](?:[A-Za-z0-9\-\.]*[A-Za-z0-9])?\z/;
my %valid_encoding = map{ $_ => 1 } qw( 7bit 8bit binary base64 quoted-printable );

sub init
{
    my $self = shift( @_ );
    # Internal ordered list of [ $name, $value ] pairs to preserve order
    $self->{_headers}         = [];
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->{_init_strict_use_sub} = 1;
    $self->{_t} = MM::Table->make;
    if( @_ )
    {
        if( @_ % 2 )
        {
            return( $self->error( "new needs an even number of arguments" ) );
        }
        # We need to preserve the order in which the header field names were provided.
        for( my $i = 0; $i < scalar( @_ ); $i += 2 )
        {
            if( defined( $_[$i] ) && $_[$i] eq 'debug' )
            {
                $self->debug( $_[$i + 1] );
                next;
            }
            $self->push_header( $_[$i] => $_[$i + 1] ) ||
                return( $self->pass_error );
        }
    }
    $self->SUPER::init() || return( $self->pass_error );
    return( $self );
}

# instead of aliasing it, we redirect so it shows up in a stack trace.
sub add { return( shift->push_header( @_ ) ); }

# Returns the string representation of all headers, CRLF-terminated,
# ready to be written to a message (without the trailing blank line).
sub as_string
{
    my $self = shift( @_ );
    my $eol  = @_ ? shift( @_ ) : $CRLF;
    my $max  = @_ ? shift( @_ ) : 78;
    if( $self->{_cache_value} &&
        $self->{_cache_value}->[0] eq $eol &&
        $self->{_cache_value}->[1] == $max &&
        $self->{_cache_value}->[2] &&
        !CORE::length( $self->{_reset} ) )
    {
        return( $self->{_cache_value}->[2] );
    }

    # WARNING: sorting email headers can be semantically risky (e.g. Received:).
    my @pairs;
    $self->{_t}->do(sub
    {
        my( $k, $v ) = @_;
        push( @pairs, [ $k, $v ] );
        return(1);
    });

    @pairs = sort
    {
        $self->_mail_header_order( $a->[0] ) <=> $self->_mail_header_order( $b->[0] )
    } @pairs;

    my $out = '';
    for( my $i = 0; $i < @pairs; $i++ )
    {
        my $line = $self->_display_name( $pairs[ $i ]->[0] ) . ': ' . $pairs[ $i ]->[1];

        $out .= $self->_fold_header_line( $line, $eol, $max ) . $eol;
    }

    $self->{_cache_value} = [$eol, $max, $out];
    CORE::delete( $self->{_reset} );
    return( $out );
}

sub as_string_without_sort
{
    my $self = shift( @_ );
    my $eol  = @_ ? shift( @_ ) : $CRLF;

    my $out = '';
    $self->{_t}->do(sub
    {
        my( $k, $v ) = @_;
        $out .= $k . ': ' . $v . $eol;
        return(1);
    });

    return( $out );
}

sub clear
{
    my $self = shift( @_ );
    $self->{_t}->clear();
    return( $self );
}

sub clone
{
    my $self = shift( @_ );

    my $c = ref( $self )->new();
    $c->{_t} = $self->{_t}->copy( undef );

    return( $c );
}

# content_disposition - convenience typed accessor
sub content_disposition
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        $val    = "$val" if( ref( $val ) );
        $self->reset(1);
        return( $self->set( 'Content-Disposition', $val ) );
    }
    return( $self->new_field( 'Content-Disposition' ) );
}

# content_id - convenience accessor for Content-ID
sub content_id
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $cid = shift( @_ );
        # Normalise: strip surrounding angle brackets if present, then re-add
        $cid =~ s/^<//;
        $cid =~ s/>$//;
        if( $cid =~ /[\x00-\x1F\x7F]/ )
        {
            return( $self->error( "Invalid Content-ID value '$cid': contains illegal characters." ) );
        }
        $self->reset(1);
        return( $self->set( 'Content-ID', "<${cid}>" ) );
    }
    return( $self->get( 'Content-ID' ) );
}

# content_transfer_encoding - convenience accessor
sub content_transfer_encoding
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $enc = lc( shift( @_ ) );
        unless( exists( $valid_encoding{ $enc } ) )
        {
            return( $self->error( "Unknown Content-Transfer-Encoding '$enc'." ) );
        }
        $self->reset(1);
        return( $self->set( 'Content-Transfer-Encoding', $enc ) );
    }
    return( $self->get( 'Content-Transfer-Encoding' ) );
}

# content_type - convenience typed accessor
sub content_type
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        $val    = "$val" if( ref( $val ) );
        $self->reset(1);
        return( $self->set( 'Content-Type', $val ) );
    }
    return( $self->new_field( 'Content-Type' ) );
}

# $hdr->date( $my_date );
# $hdr->date( $my_date, { strict => 1 } );
sub date
{
    my $self     = shift( @_ );
    my $has_args = scalar( @_ ) ? 1 : 0;
    my $opts     = {};
    $opts        = pop( @_ ) if( scalar( @_ ) && ref( $_[-1] ) eq 'HASH' );

    # Accessor mode
    if( @_ == 0 )
    {
        if( $has_args )
        {
            return( $self->error( "No date was provided." ) );
        }
        return( $self->header( 'Date' ) );
    }

    # Mutator mode
    my $v = shift( @_ );

    if( defined( $v ) && !ref( $v ) )
    {
        # epoch seconds -> RFC 5322 date-time
        if( $v =~ /^[[:blank:]]*-?\d+[[:blank:]]*$/ )
        {
            my $epoch = $v;
            $epoch =~ s/^[[:blank:]]+//;
            $epoch =~ s/[[:blank:]]+$//;
    
            my $date = $self->_format_rfc5322_date( $epoch ) ||
                return( $self->pass_error );
    
            $self->header( 'Date' => $date );
            $self->reset(1);
            return( $self );
        }
        # Non-numeric: accept as-is, but optionally validate
        elsif( $opts->{strict} )
        {
            $self->_validate_date_value( $v ) ||
                return( $self->pass_error );
        }
        # else, anything goes...
    }

    $self->reset(1);
    $self->header( 'Date' => $v );
    # We return the current instance for chaining.
    return( $self );
}

sub exists
{
    my $self = shift( @_ );

    if( @_ != 1 )
    {
        return( $self->error( "exists expects exactly one argument" ) );
    }

    my $cname = $self->_canon_name( $_[0] ) || return( $self->pass_error );

    my $v = $self->{_t}->get( $cname );

    return( defined( $v ) ? 1 : 0 );
}

# get( $name ) - returns the raw string value of the first matching header
sub get
{
    my $self = shift( @_ );

    if( @_ != 1 )
    {
        return( $self->error( "get expects exactly one argument" ) );
    }

    return( $self->header( $_[0] ) );
}

# has( $name ) - boolean existence check
{
    no warnings 'once';
    # NOTE: sub has aliased to 'has'
    *has = \&exists;
}

sub header
{
    my $self = shift( @_ );

    if( @_ == 0 )
    {
        return( $self->error( "header called with no arguments" ) );
    }

    # Getter
    if( @_ == 1 )
    {
        my $name  = $_[0];
        my $cname = $self->_canon_name( $name ) || return( $self->pass_error );

        my @vals = $self->{_t}->get( $cname );

        if( !@vals )
        {
            return;
        }

        return( wantarray() ? @vals : join( ', ', @vals ) );
    }

    # Setter
    if( @_ % 2 )
    {
        return( $self->error( "header needs one or an even number of arguments" ) );
    }

    my %cleared;
    for( my $i = 0; $i < @_; $i += 2 )
    {
        my $name = $_[$i];
        my $val  = $_[$i + 1];

        my $cname = $self->_canon_name( $name ) || return( $self->pass_error );

        my $lkey = lc( $cname );
        $lkey    =~ tr/_/-/;

        if( !$cleared{ $lkey }++ )
        {
            $self->{_t}->unset( $cname );
        }

        # We get back an array reference
        my $vals = $self->_coerce_values( $val ) || return( $self->pass_error );

        for( my $j = 0; $j < @$vals; $j++ )
        {
            $self->{_t}->add( $cname => $vals->[ $j ] );
        }
    }
    $self->reset(1);

    # We return the current instance for chaining
    return( $self );
}

sub header_field_names
{
    my $self = shift( @_ );

    my %seen;
    my @out;

    $self->{_t}->do(sub
    {
        my( $k, $v ) = @_;

        my $lkey = lc( $k );
        $lkey =~ tr/_/-/;

        if( !$seen{ $lkey }++ )
        {
            my $name = $self->_display_name( $k ) || return( $self->pass_error );
            push( @out, $name );
        }
        return(1);
    });

    return( wantarray() ? @out : \@out );
}

sub init_header
{
    my $self = shift( @_ );

    if( @_ % 2 )
    {
        return( $self->error( "init_header needs an even number of arguments" ) );
    }

    for( my $i = 0; $i < @_; $i += 2 )
    {
        my $name = $_[$i];
        my $val  = $_[$i + 1];

        my $cname = $self->_canon_name( $name ) ||
            return( $self->pass_error );

        my @existing = $self->{_t}->get( $cname );
        next if( @existing );

        $self->push_header( $cname => $val ) ||
            return( $self->pass_error );
    }
    $self->reset(1);
    return( $self );
}

# length()
# Returns the total number of header field entries currently stored,
# counting each value separately for multi-valued fields.
# Returns 0 when no headers have been set.
sub length
{
    my $self = shift( @_ );
    my $st   = $self->{_t}->_state();
    return( scalar( @{$st->{_entries}} ) );
}

# $hdr->message_id( undef );                     # remove
# $hdr->message_id( undef, { strict => 1 } );    # same: remove
sub message_id
{
    my $self     = shift( @_ );
    my $has_args = scalar( @_ ) ? 1 : 0;
    my $opts     = {};
    $opts        = pop( @_ ) if( scalar( @_ ) && ref( $_[-1] ) eq 'HASH' );

    # Generate mode
    # Allow: $hdr->message_id( { generate => 1, domain => 'example.com' } )
    if( $opts->{generate} )
    {
        my $domain = $opts->{domain};
        if( !defined( $domain ) || $domain eq '' )
        {
            # Sys::Hostname is a core module, so it is guaranteed to be available.
            $self->_load_class( 'Sys::Hostname' ) ||
                return( $self->pass_error );
            local $@;
            # Sys::Hostname::hostname() croaks, so we need to catch that.
            eval
            {
                $domain = Sys::Hostname::hostname();
            };
        }

        # Need to check the user-provided value against rfc1123 and rfc952 using regular expression
        # Validate domain: require dot + RFC-ish hostname
        if( !defined( $domain ) ||
            # Better than using a regular expression, and we check it first, before executing the following complexe regular expression.
            index( $domain, '.' ) == -1 ||
            # We use a pre-compiled regular expression
            $domain !~ $fqdn_re )
        {
            # Let's be clear, and tell the user what is wrong so he does not need to go looking in the code to understand.
            return( $self->error( "Invalid Message-ID domain '$domain'. You need to specify a domain with the option 'domain'." ) );
        }

        my $mid = $self->_generate_message_id( $domain ) ||
            return( $self->pass_error );

        $self->reset(1);
        $self->header( 'Message-ID' => $mid );
        return( $mid );
    }

    # Accessor mode
    if( @_ == 0 )
    {
        if( $has_args )
        {
            return( $self->error( "No Message-ID value was provided." ) );
        }
        return( $self->header( 'Message-ID' ) );
    }

    my $v = shift( @_ );

    # undef => remove
    if( !defined( $v ) )
    {
        $self->reset(1);
        $self->remove_header( 'Message-ID' );
        return( $self );
    }

    if( ref( $v ) )
    {
        if( !$self->_can_overload( $v => '""' ) )
        {
            return( $self->error( "Invalid Message-ID value (", $self->_str_val( $v ), ")." ) );
        }
        $v = "$v";
    }

    if( $opts->{strict} )
    {
        $self->_validate_message_id_value( $v ) ||
            return( $self->pass_error );
    }

    $self->reset(1);
    $self->header( 'Message-ID' => $v );
    # We return the current instance for chaining
    return( $self );
}

# new_field( $name, $value ) - factory returning a typed object or Generic
# e.g. $headers->new_field( 'Content-Type' )
sub new_field
{
    my $self  = shift( @_ );
    my $name  = shift( @_ ) || return( $self->error( "No field name provided." ) );
    my $value = shift( @_ );
    my $key   = $self->_normalise_name( $name ) || return( $self->pass_error );
    my $class = $SUPPORTED->{ $key } || 'Mail::Make::Headers::Generic';
    $self->_load_class( $class ) || return( $self->pass_error );
    if( defined( $value ) && CORE::length( $value ) )
    {
        return( $class->new( $value ) || $self->pass_error( $class->error ) );
    }
    return( $class->new || $self->pass_error( $class->error ) );
}

# print( $fh ) - writes all headers + blank line to filehandle
sub print
{
    my $self = shift( @_ );
    my $fh   = shift( @_ );
    my $eol  = @_ ? $_[0] : $CRLF;
    $fh->print( $self->as_string( @_ ) ) ||
        return( $self->error( "Unable to print headers: $!" ) );
    $fh->print( $eol ) ||
        return( $self->error( "Unable to print blank line after headers: $!" ) );
    return( $self );
}

sub push_header
{
    my $self = shift( @_ );

    if( @_ % 2 )
    {
        return( $self->error( "push_header needs an even number of arguments" ) );
    }

    for( my $i = 0; $i < @_; $i += 2 )
    {
        my $name = $_[$i];
        my $val  = $_[$i + 1];

        my $cname = $self->_canon_name( $name ) ||
            return( $self->pass_error );

        # We get back an array reference
        my $vals = $self->_coerce_values( $val ) ||
            return( $self->pass_error );

        for( my $j = 0; $j < @$vals; $j++ )
        {
            $self->{_t}->add( $cname => $vals->[ $j ] );
        }
    }
    $self->reset(1);

    return( $self );
}

# remove( $name ) - removes all headers with the given name
{
    no warnings 'once';
    # NOTE: sub remove is aliased to remove_header()
    *remove = \&remove_header;
}

sub remove_header
{
    my $self = shift( @_ );
    if( @_ == 0 )
    {
        return( $self->error( "remove_header called with no arguments" ) );
    }

    my @removed_all;

    for( my $i = 0; $i < @_; $i++ )
    {
        my $name  = $_[$i];
        my $cname = $self->_canon_name( $name ) ||
            return( $self->pass_error );

        my @vals = $self->{_t}->get( $cname );
        push( @removed_all, @vals ) if( @vals );

        $self->{_t}->unset( $cname );
    }
    $self->reset(1) if( scalar( @removed_all ) );

    return( wantarray() ? @removed_all : ( scalar( @removed_all ) ? $removed_all[-1] : 0 ) );
}

{
    no warnings 'once';
    # NOTE: sub replace is aliased to replace_header()
    *replace = \&replace_header;
}

sub replace_header
{
    my $self = shift( @_ );

    if( @_ == 0 )
    {
        return( $self->error( "replace_header called with no arguments" ) );
    }

    if( @_ % 2 )
    {
        return( $self->error( "replace_header needs an even number of arguments" ) );
    }

    my %cleared;
    for( my $i = 0; $i < @_; $i += 2 )
    {
        my $name = $_[$i];
        my $val  = $_[$i + 1];

        my $cname = $self->_canon_name( $name ) ||
            return( $self->pass_error );

        my $lkey = lc( $cname );
        $lkey    =~ tr/_/-/;

        if( !$cleared{ $lkey }++ )
        {
            $self->{_t}->unset( $cname );
        }

        # undef => remove header (no re-add)
        next if( !defined( $val ) );

        # We get back an array reference
        my $vals = $self->_coerce_values( $val ) || return( $self->pass_error );
        for( my $j = 0; $j < @$vals; $j++ )
        {
            $self->{_t}->add( $cname => $vals->[ $j ] );
        }
    }
    $self->reset(1);

    # We return the current instance for chaining.
    return( $self );
}

sub reset
{
    my $self = shift( @_ );
    $self->{_reset} = scalar( @_ ) if( !CORE::length( $self->{_reset} ) && scalar( @_ ) );
    return( $self );
}

sub scan
{
    my $self = shift( @_ );
    my $cb   = shift( @_ ) ||
        return( $self->error( "No callback was provided." ) );

    if( ref( $cb ) ne 'CODE' )
    {
        return( $self->error( "scan expects a CODE reference" ) );
    }

    $self->{_t}->do(sub
    {
        my( $k, $v ) = @_;
        $cb->( $k, $v );
        return(1);
    });

    return( $self );
}

# instead of aliasing it, we redirect so it shows up in a stack trace.
sub set { return( shift->replace_header( @_ ) ); }

# replace( $name, $value ) - alias for set(). Provided for API compatibility.
# sub replace { return( shift->set( @_ ) ); }

sub _canon_name
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No header name was provided." ) );

    $self->_validate_field_name( $name ) || return( $self->pass_error );

    $name =~ tr/_/-/;
    return( $self->_display_name( $name ) );
}

sub _coerce_values
{
    my $self = shift( @_ );
    my $val  = shift( @_ );
    unless( defined( $val ) && CORE::length( $val ) )
    {
        return( $self->error( "No header value was provided to coerce." ) );
    }

    my @vals;
    if( ref( $val ) eq 'ARRAY' )
    {
        for( my $i = 0; $i < @$val; $i++ )
        {
            my $clean = $self->_sanitize_value( $val->[$i] ) ||
                return( $self->pass_error );
            push( @vals, $clean );
        }
    }
    else
    {
        my $clean = $self->_sanitize_value( $val ) ||
            return( $self->pass_error );
        push( @vals, $clean );
    }

    return( \@vals );
}

sub _display_name
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No header name was provided." ) );

    my $k = lc( $name );
    $k    =~ tr/_/-/;

    my $canon = $self->_mail_canonical_name( $k );
    return( $self->pass_error ) if( !defined( $canon ) );
    return( $canon ) if( $canon );

    return( join( '-', map{ ucfirst( $_ ) } split( /-/, $k ) ) );
}

sub _fold_header_line
{
    my $self  = shift( @_ );
    my( $line, $eol, $max ) = @_;

    $max ||= 78;
    # Unsigned integer
    if( $max !~ /^\d+$/ )
    {
        return( $self->error( "The maximum line length value provided (", $self->_str_val( $max ), ") is not an unsigned integer." ) );
    }

    # If already short enough, return unchanged
    if( CORE::length( $line ) <= $max )
    {
        return( $line );
    }

    my $out = '';
    while( CORE::length( $line ) > $max )
    {
        my $cut = $max;

        # Find last WSP within first $max chars
        my $chunk   = substr( $line, 0, $max + 1 );
        my $pos_sp  = rindex( $chunk, ' ' );
        my $pos_tab = rindex( $chunk, "\t" );
        my $pos = $pos_sp > $pos_tab ? $pos_sp : $pos_tab;

        if( $pos > 0 )
        {
            $cut = $pos;
        }

        $out .= substr( $line, 0, $cut ) . $eol . ' ';

        # Drop leading WSP on the remainder
        $line = substr( $line, $cut );
        $line =~ s/^[ \t]+//;
    }
    $out .= $line;
    return( $out );
}

sub _format_rfc5322_date
{
    my $self  = shift( @_ );
    my $epoch = shift( @_ );
    if( !defined( $epoch ) )
    {
        return( $self->error( "No timestamp was provided to get the mail formatted date." ) );
    }

    # Good until 2286
    unless( $epoch =~ /^\d{1,10}$/ )
    {
        return( $self->error( "The timestamp provided is incorrect (", $self->_str_val( $epoch // 'undef' ), "). It should be a 10-digits integer." ) );
    }

    my @wd = qw( Sun Mon Tue Wed Thu Fri Sat );
    my @mo = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    # localtime gives local TZ; we also need numeric offset +HHMM
    my( $sec, $min, $hour, $mday, $mon, $year, $wday ) = localtime( $epoch );

    $year += 1900;

    my $off = $self->_tz_offset_hhmm( $epoch );

    # Because providing an $epoch value of 0 would trigger warnings of uninitialized values.
    no warnings 'uninitialized';
    # Maybe use POSIX::strftime instead ?
    return( sprintf(
        "%s, %02d %s %04d %02d:%02d:%02d %s",
        $wd[$wday],
        $mday,
        $mo[$mon],
        $year,
        $hour,
        $min,
        $sec,
        $off
    ) );
}

sub _generate_message_id
{
    my( $self, $domain ) = @_;

    if( !defined( $domain ) || $domain !~ /\A[A-Za-z0-9](?:[A-Za-z0-9\-\.]*[A-Za-z0-9])?\z/ || $domain !~ /\./ )
    {
        return( $self->error( "Invalid domain for Message-ID generation." ) );
    }

    my $left = $self->_message_id_left_part() ||
        return( $self->pass_error );

    return( '<' . $left . '@' . $domain . '>' );
}

sub _mail_canonical_name
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No header name was provided." ) );
    my $name_lc = lc( $name );
    return( $header_fields_canonical->{ $name_lc } ) if( exists( $header_fields_canonical->{ $name_lc } ) );
    return( '' );
}

sub _mail_header_order
{
    my $self      = shift( @_ );
    my $name_disp = shift( @_ ) ||
        return( $self->error( "No header name was provided." ) );

    my $k = lc( $name_disp );
    $k    =~ tr/_/-/;
    # Moved the header fields order definition table at the top of this module, as a private variable.
    return( exists( $header_fields_order->{ $k } ) ? $header_fields_order->{ $k } : 1000 );
}

sub _message_id_left_part
{
    my( $self ) = @_;

    # Prefer Data::UUID if available
    if( $self->_load_class( 'Data::UUID' ) )
    {
        my $ug  = Data::UUID->new;
        my $bin = $ug->create; # 16 bytes

        # Base64url, no padding, no newline
        $self->_load_class( 'MIME::Base64' ) || return( $self->pass_error );
        my $b64 = MIME::Base64::encode_base64( $bin, '' );
        $b64 =~ tr!+/!-_!;
        $b64 =~ s/=+\z//;

        return( $b64 );
    }

    # Fallback: time+pid+seq+rand
    my $t   = time();
    my $pid = $$;

    our $MSGID_SEQ;
    $MSGID_SEQ = 0 if( !defined( $MSGID_SEQ ) );
    $MSGID_SEQ++;

    my $r = int( rand( 0xFFFFFFFF ) );

    return( sprintf( "%x.%x.%x.%x", $t, $pid, $MSGID_SEQ, $r ) );
}

sub _normalise_name
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No header name was provided to normalise." ) );
    $name = lc( $name );
    $name =~ tr/-//d; # More efficient than $name =~ s/-//g;
    return( $name );
}

sub _sanitize_value
{
    my $self = shift( @_ );
    my $v    = shift( @_ );

    $v = '' if( !defined( $v ) );

    # Freeze stringification NOW (important for objects like Module::Generic::HeaderValue)
    if( ref( $v ) )
    {
        if( !$self->_can_overload( $v => '""' ) )
        {
            $self->error( "Header value is a reference but is not stringifiable (", $self->_str_val( $v ), ")." );
            return;
        }
        $v = "$v";
    }

    # Allow RFC-style folding: CRLF or LF followed immediately by SP/HTAB.
    # All other CR/LF sequences (i.e. attempted header injection) are replaced
    # by a single space instead of being passed through.
    # First, normalise CRLF -> LF
    $v =~ s/\r\n/\n/g;
    # Bare CR -> LF
    $v =~ s/\r/\n/g;
    # Unwrap legal folding: LF + WSP -> single space
    $v =~ s/\n[ \t]+/ /g;
    # Any remaining LF is injection - replace with space
    $v =~ s/\n/ /g;

    # Remove ASCII control chars except tab
    $v =~ s/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]//g;

    return( $v );
}

# This is normally called by _tz_offset_hhmm()
sub _timegm_approx
{
    my $self  = shift( @_ );
    # localtime() and gmtime() return 9 elements in list context; we only need the first 7.
    unless( scalar( @_ ) >= 7 )
    {
        return( $self->error(
            q{_timegm_approx() called improperly. You need to call it as $self->_timegm_approx( $sec, $min, $hour, $mday, $mon, $year, $wday )}
        ) );
    }
    # Discard $yday and $isdst if present
    my @args = @_[0..6];
    my @params = qw( seconds minutes hours day month year weekday );
    for( my $i = 0; $i < scalar( @args ); $i++ )
    {
        if( !$self->_is_number( $args[$i] ) )
        {
            return( $self->error(
                "The ", $params[$i],
                " parameter at offset $i needs to be an integer, but I got '",
                $self->_str_val( $args[$i] // 'undef' ), "'"
            ) );
        }
    }
    my( $sec, $min, $hour, $mday, $mon, $year, $wday ) = @args;

    # localtime/gmtime give: year since 1900, mon 0..11
    $year += 1900;

    # Days since epoch, using a civil->days algorithm (no modules).
    my $y = $year;
    my $m = $mon + 1;

    if( $m <= 2 )
    {
        $y -= 1;
        $m += 12;
    }

    my $era = int( $y / 400 );
    my $yoe = $y - $era * 400;
    my $doy = int( ( 153 * ( $m - 3 ) + 2 ) / 5 ) + $mday - 1;
    my $doe = $yoe * 365 + int( $yoe / 4 ) - int( $yoe / 100 ) + $doy;

    # 719468 is days from 0000-03-01 to 1970-01-01
    my $days = $era * 146097 + $doe - 719468;

    return( $days * 86400 + $hour * 3600 + $min * 60 + $sec );
}

sub _tz_offset_hhmm
{
    my $self  = shift( @_ );
    my $epoch = shift( @_ );

    # Compute offset by comparing localtime and gmtime representations.
    # This avoids non-core modules and works across DST changes.
    my @l = localtime( $epoch );
    my @g = gmtime( $epoch );

    my $lsec = $self->_timegm_approx( @l );
    return( $self->pass_error ) if( !defined( $lsec ) );
    my $gsec = $self->_timegm_approx( @g );
    return( $self->pass_error ) if( !defined( $gsec ) );

    my $delta = $lsec - $gsec;  # seconds east of UTC

    my $sign = '+';
    if( $delta < 0 )
    {
        $sign  = '-';
        $delta = -$delta;
    }

    my $hh = int( $delta / 3600 );
    my $mm = int( ( $delta % 3600 ) / 60 );

    return( sprintf( "%s%02d%02d", $sign, $hh, $mm ) );
}

sub _validate_date_value
{
    my( $self, $v ) = @_;

    # ASCII printable only (SP .. ~), no CR/LF (already handled elsewhere, but we must be explicit)
    # if( $v !~ /\A[\x20-\x7E]*\z/ || $v =~ /[\r\n]/ )
    if( $v !~ /\A[\x20-\x7E]*\z/ )
    {
        return( $self->error( "Invalid Date header (non-ASCII or contains line breaks)." ) );
    }

    # Trim outer blanks for matching
    $v =~ s/\A[[:blank:]]+//;
    $v =~ s/[[:blank:]]+\z//;

    # Optional weekday, strict month names, strict numeric TZ
    my $wd = qr/(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)/;
    my $mo = qr/(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/;

    my $re = qr/
        \A
        (?:
            $wd , [[:blank:]]+
        )?
        (?:0?[1-9]|[12][0-9]|3[01])
        [[:blank:]]+
        $mo
        [[:blank:]]+
        [12][0-9]{3}
        [[:blank:]]+
        (?:[01][0-9]|2[0-3])
        :
        [0-5][0-9]
        :
        [0-5][0-9]
        [[:blank:]]+
        [+-][0-9]{4}
        \z
    /x;

    if( $v !~ $re )
    {
        return( $self->error( "Invalid Date header syntax." ) );
    }
    return(1);
}

sub _validate_field_name
{
    my $self = shift( @_ );
    my $name = shift( @_ ) ||
        return( $self->error( "No field name was provided to check." ) );

    unless( $name =~ /^[\x21-\x39\x3B-\x7E]+$/ )
    {
        return( $self->error( "Invalid header field name '${name}': must be printable ASCII with no colon or whitespace." ) );
    }
    return(1);
}

sub _validate_message_id_value
{
    my( $self, $v ) = @_;

    # ASCII visible only, no spaces, no control chars
    if( $v !~ /\A[\x21-\x7E]+\z/ )
    {
        return( $self->error( "Invalid Message-ID (non-ASCII or contains spaces/control characters)." ) );
    }

    # Must be wrapped in angle brackets
    if( $v !~ /\A<([^<>]+)>\z/ )
    {
        return( $self->error( "Invalid Message-ID (missing angle brackets)." ) );
    }

    my $inner = $1;

    # Exactly one '@'
    if( $inner !~ /\A([^@]+)\@([^@]+)\z/ )
    {
        return( $self->error( "Invalid Message-ID (must contain exactly one '\@')." ) );
    }

    my $local  = $1;
    my $domain = $2;

    # Local-part: pragmatic (not full RFC)
    if( $local !~ /\A[A-Za-z0-9.!#\$%&'\*\+\/=\?\^_`\{\|\}~\-]+\z/ )
    {
        return( $self->error( "Invalid Message-ID local-part." ) );
    }

    # Domain: pragmatic
    if( $domain !~ /\A[A-Za-z0-9](?:[A-Za-z0-9\-\.]*[A-Za-z0-9])?\z/ || $domain !~ /\./ )
    {
        return( $self->error( "Invalid Message-ID domain." ) );
    }

    return(1);
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Headers - Mail Header Collection for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Headers;

    my $h = Mail::Make::Headers->new ||
        die( Mail::Make::Headers->error );

    $h->set( 'MIME-Version', '1.0' );
    $h->content_type( 'text/html; charset=utf-8' );
    $h->content_transfer_encoding( 'quoted-printable' );
    $h->content_id( 'part1.abc@example.com' );

    print $h->as_string;

=head1 VERSION

    v0.9.0

=head1 DESCRIPTION

An ordered collection of mail header fields for L<Mail::Make::Entity>.

Provides typed accessors for the headers most relevant to MIME construction (C<Content-Type>, C<Content-Disposition>, C<Content-Transfer-Encoding>, C<Content-ID>), with strict validation on every assignment, plus a generic L</set>/L</get> interface for arbitrary headers.

Header injection is prevented: field names and values are validated for illegal characters on every L</set> call.

=head2 Field names

Field names are treated case-insensitively, and C<_> may be used instead of C<-> (for example C<Content_Type> is treated as C<Content-Type>). Names are canonicalised for storage (e.g. C<Message-ID>, C<MIME-Version>, C<Content-Type>).

=head2 Values and security

Values are sanitised to prevent header injection:

=over 4

=item *

CR and LF are replaced with spaces.

=item *

ASCII control characters are removed (except tab).

=back

This keeps the header container safe even if values originate from external
input.

=head2 Ordering

Email headers sometimes have meaningful ordering (e.g. C<Received:> lines).
For this reason, C<as_string_without_sort> preserves insertion order and is recommended for general email usage.

C<as_string> applies a conservative ordering suitable for display or certain use-cases, but may not be appropriate for all messages.

=head1 METHODS

=head2 new

    my $h = Mail::Make::Headers->new;
    my $h = Mail::Make::Headers->new( Field => Value, ... );

Construct a new headers object. Constructor pairs are passed through C<push_header>.

=head2 as_string( [ $eol ] )

Returns all headers as a single string, each line terminated by C<$eol> (default CRLF). Does B<not> include the trailing blank line that separates headers from body.

=head2 as_string_without_sort

    my $s = $h->as_string_without_sort;
    my $s = $h->as_string_without_sort( $eol );

Return formatted header lines preserving insertion order. Recommended for general email usage.

=head2 clear

    $h->clear;

Remove all header fields.

=head2 content_disposition( [ $value ] )

Convenience typed accessor for the C<Content-Disposition> header. On retrieval returns a L<Mail::Make::Headers::ContentDisposition> object, or C<undef> if not set.

=head2 content_id( [ $value ] )

Sets or gets the C<Content-ID> header. Angle brackets are normalised automatically. Validates for control characters.

=head2 content_transfer_encoding( [ $encoding ] )

Sets or gets the C<Content-Transfer-Encoding> header. Validates that the value is one of C<7bit>, C<8bit>, C<binary>, C<base64>, or C<quoted-printable>. Value is normalised to lowercase.

=head2 content_type( [ $value ] )

Convenience typed accessor for the C<Content-Type> header. On retrieval returns a L<Mail::Make::Headers::ContentType> object, or C<undef> if not set.

=head2 get

    my @values = $h->get( $field );
    my $value  = $h->get( $field );

Alias for:

    $h->header( $field );

In list context returns all values for the field. In scalar context returns the values joined with C<", ">.

=head2 has( $name )

Returns 1 if the named header is present, 0 otherwise.

=head2 header

    $h->header( $field )
    $h->header( $field => $value )
    $h->header( $f1 => $v1, $f2 => $v2, ... )

Get or set header fields.

In list context, a multi-valued field is returned as a list of values.

In scalar context, values are returned joined with C<", ">.

When setting multiple fields, the old value(s) of the last field is returned (C<undef> if the field did not exist).

The C<$value> may be a string (or something that stringifies) or an arrayref of strings. Values are sanitised as described above.

=head2 header_field_names

    my @names = $h->header_field_names;
    my $names = $h->header_field_names;

Return the list of distinct field names (canonical spelling). In scalar context returns an arrayref.

=head2 length

    my $count = $h->length;

Returns the total number of header field B<entries> currently stored.

Each value is counted separately, so a multi-valued field (set via repeated calls to L</push_header>) contributes one to the count per value added.

Returns C<0> when no headers have been set.

=head2 init_header

    $h->init_header( $field => $value )

Set the header only if it is not already present.

=head2 new_field( $name [, $value ] )

Factory method: returns a new typed header object (L<Mail::Make::Headers::ContentType>, L<Mail::Make::Headers::ContentDisposition>, etc.) or a L<Mail::Make::Headers::Generic> object for unknown field names.

=head2 print( $fh )

Writes all headers followed by a blank line to the given filehandle.

=head2 add( $field => $value )

    $h->add( 'X-Custom' => 'hello' );
    $h->add( $f1 => $v1, $f2 => $v2, ... );

Alias for L</push_header>. Adds value(s) for the specified field(s) without removing any pre-existing values.

=head2 message_id( [$value | %opts] )

    # Read current Message-ID
    my $mid = $h->message_id;

    # Set an explicit value
    $h->message_id( '<unique@example.com>' );

    # Generate a new Message-ID automatically
    $h->message_id( { generate => 1, domain => 'example.com' } );

    # Remove the Message-ID header
    $h->message_id( undef );

Accessor and generator for the C<Message-ID> header field.

Called with no arguments, returns the current C<Message-ID> value.

Called with a plain string, sets the C<Message-ID> to that value after clearing any existing one. If C<< { strict => 1 } >> is passed in the options hash, the value is validated against the RFC 2822 msg-id grammar.

Called with C<< { generate => 1 } >>, a new unique Message-ID is generated using the supplied C<domain> option (or the system hostname if none is given).
The domain must be a valid FQDN containing at least one dot.

Called with C<undef>, removes the C<Message-ID> header.

Returns C<$self> in setter mode, the Message-ID string in getter mode, and C<undef> on error.

=head2 push_header

    $h->push_header( $field => $value )
    $h->push_header( $f1 => $v1, $f2 => $v2, ... )

Add new value(s) for the specified field(s). Previous values are retained.

C<$value> may be a scalar or an arrayref.

=head2 remove( $field, ... )

    $h->remove( 'X-Custom' );
    $h->remove( 'Cc', 'Bcc' );

Alias for L</remove_header>.

=head2 remove_header( $field, ... )

    $h->remove_header( $field, ... )

Remove the specified fields and return the removed values.

In list context, returns the values removed.

In scalar context, returns the last removed value or C<0> if nothing was removed.

=head2 replace( $field => $value )

    $h->replace( 'Subject' => 'New subject' );

Alias for L</replace_header>.

=head2 replace_header

    $h->replace_header( $field => $value )
    $h->replace_header( $f1 => $v1, $f2 => $v2, ... )

Replace the value(s) of one or more header fields.

All existing occurrences of the specified field are removed before the new value(s) are added.

If C<$value> is C<undef>, the field is removed.

The old value(s) of the last field processed are returned. In list context, all previous values are returned. In scalar context, values are returned joined with C<", ">.

This method is similar to C<header()> in setter mode, but explicitly treats C<undef> as a request to delete the field.

=head2 reset( [$flag] )

    $h->reset(1);

Internal cache-invalidation method. When called with a true value, signals that the serialised header string cached internally is stale and must be regenerated on the next call to L</as_string>.

User code rarely needs to call this directly; it is invoked automatically by any method that modifies the header set (L</add>, L</remove_header>, L</replace_header>, L</message_id>, etc.).

=head2 scan

    $h->scan( sub { my( $k, $v ) = @_; ... } );

Call the callback for each stored header field/value pair (one call per value).

=head2 set

    $h->set( $field => $value );
    $h->set( $f1 => $v1, $f2 => $v2, ... );

Alias for C<replace_header()>.

If C<$value> is C<undef>, the field is removed.

=head2 exists

    if( $h->exists( $field ) ) { ... }

Return true if at least one value is present for the given field.

Field names are case-insensitive and C<_> is treated as C<->.

=head2 set( $name, $value )

Sets (replaces or appends) the named header. C<$value> may be a plain string or any object that stringifies.

Validates the field name (printable ASCII, no colon or whitespace) and the value (no bare CR/LF header injection).

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Entity>, L<Mail::Make::Headers::Generic>, L<Mail::Make::Headers::ContentType>, L<Mail::Make::Headers::ContentDisposition>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
