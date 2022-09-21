##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Document.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2022/09/19
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::Document;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use vars qw( $VERSION );
    use Nice::Try;
    use URI;
    use Scalar::Util ();
    use Devel::Confess;
    our $VERSION = 'v0.2.0';
    use constant MERMAID_RSRC_URI => 'https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js';
    use constant MERMAID_INIT     => "mermaid.initialize({startOnLoad:true});";
    # https://katex.org/
    use constant KATEX_CSS_URI => 'https://cdn.jsdelivr.net/npm/katex/dist/katex.min.css';
    use constant KATEX_JS_URI => 'https://cdn.jsdelivr.net/npm/katex/dist/katex.min.js';
    use constant KATEX_AUTO_RENDERER => 'https://cdn.jsdelivr.net/npm/katex/dist/contrib/auto-render.min.js';
    use constant KATEX_FONT_URI => 'https://cdn.jsdelivr.net/npm/webfontloader/webfontloader.js';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{abbreviation_case_sensitive}    = 0;
    $self->{bolds}                          = {};
    $self->{default_email}                  = '';
    $self->{dict}                           = {};
    $self->{email_obfuscate_class}          = 'courriel';
    $self->{email_obfuscate_data_host}      = 'host';
    $self->{email_obfuscate_data_user}      = 'user';
    $self->{emphasis}                       = {};
    ## All footnotes objects ordered
    $self->{footnotes}                      = [];
    ## Footnotes hash id => object
    $self->{footnotes_dict}                 = {};
    $self->{katex_delimiter}                = ['$$','$$','$','$','\[','\]','\(','\)'];
    $self->{links}                          = {};
    $self->{objects}                        = {};
    $self->{tag_name}                       = '';
    return( $self->SUPER::init( @_ ) );
}

sub abbreviation_case_sensitive { return( shift->_set_get_scalar( 'abbreviation_case_sensitive', @_ ) ); }

sub add_css_link
{
    my $self = shift( @_ );
    my $url  = shift( @_ ) || return( $self->error( "No css link uri provided" ) );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $_[-1] ) );
    my $uri;
    try
    {
        $uri = URI->new( $url );
    }
    catch( $e )
    {
        return( $self->error( "Bad uri provided for this css link: '$url'" ) );
    }
    my $found;
    $self->css_links->foreach(sub
    {
        my $ref = shift( @_ );
        if( $ref->{uri} eq $uri )
        {
            $found++;
            return;
        }
    });
    return( $uri ) if( $found );
    $opts->{uri} = $uri;
    $self->css_links->push( $opts );
    return( $self );
}

sub add_js_data
{
    my $self = shift( @_ );
    my $js = shift( @_ );
#     unless( $self->js_data->exists( $js ) )
#     {
#         $self->js_data->push( $js );
#     }
    my $found;
    $self->js_data->foreach(sub
    {
        if( $_ eq $js )
        {
            $found++;
            return;
        }
    });
    $self->js_data->push( $js ) if( !$found );
    return( $self );
}

sub add_js_link
{
    my $self = shift( @_ );
    my $url  = shift( @_ ) || return( $self->error( "No JavaScript link uri provided" ) );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $_[-1] ) );
    my $uri;
    try
    {
        $uri = URI->new( $url );
    }
    catch( $e )
    {
        return( $self->error( "Bad uri provided for this JavaScript link: '$url'" ) );
    }
    my $found;
    $self->js_links->foreach(sub
    {
        my $ref = shift( @_ );
        if( $ref->{uri} eq $uri )
        {
            $found++;
            return;
        }
    });
    return( $uri ) if( $found );
    $opts->{uri} = $uri;
    $self->js_links->push( $opts );
    return( $self );
}

sub add_object
{
    my $self = shift( @_ );
    my $obj  = shift( @_ );
    return if( !ref( $obj ) );
    return if( !$self->_is_a( $obj, 'Markdown::Parser::Element' ) );
    my $id = $obj->object_id;
    $self->objects->set( $id => $obj );
    return( $id );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    if( $self->links->length )
    {
        $str .= "\n\n";
        $str .= $self->links->map_array(sub{ $_[1]->as_markdown })->join( "\n" );
    }
    if( $self->dict->length )
    {
        $str .= "\n\n";
        $str .= $self->dict->map_array(sub{ $_[1]->as_markdown })->join( "\n" );
    }
    if( $self->footnotes->length )
    {
        $str .= "\n\n";
        $str .= $self->footnotes->map_array(sub{ $_[1]->as_markdown })->join( "\n" );
    }
    return( $str );
}

