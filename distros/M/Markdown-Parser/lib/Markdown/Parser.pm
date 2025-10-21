##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser.pm
## Version v0.5.0
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2025/10/21
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $ELEMENTS_DICTIONARY $ELEMENTS_DICTIONARY_EXTENDED $VERSION $DEBUG );
    use POSIX ();
    use Regexp::Common qw( Markdown );
    use CSS::Object;
    use Scalar::Util ();
    our $DEBUG = 0;
    our $VERSION = 'v0.5.0';
    # Including vertical space like new lines
    our $ELEMENTS_DICTIONARY =
    {
        block => [qw( blockquote code_block code_line header html line list paragraph )],
        inline => [qw( abbr bold code_span emphasis image link_auto line_break link )],
    };
    $ELEMENTS_DICTIONARY->{all} = [@{$ELEMENTS_DICTIONARY->{block}}, @{$ELEMENTS_DICTIONARY->{inline}}];
    our $ELEMENTS_DICTIONARY_EXTENDED =
    {
        block => [qw( code_block header katex )],
        inline => [qw( abbr checkbox footnote insert katex strikethrough superscript subscript )],
    };
    $ELEMENTS_DICTIONARY_EXTENDED->{all} = [@{$ELEMENTS_DICTIONARY_EXTENDED->{block}}, @{$ELEMENTS_DICTIONARY_EXTENDED->{inline}}];
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{abbreviation_case_sensitive}    = 0;
    $self->{charset}                        = 'utf8';
    $self->{code_highlight}                 = 0;
    $self->{css_grid}                       = 0;
    $self->{debug}                          = $DEBUG;
    # See Markdown::Parser::Link
    $self->{default_email}                  = '';
    $self->{document}                       = '';
    $self->{email_obfuscate_class}          = 'courriel';
    $self->{email_obfuscate_data_host}      = 'host';
    $self->{email_obfuscate_data_user}      = 'user';
    $self->{encrypt_email}                  = 0;
    $self->{footnote_ref_sequence}          = 0;
    $self->{callback}                       = undef;
    $self->{katex_delimiter}                = ['$$','$$','$','$','\[','\]','\(','\)'];
    $self->{list_level}                     = 0;
    $self->{mode}                           = 'all';
    # Top scope as specified by the user
    $self->{scope}                          = '';
    $self->{_init_strict_use_sub}           = 1;
    use utf8;
    $self->{colour_open}                    = '{';
    $self->{colour_close}                   = '}';
    $self->SUPER::init( @_ );
    return( $self );
}

sub abbreviation_case_sensitive { return( shift->_set_get_scalar( 'abbreviation_case_sensitive', @_ ) ); }

sub callback { return( shift->_set_get_code( 'callback', @_ ) ); }

sub charset { return( shift->_set_get_scalar( 'charset', @_ ) ); }

sub code_highlight { return( shift->_set_get_boolean( 'code_highlight', @_ ) ); }

sub create_document
{
    my $self = shift( @_ );
    my $class = ref( $self ) || $self;
    $class .= '::Document';
    $self->_load_class( $class ) || return;
    return( $class->new( @_, debug => $self->debug ) );
}

sub css
{
    my $self = shift( @_ );
    my $css = $self->_set_get_object( 'css', 'CSS::Object', @_ );
    return( $css ) if( $css );
    $css = CSS::Object->new;
    $self->_set_get_object( 'css', 'CSS::Object', $css );
    return( $css );
}

sub css_builder { return( shift->css->builder ); }

sub css_grid { return( shift->_set_get_boolean( 'css_grid', @_ ) ); }

sub default_email { return( shift->_set_get_scalar_as_object( 'default_email', @_ ) ); }

sub document { return( shift->_set_get_object( 'document', 'Markdown::Parser::Document', @_ ) ); }

sub email_obfuscate_class { return( shift->_set_get_scalar_as_object( 'email_obfuscate_class', @_ ) ); }

sub email_obfuscate_data_host
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( $_[0] =~ /^[a-zA-Z]\w+$/ )
        {
            return( $self->_set_get_scalar_as_object( 'email_obfuscate_data_host', @_ ) );
        }
        else
        {
            return( $self->error( "Invalid value \"$_[0]\" for the email obfuscation data-host attribute name." ) );
        }
    }
    return( $self->_set_get_scalar_as_object( 'email_obfuscate_data_host' ) );
}

sub email_obfuscate_data_user
{
    my $self = shift( @_ );
    if( @_ )
    {
        if( $_[0] =~ /^[a-zA-Z]\w+$/ )
        {
            return( $self->_set_get_scalar_as_object( 'email_obfuscate_data_user', @_ ) );
        }
        else
        {
            return( $self->error( "Invalid value \"$_[0]\" for the email obfuscation data-user attribute name." ) );
        }
    }
    return( $self->_set_get_scalar_as_object( 'email_obfuscate_data_user' ) );
}

sub encrypt_email { return( shift->_set_get_scalar_as_object( 'encrypt_email', @_ ) ); }

sub footnote_ref_sequence : lvalue { return( shift->_set_get_lvalue( 'footnote_ref_sequence', @_ ) ); }

sub from_html
{
    my $self = shift( @_ );
    my $html = shift( @_ ) || return( $self->error( "No HTML::Object::Document was provided." ) );
    if( !$self->_is_a( $html => 'HTML::Object::Document' ) )
    {
        return( $self->error( "Value provided (", overload::StrVal( $html ), ") is not an HTML::Object::Document object." ) );
    }

    my $doc = $self->create_document(
        abbreviation_case_sensitive => $self->abbreviation_case_sensitive,
        default_email               => $self->default_email,
        email_obfuscate_class       => $self->email_obfuscate_class,
        email_obfuscate_data_host   => $self->email_obfuscate_data_host,
        email_obfuscate_data_user   => $self->email_obfuscate_data_user,
        css         => $self->css,
        debug       => $self->debug,
        tag_name    => 'top',
    );
    # Sharing the parameter
    $doc->katex_delimiter( $self->katex_delimiter );
    $self->document( $doc ) if( !$self->document );
    
    my $seen = {};
    my $crawl;
    $crawl = sub
    {
        my $e = shift( @_ );
        # Markdown Element
        my $me = shift( @_ );
        my $addr = Scalar::Util::refaddr( $e );
        # Duplicate
        return if( ++$seen->{ $addr } > 1 );
        my $tag = $e->tag;
        my $top;
        if( $tag eq 'abbr' )
        {
            my $name = $e->content->map( $_->as_string )->scalar;
            my $val  = $e->attr( 'title' );
            my $elem = $doc->create_abbreviation({
                name => $name,
                value => $val,
            }) || return( $self->pass_error );
            $me->add_element( $elem ) || return( $self->pass_error );
        }
        elsif( $tag eq 'blockquote' )
        {
            $top = $doc->create_blockquote || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'b' )
        {
            $top = $doc->create_bold || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'checkbox' )
        {
            $top = $doc->create_checkbox({
                checked => $e->attributes->exists( 'checked' ),
                disabled => $e->attributes->exists( 'disabled' ),
            }) || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'code' )
        {
            my $test_str = $e->children->map(sub{ $_->as_string })->join( '' )->scalar;
            my $is_fenced = ( CORE::index( $test_str, "\n" ) != -1 ) ? 1 : 0;
            $top = $doc->create_code({
                fenced => $is_fenced,
                inline => !$is_fenced,
            }) || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'em' )
        {
            $top = $doc->create_em || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'h1' ||
               $tag eq 'h2' ||
               $tag eq 'h3' ||
               $tag eq 'h4' ||
               $tag eq 'h5' ||
               $tag eq 'h6' )
        {
            my $level = int( substr( $tag, -1, 1 ) );
            $top = $doc->create_header({ level => $level }) || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'img' )
        {
            $top = $doc->create_image({
                ( $e->attr( 'alt' ) ? ( alt => $e->attr( 'alt' ) ) : () ),
                ( $e->attr( 'id' ) ? ( id => $e->attr( 'id' ) ) : () ),
                ( $e->attr( 'title' ) ? ( title => $e->attr( 'title' ) ) : () ),
                ( $e->attr( 'src' ) ? ( url => $e->attr( 'src' ) ) : () ),
            }) || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'ins' )
        {
            $top = $doc->create_insertion || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'hr' )
        {
            # <hr> cannot have children so use $elem instead of $top
            my $elem = $doc->create_line || return( $self->pass_error );
            $me->add_element( $elem ) || return( $self->pass_error );
        }
        elsif( $tag eq 'a' )
        {
            if( $e->attr( 'href' ) )
            {
                $top = $doc->create_link({
                    ( $e->attr( 'name' ) ? ( name => $e->attr( 'name' ) ) : () ),
                    ( $e->attr( 'id' ) ? ( id => $e->attr( 'id' ) ) : () ),
                    ( $e->attr( 'title' ) ? ( title => $e->attr( 'title' ) ) : () ),
                    url => $e->attr( 'href' ),
                }) || return( $self->pass_error );
                $me->add_element( $top ) || return( $self->pass_error );
            }
            # else, an anchor, and we ignore it, and move on to add it possible children directly here at the same level
        }
        elsif( $tag eq 'ul' ||
               $tag eq 'ol' )
        {
            my $indent = 0;
            my $is_ordered = ( $tag eq 'ol' ? 1 : 0 );
            if( $me->tag_name eq 'list_item' )
            {
                $indent = $me->indent + 1;
            }
            $top = $doc->create_list({
                indent => $indent,
                order  => $is_ordered,
            }) || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'li' )
        {
            my $indent = 0;
            my $is_ordered = 0;
            if( $me->tag_name eq 'list' )
            {
                $indent = $me->indent + 1;
                $is_ordered = $me->order ? 1 : 0;
            }
            $top = $doc->create_list_item({
                indent => $indent,
            }) || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'br' )
        {
            # <br> cannot have children so use $elem instead of $top
            my $elem = $doc->create_new_line || return( $self->pass_error );
            $me->add_element( $elem ) || return( $self->pass_error );
        }
        elsif( $tag eq 'p' )
        {
            $top = $doc->create_paragraph || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 's' || $tag eq 'del' )
        {
            $top = $doc->create_strikethrough || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'sub' )
        {
            $top = $doc->create_subscript || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'sup' )
        {
            $top = $doc->create_superscript || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'table' )
        {
            $top = $doc->create_table || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'tbody' )
        {
            $top = $doc->create_table_body || return( $self->pass_error );
            if( $me->tag_name eq 'table' )
            {
                $me->add_body( $top ) || return( $self->pass_error );
            }
            else
            {
                $me->add_element( $top ) || return( $self->pass_error );
            }
        }
        elsif( $tag eq 'thead' )
        {
            $top = $doc->create_table_header || return( $self->pass_error );
            if( $me->tag_name eq 'table' )
            {
                $me->add_header( $top ) || return( $self->pass_error );
            }
            else
            {
                $me->add_element( $top ) || return( $self->pass_error );
            }
        }
        elsif( $tag eq 'tr' )
        {
            $top = $doc->create_table_row || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'td' )
        {
            $top = $doc->create_table_cell || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'th' )
        {
            $top = $doc->create_table_cell({
                tag_name => 'th',
            }) || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq 'caption' )
        {
            $top = $doc->create_table_caption || return( $self->pass_error );
            $me->add_element( $top ) || return( $self->pass_error );
        }
        elsif( $tag eq '_text' || $tag eq '_space' )
        {
            # text chunk cannot have children so use $elem instead of $top
            my $elem = $doc->create_text({
                text => $e->value,
            }) || return( $self->pass_error );
            $me->add_element( $elem ) || return( $self->pass_error );
        }
        elsif( $tag eq '_document' )
        {
            $e->children->foreach(sub
            {
                $crawl->( $_[0] => $me );
            });
        }
        # Anything else, and we save it as raw HTML, and we do not delve deeper
        else
        {
            my $raw = $e->as_string;
            my $elem = $doc->create_html({
                object => $e,
                raw => $raw,
            }) || return( $self->pass_error );
            $me->add_element( $elem ) || return( $self->pass_error );
        }
        
        if( defined( $top ) )
        {
            $e->children->foreach(sub
            {
                $crawl->( $_[0] => $top );
            });
        }
    };
    $crawl->( $html => $doc );
    return( $doc );
}

sub katex_delimiter { return( shift->_set_get_array_as_object( 'katex_delimiter', @_ ) ); }

