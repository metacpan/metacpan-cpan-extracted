# -------------------------------------------------------------------------------------
# MKDoc::XML::Tagger
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This module adds markup to an existing XML file / variable by matching expression.
# You could see it as an XML-compatible search and substitute module.
#
# The main reason it exists is to automagically hyperlink HTML in MKDoc, and also to
# mark up properly abbreviations based on glossaries.
#
# This module is distributed under the same license as Perl itself.
# -------------------------------------------------------------------------------------
package MKDoc::XML::Tagger;
use MKDoc::XML::Tokenizer;
use strict;
use warnings;
use utf8;

our $tags = [];
our $Ignorable_RE = qr /(?:\r|\n|\s|(?:\&\(\d+\)))*/;

our @DONT_TAG = qw/a/;

##
# $class->process_data ($xml, @expressions);
# ------------------------------------------
# Tags $xml with @expressions, where expression is a list of hashes.
#
# For example:
#
# MKDoc::XML::Tagger->process (
#     'I like oranges and bananas',
#     { _expr => 'oranges', _tag => 'a', href => 'http://www.google.com?q=oranges' },
#     { _expr => 'bananas', _tag => 'a', href => 'http://www.google.com?q=bananas' },
#
# Will return
#
# 'I like <a href="http://www.google.com?q=oranges">oranges</a> and \
# <a href="http://www.google.com?q=bananas">bananas</a>.
##
sub process_data
{
    my $class  = shift;
    my $tokens = MKDoc::XML::Tokenizer->process_data (shift);
    return _replace ($tokens, @_);
}


##
# $class->process_file ($file, @expressions);
# -------------------------------------------
# Same as $class->process_data ($data, @expressions), except that $data is read
# from $file.
##
sub process_file
{
    my $class  = shift;
    my $tokens = MKDoc::XML::Tokenizer->process_file (shift);
    return _replace ($tokens, @_);
}


##
# _replace ($tokens, @expressions);
# ---------------------------------
# This function constructs the newly marked up text from a list
# of XML $tokens and a list of @expressions and returns it.
#
# Longest expressions are applied first.
##
sub _replace
{
    my $tokens = shift;
    my @expr   = sort { length ($b->{_expr}) <=> length ($a->{_expr}) } @_;
    
    @expr = map {
	my $hash = \%{$_};
	for (keys %{$hash}) {
	    $hash->{$_} =~ s/\&/\&amp;/g;
	    $hash->{$_} =~ s/\</\&lt;/g;
	    $hash->{$_} =~ s/\>/\&gt;/g;
	    $hash->{$_} =~ s/\"/\&quot;/g;
	};
	$hash;
    } @expr;
    
    my $text; local $tags;
    ($text, $tags) = _segregate_markup_from_text ($tokens);
    
    # once we have segregated markup from the text, we can safely
    # encode < and > and "...
    # $text =~ s/\&/\&amp;/g; # seems to be already encoded... where do we encode this stuff !?!
    $text =~ s/\</\&lt;/g;
    $text =~ s/\>/\&gt;/g;
    $text =~ s/\"/\&quot;/g;
    
    # but we don't want any &apos;
    $text =~ s/\&apos;/\'/g;
    
    # @expr = _filter_out ($text, @expr);
    while (my $attr = shift (@expr))
    {
	my %attr = %{$attr};
        my $tag  = delete $attr{_tag}  || next;
        my $expr = delete $attr{_expr} || next;
        $text = _text_replace ($text, $expr, $tag, \%attr);
    }
    
    while ($text =~ /\&\(\d+\)/)
    {
    for (my $i = 0; $i < @{$tags}; $i++)
    {
        my $c   = $i + 1;
        my $tag = $tags->[$i];
        $text =~ s/\&\($c\)/$tag/g;
    }
    }
    
    return $text;
}


##
# _text_replace ($text, $expr, $tag, $attr);
# ------------------------------------------
# Replaces all $text, $expr, $tag, $attr.
##
sub _text_replace
{
    my $text  = shift;
    my $expr  = shift;
    my $tag   = shift;
    my $attr  = shift;
    
    my $re    = _expression_to_regex ($expr);
    my $tag1  = _tag_open ($tag, $attr);
    my $tag2  = _tag_close ($tag, $attr);

    # let's treat beginning and end of string as spaces,
    # it makes the regular expressions much easier.
    $text = " $text ";

    my %expr  = map { $_ => 1 } $text =~
    /(?<=\p{IsSpace}|\p{IsPunct}|\&)($re)(?=\p{IsSpace}|\p{IsPunct}|\&)/gi;

    foreach (keys %expr)
    {
        my $to_replace  = quotemeta ($_);
        my $replacement = $_;
        $replacement =~ s/(\&\(\d+\))/$tag2$1$tag1/g;
        $replacement = "$tag1$replacement$tag2";
	
	# Double hyperlinking fix
	# JM - 2004-01-23
	push @{$tags}, $replacement;
	my $rep = '&(' . @{$tags} . ')';
        $text =~ s/(?<=\p{IsSpace}|\p{IsPunct}|\&)$to_replace(?=\p{IsSpace}|\p{IsPunct}|\&)/$rep/g;
        # matching placeholders fix Bruno 2005-03-10
        my $rep_quoted = quotemeta ($rep);
        $text =~ s/&\($rep_quoted\)/&($to_replace)/g;
    }
   
    # remove the first and last space which we previously inserted for
    # ease-of-regex purposes.
    $text =~ s/^ //;
    $text =~ s/ $//; 
    return $text;
}


