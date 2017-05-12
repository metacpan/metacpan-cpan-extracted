# -------------------------------------------------------------------------------------
# MKDoc::XML::TreeBuilder
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This module turns an XML string into a tree of elements and returns the top elements.
# This assumes that the XML string is well-formed. Well. More or less :)
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::TreeBuilder;
use MKDoc::XML::Tokenizer;
use strict;
use warnings;


##
# $class->process_data ($xml);
# ----------------------------
# Parses $xml and turns it into a tree structure very similar
# to HTML::Element objects.
##
sub process_data
{
    my $class  = shift;
    my $tokens = MKDoc::XML::Tokenizer->process_data (@_);
    return _process_recurse ($tokens);
}


##
# $class->process_file ($filename);
# ---------------------------------
# Parses $xml and turns it into a tree structure very similar
# to HTML::Element objects.
##
sub process_file
{
    my $class  = shift;
    my $tokens = MKDoc::XML::Tokenizer->process_file (@_);
    return _process_recurse ($tokens);
}


##
# _process_recurse ($token_list);
# -------------------------------
# Turns $token_list array ref into a tree structure.
##
sub _process_recurse
{
    my $tokens = shift;
    my @result = ();
    
    while (@{$tokens})
    {
	# takes the first available token from the $tokens array reference
        my $token = shift @{$tokens};
	my $node  = undef;
	
	$node = $token->leaf();
	defined $node and do {
	    push @result, $node;
	    next;
	};
	
	$node = $token->tag_open();
	defined $node and do {
	    my $descendants   = _descendant_tokens ($token, $tokens);
	    $node->{_content} = _process_recurse ($descendants);
	    push @result, $node;
	    next;
	};

        my $token_as_string = $token->as_string();	
	die qq |parse_error: Is this XML well-formed? (unexpected closing tag "$token_as_string")|;
    }
    
    return wantarray ? @result : \@result;
}


##
# $class->descendant_tokens ($token, $tokens);
# --------------------------------------------
# Removes all tokens from $tokens which are descendants
# of $token - assuming that $token is an opening tag token.
#
# Returns all the tokens removed except for $token matching
# closing tag. So the closing tag is removed from $tokens
# but not returned.
##
sub _descendant_tokens
{
    my $token   = shift;
    my $tokens  = shift;
    my @res     = ();
    my $balance = 1;
    while (@{$tokens})
    {
	my $next_token = shift (@{$tokens});
	my $node       = undef;
	
	$node = $next_token->leaf();
	defined $node and do {
	    push @res, $next_token;
	    next;
	};
	
	$node = $next_token->tag_open();
	defined $node and do {
	    $balance++;
	    push @res, $next_token;
	    next;
	};
	
	$node = $next_token->tag_close();
	defined $node and do {
	    $balance--;
	    last if ($balance == 0);
	    push @res, $next_token;
	    next;
	};
	
	die "BUG: The program should never reach this statement.";
    }
    
    return \@res if ($balance == 0);
    my $token_as_string = $token->as_string();
    die qq |parse_error: Is this XML well-formed? (could not find closing tag for "$token_as_string")|;
}


1;


__END__


=head1 NAME

MKDoc::XML::TreeBuilder - Builds a parsed tree from XML data


=head1 SYNOPSIS

  my @top_nodes = MKDoc::XML::TreeBuilder->process_data ($some_xml);


=head1 SUMMARY

L<MKDoc::XML::TreeBuilder> uses L<MKDoc::XML::Tokenizer> to turn XML data
into a parsed tree. Basically it smells like an XML parser, looks like an
XML parser, and awfully overlaps with XML parsers.

But it's not an XML parser.

XML parsers are required to die if the XML data is not well formed.
MKDoc::XML::TreeBuilder doesn't give a rip: it'll parse whatever as long
as it's good enough for it to parse.

XML parsers expand entities. MKDoc::XML::TreeBuilder doesn't.
At least not yet.

XML parsers generally support namespaces. MKDoc::XML::TreeBuilder doesn't -
and probably won't.


=head1 DISCLAIMER

B<This module does low level XML manipulation. It will somehow parse even broken XML
and try to do something with it. Do not use it unless you know what you're doing.>


=head1 API

=head2 my @top_nodes = MKDoc::XML::Tokenizer->process_data ($some_xml);

Returns all the top nodes of the $some_xml parsed tree.

Although the XML spec says that there can be only one top element in an XML
file, you have to take two things into account:

1. Pseudo-elements such as XML declarations, processing instructions, and
comments.

2. MKDoc::XML::TreeBuilder is not an XML parser, it's not its job to care
about the XML specification, so having multiple top elements is just fine.


=head2 my $tokens = MKDoc::XML::Tokenizer->process_data ('/some/file.xml');

Same as MKDoc::XML::TreeBuilder->process_data ($some_xml), except that it
reads $some_xml from '/some/file.xml'.


=head1 Returned parsed tree - data structure

I have tried to make MKDoc::XML::TreeBuilder look enormously like HTML::TreeBuilder.
So most of this section is stolen and slightly adapted from the HTML::Element
man page.


START PLAGIARISM HERE

It may occur to you to wonder what exactly a "tree" is, and how
it's represented in memory.  Consider this HTML document:

  <html lang='en-US'>
    <head>
      <title>Stuff</title>
      <meta name='author' content='Jojo' />
    </head>
    <body>
     <h1>I like potatoes!</h1>
    </body>
  </html>

Building a syntax tree out of it makes a tree-structure in memory
that could be diagrammed as:

                     html (lang='en-US')
                      / \
                    /     \
                  /         \
                head        body
               /\               \
             /    \               \
           /        \               \
         title     meta              h1
          |       (name='author',     |
       "Stuff"    content='Jojo')    "I like potatoes"

This is the traditional way to diagram a tree, with the "root" at the
top, and it's this kind of diagram that people have in mind when they
say, for example, that "the meta element is under the head element
instead of under the body element".  (The same is also said with
"inside" instead of "under" -- the use of "inside" makes more sense
when you're looking at the HTML source.)

Another way to represent the above tree is with indenting:

  html (attributes: lang='en-US')
    head
      title
        "Stuff"
      meta (attributes: name='author' content='Jojo')
    body
      h1
        "I like potatoes"

Incidentally, diagramming with indenting works much better for very
large trees, and is easier for a program to generate.  The $tree->dump
method uses indentation just that way.

However you diagram the tree, it's stored the same in memory -- it's a
network of objects, each of which has attributes like so:

  element #1:  _tag: 'html'
               _parent: none
               _content: [element #2, element #5]
               lang: 'en-US'

  element #2:  _tag: 'head'
               _parent: element #1
               _content: [element #3, element #4]

  element #3:  _tag: 'title'
               _parent: element #2
               _content: [text segment "Stuff"]

  element #4   _tag: 'meta'
               _parent: element #2
               _content: none
               name: author
               content: Jojo

  element #5   _tag: 'body'
               _parent: element #1
               _content: [element #6]

  element #6   _tag: 'h1'
               _parent: element #5
               _content: [text segment "I like potatoes"]

The "treeness" of the tree-structure that these elements comprise is
not an aspect of any particular object, but is emergent from the
relatedness attributes (_parent and _content) of these element-objects
and from how you use them to get from element to element.

STOP PLAGIARISM HERE


This is pretty much the kind of data structure MKDoc::XML::TreeBuilder
returns. More information on different nodes and their type is available
in L<MKDoc::XML::Token>.


=head1 NOTES

Did I mention that MKDoc::XML::TreeBuilder is NOT an XML parser?


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::Token>
L<MKDoc::XML::Tokenizer>

=cut
