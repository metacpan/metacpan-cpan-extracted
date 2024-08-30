##----------------------------------------------------------------------------
## Markdown Parser Only - ~/lib/Markdown/Parser/Code.pm
## Version v0.3.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/08/23
## Modified 2024/08/30
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Markdown::Parser::Code;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Markdown::Parser::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.3.0';
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
    $self->{fenced}     = 0;
    $self->{id}         = [];
    $self->{css_rsrc}   = [qw( https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.1.2/styles/default.min.css )];
    $self->{highlight}  = 0;
    $self->{inline}     = 0;
    $self->{js_data}    = 'hljs.initHighlightingOnLoad();';
    $self->{js_rsrc}    = [qw( https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.1.2/highlight.min.js )];
    $self->{tag_name}   = 'code';
    return( $self->SUPER::init( @_ ) );
}

sub as_markdown
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_markdown })->join( '' );
    if( $self->fenced )
    {
        return( "```\n${str}\n```\n" );
    }
    elsif( $self->inline )
    {
        return( "`${str}`" );
    }
    elsif( $str->index( "\n" ) != -1 )
    {
        my $lines = $str->split( "\n" );
        $lines->for(sub
        {
            my( $i, $val ) = @_;
            substr( $lines->[ $i ], 0, 0 ) = '    ';
        });
        return( $lines->join( "\n" )->scalar );
    }
    else
    {
        return( "`${str}`" );
    }
}

sub as_pod
{
    my $self = shift( @_ );
    my $str = $self->children->map(sub{ $_->as_pod })->join( '' );
    if( $self->fenced )
    {
        my $lines = $str->split( qr/\n/ );
        return( '    ' . $lines->join( "\n    " )->scalar );
    }
    elsif( $self->inline )
    {
        if( $str->index( '>' ) != -1 ||
            $str->index( '<' ) != -1 )
        {
            return( "C<< ${str} >>" );
        }
        else
        {
            return( "C<${str}>" );
        }
    }
    # Essentially same as 'fenced'. Might need to improve the code
    else
    {
        my $lines = $str->split( qr/\n/ );
        $lines->for(sub
        {
            my( $i, $val ) = @_;
            substr( $lines->[ $i ], 0, 0 ) = '    ';
        });
        return( $lines->join( "\n" )->scalar );
    }
}

sub as_string
{
    my $self = shift( @_ );
    my $tag  = 'code';
    my $tag_open = $tag;
    if( $self->id->length )
    {
        $tag_open .= ' ' . $self->id->map(sub{ sprintf( 'id="%s"', $_ ) })->join( ' ' )->scalar;
    }
    if( $self->class->length )
    {
        $tag_open .= ' class="' . $self->class->join( ' ' )->scalar . '"';
        ## This does not apply to inline code
        if( !$self->inline )
        {
            if( $self->class->has( 'mermaid' ) )
            {
                $self->document->setup_mermaid;
            }
            elsif( $self->class->has( 'katex' ) )
            {
                $self->document->setup_katex;
            }
            else
            {
                $self->css_rsrc->foreach(sub
                {
                    $self->document->add_css_link( $_ ) if( length( $_ ) );
                });
                $self->js_rsrc->foreach(sub
                {
                    $self->document->add_js_link( $_ ) if( length( $_ ) );
                });
                $self->document->add_js_data( $self->js_data->scalar ) if( $self->js_data->length > 0 );
            }
        }
    }
    my $arr = $self->new_array;
    my $ct  = $self->new_array;
    my $attributes = $self->format_attributes;
    ## If the class is mermaid, we return a div with the content as per the Mermaid manual instructions:
    ## https://mermaid-js.github.io/mermaid/#/n00b-gettingStarted
    if( $self->class->has( 'mermaid' ) )
    {
        $arr->push( sprintf( '<div %sclass="%s"%s>', ( $self->id->length > 0 ? 'id="' . $self->id->first . '" ' : '' ), $self->class->join( ' ' )->scalar, ( $attributes->length > 0 ? ' ' . $attributes->join( ' ' )->scalar : '' ) ) );
        $ct->push( $self->children->map(sub
        {
            $_->as_string;
        })->list );
        $arr->push( $ct->join( "\n" )->scalar );
        $arr->push( "</div>" );
        return( $arr->join( "\n" )->scalar );
    }
    else
    {
        $arr->push( "<pre>" ) if( !$self->inline );
        my $tmp = $self->new_array( [ "<$tag_open" ] );
        my $attr = $self->new_array;
        $attr->push( $self->format_id ) if( $self->id->length );
        $attr->push( $self->format_class ) if( $self->class->length );
        my $attributes = $self->format_attributes;
        $attr->push( $attributes->join( ' ' )->scalar ) if( $attributes->length );
        $tmp->push( ' ' . $attr->join( ' ' )->scalar ) if( $attr->length );
        $tmp->push( '>' );
        $arr->push( $tmp->join( '' )->scalar );
        $ct->push( $self->children->map(sub
        {
            $_->as_string;
        })->list );
        $arr->push( $ct->join( "<br />\n" )->scalar );
        $arr->push( "</$tag>" );
        $arr->push( "</pre>" ) if( !$self->inline );
        return( $arr->join( ( $self->children->length > 1 || $ct->join( '' )->index( "\n" ) != -1 ) ? "\n" : '' )->scalar );
    }
}