##
# _segregate_markup_from_text ($tokens);
# --------------------------------------
# From an array reference of tokens, returns text with
# placeholders for markup, followed by an array reference
# of markup tokens.
#
# Example:
#
#   [ '<span>', 'Hello ', '<br />', 'World', '</span>' ]
# 
# becomes
# 
#   ( '&(1)Hello &(2)World&(3)', [ '<span>', '<br />', '</span>' ] )
##
sub _segregate_markup_from_text
{
    my $tokens = shift;
    my @tags   = ();
    my $res    = '';
    
    for (@{$tokens})
    {
	$_ = $$_; # replace the token object by its value
        /^</ and do {
            push @tags, $_;
            $res .= '&(' . @tags . ')';
            next;
        };
        $res .= $_;
    }
    
    return $res, \@tags;
}


##
# _expression_to_regex ($expr);
# -----------------------------
# Turns $expr into a regular expression that will match
# all segregated text which should match this expression.
##
sub _expression_to_regex
{
    my $text  = shift;
    $text     = lc ($text);
    $text     =~ s/^(?:\s|\r|\n)+//;
    $text     =~ s/(?:\s|\r|\n)+$//;
    
    my @split = split /(?:\s|\r|\n)+/, $text;
    $text     = join $Ignorable_RE, map { quotemeta ($_) } @split;
    
    return $text;
}


##
# _tag_open ($tag_name, $tag_attributes);
# ---------------------------------------
# Turns a structure representing an opening tag into
# a string representing an opening tag.
##
sub _tag_open
{
    my $tag  = shift;
    my $attr = shift;

    my $attr_str = join ' ', map { $_ . '=' . do {
        my $val = $attr->{$_};
        "\"$val\"";
    } } keys %{$attr};

    return $attr_str ? "<$tag $attr_str>" : "<$tag>";
}


##
# _tag_close ($tag_name);
# -----------------------
# Turns a structure representing an closing tag into
# a string representing a closing tag.
##
sub _tag_close
{
    my $tag  = shift;
    return "</$tag>";
}


1;


__END__


=head1 NAME

MKDoc::XML::Tagger - Adds XML markup to XML / XHTML content.


=head1 SYNOPSIS

  use MKDoc::XML::Tagger;
  print MKDoc::XML::Tagger->process_data (
      "<p>Hello, World!</p>",
      { _expr => 'World', _tag => 'strong', class => 'superFort' }
  );

Should print:

  <p>Hello, <strong class="superFort">World</strong>!</p>


=head1 SUMMARY

MKDoc::XML::Tagger is a class which lets you specify a set of tag and attributes associated
with expressions which you want to mark up. This module will then stuff any XML you send out
with the extra expressions.

For example, let's say that you have a document which has the term 'Microsoft Windows' several
times in it. You could wish to surround any instance of the term with a <trademark> tag.
MKDoc::XML::Tagger lets you do exactly that.

In MKDoc, this is used so that editors can enter hyperlinks separately from the content.
It allows them to enter content without having to worry about the annoying <a href="...">
syntax. It also has the added benefit from preventing bad information architecture such as
the 'click here' syndrome.

We also have plans to use it for automatically linking glossary words, abbreviation tags,
etc.

MKDoc::XML::Tagger is also probably a very good tool if you are building some kind of Wiki
system in which you want expressions to be automagically hyperlinked.


=head1 DISCLAIMER

B<This module does low level XML manipulation. It will somehow parse even broken XML
and try to do something with it. Do not use it unless you know what you're doing.>


=head1 API

The API is very simple.


=head2 my $result = MKDoc::XML::Tagger->process_data ($xml, @expressions);

Tags $xml with the @expressions list.

Each element of @expressions is a hash reference looking like this:

  {
      _expr      => 'Some Expression',
      _tag       => 'foo',
      attribute1 => 'bar'
      attribute2 => 'baz'
  }

Which will try to turn anything which looks like:

  Some Expression
  sOmE ExPrEssIoN
  (etcetera)

Into:

  <foo attr1="bar" attr2="baz">Some Expression</foo>
  <foo attr1="bar" attr2="baz">sOmE ExPrEssIoN</foo>
  <foo attr1="bar" attr2="baz">(etcetera)</foo>

You can have multiple expressions, in which case longest expressions
are processed first.


=head2 my $result = MKDoc::XML::Tagger->process_file ('some/file.xml', @expressions);

Same as process_data(), except it takes its data from 'some/file.xml'.


=head1 NOTES

L<MKDoc::XML::Tagger> does not really parse the XML file you're giving to it
nor does it care if the XML is well-formed or not. It uses L<MKDoc::XML::Tokenizer>
to turn the XML / XHTML file into a series of L<MKDoc::XML::Token> objects
and strictly operates on a list of tokens.

For this same reason MKDoc::XML::Tagger does not support namespaces.


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

L<MKDoc::XML::Tokenizer>
L<MKDoc::XML::Token>


=cut
