package HTML::Index::Document;

use strict;
use warnings;

use Class::Struct;
use HTML::Entities qw( decode_entities );
require HTML::TreeBuilder;

struct 'HTML::Index::Document::Struct' => {
    name        => '$',
    path        => '$',
    contents    => '$',
    parser      => '$',
};

my @NON_VISIBLE_HTML_TAGS = qw(
    style
    script
    head
);

my $NON_VISIBLE_HTML_TAGS = '(' . join( '|', @NON_VISIBLE_HTML_TAGS ) . ')';

use vars qw( @ISA );

@ISA = qw( HTML::Index::Document::Struct );

#------------------------------------------------------------------------------
#
# Constructor
#
#------------------------------------------------------------------------------

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new( @_ );
    $self->_init();
    return $self;
}

sub parse
{
    my $self = shift;

    my $contents = $self->contents();

    if ( lc( $self->parser ) eq 'html' )
    {
        my $tree = HTML::TreeBuilder->new();
        $tree->parse( $contents );
        my $text = join( ' ', _get_text_array( $tree ) );
        $tree->delete();
        return $text;
    }
    elsif ( lc( $self->parser eq 'regex' ) )
    {
        my $text = $contents;
        # get rid of non-visible (script / style / head) text
        $text =~ s{
            <$NON_VISIBLE_HTML_TAGS.*?> # a head, script, or style start tag
            .*?                         # non-greedy match of anything
            </\1>                       # matching end tag
        }
        {}gxis; 
        # get rid of tags
        $text =~ s/<.*?>//gs;
        $text = decode_entities( $text );
        $text =~ s/[\s\240]+/ /g;
        return $text;
    }
    else
    {
        die "Unrecognized value for parser - should be one of (html|regex)\n";
    }
}

#------------------------------------------------------------------------------
#
# Private functions
#
#------------------------------------------------------------------------------

sub _init
{
    my $self = shift;
    if ( my $path = $self->path() )
    {
        die "Can't read $path\n" unless -r $path;
        unless ( $self->contents() )
        {
            open( FH, $path );
            $self->contents( join( '', <FH> ) );
            close( FH );
        }
        $self->name( $self->path() ) unless $self->name();
    }
    die "No name attribute\n" unless defined $self->name();
    die "No contents attribute\n" unless defined $self->contents();
    $self->parser( 'html' ) unless $self->parser();
    die "parser attribute should be one of (html|regex)\n" 
        unless $self->parser() =~ /^(html|regex)$/i
    ;

    return $self;
}

sub _get_text_array
{
    my $element = shift;
    my @text;

    for my $child ( $element->content_list )
    {
        if ( ref( $child ) )
        {
            next if $child->tag =~  /^$NON_VISIBLE_HTML_TAGS$/;
            push( @text, _get_text_array( $child ) );
        }
        else
        {
            push( @text, $child );
        }
    }

    return @text;
}

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

HTML::Index::Document - Perl object used by HTML::Index::Store to create an
index of HTML documents for searching

=head1 SYNOPSIS

    $doc = HTML::Index::Document->new( path => $path );

    $doc = HTML::Index::Document->new( 
        name        => $name,
        contents    => $contents,
        mod_time    => $mod_time,
    );

=head1 DESCRIPTION

This module allows you to create objects to represent HTML documents to be
indexed for searching using the HTML::Index modules. These might be HTML files
in a webserver document root, or HTML pages stored in a database, etc.

HTML::Index::Document is a subclass of Class::Struct, with 4 attributes:

=over 4

=item path

The path to the document. This is an optional attribute, but if used should
correspond to an existing, readable file.

=item name

The name of the document. This attribute is what is returned as a result of a
search, and is the primary identifier for the document. It should be unique. If
the path attribute is set, then the name attribute defaults to path. Otherwise,
it must be provided to the constructor.

=item contents

The (HTML) contents of the document. This attribute provides the text which is
indexed by HTML::Index::Store. If the path attribute is set, the contents
attribute defaults to the contents of path. Otherwise, it must be provided to
the constructor.

=item parser

Should be one of html or regex. If html, documents are parsed using
HTML::TreeBuilder to extract visible text. If regex, the
same job is done by a "quick and dirty" regex.

=back

=head1 SEE ALSO

=over 4

=item L<HTML::Index>

=item L<HTML::Index::Store>

=back

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
#
# True ...
#
#------------------------------------------------------------------------------

1;
