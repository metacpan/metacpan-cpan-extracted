=head1 NAME

MKDoc::Text::Structured - Another Text to HTML module


=head1 SYNOPSIS

    my $text = some_structured_text();
    my $html = MKDoc::Text::Structured::process ($text);


=head1 SUMMARY

L<MKDoc::Text::Structured> is a library which allows simple syntaxic 
text construct to be turned into HTML. These constructs are the ones
you would be using when writing a text email or newsgroup message.

L<MKDoc::Text::Structured> follows the KISS philosophy. Comparing with
similar modules which try to implement as many HTML constructs as possible,
this module is incredibly conservative.

=cut
package MKDoc::Text::Structured;
use MKDoc::Text::Structured::Factory;
use strict;
use warnings;

our $Text    = '';
our $VERSION = 0.83;


sub process
{
    my $text    = shift;

    # Mac + DOS carriage returns -> bang!
    $text =~ s/\r\n/\n/gs;
    $text =~ s/\r/\n/gs;

    # Trailing spaces -> fizzle!
    # (except when the line is made only of trailing spaces...)
    $text = join "\n", map {
        chomp();
        s/\s+$// unless (/^\s*$/);
        $_;
    } split /\n/, $text;

    my @lines   = split /\n/, $text;
    my @result  = ();
    my $current = undef;

    while (scalar @lines)
    {
        my $line   = shift (@lines);
        $current ||= MKDoc::Text::Structured::Factory->new ($line);
        $current || next;

        if ($current->is_ok ($line))
        {
            $current->add_line ($line);
        }
        else
        {
            push @result, $current->process();
            unshift (@lines, $line);
            $current = undef;
        }
    }

    push @result, $current->process() if ($current);
    return join "\n", @result;
}


1;


__END__


=head1 Block level elements


=head2 P

Paragraphs are defined by blocks of text separated by one or more empty
lines.

The text:

  This is a paragraph,
  until it meets an empty line.
  
  This is another paragraph.

Would become:

  <p>This is a paragraph,
  until it meets an empty line.</p>
  <p>This is another paragraph.</p>


=head2 H1, H2, H3

Headlines are really just like a paragraph, except that they have
the following syntax:

The text:

  ==========
  Headline 1
  ==========
  
  Headline 2
  ==========
  
  Headline 3
  ----------

Would become:

  <h1>Headline 1</h1>
  <h2>Headline 2</h2>
  <h3>Headline 3</h3>


The advantage in treating headlines just like paragraph is that multi-line
headlines are no problem. Also, it means you can use *strong* and _emphasized_
within a headline (see STRONG and EM sections).


=head2 PRE 

Pre-formatted text looks like a paragraph, except that it must be indented
with at least one space character.

The text:

  This is a paragraph,
  until it meets an empty line.
  
    But this is pre-formatted text.
    Hey  Hey Ho  Ho!

  This is another paragraph.

Would become:

  <p>This is a paragraph,
  until it meets an empty line.</p>
  <pre>But this is pre-formatted text.
  Hey  Hey Ho  Ho!</pre>
  <p>This is another paragraph.</p>

Again, you can use *strong* and _emphasized_ within pre-formatted text (see
STRONG and EM sections).


=head1 Inline Elements

=head2 STRONG 

The text:

  This is *strong text*

Would become:

  <p>This is <strong>strong text</strong></p>


Note 1: The star character will act as a 'strong' marker only when:

- The "opening" star is preceded by whitespace or carriage return,

- The "closing" star is followed by whitespace or carriage return,
or punctuation immediately followed by whitespace or carriage return.

In other words, you can write 3*3*2 = 18 safely. The module tries to follow the
DWIM ("Do What I Mean") philosophy as much as possible.

Note 2: This can only work within one block level element.  It will not work
across paragraphs or lists (See UL, LI and OL, LI sections).

Example 1:

  * Hello, *I will not
  * be bold*
  * but
  * *I will be*

Example 2:

  This is a paragraph. *Nothing in this paragraph
  is going to be bold.

  Nor in this one*.


=head2 EM

The text:

  This is _emphasized text_

Would become:

  <p>This is <em>emphasized text</em></p>

Same notes as for bold / strong text also applied for emphasized text.

=head2 Entity substitution

Characters that would otherwise be interpreted as XML are encoded. i.e. &, <
and > become &amp; &lt; and &gt;

Additionally some standard typed versions of special characters are
substituted with a richer and better-looking HTML entity:

  --   surrounded by whitespace becomes &mdash;
  -    surrounded by whitespace becomes &ndash;
  ...  becomes &hellip;
  (tm) becomes &trade;
  (r)  becomes &reg;
  (c)  becomes &copy;
  x    between numbers becomes &times;
  ''   surrounding text becomes &lsquo; &rsquo;
  ""   surrounding text becomes &ldquo; &rdquo;

=head1 Nested Structures

=head2 BLOCKQUOTE 

Quoted text is text that starts with a 'greater than' character
and followed by a space on each line.

  > > Hey, that's pretty cool!

  > Well, sort-of

  I think it's pretty cool...

Would become:

  <blockquote><blockquote><p>Hey, that's pretty cool!</p></blockquote>
  <p>Well, sort-of</p></blockquote>
  <p>I think it's pretty cool...</p>


=head2 UL, LI

Ordered lists and unordered lists can be constructed and nested:

The text:

  * An item
  * Another item

  * Headlines work too
    ==================

    I can write *paragraphs within lists*.

      And even _pre-formatted text_!

    - Also, I can have sub-lists
    - That's no problem
    - Notice that '*' and '-' have the same meaning.
      It's just syntaxic sugar, really :-)

Would become:

  <ul><li><p>An item</p></li>
  <li><p>Another item</p></li>
  <li><h2>Headlines work too</h2>
  <p>I can write <strong>paragraphs within lists</strong>.</p>
  <pre>And even <em>pre-formatted text</em>!</pre>
  <ul><li><p>Also, I can have sub-lists</p></li>
  <li><p>That's no problem</p></li>
  <li><p>Notice that '*' and '-' have the same meaning.
  It's just syntaxic sugar, really :-)</p></li></ul></li></ul>


=head2 OL, LI

Un-ordered lists and unordered lists can be constructed and nested:

The text:

  1. An item
  2. Another item

  3. Headlines work too
     ==================

     * An un-ordered list
     * Can be nested
     * It should all work nicely.

Would become:

  <ol><li><p>An item</p></li>
  <li><p>Another item</p></li>
  <li><h2>Headlines work too</h2>
  <ul><li><p>An un-ordered list</p></li>
  <li><p>Can be nested</p></li>
  <li><p>It should all work nicely.</p></li></ul></li></ol>


=head1 Hyperlinks

This module uses L<URI::Find> to locate URIs such as http://mkdoc.com/ and turn
them into clickable links.

Add rel="nofollow" attributes to <a> tags like so:

  local $MKDoc::Text::Structured::Inline::NoFollow = 1;

Additionally, once the XHTML fragment is produced, you could use
L<MKDoc::XML::Tagger> to hyperlink it against a glossary of hyperlinks.

=head1 Smilies

Basic smilies such as :-) and :-( are wrapped in a CSS class:

  <span class="smiley-happy">:-)</span>
  <span class="smiley-sad">:-(</span>

=head1 Long Words

Long words are split up into fragments separated by spaces if the length
exceeds a 78 character default.

Change the default length using a package variable:

  local $MKDoc::Text::Structured::Inline::LongestWord = 12;

Disable this fuctionality by setting a value of 0.

=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk

=cut