# Nothing fancy, and used internally so no chaining or anything
# We use it like $p->list_level++ or $p->list_level--;
sub list_level : lvalue { return( shift->_set_get_lvalue( 'list_level', @_ ) ); }

sub mode
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $mode = shift( @_ );
        my $curr = $self->_set_get_scalar( 'mode' );
        my $ref  = $self->new_array( [split( /[[:blank:]]+/, $curr )] );
        if( substr( $mode, 0, 1 ) eq '+' )
        {
            $mode =~ s/^\++//g;
            $ref->push( $mode );
        }
        elsif( substr( $mode, 0, 1 ) eq '-' )
        {
            $mode =~ s/^\-+//g;
            $ref->remove( $mode );
        }
        else
        {
            $ref->push( $mode );
        }
        $ref->unique(1);
        $curr = $ref->join( ' ' )->scalar;
        $self->_set_get_scalar( 'mode', $curr );
    }
    return( $self->_set_get_scalar( 'mode' ) );
}

sub parse
{
    my $self = shift( @_ );
    # We accept empty data and we return empty elements array then
    my $data = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my $cb = $self->callback;
    if( !defined( $cb ) )
    {
        $cb = sub{1};
    }
    elsif( ref( $cb ) )
    {
        return( $self->error( "Callback set (${cb}) is not a code reference." ) );
    }

    unless( $opts->{element} )
    {
        # Standardise the new lines characters
        # $data =~ s/\cM/\n/gs;
        # $data =~ s/\c@//g;
        $data =~ s/\r\n/\n/gs;
        $data =~ s/\r//gs;
        # Clean up the empty lines as they do not matter
        $data =~ s/^[[:blank:]\h]+$//gm;
        # Detab
        # Cribbed from a post by Bart Lateur:
        # <http://www.nntp.perl.org/group/perl.macperl.anyperl/154>
        my $tab_width = 4;
        $data =~ s{(.*?)\t}{$1 . ( ' ' x ( $tab_width - length( $1 ) % $tab_width ) )}ge;
        # Make sure $text ends with a couple of newlines, unless this is sub parsing
        my $trailing_nl = ( $data =~ /(\n+)$/ )[0];
        my $nth_nl = defined( $trailing_nl ) ? length( $trailing_nl ) : 0;
        unless( $nth_nl > 1 )
        {
            $data .= ( "\n" x ( 2 - $nth_nl ) );
        }
    }


    pos( $data ) = 0;
    # all excludes extended markdowns
    my $mode = $self->mode || 'all';
    my $space_re = qr/[[:blank:]\h]{1,3}/;
    my $PH_PREFIX = 'OBJ{';
    my $PH_SUFFIX = '}';
    my $top;
    if( !( $top = $opts->{element} ) )
    {
        my $doc = $self->create_document(
            abbreviation_case_sensitive => $self->abbreviation_case_sensitive,
            default_email               => $self->default_email,
            email_obfuscate_class       => $self->email_obfuscate_class,
            email_obfuscate_data_host   => $self->email_obfuscate_data_host,
            email_obfuscate_data_user   => $self->email_obfuscate_data_user,
            css         => $self->css,
            debug       => $self->debug,
            tag_name    => 'top',
        );
        # Sharing the parameter
        $doc->katex_delimiter( $self->katex_delimiter );
        # First time called, we reset the top document, so the same parser can be called several times
        $self->document( $doc );
        $top = $doc;
    };
    $self->messagef_colour( 3, "%s %d bytes of data with mode set to '{green}%s{/}' with container being '{green}%s{/}'.", ( $opts->{element} ? "Sub-parsing" : "Parsing" ), length( $data ), $mode, $top->tag_name );

    # Previous element added. We store it here to keep track of context
    my $context;
    # pos( $data ) = 0;
    pos( $data ) = $opts->{pos} if( length( $opts->{pos} ) && $opts->{pos} =~ /^\d+$/ );
    $opts->{scope_cond} = 'any';
    # If the 'scope' option has not been provided, or is not an array
    if( !$self->_is_array( $opts->{scope} ) )
    {
        # Split the scope option to make it an array, or else split the object 'mode' option
        $opts->{scope} = length( $opts->{scope} ) ? [split( /\s+/, $opts->{scope} )] : [split( /\s+/, $mode )];
    }
    # The option 'scope' is an array, but it is empty
    elsif( $self->_is_array( $opts->{scope} ) &&
        !$self->_to_array_object( $opts->{scope} )->length )
    {
        $opts->{scope} = $self->_is_empty( $mode ) ? [] : $self->_is_array( $mode ) ? $mode : ["$mode"];
    }

    if( length( $opts->{scope} ) && $self->_is_array( $opts->{scope} ) )
    {
        my $scopes = $self->new_array;
        $self->_to_array_object( $opts->{scope} )->foreach(sub
        {
            # OR
            if( s/\|{1,2}/ /g )
            {
                $scopes->push( split( /\s+/, $_ ) );
                $opts->{scope_cond} = 'any';
            }
            # AND
            elsif( s/(?:\&{1,2}|\+)/ /g )
            {
                $scopes->push( split( /\s+/, $_ ) );
                $opts->{scope_cond} = 'all';
            }
            # Scope term
            else
            {
                $scopes->push( $_ );
            }
        });
        $opts->{scope} = $scopes;
    }

    my $scope = Markdown::Parser::Scope->new( $opts->{scope}, debug => $self->debug, condition => $opts->{scope_cond} );
    $self->scope( $scope ) if( $top->tag_name eq 'top' && !$self->scope );
    
    my $katex_re;
    # We check for link definitions, but only if we are in the top element, since sub elements would not hold any of them and it would thus be pointless to process them
    # Need to remove the link definition from the document
    if( $top->tag_name eq 'top' )
    {
        # NOTE: html
        # Need to isolate html code blocks, because their indentation can be mistaken for code blocks.
        # Then, we parse for code block, we re-instate the html block found and isolated.
        if( $scope->has( [qw( html )]) )
        {
            $data =~ s{$RE{Markdown}{Html}}
            {
                my $re = { %+ };
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                # my $html = $re->{tag_all};
                # We save exactly what we caught
                my $html = substr( $data, $-[0], $+[0] - $-[0] );
                my $elem = $top->create_html({
                    pos => $pos,
                    raw => $html,
                }) || die( $top->error );
                my $id = $self->document->add_object( $elem ) || die( $top->error );
                "!!HTML[$id]!!";
            }xgems;
        }

        # NOTE: extended code_block
        # Code blocks trumps everything else, so they come first
        # First, check the parts that are surrounded by backticks or equivalents
        $self->message_colour( 3, "Does scope have '{green}extended code_block{/}' ? ", $scope->has( [qw( extended code_block )] ) ? '{green}yes{/}' : '{red}no{/}' );
        if( $scope->has( [qw( extended code_block )] ) )
        {
            $data =~ s{$RE{Markdown}{ExtCodeBlock}}
            {
                my $re = { %+ };
                $re->{capture} = substr( $data, $-[0], $+[0] - $-[0] );
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $code_def = $re->{code_attr};
                my $code_class = $re->{code_class};
                my $raw = $re->{code_all};
                my $content = $re->{code_content};
                
                # Restore any html that got caught previously
                $content =~ s{\!{2}HTML\[(?<obj_id>\d+)\]\!{2}}
                {
                    my $obj_id = $+{obj_id};
                    my $obj = $self->document->objects->get( $obj_id );
                    if( $obj )
                    {
                        $obj->raw->scalar;
                    }
                    else
                    {
                        "!!HTML[${obj_id}]!!";
                    }
                }xgems;
        
                $code_def =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//gs if( defined( $code_def ) );
                $code_class =~ s/^[\.[:blank:]\h]+//gs if( defined( $code_class ) );
        
                my $code = $top->create_code({
                    class => [split( /\./, $code_class )],
                    pos => $pos,
                    raw => $raw,
                    fenced => 1,
                });
                $code->add_element( $top->create_text({
                    text => $content,
                    pos => $pos,
                }) ) || return( $self->pass_error( $code->error ) );
                $code->add_attributes( $code_def ) if( length( $code_def ) );
                my $id = $top->add_object( $code );
                "${PH_PREFIX}${id}${PH_SUFFIX}\n";
            }xgems;
        }
        # NOTE: code_block
        elsif( $self->message_colour( 3, "Does scope have '{green}code_block{/}' ? ", $scope->has( 'code_block' ) ? '{green}yes{/}' : '{red}no{/}' ) && $scope->has( 'code_block' ) )
        {
            $data =~ s{$RE{Markdown}{CodeBlock}}
            {
                my $re = { %+ };
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $raw = $re->{code_all};
                my $content = $re->{code_content};
                # my $new_lines = $re->{code_trailing_new_line};
                
                # Restore any html that got caught previously
                $content =~ s{\!{2}HTML\[(?<obj_id>\d+)\]\!{2}}
                {
                    my $obj_id = $+{obj_id};
                    my $obj = $self->document->objects->get( $obj_id );
                    if( $obj )
                    {
                        $obj->raw->scalar;
                    }
                    else
                    {
                        "!!HTML[${obj_id}]!!";
                    }
                }xgems;
        
                my $code = $top->create_code({
                    pos => $pos,
                    raw => $raw,
                    fenced => 1,
                });
                $code->add_element( $top->create_text({
                    text => $content,
                    pos => $pos,
                }) ) || return( $self->pass_error( $code->error ) );
                my $id = $top->add_object( $code );
                "${PH_PREFIX}${id}${PH_SUFFIX}\n";
            }xgems;
        }

        # NOTE: code_line
        $self->message_colour( 3, "Does scope have '{green}code_line{/}' ? ", $scope->has( 'code_line' ) ? '{green}yes{/}' : '{red}no{/}' );
        # Code single line. If it is a series of them treat them as a block
        if( $scope->has( 'code_line' ) )
        {
            $data =~ s{$RE{Markdown}{CodeLine}}
            {
                my $re = { %+ };
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $raw = $re->{code_all};
                my $content = $re->{code_all};
                
                ## Restore any html that got caught previously
                $content =~ s{\!{2}HTML\[(?<obj_id>\d+)\]\!{2}}
                {
                    my $obj_id = $+{obj_id};
                    my $obj = $self->document->objects->get( $obj_id );
                    if( $obj )
                    {
                        $obj->raw->scalar;
                    }
                    else
                    {
                        "!!HTML[${obj_id}]!!";
                    }
                }xgems;
        
                # trim leading newlines
                $content =~ s/\A\n+//;
                # trim trailing whitespace
                $content =~ s/\s+\z//;
                my $trailing_nl = $self->_total_trailing_new_lines( $raw );
                my $code = $top->create_code({
                    # Setting this to true will have the leading 4 spaces or tab removed
                    fenced => 1,
                    pos => $pos,
                    raw => $re->{code_all},
                });
                $code->add_element( $top->create_text({
                    text => $content,
                    pos => $pos,
                }) ) || return( $self->pass_error( $code->error ) );
                my $id = $top->add_object( $code );
                # Move back before the trailing new lines as they may be important for the next check
                "${PH_PREFIX}${id}${PH_SUFFIX}\n";
            }xgems;
        }

        # NOTE: Restore any html blocks if any
        # Restore any html blocks if any
        $data =~ s{\!{2}HTML\[(?<obj_id>\d+)\]\!{2}}
        {
            my $obj_id = $+{obj_id};
            my $obj = $self->document->objects->get( $obj_id );
            if( $obj )
            {
                $obj->raw->scalar;
            }
            else
            {
                "!!HTML[${obj_id}]!!";
            }
        }xgems;

        
        pos( $data ) = 0;
        # NOTE: code_span
        # Inline code `some thing`
        if( $scope->has( 'code_span' ) )
        {
            $data =~ s{$RE{Markdown}{CodeSpan}}
            {
                my $re = { %+ };
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $raw = $re->{code_all};
                my $content = $re->{code_content};
                $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found an inline code '$raw' at pos '$pos' with content:\n'{green}" . $content . "{/}' and with capture: " . $self->dump( $re ), return => 1 } ) );
                # leading whitespace
                $content =~ s/^[ \t]*//g;
                # trailing whitespace
                $content =~ s/[ \t]*$//g;
                my $code = $top->create_code({
                    inline => 1,
                    pos => $pos,
                    raw => $raw,
                });
                $code->add_element( $top->create_text({
                    text => $content,
                    pos => $pos,
                }) );
                my $id = $top->add_object( $code );
                "${PH_PREFIX}${id}${PH_SUFFIX}";
            }xgems;
        }
       
        $self->messagef_colour( 3, "%d objects found so far.", $top->objects->length );
        
        # NOTE: extended link
        $self->message_colour( 3, "Processing possible {green}link{/} definitions." );
        $data =~ s{$RE{Markdown}{ExtLinkDefinition}}
        {
            my $re = { %+ };
            my $id = $re->{link_id};
            my $url = $re->{link_url};
            my $title = $re->{link_title};
            my $link_def = $re->{link_attr};
            my $raw = $re->{link_all};
            my $end = pos( $data );
            my $start = $end - length( $re->{link_all} );
            $self->message_colour( 3, $self->whereami( \$data, pos( $data ), { text => "Found link definition with id '{green}" . $re->{link_id} . "{/}', url '{green}" . $re->{link_url} . "{/}', title '{green}" . $re->{link_title} . "{/}', all '{green}" . $re->{link_all} . "{/}' at position '" . $start . "' until position '" . $end . "'.", return => 1 } ) );
            my $lnk = $top->create_link_definition({
                link_id => $id,
                pos => pos( $data ),
                raw => $raw,
                title => $title,
                url => $url,
            });
            $link_def =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//gs;
            $lnk->add_attributes( $link_def ) if( length( $link_def ) );
            ## Just register the link definition, but do not add it to the document
            $top->register_link_definition( $lnk );
            '';
        }gme;

        # NOTE: link
        $data =~ s{$RE{Markdown}{LinkDefinition}}
        {
            my $re = { %+ };
            my $id = $re->{link_id};
            my $url = $re->{link_url};
            my $title = $re->{link_title};
            my $raw = $re->{link_all};
            my $end = pos( $data );
            my $start = $end - length( $re->{link_all} );
            $self->message_colour( 3, $self->whereami( \$data, pos( $data ), { text => "Found link definition with id '{green}" . $re->{link_id} . "{/}', url '{green}" . $re->{link_url} . "{/}', title '{green}" . $re->{link_title} . "{/}', all '{green}" . $re->{link_all} . "{/}' at position '" . $start . "' until position '" . $end . "'.", return => 1 } ) );
            my $lnk = $top->create_link_definition({
                link_id => $id,
                pos => pos( $data ),
                raw => $raw,
                title => $title,
                url => $url,
            });
            # Just register the link definition, but do not add it to the document
            $top->register_link_definition( $lnk );
            '';
        }gme;

        pos( $data ) = 0;
        # NOTE: extended abbr
        $self->message_colour( 3, "Does scope have '{green}abbr{/}' ? ", $scope->has( [qw( extended abbr )] ) ? '{green}yes{/}' : '{red}no{/}' );
        if( $scope->has( [qw( extended abbr )] ) )
        {
            $data =~ s{^[[:blank:]\h]{0,3}$RE{Markdown}{ExtAbbr}}
            {
                my $re = { %+ };
                my $end = pos( $data );
                my $start = $end - length( $re->{abbr_all} );
                $self->message_colour( 3, $self->whereami( \$data, pos( $data ), { text => "Found abbreviation \"{green}" . $re->{abbr_all} . "{/}\" with name '{green}" . $re->{abbr_name} . "{/}' with capture: " . $self->dump( $re ), return => 1 } ) );
                my $abbr = $top->create_abbreviation({
                    name => $re->{abbr_name},
                    value => $re->{abbr_value},
                    parent => $top,
                    pos => pos( $data ),
                    raw => $re->{abbr_all},
                });
                $top->register_abbreviation( $abbr, { case_sensitive => $self->abbreviation_case_sensitive } );
                '';
            }gme;
        }

        # NOTE: extended footnote
        $self->message_colour( 3, "Does scope have '{green}footnote{/}' ? ", $scope->has( [qw( extended footnote )] ) ? '{green}yes{/}' : '{red}no{/}' );
        if( $scope->has( [qw( extended footnote )] ) )
        {
            $data =~ s{$RE{Markdown}{ExtFootnote}}
            {
                my $re = { %+ };
                my $end = pos( $data );
                my $start = $end - length( $re->{footnote_all} );
                $self->message_colour( 3, $self->whereami( \$data, pos( $data ), { text => "Found footnote \"{green}" . $re->{footnote_all} . "{/}\" with id '{green}" . $re->{footnote_id} . "{/}' with capture: " . $self->dump( $re ), return => 1 } ) );
                my $content = $re->{footnote_text} . ' !!FN!!';
                my $footnote = $top->create_footnote({
                    id => $re->{footnote_id},
                    unparsed => $content,
                    parent => $top,
                    pos => pos( $data ),
                    raw => $re->{footnote_all},
                }) || die( "Unable to create footnote object: ", $top->error, "\n" );
                $top->register_footnote( $footnote );
                '';
            }gme;
        }

        # NOTE: footnote reference extended
        $self->message_colour( 3, "Does scope have '{green}footnote{/}' ? ", $scope->has( [qw( footnote extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
        if( $scope->has( [qw( footnote extended )] ) )
        {
            $data =~ s{$RE{Markdown}{ExtFootnoteReference}}
            {
                my $re = { %+ };
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $id = $re->{footnote_id};
                my $text = $re->{footnote_text};
                my $footnote;
                # Auto-generated id for inline footnote
                # Example:
                # I met Jack [^](Co-founder of Angels, Inc) at the meet-up.
                # Here is an inline note.^[Inlines notes are easier to write]
                # Inline footnote, i.e. text provided
                # We cannot just do if( !$id ) because a valid id could be '0'
                my $object_id;
                if( !length( $id ) )
                {
                    $id = $self->document->footnotes->length + 1;
                }
        
                if( length( $text ) )
                {
                    $footnote = $top->create_footnote({
                        id => $id,
                        text => $text,
                        parent => $top,
                        pos => $pos,
                        raw => $re->{footnote_all},
                    });
                    $top->register_footnote( $footnote );
                }
                # Cannot find an id matching this footnote, so we just add this footnote reference as a text
                elsif( !( $footnote = $self->document->get_footnote( $id ) ) )
                {
                    warn( "Unable to find a matching footnote with the footnote id \"$id\".\nAvailable footnotes ids are: '", $self->document->footnotes->map(sub{ $_->id })->join( "', '" ), "'." );
                    $object_id = $self->document->add_object( $top->create_text(
                    {
                        text => $re->{footnote_all},
                        pos => $pos,
                    }) );
                }
                
                if( $footnote )
                {
                    # Create a footnote reference and associate this footnote id with this reference
                    # The footnote reference id will be set by add_reference()
                    my $ref = $top->create_footnote_ref({
                        footnote => $footnote,
                        raw => $re->{footnote_all},
                        sequence => ++$self->footnote_ref_sequence,
                        pos => $pos,
                    });
                    ## add_reference will take care of setting the id used for backlink for this footnote reference
                    $footnote->add_reference( $ref );
                    $object_id = $self->document->add_object( $ref );
                }
                "${PH_PREFIX}${object_id}${PH_SUFFIX}";
            }xgems;
        }
    
        $self->message_colour( 3, "After processing {green}link{/} definition, {green}abbreviations{/} and {green}footnotes{/}, data is now '$data'." );
    }
    
    # NOTE: extended katex
    if( $scope->has( [qw( extended katex )] ) )
    {
        if( $self->katex_delimiter->length > 0 )
        {
            $katex_re = $RE{Markdown}{ExtKatex}{-delimiter => $self->katex_delimiter->join( ',' )};
        }
        else
        {
            $katex_re = $RE{Markdown}{ExtKatex};
        }
    }
    
    my $abbr_re;
    if( $self->document->dict->length > 0 )
    {
        $abbr_re = '(?' . ( $self->abbreviation_case_sensitive ? '' : 'i' ) . ':' . $self->document->dict->keys->join( '|' )->scalar . ')';
        $abbr_re = qr/$abbr_re/;
    }
    pos( $data ) = 0;
    
        
    if( $top->tag_name ne 'top' )
    {
        # NOTE: extended code block
        $self->message_colour( 3, "Does scope have '{green}extended code_block{/}' ? ", $scope->has( [qw( extended code_block )] ) ? '{green}yes{/}' : '{red}no{/}' );
        if( $scope->has( [qw( extended code_block )] ) )
        {
            $data =~ s{$RE{Markdown}{ExtCodeBlock}}
            {
                my $re = { %+ };
                $re->{capture} = substr( $data, $-[0], $+[0] - $-[0] );
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $code_def = $re->{code_attr};
                my $code_class = $re->{code_class};
                my $raw = $re->{code_all};
                my $content = $re->{code_content};
        
                $code_def =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//gs;
                $code_class =~ s/^[\.[:blank:]\h]+//gs;
        
                my $code = $top->create_code({
                    class => [split( /\./, $code_class )],
                    pos => $pos,
                    raw => $raw,
                    fenced => 1,
                });
                $code->add_element( $top->create_text({
                    text => $content,
                    pos => $pos,
                }) ) || return( $self->pass_error( $code->error ) );
                $code->add_attributes( $code_def ) if( length( $code_def ) );
                my $id = $self->document->add_object( $code );
                "${PH_PREFIX}${id}${PH_SUFFIX}\n";
            }xgems;
        }
    
        # NOTE: code block
        $self->message_colour( 3, "Does scope have '{green}code_block{/}' ? ", $scope->has( 'code_block' ) ? '{green}yes{/}' : '{red}no{/}' );
        # Code blocks trumps everything else, so they come first
        if( $scope->has( 'code_block' ) )
        {
            $data =~ s{$RE{Markdown}{CodeBlock}}
            {
                my $re = { %+ };
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $raw = $re->{code_all};
                my $content = $re->{code_content};
                # my $new_lines = $re->{code_trailing_new_line};
                my $code = $top->create_code({
                    pos => $pos,
                    raw => $raw,
                    fenced => 1,
                });
                $code->add_element( $top->create_text({
                    text => $content,
                    pos => $pos,
                }) ) || return( $self->pass_error( $code->error ) );
                my $id = $self->document->add_object( $code );
                "${PH_PREFIX}${id}${PH_SUFFIX}\n";
            }xgems;
        }
    
        # NOTE: code line
        $self->message_colour( 3, "Does scope have '{green}code_line{/}' ? ", $scope->has( 'code_line' ) ? '{green}yes{/}' : '{red}no{/}' );
        # Code single line. If it is a series of them treat them as a block
        if( $scope->has( 'code_line' ) )
        {
            $data =~ s{$RE{Markdown}{CodeLine}}
            {
                my $re = { %+ };
                # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
                my $pos = pos( $data );
                my $raw = $re->{code_all};
                my $content = $re->{code_all};
                # trim leading newlines
                $content =~ s/\A\n+//;
                # trim trailing whitespace
                $content =~ s/\s+\z//;
                my $trailing_nl = $self->_total_trailing_new_lines( $raw );
                my $code = $top->create_code({
                    ## Setting this to true will have the leading 4 spaces or tab removed
                    fenced => 1,
                    pos => $pos,
                    raw => $re->{code_all},
                });
                $code->add_element( $top->create_text({
                    text => $content,
                    pos => $pos,
                }) ) || return( $self->pass_error( $code->error ) );
                my $id = $self->document->add_object( $code );
                # Move back before the trailing new lines as they may be important for the next check
                "${PH_PREFIX}${id}${PH_SUFFIX}\n";
            }xgems;
        }
    }

    # NOTE: table extended
    $self->message_colour( 3, "Does scope have '{green}table extended{/}' ? ", $scope->has( [qw( table extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'table extended' ) )
    {
        $data =~ s{$RE{Markdown}{ExtTable}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $tbl = $self->parse_table( $re, { doc => $top } );
            my $id = $tbl->object_id;
            # pos( $data ) = $pos + length( $re->{table} );
            "${PH_PREFIX}${id}${PH_SUFFIX}\n";
        }xgems;
    }

    # NOTE: html
    $self->message_colour( 3, "Does scope have '{green}html{/}' ? ", $scope->has( 'html' ) ? '{green}yes{/}' : '{red}no{/}' );
    # HTML blocks MUST be start and end on their own lines
    if( $scope->has( 'html' ) )
    {
        $data =~ s{$RE{Markdown}{Html}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $html = $re->{tag_all};
            $html =~ s{$RE{Markdown}{ExtHtmlMarkdown}}
            {
                my $ct = $+{content};
                my $open = $+{div_open};
                my $close = $+{div_close};
                my $tag_name = $+{tag_name};
                my $leading_space = $+{leading_space};
                ## Remove the markdown attribute
                $open =~ s/[[:blank:]\h]+markdown[[:blank:]\h]*\=[[:blank:]\h]*(?<quote>["']?)1\g{quote}//;
                ## Need to remove indentation at begining of line
                if( length( $leading_space ) )
                {
                    $ct =~ s/^$leading_space//gm;
                }
                my $p = $top->create_paragraph({
                    parent => $top,
                    pos => $pos,
                });
                $self->parse( $ct, { element => $p });
                my $res = $p->children->map(sub{ $_->as_string })->join( '' )->scalar;
                "${open}${res}\n${close}\n";
            }xgems;
    
            my $elem = $top->create_html({
                pos => $pos,
                raw => $html,
            }) || die( $top->error );
            my $id = $self->document->add_object( $elem ) || die( $top->error );
            "${PH_PREFIX}${id}${PH_SUFFIX}\n";
        }xgemsi;
    }

    # NOTE: blockquote
    $self->message_colour( 3, "Does scope have '{green}blockquote{/}' ? ", $scope->has( 'blockquote' ) ? '{green}yes{/}' : '{red}no{/}' );
    # Blockquote
    if( $scope->has( 'blockquote' ) )
    {
        $data =~ s{$RE{Markdown}{Blockquote}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found a blockquote '{green}" . $re->{bquote_all} . "{/}' at pos '$pos' with capture: " . $self->dump( $re ), return => 1 } ) );
            my $raw = $re->{bquote_all};
            my $bq = $raw;
            $bq =~ s/^[ \t]*>[ \t]?//gm;    # trim one level of quoting
            $bq =~ s/^[ \t]+$//mg;          # trim whitespace-only lines
            my $block = $top->create_blockquote({
                pos => $pos,
                raw => $raw,
            });
            my $id = $self->document->add_object( $block );
            $self->parse( $bq, { scope => $self->scope_block, element => $block } );
            "${PH_PREFIX}${id}${PH_SUFFIX}\n";
        }xgems;
    }

    # NOTE: line
    # Now, the line elements

    # Setext-style headers:
    #     Header 1 {.main .shine #the-site lang=fr}
    #     ========
    #  
    #     Header 2 {.main .shine #the-site lang=fr}
    #     --------
    #
    # This is to be on a single line of its own
    $self->message_colour( 3, "Does scope have '{green}header extended{/}' ? ", $scope->has( 'header extended' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'header extended' ) )
    {
        $data =~ s{$RE{Markdown}{ExtHeader}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found an extended header '{green}" . $re->{header_all} . "{/}' with header level '{green}" . length( $re->{header_level} ) . "{/}' and attributes '{green}" . $re->{header_attr} . "{/}' at pos '$pos' with capture: " . $self->dump( $re ), return => 1 } ) );
            my $text = $re->{header_content};
            my $attr = $re->{header_attr};
            my $header = $top->create_header({
                level => length( $re->{header_level} ),
                pos => $pos,
                raw => $re->{header_all},
            });
            # Further process the text capture
            # If there are any elements, they will be placed inside the header element as children
            my $id = $self->document->add_object( $header );
            $self->parse( $text, { scope => 'inline extended', element => $header } );
            $header->add_attributes( $attr );
            "${PH_PREFIX}${id}${PH_SUFFIX}\n";
        }xgem;
    }

    # NOTE: header
    # Checking for headers
    # atx-style headers:
    #   # Header 1
    #   ## Header 2
    #   ## Header 2 with closing hashes ##
    #   ...
    #   ###### Header 6
    $self->message_colour( 3, "Does scope have '{green}header{/}' ? ", $scope->has( 'header' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'header' ) )
    {
        $data =~ s{$RE{Markdown}{Header}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found a vanilla header '{green}" . $re->{header_all} . "{/}' with header level '{green}" . length( $re->{header_level} ) . "{/}' at pos '$pos' with capture: " . $self->dump( $re ), return => 1 } ) );
            my $text = $re->{header_content};
            my $header = $top->create_header({
                level => length( $re->{header_level} ),
                pos => $pos,
                raw => $re->{header_all},
            });
            # Further process the text capture
            # If there are any elements, they will be placed inside the header element as children
            my $id = $self->document->add_object( $header );
            $self->parse( $text, { scope => $self->scope_inline, element => $header } );
            "${PH_PREFIX}${id}${PH_SUFFIX}\n";
        }xgem;
    }

    # NOTE: list
    # List goes before header line because a list with a 2nd empty element could be confused as an header line.
    # For example:
    # - HIJ
    # -

    # List
    my $list_re = $self->list_level ? $RE{Markdown}{ListNthLevel} : $RE{Markdown}{ListFirstLevel};
    $self->message_colour( 3, "Does scope have '{bold green}list{/}' ? ", $scope->has( 'list' ) ? '{green}yes{/}' : '{red}no{/}', " for scope '", $opts->{scope}->as_string, "'." );
    $self->message_colour( 3, "List level is '{green}", $self->list_level, "{/}'." );
    # If I do the following it does not work witht he regexp, but if I do substr( $data, $pos ) it works.
    # I am puzzled as to why, and I give up.
    # if( $scope->has( 'list' ) && $data =~ /\G$list_re/gmcs )
    # if( $scope->has( 'list' ) && substr( $data, $pos ) =~ /\G$list_re/gmcs )
    if( $scope->has( 'list' ) )
    {
        $data =~ s{$list_re}
        {
            my $re = { %+ };
            my $list = $re->{list_all};
            # my $list = $re->{list_content};
            # my $trailing_nl = ( $list =~ s/(\n+)$// )[0];
            # my $nth_nl = length( $trailing_nl );
            my $nth_nl = $self->_total_trailing_new_lines( $re->{list_all} );
            my $content = $re->{list_prefix} . $re->{list_content};
            my $post_nl_id;
            if( $nth_nl )
            {
                my $post_nl = $top->create_text({ text => "\n" x $nth_nl });
                $post_nl_id = $self->document->add_object( $post_nl );
            }
            
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $list_type = $re->{list_type_ordered} ? 'ol' : 'ul';
            # Corollary from using substr( $daata, $pos ). We ned to update the position in the string manually
            # pos( $data ) = $pos + length( substr( $data, $-[0], $+[0]-$-[0] ) );
            # TODO With this new way of processing list, I do not know the indent level anymore. Might want to look into that.
            my $indent_level = 0;
            # Turn double returns into triple returns, so that we can make a
            # paragraph for the last item in a list, if necessary:
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found a list of type '" . $list_type . "' and {green}${nth_nl}{/} trailing new lines at pos '" . $pos . "':\n'{bold orange}" . $list . "{/}' with capture: " . $self->dump( $re ), return => 1 } ) );
            my $new_list = $top->create_list({
                indent => $indent_level,
                pos => $pos,
                raw => "${content}\n",
                order => $list_type eq 'ol' ? 1 : 0,
            });
            my $id = $self->document->add_object( $new_list );
            # $list =~ s/\n{2,}/\n\n\n/g;
            $self->parse_list_item( $list, { doc => $new_list, pos => pos( $data ) } );
            # $nth_nl-- if( $nth_nl > 1 );
            # Trailing new lines are also preceding new lines for the next element if more than 1
            "${PH_PREFIX}${id}${PH_SUFFIX}" . ( defined( $post_nl_id ) ? "${PH_PREFIX}${post_nl_id}${PH_SUFFIX}" : '' );
        }xgems;
    }
    
    # NOTE: header line extended
    # Ex: Some thing\n
    #     ==========\n
    $self->message_colour( 3, "Does scope have '{green}header line extended{/}' ? ", $scope->has( 'header extended' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'header extended' ) )
    {
        $data =~ s{$RE{Markdown}{ExtHeaderLine}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found an extended header line '{green}" . $re->{header_all} . "{/}' with text '{green}" . $re->{header_content} . "{/}' at pos '$pos' with capture: " . $self->dump( $re ), return => 1 } ) );
            my $text = $re->{header_content};
            my $raw  = $re->{header_all};
            my $attr = $re->{header_attr};
            my $levels =
            {
            '=' => 1,
            '-' => 2,
            };
            my $header = $top->create_header({
                level => $levels->{ substr( $re->{header_type}, 0, 1 ) },
                parent => $top,
                pos => $pos,
                raw => $raw,
            });
            $header->add_attributes( $attr );
    
            # Further process the text capture
            # If there are any elements, they will be placed inside the header element as children
            my $id = $self->document->add_object( $header );
            $self->parse( $text, { scope => 'inline extended', element => $header } );
            "${PH_PREFIX}${id}${PH_SUFFIX}\n";
        }xgems;
    }

    # NOTE: header line
    # Ex: Some thing\n
    #     ==========\n
    $self->message_colour( 3, "Does scope have '{green}header line{/}' ? ", $scope->has( 'header' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'header' ) )
    {
        $data =~ s{$RE{Markdown}{HeaderLine}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found a vanilla header line '{green}" . $re->{header_all} . "{/}' with text '{green}" . $re->{header_content} . "{/}' at pos '$pos' with capture: " . $self->dump( $re ), return => 1 } ) );
            my $text = $re->{header_content};
            my $raw  = $re->{header_all};
            my $levels =
            {
            '=' => 1,
            '-' => 2,
            };
            my $header = $top->create_header({
                level => $levels->{ substr( $re->{header_type}, 0, 1 ) },
                parent => $top,
                pos => $pos,
                raw => $raw,
            });
            # Further process the text capture
            # If there are any elements, they will be placed inside the header element as children
            $self->parse( $text, { scope => $self->scope_inline, element => $header } );
            my $id = $self->document->add_object( $header );
            "${PH_PREFIX}${id}${PH_SUFFIX}\n";
        }xgems;
    }

    # NOTE: line
    # Horizontal lines
    # * * *
    # 
    # ***
    # 
    # *****
    # 
    # - - -
    # 
    # ---------------------------------------
    $self->message_colour( 3, "Does scope have '{green}line{/}' ? ", $scope->has( 'line' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'line' ) )
    {
        $data =~ s{$RE{Markdown}{Line}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found new horizontal line at pos '$pos': '{green}" . $re->{line_all} . "'{/} with capture: " . $self->dump( $re ), return => 1 } ) );
            my $id = $self->document->add_object( $top->create_line({
                pos => $pos,
                raw => $re->{line_all},
            }) );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgem;
    }

    # NOTE: paragraph
    $self->message_colour( 3, "Does scope have '{green}paragraph{/}' ? ", $scope->has( 'paragraph' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'paragraph' ) )
    {
        $data =~ s{$RE{Markdown}{Paragraph}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $text = $re->{para_all};
            my $raw  = $re->{para_all};
            my $nth_nl = $self->_total_trailing_new_lines( $text );
            my $post_nl_id;
            if( $nth_nl )
            {
                my $post_nl = $top->create_text({ text => "\n" x $nth_nl });
                $post_nl_id = $self->document->add_object( $post_nl );
            }
            $text =~ s/^\n+|\n+$//gs;
            # Replace new lines that are not preceded by 2 space or more with 1 space.
            $text =~ s/(?<![ ]{2})\n/ /gs;
            $self->message_colour( 3, "Found {green}${nth_nl}{/} trailing new line(s)." );
            my $p = $top->create_paragraph({
                pos => $pos,
                raw => $raw,
            });
            # Position ourself before the trailing new lines
            my $id = $self->document->add_object( $p );
            # $self->message_colour( 3, "Sub parsing paragraph content '{green}", quotemeta( $text ), "{/}'" );
            $self->parse( $text, { scope => $self->scope_inline, element => $p } );
            # We remove one new line to account for the new line added by as_markdown() method
            # $trailing_nl-- if( $trailing_nl > 1 );
            # "${PH_PREFIX}${id}${PH_SUFFIX}";
            "${PH_PREFIX}${id}${PH_SUFFIX}" . ( defined( $post_nl_id ) ? "${PH_PREFIX}${post_nl_id}${PH_SUFFIX}" : '' );
        }xgems;
    }
    # End of block elements parsing
    
    # NOTE: link extended
    # Now the inline elements
    $self->message_colour( 3, "Does scope have '{green}link extended{/}' ? ", $scope->has( [qw( link extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( [qw( link extended )] ) )
    {
        $data =~ s{$RE{Markdown}{ExtLink}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $raw = $re->{link_all};
            my $id  = $re->{link_id};
            my $name = $re->{link_name};
            my $title = $re->{link_title};
            my $url = $re->{link_url};
            my $def = $re->{link_attr};
            my $link = $top->create_link({
                pos => $pos,
                raw => $raw,
            });
            if( length( $def ) )
            {
                $def =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//gs;
                $link->add_attributes( $def ) if( length( $def ) );
            }
            my $object_id = $self->document->add_object( $link );
            ## An url has been provided, we sub-parse the link name for inline markdown, and especially abbreviations
            if( $url )
            {
                $link->url( $url );
            }
            ## as in [Example][] instead of [Example][site_id]
            else
            {
                $id = $name if( !length( $id ) );
                $link->link_id( $id );
                my $link_def = $self->document->get_link_by_id( $id );
                if( $link_def )
                {
                    $title = $link_def->title->scalar;
                    $url = $link_def->url;
                    $link->copy_from( $link_def );
                }
                else
                {
                }
                $link->url( $url );
            }
            $link->title( $title );
            $self->parse( $name, { element => $link, scope => $self->scope_inline });
            "${PH_PREFIX}${object_id}${PH_SUFFIX}";
        }xgems;
    }
    
    # NOTE: link
    $self->message_colour( 3, "Does scope have '{green}link{/}' ? ", $scope->has( [qw( link )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'link' ) )
    {
        $data =~ s{$RE{Markdown}{Link}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $raw = $re->{link_all};
            my $id  = $re->{link_id};
            my $name = $re->{link_name};
            my $title = $re->{link_title};
            my $url = $re->{link_url};
            my $link = $top->create_link({
                pos => $pos,
                raw => $raw,
            });
            my $object_id = $self->document->add_object( $link );
            # An url has been provided, we sub-parse the link name for inline markdown, and especially abbreviations
            if( $url )
            {
                $link->url( $url );
            }
            # as in [Example][] instead of [Example][site_id]
            else
            {
                $id = $name if( !length( $id ) );
                $link->link_id( $id );
                my $link_def = $self->document->get_link_by_id( $id );
                if( $link_def )
                {
                    $title = $link_def->title;
                    $url = $link_def->url;
                    $link->copy_from( $link_def );
                }
                else
                {
                }
                $link->url( $url );
            }
            $link->title( $title );
            $self->parse( $name, { element => $link, scope => $self->scope_inline });
            "${PH_PREFIX}${object_id}${PH_SUFFIX}";
        }xgems;
    }

    # NOTE: auto-link
    # Automatic link like <https://example.com> or <news://news.example.com> or <mailto://john@example.com> or <john@example.com>, etc...
    $self->message_colour( 3, "Does scope have '{green}auto-link{/}' ? ", $scope->has( [qw( link )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'link' ) )
    {
        $data =~ s{$RE{Markdown}{LinkAuto}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $raw = $re->{link_all};
            my $url = $re->{link_url};
            # Add the mailto: scheme if it's an e-mail address and the scheme is missing
            substr( $url, 0, 0 ) = 'mailto:' if( length( $re->{link_mailto} ) && substr( $re->{link_mailto}, 0, 7 ) ne 'mailto:' );
            my $link = $top->create_link({
                encrypt => $self->encrypt_email,
                ## We save the original as URI may alter it by url-encoding characters
                original => $re->{link_url},
                pos => $pos,
                raw => $raw,
                url => $url,
            });
#                 $link->add_element( $link->create_text({
#                     pos => $pos,
#                     text => $re->{link_url},
#                 }) );
            my $id = $self->document->add_object( $link );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }

    # NOTE: image extended
    $self->message_colour( 3, "Does scope have '{green}image extended{/}' ? ", $scope->has( [qw( image extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( [qw( image extended )] ) )
    {
        $data =~ s{$RE{Markdown}{ExtImage}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $raw = $re->{img_all};
            my $url = $re->{img_url};
            my $id  = $re->{img_id};
            my $alt = $re->{img_alt};
            my $attr = $re->{img_attr};
            my $title = $re->{img_title};
            my $img = $top->create_image({
                alt => $alt,
                pos => $pos,
                raw => $raw,
            });
            if( !$url )
            {
                $id = $alt if( !length( $id ) );
                my $img_def = $self->document->get_link_by_id( $id );
                if( $img_def )
                {
                    $title = $img_def->title;
                    $url = $img_def->url;
                    $img->copy_from( $img_def );
                }
            }
            $img->url( $url );
            $img->title( $title );
            $img->link_id( $id ) if( length( $id ) );
            $img->add_attributes( $attr );
            my $object_id = $self->document->add_object( $img );
            "${PH_PREFIX}${object_id}${PH_SUFFIX}";
        }xgems;
    }

    # NOTE: image
    $self->message_colour( 3, "Does scope have '{green}image{/}' ? ", $scope->has( [qw( image )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'image' ) )
    {
        $data =~ s{$RE{Markdown}{Image}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $raw = $re->{img_all};
            my $url = $re->{img_url};
            my $id  = $re->{img_id};
            my $alt = $re->{img_alt};
            my $title = $re->{img_title};
            my $img = $top->create_image({
                alt => $alt,
                pos => $pos,
                raw => $raw,
            });
            if( !$url )
            {
                $id = $alt if( !length( $id ) );
                my $img_def = $self->document->get_link_by_id( $id );
                if( $img_def )
                {
                    $title = $img_def->title;
                    $url = $img_def->url;
                    $img->copy_from( $img_def );
                }
            }
            $img->url( $url );
            $img->title( $title );
            $img->link_id( $id ) if( length( $id ) );
            my $object_id = $self->document->add_object( $img );
            "${PH_PREFIX}${object_id}${PH_SUFFIX}";
        }xgems;
    }

    # NOTE: bold
    # Bold check comes before emphasis one
    $self->message_colour( 3, "Does scope have '{green}bold{/}' ? ", $scope->has( 'bold' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'bold' ) )
    {
        $data =~ s{$RE{Markdown}{Bold}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $content = $re->{bold_text};
            my $bold = $top->create_bold({
                pos => pos( $data ),
                raw => $re->{bold_all},
                type => $re->{bold_type},
            });
            $self->parse( $content, { element => $bold, scope => $self->scope_inline });
            my $id = $self->document->add_object( $bold );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }

    # NOTE: emphasis
    $self->message_colour( 3, "Does scope have '{green}emphasis{/}' ? ", $scope->has( 'emphasis' ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'emphasis' ) )
    {
        $data =~ s{$RE{Markdown}{Em}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $em = $top->create_em({
                pos => $pos,
                raw => $re->{em_all},
                type => $re->{em_type},
            });
            my $content = $re->{em_text};
            $self->parse( $content, { element => $em, scope => $self->scope_inline });
            my $id = $self->document->add_object( $em );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }gexms;
    }
    
    # NOTE: code span
    # Inline code `some thing`
    $self->message_colour( 3, "Does scope have '{green}code span{/}' ? ", $scope->has( [qw( code_span )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'code_span' ) )
    {
        $data =~ s{$RE{Markdown}{CodeSpan}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $raw = $re->{code_all};
            my $content = $re->{code_content};
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found an inline code '$raw' at pos '$pos' with content:\n'{green}" . $content . "{/}' and with capture: " . $self->dump( $re ), return => 1 } ) );
            ## leading whitespace
            $content =~ s/^[ \t]*//g;
            ## trailing whitespace
            $content =~ s/[ \t]*$//g;
            my $code = $top->create_code({
                inline => 1,
                pos => $pos,
                raw => $raw,
            });
            $code->add_element( $top->create_text({
                text => $content,
                pos => $pos,
            }) );
            my $id = $top->add_object( $code );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }
    
    # NOTE: checkbox extended
    $self->message_colour( 3, "Does scope have '{green}checkbox{/}' ? ", $scope->has( [qw( checkbox extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( [qw( checkbox extended )] ) )
    {
        $data =~ s{$RE{Markdown}{ExtCheckbox}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $check = $top->create_checkbox({
                checked => lc( $re->{check_content} ) eq 'x',
                raw => $re->{check_all},
                pos => $pos,
            });
            my $id = $self->document->add_object( $check );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }
    
    # NOTE: katex
    $self->message_colour( 3, "Does scope have '{green}katex{/}' ? ", ( $scope->has( [qw( katex extended )] ) ? '{green}yes{/}' : '{red}no{/}' ) );
    if( length( $katex_re ) && $scope->has( [qw( katex extended )] ) )
    {
        $data =~ s{$katex_re}
        {
            my $re = { %+ };
            my $raw = $re->{katex_all};
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            ## There is at least one new line, so this is a block, we use paragraph
            my $id;
            if( index( $raw, "\n" ) != -1 )
            {
                my $p = $top->create_paragraph({
                    pos => $pos,
                    raw => $raw,
                });
                $p->add_element( $p->create_text({
                    pos => $pos,
                    text => $re->{katex_all},
                }) );
                $id = $self->document->add_object( $p );
            }
            ## Inline style
            else
            {
                $id = $self->document->add_object( $top->create_text({
                    pos => $pos,
                    text => $re->{katex_all},
                }) );
            }
            $self->document->setup_katex;
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }
    
    # NOTE: strikethrough
    $self->message_colour( 3, "Does scope have '{green}strikethrough{/}' ? ", $scope->has( [qw( strikethrough extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( [qw( strikethrough extended )] ) )
    {
        $data =~ s{$RE{Markdown}{ExtStrikeThrough}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $text = $re->{strike_content};
            my $strike = $top->create_strikethrough({
                raw => $re->{strike_all},
                pos => $pos,
            });
            $strike->add_element( $strike->create_text({
                pos => $pos,
                text => $text,
            }) );
            my $id = $self->document->add_object( $strike );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }
    
    # NOTE: insertion
    $self->message_colour( 3, "Does scope have '{green}insertion{/}' ? ", $scope->has( [qw( insertion extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( [qw( insertion extended )] ) )
    {
        $data =~ s{$RE{Markdown}{ExtInsertion}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $text = $re->{ins_content};
            my $ins = $top->create_insertion({
                raw => $re->{ins_all},
                pos => $pos,
            });
            $ins->add_element( $ins->create_text({
                pos => $pos,
                text => $text,
            }) );
            my $id = $self->document->add_element( $ins );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }
    
    # NOTE: subscript
    $self->message_colour( 3, "Does scope have '{green}subscript{/}' ? ", $scope->has( [qw( subscript extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( [qw( subscript extended )] ) )
    {
        $data =~ s{$RE{Markdown}{ExtSubscript}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $text = $re->{sub_text};
            my $sub = $top->create_subscript({
                raw => $re->{sub_all},
                pos => $pos,
            });
            $sub->add_element( $sub->create_text({
                pos => $pos,
                text => $text,
            }) );
            my $id = $self->document->add_object( $sub );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }
    
    # NOTE: superscript
    $self->message_colour( 3, "Does scope have '{green}superscript{/}' ? ", $scope->has( [qw( superscript extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( [qw( superscript extended )] ) )
    {
        $data =~ s{$RE{Markdown}{ExtSuperscript}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            my $text = $re->{sup_text};
            my $sup = $top->create_superscript({
                raw => $re->{sup_all},
                pos => $pos,
            });
            $sup->add_element( $sup->create_text({
                pos => $pos,
                text => $text,
            }) );
            my $id = $self->document->add_object( $sup );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }
    
#     $self->message_colour( 3, "Does scope have '{green}line break extended{/}' ? ", $scope->has( [qw( line_break extended )] ) ? '{green}yes{/}' : '{red}no{/}' );
#     if( $scope->has( [qw( line_break extended )] ) )
#     {
#         $data =~ s{$RE{Markdown}{ExtLineBreak}}
#         {
#             my $re = { %+ };
#             # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
#             my $pos = pos( $data );
#             $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found an extended {green}line break{/} (end of line possibly prepended by 2 or more spaces) at pos '" . $pos . "' with capture: " . $self->dump( $re ), return => 1 } ) );
#             my $id = $self->document->add_object( $top->create_new_line({
#                 break => 1,
#                 pos => $pos,
#             }) );
#             "${PH_PREFIX}${id}${PH_SUFFIX}";
#         }xgems;
#     }

    # NOTE: line break
    $self->message_colour( 3, "Does scope have '{green}line break{/}' ? ", $scope->has( [qw( line_break )] ) ? '{green}yes{/}' : '{red}no{/}' );
    if( $scope->has( 'line_break' ) )
    {
        $data =~ s{$RE{Markdown}{LineBreak}}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            $self->message_colour( 3, $self->whereami( \$data, $pos, { text => "Found a {green}line break{/} (end of line prepended by 2 or more spaces) at pos '" . $pos . "' with capture: " . $self->dump( $re ), return => 1 } ) );
            my $id = $self->document->add_object( $top->create_new_line({
                break => 1,
                pos => $pos,
            }) );
            "${PH_PREFIX}${id}${PH_SUFFIX}";
        }xgems;
    }

    # NOTE: footnote backreference
    # This is a placeholder added at the end of the footnote text where we will insert a back reference link
    $data =~ s{(?<fn_backref>[ ]+\!{2}FN\!{2})}
    {
        my $re = { %+ };
        # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
        my $pos = pos( $data );
        my $id = $self->document->add_object( $top->create_text({
            pos => $pos,
            text => $re->{fn_backref},
        }) );
        "${PH_PREFIX}${id}${PH_SUFFIX}";
    }xgems;

    # NOTE: abbreviation
    $self->message_colour( 3, "Does scope have '{green}abbr{/}' ? ", $scope->has( [qw( extended abbr )] ) ? '{green}yes{/}' : '{red}no{/}' );
    # Now find and replace any match with its corresponding expanded name
    if( length( $abbr_re ) && $scope->has( [qw( extended abbr )] ) )
    {
        $data =~ s{\b(?<abbr_name>$abbr_re)\b}
        {
            my $re = { %+ };
            # my $pos = pos( $data ) - length( substr( $data, $-[0], $+[0] - $-[0] ) );
            my $pos = pos( $data );
            ## We save what we caught to put it back in case the abbreviation lookup failed
            my $catch = substr( $data, $-[0], $+[0] - $-[0] );
            if( defined( my $abbr = $self->document->get_abbreviation( $re->{abbr_name} ) ) )
            {
                my $id = $self->document->add_object( $abbr->clone );
                "${PH_PREFIX}${id}${PH_SUFFIX}";
            }
            # Failed somehow
            else
            {
                "$catch";
            }
        }xge;
    }

    $self->message_colour( 3, "{orange}", ( $top->tag_name eq 'top' ? 'Parsing' : 'Sub-parsing' ), " done.{/}" );

    if( $top->tag_name eq 'top' )
    {
        # We need to separate parsing of footnotes' text in a second step, so we do this here
        $top->footnotes->foreach(sub
        {
            $_->parse( $self );
        });
    }

    # NOTE: ultra fast parsing
    my $object_re = qr/\Q${PH_PREFIX}\E(?<object_id>\d+)\Q${PH_SUFFIX}\E/;
    my $parts = [ split( m/${object_re}\n?/, $data ) ];
    $self->message( 3, "Parts are: '", join( "', '", @$parts ), "'." ); 
    my $objects = $self->document->objects;
    for( my $n = 0; $n < scalar( @$parts ); $n++ )
    {
        # When $n is an even number, it means this is a text, otherwise it is an object id
        # If this is a text, we create a text object and add it to the tree
        if( $n % 2 )
        {
            my $id = $parts->[ $n ];
            next if( !length( $id ) );
            my $obj = $objects->get( $id );
            if( ref( $obj ) )
            {
                $cb->( $obj );
                $top->add_element( $obj );
            }
            else
            {
                $self->message_colour( 3, "{bold red}No object found for id \"", $id, "\"!{/}" );
            }
        }
        else
        {
            my $obj = $top->create_text({
                text => $parts->[ $n ],
            });
            $cb->( $obj );
            $top->add_element( $obj );
        }
    }

    # Depth-first expansion, repeat until no changes (handles cascades)
    my $changed = 1;

    my $walk;
    $walk = sub
    {
        my( $node ) = @_;

        # Recurse into container children first (depth-first)
        if( $node->can( 'children' ) && $node->children->length )
        {
            # Children list may mutate while we insert; iterate by index
            my $i = 0;
            while( $i < $node->children->length )
            {
                my $child = $node->children->get( $i );
                $walk->( $child );
                # If structure changed, do not increment blindly
                $i++;
            }
        }

        # Only interested in Text nodes that might contain placeholders
        return if( !$node->isa( 'Markdown::Parser::Text' ) );

        my $txt = $node->text->scalar // '';
        return if( $txt !~ /$object_re/ );

        # Split into text / id / text / id / ... / text
        my @parts = split( /$object_re/, $txt );

        # First piece stays in current node
        my $head = shift( @parts );
        $node->text( $head );

        my $cursor = $node;
        while( @parts )
        {
            my $id    = shift( @parts );
            # may be undef at end
            my $after = shift( @parts );

            my $obj = $self->document->objects->get( $id );

            if( $obj )
            {
                # Splice the referenced object right after the cursor
                $node->parent->insert_after( $cursor, $obj );
                $cursor = $obj;
                $changed = 1;
            }
            else
            {
                # Unknown id: keep literal placeholder (safer than dropping)
                my $lit = $node->parent->create_text({ text => "${PH_PREFIX}${id}${PH_SUFFIX}" });
                $node->parent->insert_after( $cursor, $lit );
                $cursor = $lit;
            }

            if( defined( $after ) && length( $after ) )
            {
                my $tail = $node->parent->create_text({ text => $after });
                $node->parent->insert_after( $cursor, $tail );
                $cursor = $tail;
                # will be caught next pass
                $changed = 1 if( $after =~ /$object_re/ );
            }
        }
    };

    while( $changed )
    {
        $changed = 0;
        $walk->( $top );
    }
    return( $top );
}

sub parse_file
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->error( "No file to parse was provided." ) );
    return( $self->error( "Markdown file provided \"$file\" does not exist." ) ) if( !-e( $file ) );
    return( $self->error( "Markdown file provided \"$file\" is actually a directory." ) ) if( -d( $file ) );
    return( $self->error( "Markdown file provided \"$file\" is empty." ) ) if( -z( $file ) );
    return( $self->error( "Markdown file provided \"$file\" does not have read permission." ) ) if( !-r( $file ) );
    my $io = IO::File->new( "<$file" ) || return( $self->error( "Unable to open markdown file \"$file\": $!" ) );
    my $charset = $self->charset;
    $io->binmode( ":encode(${charset})" ) if( length( $charset ) );
    my $data = join( '', $io->getlines );
    $io->close;
    return( $self->parse( $data, @_ ) );
}

sub parse_list_item
{
    my $self = shift( @_ );
    my $text = shift( @_ ) || '';
    my $opts = {};
    $opts    = shift( @_ ) if( $self->_is_hash( $opts ) );
    my $top = $opts->{doc} || do
    {
        warn( "No element object provided as a container.\n" );
        return( $self->error( "No element object provided as a container." ) );
    };
    $opts->{pos} = int( $opts->{pos} );
    $self->message_colour( 3, "Parsing list item '{bold green}", $text, "{/}' with options: ", sub{ $self->dump( $opts, {
        filter => sub
        {
            my( $ctx, $ref ) = @_;
            if( $ctx->class eq 'Markdown::Parser::Document' )
            {
                return({ dump => overload::StrVal( $ref ) });
            }
            elsif( $ctx->is_blessed && $ref->isa( 'Markdown::Parser::Element' ) )
            {
                return({ dump => overload::StrVal( $ref ) });
            }
        }
    }) } );
    # If more than 1 trailing new lines, our caller should hae dealt with it be putting back any excess of 1, because those are the preceding new lines for the next element and it is important for parsing.
    $text =~ s/\n{2,}\z/\n/;
#     my @post_nl = ();
#     $text =~ s{(\n{2,})\z}
#     {
#         my $n = length( $1 );
#         $n--;
#         $self->message_colour( 4, "Adding {green}${n}{/} new lines at end of list." );
#         if( $n > 0 )
#         {
#             for( my $i = 0; $i < $n; $i++ )
#             {
#                 my $nl = $top->create_new_line({ break => 1 });
#                 push( @post_nl, $nl );
#             }
#         }
#         "\n";
#     }xgems;
    $self->list_level++;
    $text =~ s{$RE{Markdown}{ListItem}}
    {
        my $re = { %+ };
        my $item = $re->{li_content};
        my $leading_line = $re->{li_lead_line};
        my $leading_space = $re->{li_lead_space};
        my $list_type = $re->{list_type_any};
        my $list_line = $re->{li_all};
    
        my $indent = $leading_space;
        $indent =~ s/\t/    /gs;
        # int() because length on undef produces undef
        my $total_spaces = int( length( $indent ) );
        my $indent_level = POSIX::ceil( $total_spaces / 4 );
        $self->message_colour( 3, "Found a list item of type '{green}", $list_type, "{/}' with indent level '{green}", $indent_level, "{/}' (total spaces found = '", $total_spaces, "') and list item line '{green}", $re->{list_line}, "{/}' list item '{green}", $item, "{/}'. List indentation is '", $indent, "'" );
    
        my $li = $top->create_list_item({
            indent => ( $indent_level + 1 ),
            pos => $opts->{pos} + pos( $text ),
            raw => $list_line,
            type => $list_type,
            # Alternatively
            # order => 1, # or 0
        });
        $top->add_element( $li );

        if( $leading_line || ( $item =~ m/\n{2,}/) )
        {
            $item =~ s/^(\t|[ ]{1,4})//gm;
            $self->message_colour( 3, "{white on blue}Processing list content: '$item'{/} with list level '", $self->list_level, "'" );
            $self->parse( $item, { scope => $self->scope_block, element => $li } );
        }
        else
        {
            # Recursion for sub-lists:
            $item =~ s/^(\t|[ ]{1,4})//gm;
            $self->message_colour( 3, "{white on orange}Processing sub list with content: '$item'{/} with list level '", $self->list_level, "'" );
            $self->parse( $item, { scope => [qw( extended list||inline )], element => $li } );
        }
    }xgems;
#     for( @post_nl )
#     {
#         $top->add_element( $_ );
#     }
    $self->list_level++;
    return( $self );
}

sub parse_table
{
    my $self = shift( @_ );
    # Hash reference of capture groups: %-
    # See perlvar for more information
    my $re   = shift( @_ );
    my $opts = {};
    $opts    = shift( @_ ) if( $self->_is_hash( $opts ) );
    my $top = $opts->{doc} || do
    {
        warn( "No element object provided as a container.\n" );
        return( $self->error( "No element object provided as a container." ) );
    };
    my $tbl = $top->create_table(
        use_css_grid => $self->css_grid,
        ## shared css object
        css => $self->css,
    );
    $self->document->add_object( $tbl );
    my $info =
    {
    cols => {},
    rows => {},
    };
    my $seps = $self->new_array;
    my $headers = [split( /\n/, $re->{table_headers}->[0] )];
    for my $i ( 0..$#$headers )
    {
        ## This is a separator, store our data to the array $headers
        if( $headers->[$i] =~ /^[\|\-\+\: ]+$/ )
        {
            splice( @$headers, $i, 1 );
            $i--;
        }
    }
    # We check for leading space (up to 3), otherwise this would be code
    # and we use this leading space when parsing rows to factor in leading empty cells, i.e.
    # -------
    #        | # <- this is an empty cell, but
    #    ----
    #    | A | # <- the space before the leading pipe is not
    my $leading_space = 0;
    # Check the space at the beginning of separator line as reference
    if( $re->{table_header_sep}->[0] =~ /^([[:blank:]\h]+)/ )
    {
        $leading_space = length( $leading_space );
    }
    
    # Process the separator(s) in the header to find
    for my $i ( 0..1 )
    {
        $seps->push( $re->{table_header_sep}->[$i] ) if( length( $re->{table_header_sep}->[$i] ) );
    }
    my $cell_align = $self->new_array;
    $seps->for(sub
    {
        my( $n, $s ) = @_;
        $s =~ s/^[\+\|\-][[:blank:]\h]+|[[:blank:]\h]+[\+\|\-]$//g;
        return if( index( $s, ':' ) == -1 );
        my $cells = $self->new_array( [split( /[\+\|]/, $s )] );
        $cells->for(sub
        {
            my( $i, $c ) = @_;
            $c =~ s/^[[:blank:]\h\v]+|[[:blank:]\h\v]+$//g;
            return if( !length( $c ) );
            my( $left, $right );
            $left = 1 if( substr( $c, 0, 1 ) eq ':' );
            $right = 1 if( substr( $c, -1, 1 ) eq ':' );
            ## First row, so we just assign the value
            if( $n == 0 )
            {
                $cell_align->push({ left => $left, right => $right });
            }
            else
            {
                my $prev = $cell_align->index( $i );
                if( !defined( $prev ) )
                {
                    $cell_align->[ $i ] = { left => $left, right => $right };
                }
            }
        });
    });
    
    my $caption;
    if( $re->{table_caption}->[0] || $re->{table_caption}->[1] )
    {
        $caption = $re->{table_caption}->[0] // $re->{table_caption}->[1];
        $caption =~ s/^[[:blank:]\h]*\[|\][[:blank:]\h\v]*$//gs;
        if( length( $caption ) )
        {
            my $cap = $tbl->create_table_caption;
            $self->parse( $caption, { element => $cap, scope => 'inline' });
            # $cap->add_element( $cap->create_text({ text => $caption }) );
            $tbl->caption( $cap );
            $cap->position( $re->{table_caption_bottom}->[0] ? 'bottom' : 'top' );
        }
    }
    
    ## Getting an array ref of array ref containing row objects
    my $hdrs_rows = $self->parse_table_row( $headers, { doc => $top, alignment => $cell_align, leading_space => $leading_space });
    my $header = $top->create_table_header;
    ## Possibly multiple rows in the header, but only one table header
    foreach my $rows ( @$hdrs_rows )
    {
        $header->children->push( @$rows );
    }
    $tbl->header( $header );
    
    my $body_rows = $self->parse_table_row( $re->{table_rows}->[0], { doc => $top, alignment => $cell_align });
    ## Possibly multiple table body
    foreach my $rows ( @$body_rows )
    {
        my $body = $top->create_table_body;
        $body->children->push( @$rows );
        $tbl->add_body( $body ) || return( $self->error( "Could not add body: ", $tbl->error ) );
    }
    
    foreach my $this ( $hdrs_rows, $body_rows )
    {
        for my $i ( 0..$#$this )
        {
            $info->{rows}->{total} += scalar( @{$this->[$i]} );
        }
    }
    $info->{cols}->{total} = scalar( keys( %{$info->{cols}} ) );
    $tbl->stat( $info );
    return( $tbl );
}

sub parse_table_row
{
    my $self = shift( @_ );
    my $str  = shift( @_ );
    my $opts = {};
    $opts    = shift( @_ ) if( $self->_is_hash( $opts ) );
    my $top = $opts->{doc} || do
    {
        warn( "No element object provided as a container.\n" );
        return( $self->error( "No element object provided as a container." ) );
    };
    ## Leading space in length
    my $lead_space = int( $opts->{leading_space} );
    ## my $cols = [];
    my $body = [];
    my $rows = [];
    my $info =
    {
    cols => {},
    rows => {},
    };
    # A Module::Generic::Array object containing hash references with left and right keys
    my $al = $opts->{alignment};
    # Removing trailing new lines
    $str =~ s/\n+$//gs;
    my $row_n = 0;
    my $lines = ref( $str ) eq 'ARRAY' ? $str : [split( /\n/, $str )];
    foreach my $l ( @$lines )
    {
        ## Get rid of leading (up to 3) and trailing spaces
        ## If there are remaining leading space to the pipe, we use it to determine this is an empty cell
        $l =~ s/^[[:blank:]\h]{$lead_space}|[[:blank:]\h]+$//gs;
        if( $l =~ /^[[:blank:]\h]*$/ )
        {
            push( @$body, $rows );
            $rows = [];
            next;
        }
        
        my $row = $top->create_table_row;
        # Make sure there is a leading and trailing | to standardise our parsing
        substr( $l, 0, 0 ) = '|' if( $l !~ /^[\|\:]/ );
        $l .= '|' if( $l !~ /[\|\:]$/ );
        my $is_prev_row = substr( $l, 0, 1 ) eq ':' ? 1 : 0;
        # Skip the leading pipe
        $l = substr( $l, 1 );
        my $col_n = 0;
        while( $l =~ s/^(?<col_content>[^\|\:]+)(?<sep>[\|\:]+)// )
        {
            my $re = { %+ };
            my $cell = $top->create_table_cell;
            # print( "Regexp: ", dump( $re ), "\n" );
            $is_prev_row = 1 if( substr( $re->{sep}, 0, 1 ) eq ':' );
            my $content = $re->{col_content};
            # If we do not have information about this column and this is not a colspan
            # then, store the column width
            if( !length( $info->{cols}->{ $col_n + 1 } ) &&
                length( $re->{sep} ) == 1 )
            {
                $info->{cols}->{ $col_n + 1 } = length( $content );
            }
            # In the cell width we include the additional pipes on the right, if any, that represent spawned columns
            $cell->width( length( $content ) + ( length( $re->{sep} ) > 1 ? ( length( $re->{sep} ) - 1 ) : 0 ) );
            $cell->colspan( length( $re->{sep} ) );
            $content =~ s/^([[:blank:]\h]*)(.*?)([[:blank:]\h]*)$/$2/gs;
            my $left = $+[1];
            my $right = $+[3] - $-[3];
            ## $cell->add_element( $cell->create_text( $content ) );
            $self->parse( $content, { element => $cell });
            my $al_def = $al->[ $col_n ];
            ## Alignment was provided for this table using ":"
            if(  $self->_is_hash( $al_def ) && 
                ( length( $al_def->{left} ) || length( $al_def->{right} ) ) )
            {
                if( $al_def->{left} && $al_def->{right} )
                {
                    $cell->align( 'center' );
                }
                elsif( $al_def->{left} )
                {
                    $cell->align( 'left' );
                }
                elsif( $al_def->{right} )
                {
                    $cell->align( 'right' );
                }
            }
            elsif( $left <= 1 )
            {
                $cell->align( 'left' );
            }
            elsif( $right <= 1 )
            {
                $cell->align( 'right' );
            }
            elsif( $left == $right ||
                   ( $left && $right && 
                     ( int( ( $left + $right ) / 2 ) == $left || int( ( $left + $right ) / 2 ) == $right ) 
                   ) ||
                   ( $left >= 2 && $right >= 2 )
                 )
            {
                $cell->align( 'center' );
            }
            if( $is_prev_row )
            {
                if( length( $content ) )
                {
                    ## Check for the cell above
                    my $prev_cell = $rows->[-1]->children->get( $col_n );
                    if( $prev_cell )
                    {
                        $prev_cell->add_element( $cell->create_text({ text => $content }) );
                        # $prev_cell->children->push( $cell->create_text( $content ) );
                    }
                    else
                    {
                        warn( "This cell $col_n at row $row_n is marked as continuity, but there is no record of previous upper cell.\n" );
                    }
                }
                ## Empty cell and this row is a continuity from the previous row, so we skip
                else
                {
                    next;
                }
            }
            else
            {
                # push( @$cols, $cell );
                $row->add_element( $cell );
            }
            $col_n++;
        }
        
        unless( $is_prev_row )
        {
            $row_n++;
            push( @$rows, $row );
        }
    }
    push( @$body, $rows ) if( scalar( @$rows ) );
    ## Return body of rows set, which is an array of array reference containing row objects.
    return( $body );
}

sub scope { return( shift->_set_get_object( 'scope', 'Markdown::Parser::Scope', @_ ) ); }

sub scope_block
{
    my $self = shift( @_ );
    my $opts = {};
    if( scalar( @_ ) && $self->_is_array( $_[0] ) )
    {
        $opts = $self->new_array( shift( @_ ) )->as_hash({ start_from => 1 });
    }
    else
    {
        $opts = $self->new_hash;
    }
    my $res = $self->new_array( [qw( block )] );
    if( !$opts->exists( '-extended' ) && $self->scope->has( 'extended' ) )
    {
        $res->push( 'extended' );
    }
    elsif( $opts->exists( '+extended' ) )
    {
        $res->push( 'extended' );
    }
    return( $res );
}

sub scope_inline
{
    my $self = shift( @_ );
    my $opts = {};
    if( scalar( @_ ) && $self->_is_array( $_[0] ) )
    {
        $opts = $self->new_array( shift( @_ ) )->as_hash({ start_from => 1 });
    }
    else
    {
        $opts = $self->new_hash;
    }
    my $res = $self->new_array( [qw( inline )] );
    if( !$opts->exists( '-extended' ) && $self->scope->has( 'extended' ) )
    {
        $res->push( 'extended' );
    }
    elsif( $opts->exists( '+extended' ) )
    {
        $res->push( 'extended' );
    }
    return( $res );
}

# Used for debugging
sub whereami
{
    my $self = shift( @_ );
    my( $ref, $pos, $opts ) = @_;
    return if( $self->debug < 4 );
    my $text = $opts->{text} || "Cusrsor is now here at position '$pos':";
    ## How far back should we look?
    my $lookback = 10;
    $lookback = $pos if( $pos < $lookback );
    my $lookahed = 20;
    my $start = $pos - $lookback;
    my $first_line = substr( $$ref, $start, $lookback + $lookahed );
    $lookback += () = substr( $$ref, $start, $lookback ) =~ /\n/gs;
    $first_line =~ s/\n/\\n/gs;
    my $sec_line = ( '.' x $lookback ) . '^' . ( '.' x $lookahed );
    return( "$text\n$first_line\n$sec_line" ) if( $opts->{return} );
    $self->message_colour( 3, "$text\n$first_line\n$sec_line" );
}

sub _total_trailing_new_lines
{
    my $self = shift( @_ );
    my $text = shift( @_ );
    my $trailing_nl = ( $text =~ /(\n+)$/ )[0];
    return( defined( $trailing_nl ) ? length( $trailing_nl ) : 0 );
}

# NOTE: Markdown::Parser::Scope package
package Markdown::Parser::Scope;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $ELEMENTS_DICTIONARY $ELEMENTS_DICTIONARY_EXTENDED $VERSION );
    our $VERSION = 'v0.1.0';
    our $ELEMENTS_DICTIONARY = $Markdown::Parser::ELEMENTS_DICTIONARY;
    our $ELEMENTS_DICTIONARY_EXTENDED = $Markdown::Parser::ELEMENTS_DICTIONARY_EXTENDED;
};

use strict;
use warnings;

sub init
{
    my $self  = shift( @_ );
    my $scope = shift( @_ );
    $self->{cache}      = {};
    $self->{condition}  = 'any';
    $self->{extended}   = 0;
    $self->{scope}      = {};
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    if( $self->_is_array( $scope ) )
    {
        $self->{scope} = $self->_to_array_object( $scope )->as_hash;
    }
    return( $self );
}

sub all { return( shift->_set_get_prop( 'all', @_ ) ); }

sub as_string { return( shift->scope->as_string ); }

sub cache { return( shift->_set_get_hash_as_mix_object( 'cache', @_ ) ); }

sub condition { return( shift->_set_get_scalar_as_object( 'condition', @_ ) ); }

sub extended { return( shift->_set_get_prop( 'extended', @_ ) ); }

sub extended_only { return( shift->_set_get_prop( 'extended_only', @_ ) ); }

sub has
{
    my $self  = shift( @_ );
    my $check = shift( @_ ) || return;
    # We clone the object, because we might modify it for the purpose of our checks
    my $scope = $self->scope->clone;
    my $what  = $self->new_array( $self->_is_array( $check ) ? $check : [ $check ] );
    my $cache = $self->cache;
    my $scope_cond = $self->condition || 'any';
    my $term_cond  = 'all';
    my $new   = $self->new_array;
    # Go through the required tokens
    $what->foreach(sub
    {
        if( s/\|{1,2}/ /g )
        {
            $new->push( split( /\s+/, $_ ) );
            $term_cond = 'any';
        }
        if( s/\+{1,2}/ /g )
        {
            $new->push( split( /\s+/, $_ ) );
            $term_cond = 'all';
        }
        else
        {
            $new->push( $_ );
        }
    });
    my $cache_key = join( ':', $scope_cond, $term_cond, $what->join( '|' )->scalar );
    return( $cache->{ $cache_key } ) if( exists( $cache->{ $cache_key } ) );
    $new->for(sub
    {
        my( $i, $val ) = @_;
        if( substr( $val, 0, 4 ) eq 'ext_' )
        {
            $new->splice( $i, 1, substr( $val, 4 ) );
            $new->push( 'extended' ) unless( $new->has( 'extended' ) );
        }
    });
    $what = $new;
    # Expected positive hits should be equal to the number of array elements for the scope terms being checked
    # Ex: [qw( header extended )] requires 2 hits, but
    # [qw( header||extended )] requires just 1 hit
    my $expect = $what->length;
    my $hits = 0;
    my $is_ext = $scope->has( 'extended' );

    my $dict;
    if( $is_ext )
    {
        $dict = $ELEMENTS_DICTIONARY_EXTENDED;
        # We remove it so it does not interfere. It is ok, since $scope here is a clone.
        $scope->delete( 'extended' );
    }
    else
    {
        $dict = $ELEMENTS_DICTIONARY;
    }

    $scope->foreach(sub
    {
        my $scope_key = shift( @_ );
        $what->foreach(sub
        {
            my $scope_check = shift( @_ );
            # If the scope is explicitly included; or
            # if the scope is all, but excluding extended features and the query item is not an extended feature; or
            # if the scope is extended ONLY and the query item is an extended feature; or
            # if the scope is extended and it does not matter what the query item is

            if( $scope_key eq $scope_check ||
                (
                    ( $scope_key eq 'all' || $scope_key eq 'block' || $scope_key eq 'inline' ) &&
                    exists( $dict->{ $scope_key } ) &&
                    ref( $dict->{ $scope_key } ) eq 'ARRAY' &&
                    scalar( grep( /^$scope_check$/i, @{$dict->{ $scope_key }} ) )
                )
                ||
                (
                    $scope_key eq 'all' &&
                    ( $scope_check eq 'block' || $scope_check eq 'inline' ) &&
                    exists( $dict->{ $scope_check } )
                )
                ||
                ( $scope_check ne 'extended' && $scope_key eq 'all' )
                ||
                ( $is_ext && $scope_check eq 'extended' ) )
            {
                $hits++;
            }
            else
            {
                # No match
            }
        });
    });
    $cache->{ $cache_key } = ( ( $term_cond eq 'all' && $expect == $hits ) || ( $term_cond eq 'any' && $hits ) ) ? 1 : 0;
    return( ( ( $term_cond eq 'all' && $expect == $hits ) || ( $term_cond eq 'any' && $hits ) ) ? 1 : 0 );
}

sub scope { return( shift->_set_get_hash_as_mix_object( 'scope', @_ ) ); }

sub _set_get_prop
{
    my $self = shift( @_ );
    my $key  = shift( @_ );
    my $scope = $self->scope;
    $scope->{ $key } = shift( @_ ) if( @_ );
    return( $scope->{ $key } );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Markdown::Parser - Markdown Parser Only

=head1 SYNOPSIS

    use Markdown::Parser;
    my $p = Markdown::Parser->new;
    # Maybe with some callback?
    my $p = Markdown::Parser->new( callback => sub
    {
        my $obj = shift( @_ );
        # Do some processing with that Markdown object..
    });
    my $doc = $p->parse( $some_markdown_string ) || 
        die( $p->error );
    my $doc = $p->parse_file( $some_file ) ||
        die( $p->error );
    # Each element is an object inheriting from Markdown::Parser::Element
    printf( "%d children object collected.\n", $doc->children->length );
    my $markdown = $doc->as_markdown;
    my $html = $doc->as_string;
    my $pod = $doc->as_pod;

=head1 VERSION

    v0.5.0

=head1 DESCRIPTION

L<Markdown::Parser> is an object oriented L<Markdown parser|https://daringfireball.net/projects/markdown/syntax> and manipulation interface.

It provides 2 modes: 1) strict and 2) extended

In strict mode, it conform rigorously to the Markdown specification as set out by its original author John Gruber and the extended mode, it accept and recognises extended Markdown syntax as set out in L<PHP Markdown Extra|https://michelf.ca/projects/php-markdown/extra/> by L<Michel Fortin|https://michelf.ca/home/>

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<Markdown::Parser> object, pass an hash reference of following parameters:

=over 4

=item abbreviation_case_sensitive

Boolean value to determine if abbreviation, that are extended markdown, should be case sensitive or not.
Default is false, i.e. they are not case sensitive, so an abbreviation declaration like:

*[HTML4] Hypertext Markup Language Version 4

would match either C<HTML4> or C<html4> or even C<hTmL4>

=item callback

Provided with a code reference, and this will register it as a callback to be triggered for every Markdown object encountered while parsing the data provided.

You can also provide C<undef>

=item css_grid

A boolean value to set whether to return the tables as a L<css grid|https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout> rather than as an L<html table|https://developer.mozilla.org/en-US/docs/Learn/HTML/Tables/Basics>.

This boolean value is passed to the L<Markdown::Parser::Element/create_table> in the L</parse_table> method.

L<CSS grids|https://medium.com/@js_tut/css-grid-tutorial-filling-in-the-gaps-c596c9534611> offer more flexibility and power than their conventional html counterparts.

To achieve this, this module uses L<CSS::Object> and inserts necessary css rules to be added to an inline style in the head section of the html document.

Once the parsing is complete, you can get the L<CSS::Object> object with L</css> method.

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<mode>

This can be either I<strict> or I<extended>. By default it is set to I<strict>

=back

=head1 EXCEPTION HANDLING

Whenever an error has occurred, L<Markdown::Parser> will set a L<Module::Generic::Exception> object containing the detail of the error and return undef.

The error object can be retrieved with the inherited L<Module::Generic/error> method. For example:

    my $p = Markdown::Parser->new( debug => 3 ) || die( Markdown::Parser->error );

=head1 METHODS

=head2 abbreviation_case_sensitive

Boolean value that affects the way abbreviation are retrieved with L<Markdown::Parser::Document/get_abbreviation>

=head2 callback

Sets or gets a code reference, and this will register it as a callback to be triggered for every Markdown object encountered while parsing the data provided.

You can also set C<undef> to deactivate this feature.

=head2 charset

Sets or gets the character set for the document. Typically something like C<utf-8>

=head2 code_highlight

Takes a boolean value.

This is currently unused.

=head2 create_document

Creates and returns a L<Markdown::Parser::Document> object. This is a special object which is the top element.

=head2 css

Sets or get the L<CSS::Object> objects. If one is set already, it is returned, or else an object is instantiated.

=head2 css_builder

This is a shortcut for the L<CSS::Object/builder> method.

=head2 css_grid

A boolean value to set whether to return the tables as a L<css grid|https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout> rather than as an L<html table|https://developer.mozilla.org/en-US/docs/Learn/HTML/Tables/Basics>.

=head2 default_email

Sets or gets the default email address to use, such as when setting up anti-spam measures.

See L<Markdown::Parser::Link/as_string>

=head2 document

Contains the L<Markdown::Parser::Document> object. An L<Markdown::Parser::Document> object is created by L</parser> to contain all the parsed markdown elements.

=head2 email_obfuscate_class

The css class to use when obfuscating email address.

See L<Markdown::Parser::Link/as_string>

=head2 email_obfuscate_data_host

The fake host to use when performing email obfuscation.

See L<Markdown::Parser::Link/as_string>

=head2 email_obfuscate_data_user

The fake user to use when performing email obfuscation.

See L<Markdown::Parser::Link/as_string>

=head2 encrypt_email

Boolean value to mark e-mail address found to be encrypted. See L<Markdown::Parser::Link> for more information.

=head2 footnote_ref_sequence

This is more an internal method used to keep track of the footnote reference found, i.e. something like:

    Here's a simple footnote,[^1] and here's a longer one.[^bignote]

So that the counter can be used to auto-generate number visible for those reference to footnotes.

This is differente from the footnote reference id i.e. the link from footnote back to the point where they are linked. For example:

    Here’s a simple footnote,1 and here’s a longer one.2

        1. This is the first footnote. ↩ # <-- Backlink is here

        2. Here’s one with multiple paragraphs and code. ↩ # <-- and here also

Here C<1> and C<2> are provided thanks to the L</footnote_ref_sequence> and allocated to each L<Markdown::Parser::FootnoteReference>

=head2 from_html

Provided with an L<HTML::Object::Element>, presumably an L<HTML::Object::Document> object, and this will do its best to import it as a L<Markdown::Parser::Document> object.

It returns a L<Markdown::Parser::Document> object upon success, and if an L<error|Module::Generic> occurred, it returns C<undef>

=head2 katex_delimiter

Sets or gets an array reference.

The delimiter to use with C<katex>

Returns an array object (L<Module::Generic::Array>)

=head2 list_level

Sets or gets the list level. This takes an integer and is used during parsing of lists.

This method can be accessed as a regular method, or as a lvalue method, such as:

    $parser->list_level( 2 );
    # or
    $parser->list_level = 2;
    # or even
    $parser->list_level++;

=head2 mode

Sets or gets the mode for the parser. Possible values are C<strict> or C<extended>

If set to C<extended>, the the scope of the parser will include non-standard markdown formattings.

=head2 parse

Provided with a string and some optional argument passed as an hash reference, and this will parse the string, create all the necessary object to represent the extent of the markdown document.

It returns the L<Markdown::Parser::Document> object.

Possible arguments are:

=over 4

=item I<element>

A L<Markdown::Parser::Element> subclass object that is used to store all newly created object from the parsing of the string provided.

L</parse> is called recursively, so this makes it possible to set sub element as the container element in parsing.

=item I<scope>

Can be a string or an array reference defining the extent of the scope within which the parser operates. For example, if it is set to C<strict>, it will only parse standard markdown formatting and ignore the rest.

But, if we wanted to only parse paragraph and blockquotes and nothing else, its value would be:

    [qw( paragraph blockquote )]

=item I<scope_cond>

Sets whether the scope item specified are to be understood as C<any one of them> or C<all of them> Thius possible value is C<any> or C<all>.

=back

=head2 parse_file

Given a file path, and this will check if it can access the resource, and open the file and call L</parse> on the content retrieved.

If for some reason, the file content could not be accessed, it returns undef and set an error using L<Module::Generic/error> that this package inherits.

=head2 parse_list_item

This method is called when the parser encounters a markdown list.

It takes a string representing the entire list and an optional hash reference of options.

Possible options are:

=over

=item I<doc>

The L<Markdown::Parser::Element> object to be used as container of all the item found during parsing.

=item I<pos>

An integer representation the position at which the parsing should start.

=back

It returns a L<Markdown::Parser::Document> object.

=head2 parse_list_item

This method is called from within L</parse> when an ordered or unordered list is found. It recursively parse the list data.

=head2 parse_table

This method is called from within L</parse> when a table is found.

It will create a L<Markdown::Parser::Table> and associated objects, such as L<Markdown::Parser::TableHeader>, L<Markdown::Parser::TableBody> and L<Markdown::Parser::Caption>

There can be one to 2 lines of headers and multiple table bodies. Table headers and table bodies contain L<table rows|Markdown::Parser::TableRow>, who, in turn, contain L<Markdown::Parser::TableCell> objects.

=head2 parse_table_row

Provided with a string representing a table row, along with optional hash reference of options and this willparse the string and return an array reference of L<Markdown::Parser::TableRow> objects. Each L<Markdown::Parser::TableRow> object contains one or multiple instance of L<Markdown::Parser::TableCell> objects.

=head2 scope

Returns the L<Markdown::Parser::Scope> which is used during parsing to determine whether each element is part of the scope of not. During parsing, the scope may vary and may include only block element while sometime, the scope is limited to inline elements. For speed, the scope method L<Markdown::Parser::Scope/has> is cached.

=head2 scope_block

Get a new scope parameter, in the form of an array reference, that has a scope for block elements.

=head2 scope_inline

Get a new scope parameter, in the form of an array reference, that has a scope for inline elements.

=head2 whereami

Provided with a scalar, an integer representing a position in the scalar, and an optional hash reference of options, and this method will print out or return a formatted string to visually show where exactly is the cursor in the string.

This is used solely for debugging and is resource intensive, so this along with the rest of the debugging method should not be used in live production.

This is activated when the parser object debug value is greater or equal to 3.

=head1 PRIVATE METHODS

=head2 _total_trailing_new_lines

Count how many trailing new lines there are in the given string and returns the number.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Regexp::Common::Markdown> for the regular expressions used in this distribution.

L<Text::Markdown::Discount> for a fast markdown to html converter using C code.

L<Text::Markdown> for a version in pure perl.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