sub as_pod
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_pod })->join( '' );
    if( $self->dict->length )
    {
        $str .= "\n\n";
        $str .= $self->dict->map_array(sub{ $_[1]->as_pod })->join( "\n" );
    }
    if( $self->footnotes->length )
    {
        $str .= "\n\n";
        $str .= $self->footnotes->map_array(sub{ $_[1]->as_pod })->join( "\n" );
    }
    return( $str );
}

sub as_string
{
    my $self = shift( @_ );
    my $arr = $self->new_array;
    my $css_style;
    my $css = $self->css;
    my $temp_buffer = $self->new_array;
    ## We need to set this temporary buffer because calling our children's as_string method does some set-ups that affects us
    $temp_buffer->push( $self->children->map(sub{ $_->as_string })->join( "\n" )->scalar );
    
    $arr->push( <<EOT );
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title></title>
EOT
    $self->css_links->foreach(sub
    {
        my $ref = shift( @_ );
        my $e = $self->new_array( ['link'] );
        $ref->{rel} = 'stylesheet' unless( length( $ref->{rel} ) );
        $ref->{type} = 'text/css' unless( length( $ref->{type} ) );
        $ref->{href} = delete( $ref->{uri} );
        foreach my $k ( sort( keys( %$ref ) ) )
        {
            $e->push( sprintf( '%s="%s"', $k, $ref->{ $k } ) );
        }
        $arr->push( '<' . $e->join( ' ' )->scalar . ' />' );
    });
    if( $css->elements->length > 0 )
    {
        $css_style = $css->as_string;
        $arr->push( <<EOT );
        <style>
${css_style}
        </style>
EOT
    }
    $self->js_links->foreach(sub
    {
        my $ref = shift( @_ );
        my $e = $self->new_array( ['script'] );
        $ref->{src} = delete( $ref->{uri} );
        $ref->{language} = 'JavaScript' unless( length( $ref->{language} ) );
        $ref->{type} = 'text/javascript' unless( length( $ref->{type} ) );
        $e->push( 'defer' ) if( delete( $ref->{defer} ) );
        foreach my $k ( sort( keys( %$ref ) ) )
        {
            $e->push( sprintf( '%s="%s"', $k, $ref->{ $k } ) );
        }
        $arr->push( '<' . $e->join( ' ' )->scalar . '></script>' );
    });
    $self->js_data->foreach(sub
    {
        my $js = shift( @_ );
        return( 1 ) if( !length( $js ) );
        $arr->push( '<script type="text/javascript" language="JavaScript">' );
        $arr->push( $js );
        $arr->push( '</script>' );
    });
    $arr->push( <<EOT );
    </head>
    <body>
EOT
    ## $arr->push( $self->children->map(sub{ $_->as_string })->join( "\n" )->scalar );
    $arr->push( $temp_buffer->list );
    if( $self->footnotes->length )
    {
        my $fn = $self->new_array;
        $fn->push( '<div class="footnotes" role="doc-endnotes">' );
        $fn->push( '<hr />' );
        $fn->push( '<ol>' );
        # $fn->push( $self->footnotes->map_array(sub{ $_[1]->as_string })->join( "\n" )->scalar );
        my $fn_str = $self->footnotes->map(sub{ $_->as_string })->join( "\n" )->scalar;
        $fn->push( $fn_str );
        $fn->push( '</ol>' );
        $arr->push( $fn->join( "\n" )->scalar );
    }
    $arr->push( <<EOT );
    </body>
</html>
EOT
    return( $arr->join( "\n" )->scalar );
}

sub bolds { return( shift->_set_get_hash_as_mix_object( 'bolds', @_ ) ); }

sub css { return( shift->_set_get_object( 'css', 'CSS::Object', @_ ) ); }

sub css_links { return( shift->_set_get_array_as_object( 'css_links', @_ ) ); }

sub default_email { return( shift->_set_get_scalar_as_object( 'default_email', @_ ) ); }

## Ex: $self->dict->some_word( "Some value" );
## Uses Module::Generic::Hash hash object
sub dict { return( shift->_set_get_hash_as_mix_object( 'dict', @_ ) ); }

## Alias
sub dictionary { return( shift->_set_get_hash_as_mix_object( 'dict', @_ ) ); }

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

sub emphasis { return( shift->_set_get_hash_as_mix_object( 'emphasis', @_ ) ); }

sub footnotes { return( shift->_set_get_array_as_object( 'footnotes', @_ ) ); }

sub footnotes_dict { return( shift->_set_get_hash_as_mix_object( 'footnotes_dict', @_ ) ); }

