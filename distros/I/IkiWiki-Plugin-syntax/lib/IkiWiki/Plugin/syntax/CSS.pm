package IkiWiki::Plugin::syntax::CSS;
use base qw(Exporter);
use strict;
use warnings;
use Carp;
use utf8;
use English qw(-no_match_vars);

## package variables 
our @EXPORT     =   qw( css match_css regex_match_css css_pair );
our $VERSION    =   '0.1';

## on memory data base :-)
our %css_tags       =   (
    ## added by the author
    line_number   =>  [ q(synLineNumber),  q(Number of line) ],
    title         =>  [ q(synTitle),       q(Source Title) ],
    description   =>  [ q(synDescription), q(Comments on source) ],
    bar_line      =>  [ q(synBar),         q(Source line barred) ],

    ## taken from Vim::TextColor 
    comment       =>  [ q(synComment),     q(Source commentary) ],
    constant      =>  [ q(synConstant),    q(Constant value) ],
    identifier    =>  [ q(synIdentifier),  q(Identifier name) ],
    statement     =>  [ q(synStatement),   q(Language statement) ],
    preproc       =>  [ q(synPreProc),     q(Preprocessor pragma) ],
    type          =>  [ q(synType),        q(Data type declaration) ],
    special       =>  [ q(synSpecial),     q(Special value) ],
    under         =>  [ q(synUnderlined),  q(Underlined text) ],
    error         =>  [ q(synError),       q(Error) ],
    todo          =>  [ q(synTodo),        q(To Do) ],
);

sub css {
    my  ($self, $tag, $content) =   @_;
    my  $tag_name               =   $tag;

    # only take the real CSS name if exists in hash 
    if (exists($css_tags{$tag})) {
        $tag_name = $css_tags{$tag}->[0];
    }

    return sprintf '<span class="%s">%s</span>', $tag_name, $content;
}

sub css_pair {
    my  $self       =   shift;      ## unused 
    my  $real_tag   =   shift;

    if (!defined $real_tag) {
        return ( '', '' );
    }
    return ( sprintf('<span class="%s">', $real_tag),
             sprintf '</span>' );
}

sub match_css {
    my  ($self, $search_tag, $text) = @_;
    my  $real_tag = exists($css_tags{$search_tag}) 
                    ? $css_tags{$search_tag}->[0]
                    : $search_tag;

    if ($real_tag) {                    
        return $text =~ $self->regex_match_css( $real_tag ); 
    }
    else {
        return 0;
    }
}

sub regex_match_css {
    my  ($self, $real_tag) = @_;

    return qr{<span class="$real_tag">.*</span>}ixms;
}

1;
__END__

=head1 NAME

IkiWiki::Plugin::syntax::CSS - Cascade Style Sheet library tags

=head1 VERSION

This documentation refers to IkiWiki::Plugin::syntax::CSS version 0.1

=head1 SYNOPSIS

    package IkiWiki::Plugin::syntax::base;

    use IkiWiki::Plugin::syntax::CSS;

    ...

    1;

=head1 DESCRIPTION

This package adds methods for build valid CSS expressions using neutral names.

=head1 SUBROUTINES/METHODS

=head2 css( )

    $self->css('title',q(This is the syntax paragraph title));

    $self->css('mySpecialCSStag',q(special paragraph));

This method take a tag name and a scalar text and builds a valid CSS text for
inclusion in HTML files.

If the tag name don't exists in the internal table, the method take his value
as literal.

=head2 css_pair( )

    my ($begin_css, $end_css) = $self->css_pair('content');

This method returns two CSS sequences, the begining and the ending, using the
parameter received as the class name. 

=head2 match_css( )

    if ($self->match_css( 'title', $my_html_text)) {
        # the text contains the CSS sequences on title class.
        1;
    }

This method looks for an expression CSS within a text. 

=head2 regex_match_css( )

    if ($text =~ $self->regex_match_css( 'title' )) {
        1;
    }

This method build a regular expression for matches a CSS opening and closing expression.

=head1 DIAGNOSTICS

This module don't raise any exception.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to the author.
Patches are welcome.

=head1 AUTHOR

Víctor Moral <victor@taquiones.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 "Víctor Moral" <victor@taquiones.net>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.


You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 US