sub add_element
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    my $base = $self->base_class;
    return( $self->error( "Element provided \"$elem\" is not an ${base}::Element object." ) ) if( !$self->_is_a( $elem, "${base}::Element" ) );
    return( $self->error( "Code accepts only ${base}::Text elements." ) ) if( !$self->_is_a( $elem, "${base}::Text" ) );
    my $text = $elem->text;
    if( $text )
    {
        $self->encode_html( [qw( < > & )] => $text ) || warn( $self->error );
        if( $self->inline )
        {
            $elem->text( $text );
        }
        elsif( $self->fenced )
        {
            my @lines = split( /\n/, $text );
            for( @lines )
            {
                s/^(?:\s{4}|\t)//;
            }
            $elem->text( join( "\n", @lines ) );
        }
        ## Broke it down in 3 conditions for readability
        else
        {
            $elem->text( $text );
        }
    }
    return( $self->SUPER::add_element( $elem ) );
}

sub css_rsrc { return( shift->_set_get_array_as_object( 'css_rsrc', @_ ) ); }

sub fenced { return( shift->_set_get_boolean( 'fenced', @_ ) ); }

sub highlight { return( shift->_set_get_boolean( 'highlight', @_ ) ); }

sub id { return( shift->_set_get_array_as_object( 'id', @_ ) ); }

sub inline { return( shift->_set_get_boolean( 'inline', @_ ) ); }

sub js_data { return( shift->_set_get_scalar_as_object( 'js_data', @_ ) ); }

sub js_rsrc { return( shift->_set_get_array_as_object( 'js_rsrc', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Markdown::Parser::Code - Markdown Code Element

=head1 SYNOPSIS

    my $o = Markdown::Parser::Code->new;
    # or
    $doc->add_element( $o->create_code( @_ ) );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents a code formatting. It is used by L<Markdown::Parser> and inherits from L<Markdown::Parser::Element>

=head1 METHODS

=head2 as_markdown

Returns a string representation of the code formatted in markdown.

It returns a plain string.

=head2 as_pod

Returns a string representation of the code formatted in L<pod|perlpod>.

It returns a plain string.

=head2 as_string

Returns an html representation of the code.

It returns a plain string.

=head2 add_element

Provided with a L<Markdown::Parser::Text> object, and this adds it as content element of this class.

Upon adding the text data, it does some encoding on characters E<lt>, E<gt> and C<&>

=head2 class

Sets or gets the array of css class associated with this code.

Values are stored as a L<Module::Generic::Array> object.

=head2 css_rsrc

Sets or gets an array reference of css stylesheet url used for css highlighting.

This defaults to L<https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.1.2/styles/default.min.css|>

=head2 fenced

Takes a boolean value, i.e. 1 or 0 to indicate whether this code is fenced or not.

When the value is true, the markdown representation of the code will use C<```> before and after the code as delimiter.

=head2 highlight

Boolean value that serves to decide on the use of L<JavaScript code highlighter|https://highlightjs.org>.

When set to true, this will add a C<<link>> and C<<script>> tags in the document head pointing to the CDN (Content Delivery Network) to load the necessary resources.

    <link rel="stylesheet"
          href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/10.1.2/styles/default.min.css">
    <script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/10.1.2/highlight.min.js"></script>

And you can add extra script to load for additional languages, for example:

    <script charset="UTF-8"
     src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.1.2/languages/go.min.js"></script>

According to L<"highlight" documentation|https://highlightjs.org/download/>, the default bundle contains 38 languages.

=head2 id

Sets or gets the array of id class associated with this code. Normally there should only be one.

Values are stored as a L<Module::Generic::Array> object.

=head2 inline

Takes a boolean value, i.e. 1 or 0 to indicate whether this code is inline or not.

=head2 js_data

Sets or gets the javascript code to use.

This defaults to:

    hljs.initHighlightingOnLoad();

=head2 js_rsrc

Sets or gets an array reference of javascript url used for code highlighting.

This defaults to L<https://cdnjs.cloudflare.com/ajax/libs/highlight.js/10.1.2/highlight.min.js>

=head1 SEE ALSO

Markdown original author reference on emphasis: L<https://daringfireball.net/projects/markdown/syntax#em>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