sub get_abbreviation
{
    my $self = shift( @_ );
    my $name = shift( @_ );
    return if( !length( $name ) );
    $name = lc( $name ) unless( $self->abbreviation_case_sensitive );
    return if( !$self->dict->exists( $name ) );
    my $elem = $self->dict->{ $name };
    return( $elem );
}

sub get_footnote
{
    my $self = shift( @_ );
    my $id = shift( @_ );
    return if( !length( $id ) );
    return if( !$self->footnotes_dict->exists( $id ) );
    my $elem = $self->footnotes_dict->{ $id };
    return( $elem );
}

## This method only make sense when called on the top most element, so we bubble up until we hit it
sub get_link_by_id
{
    my $self = shift( @_ );
    my $id = shift( @_ );
    return if( !length( $id ) );
    $id = lc( $id );
    return if( !$self->links->exists( $id ) );
    my $elem = $self->links->{ $id };
    return( $elem );
}

sub is_email_obfuscation_setup { return( shift->_set_get_boolean( 'is_email_obfuscation_setup', @_ ) ); }

sub is_katex_setup { return( shift->_set_get_boolean( 'is_katex_setup', @_ ) ); }

sub is_mermaid_setup { return( shift->_set_get_boolean( 'is_mermaid_setup', @_ ) ); }

sub js_data { return( shift->_set_get_array_as_object( 'js_data', @_ ) ); }

sub js_links { return( shift->_set_get_array_as_object( 'js_links', @_ ) ); }

sub katex_delimiter { return( shift->_set_get_array_as_object( 'katex_delimiter', @_ ) ); }

sub links { return( shift->_set_get_hash_as_mix_object( 'links', @_ ) ); }

sub objects { return( shift->_set_get_hash_as_mix_object( 'objects', @_ ) ); }

sub register_abbreviation
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $opts ) );
    return( $self->error( "No abbreviation definition was provided to register it." ) ) if( !length( $elem ) );
    my $base = $self->base_class;
    return( $self->error( "Element provided \"$elem\" is not an ${base}::Abbr object." ) ) if( !$self->_is_a( $elem, "${base}::Abbr" ) );
    my $name = $elem->name;
    $name = lc( $name ) if( !$opts->{abbreviation_case_sensitive} );
    return( $self->error( "No name is set for this abbreviation." ) ) if( !length( $name ) );
    $self->dict->set( $name => $elem );
    return( $self );
}

sub register_footnote
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    return( $self->error( "No link definition was provided to register it." ) ) if( !length( $elem ) );
    my $base = $self->base_class;
    return( $self->error( "Element provided \"$elem\" is not an ${base}::Footnote object." ) ) if( !$self->_is_a( $elem, "${base}::Footnote" ) );
    my $id = $elem->id;
    return( $self->error( "No id is set for this footnote." ) ) if( !length( $id ) );
    $self->footnotes_dict->set( lc( $id ) => $elem );
    $self->footnotes->push( $elem );
    return( $self );
}

sub register_link_definition
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    return( $self->error( "No link definition was provided to register it." ) ) if( !length( $elem ) );
    my $base = $self->base_class;
    return( $self->error( "Element provided \"$elem\" is not an ${base}::LinkDefinition object." ) ) if( !$self->_is_a( $elem, "${base}::LinkDefinition" ) );
    my $id = $elem->link_id;
    return( $self->error( "No id is set for this link definition." ) ) if( !length( $id ) );
    $self->links->set( lc( $id ) => $elem );
    return( $self );
}

sub setup_email_obfuscation
{
    my $self = shift( @_ );
    return( $self ) if( $self->is_email_obfuscation_setup );
    $self->is_email_obfuscation_setup( 1 );
    my $b = $self->css->builder;
    my $class = $self->email_obfuscate_class->length > 0 ? $self->email_obfuscate_class->scalar : 'courriel';
    my $data_host = $self->email_obfuscate_data_host->length > 0 ? $self->email_obfuscate_data_host->scalar : 'data-host';
    my $data_user = $self->email_obfuscate_data_user->length > 0 ? $self->email_obfuscate_data_user->scalar : 'data-user';
    ## Credits for the css part: https://stackoverflow.com/a/21421949/4814971
    $b->select( [".${class}:before"] )->
        content( sprintf( 'attr(data-%s) "\0040" attr(data-%s)', $data_host, $data_user ) )->
        unicode_bidi( 'bidi-override' )->
        direction( 'rtl' );
    $self->add_js_data( <<EOT );
(function()
{
    var docLoaded = setInterval(function()
    {
        if( document.readyState !== "complete" ) return;
        clearInterval( docLoaded );
        document.querySelectorAll('.${class}').forEach( item =>
        {
            item.addEventListener('click', event => 
            {
                if( !event.target.dataset.decoded )
                {
                    event.preventDefault();
                    function decode(a, r)
                    {
                        return a.split( '' ).reverse().join( '' );
                    };
                    var y = decode( event.target.dataset.${data_user} ) + '\@' + decode( event.target.dataset.${data_host} );
                    var enc = encodeURI( y );
                    enc = enc.replace( '?', '%3F' );
                    // console.log( "Final e-mail is: " + enc );
                    event.target.setAttribute( 'href', 'mai' + 'lto:' + enc );
                    event.target.dataset.decoded = true;
                    // console.log( "Redirecting to " + enc );
                    window.location.href = 'mai' + 'lto:' + enc;
                    return( false );
                }
            });
        });
    });
})();
EOT
    return( $self );
}

sub setup_katex
{
    my $self = shift( @_ );
    return( $self ) if( $self->is_katex_setup );
    $self->add_css_link( KATEX_CSS_URI, { crossorigin => 'anonymous' });
    $self->add_js_link( KATEX_JS_URI, { crossorigin => 'anonymous' } );
    $self->add_js_link( KATEX_AUTO_RENDERER, { crossorigin => 'anonymous', defer => 1, onload => 'renderMathInElement(document.body);' });
    $self->add_js_data( <<'EOT' );
window.WebFontConfig = 
{
    custom: 
    {
        families: ['KaTeX_AMS', 'KaTeX_Caligraphic:n4,n7', 'KaTeX_Fraktur:n4,n7',
            'KaTeX_Main:n4,n7,i4,i7', 'KaTeX_Math:i4,i7', 'KaTeX_Script',
            'KaTeX_SansSerif:n4,n7,i4', 'KaTeX_Size1', 'KaTeX_Size2', 'KaTeX_Size3',
            'KaTeX_Size4', 'KaTeX_Typewriter'],
    },
};
EOT
    $self->add_js_link( KATEX_FONT_URI, { crossorigin => 'anonymous', defer => 1 });
    my $map =
    {
    '$$$$'  => 'true',
    '$$'    => 'false',
    '\[\]'  => 'true',
    '\(\)'  => 'false',
    };
    my $delim = $self->new_array;
    my $d = $self->katex_delimiter;
    for( my $i = 0; $i < $d->length; $i += 2 )
    {
        my $k = join( '', @$d[$i..$i+1] );
        $delim->push( sprintf( '            {left: "%s", right: "%s", display: %s},', $d->[$i], $d->[$i+1], $map->{ $k } ) ) if( exists( $map->{ $k } ) );
    }
    my $delim_specs = $delim->join( "\n" )->scalar;
    $self->add_js_data( <<EOT );
document.addEventListener("DOMContentLoaded", function() 
{
    renderMathInElement(document.body,
    {
        delimiters:
        [
${delim_specs}
        ]
    });
});
EOT
    $self->is_katex_setup( 1 );
    return( $self );
}

sub setup_mermaid
{
    my $self = shift( @_ );
    return( $self ) if( $self->is_mermaid_setup );
    $self->add_js_link( MERMAID_RSRC_URI );
    $self->add_js_data( MERMAID_INIT );
    $self->is_mermaid_setup( 1 );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Document - Markdown Document Element

=head1 SYNOPSIS

    my $doc = Markdown::Parser::Document->new;
    # or
    my $parser = Markdown::Parser->new;
    my $doc = $parser->create_document;

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represents a markdown document. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

This is the top element used and created by the parser.

=head1 METHODS

=head2 abbreviation_case_sensitive

Boolean that affects how L</get_abbreviation> works. If set to true, then abbreviations will be case sensitives, otherwise case will not matter. Default is to be case insensitive.

=head2 add_css_link

Provided with an css stylesheet URI, and this will add it to the document.

It returns an error if the url is not a valid url.

If the url has already been set, it will be ignored, so as to avoid duplicates.

It returns the current document object for chaining.

=head2 add_js_data

Provided with some javascript code, and this will add it to the stack stored in L</js_data>.

If it was already provided, it will be ignore so as to avoid duplicates.

It returns the current document object for chaining.

=head2 add_js_link

Provided with an javascript URI, and this will add it to the document.

It returns an error if the url is not a valid url.

If the url has already been set, it will be ignored, so as to avoid duplicates.

It returns the current document object for chaining.

=head2 add_object

Provided with a L<Markdown::Parser::Element> object and this will add it to its list of objects for this document in the special hash L</objects> using the object id retrieved with L<Markdown::Parser::Element/object_id>

=head2 as_markdown

Returns the document as markdown

=head2 as_pod

Returns the document as L<pod|perlpod>

=head2 as_string

Returns the parsed document structure as html, possibly including inline css rules

=head2 bolds

Sets or gets an hash reference of bolds values.

=head2 css

A shared L<CSS::Object> object, instantiated by L<Markdown::Parser> and shared with modules that may require the use of css, such as L<Markdown::Parser::Table>

This method is called by L<as_string> to add the necessary inline css rules in the head fo the resulting html document.

=head2 css_links

Sets or gets an array reference of css links.

It returns a L<Module::Generic::Array> objects.

=head2 default_email

Sets or gets the default email address to use for email obfuscation.

It could be something that should not exist like C<dave.null@example.com>

=head2 dict

An alias for L</dictionary>

=head2 dictionary

This is a L<Module::Generic::Hash> object containing key-value pairs for term definition.

=head2 email_obfuscate_class

The css class to use when obfuscating email address.

See L<Markdown::Parser::Link/as_string>

=head2 email_obfuscate_data_host

The fake host to use when performing email obfuscation.

See L<Markdown::Parser::Link/as_string>

=head2 email_obfuscate_data_user

The fake user to use when performing email obfuscation.

See L<Markdown::Parser::Link/as_string>

=head2 emphasis

Sets or gets an hash reference of key-value paris used for emphasis.

This returns a L<Module::Generic::Hash> object.

=head2 footnotes

Sets or gets an array reference of footnotes.

This returns a L<Module::Generic::Array> object.

=head2 footnotes_dict

Sets or gets a dictionary hash of footnotes to their definition.

This returns a L<Module::Generic::Hash> object.

=head2 get_abbreviation

Given a term, this will return its corresponding L<Markdown::Parser::Abbr> object

If L</abbreviation_case_sensitive> is set to a true value, the terms will be case sensitive.

=head2 get_footnote

Provided a footnote reference like C<1> or C<thisRef> and this will return the corresponding L<Markdown::Parser::Footnote> object, if any.

=head2 get_link_by_id

Provided a link id, and this returns the corresponding L<Markdown::Parser::Link> object, if any.

=head2 is_email_obfuscation_setup

Sets or gets a boolean value whether the email obfuscation is enabled.

=head2 is_katex_setup

Sets or gets a boolean value whether katex is enabled.

See the L<Katex website for more information|https://katex.org/>

=head2 is_mermaid_setup

Sets or gets a boolean value whether mermaid is enabled.

Mermaid is a nifty tool used for generating flowchart effortlessly.

See the L<Mermaid website for more information|https://mermaid-js.github.io/mermaid/>

=head2 js_data

Sets or gets the array reference object of javascript code to be used in this document.

This returns a L<Module::Generic::Array> object.

=head2 js_links

Sets or gets the array reference object of javascript links to be used in this document.

This returns a L<Module::Generic::Array> object.

=head2 katex_delimiter

Sets or gets the array reference object of possible katex delimiters.

This defaults to:

    ['$$','$$','$','$','\[','\]','\(','\)']

This returns a L<Module::Generic::Array> object.

=head2 links

Sets or gets the hash object containing link name and definition pairs.

The hash object is a L<Module::Generic::Hash> object.

=head2 objects

Sets or gets the hash object of L<Markdown::Parser::Elements> ids to their corresponding object.

This is a repository used internally and not to be messed up with.

It returns a L<Module::Generic::Hash>

=head2 register_abbreviation

Provided an L<Markdown::Parser::Abbr> object, and this add the abbreviation to the list of known abbreviations.

=head2 register_footnote

Provided an L<Markdown::Parser::Footnote> object, and this add the footnote with its id to the list of known footnotes.

=head2 register_link_definition

Provided with a a L<Markdown::Parser::LinkDefinition> object, and this adds it to the hash object for future reference.

Returns the current document object.

=head2 setup_email_obfuscation

If L</is_email_obfuscation_setup> is enabled and based on the L</email_obfuscate_class> class defined, and this will use L<CSS::Object> to find all matches and implement obfuscation for each match found.

This is based on a novel idea from L<https://stackoverflow.com/a/21421949/4814971>

It returns the current document object for chaining.

=head2 setup_katex

If L</is_katex_setup> is enabled, this will add all the necessary css and javascript resource to transform markdown mathematic typesettings into visual ones    .

It returns the current document object for chaining.

=head2 setup_mermaid

If L</is_mermaid_setup> is enabled, this will add all the necessary css and javascript resource to transform markdown flowcharts into visual flowcharts.

It returns the current document object for chaining.

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#link>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
