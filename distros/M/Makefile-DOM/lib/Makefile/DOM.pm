package Makefile::DOM;

use strict;
use warnings;

our $VERSION = '0.008';

use MDOM::Document;
use MDOM::Element;
use MDOM::Node;
use MDOM::Rule;
use MDOM::Token;
use MDOM::Command;
use MDOM::Assignment;
use MDOM::Unknown;
use MDOM::Directive;

1;
__END__

=encoding utf-8

=head1 NAME

Makefile::DOM - Simple DOM parser for Makefiles

=head1 VERSION

This document describes Makefile::DOM 0.008 released on 18 November 2014.

=head1 DESCRIPTION

This libary can serve as an advanced lexer for (GNU) makefiles. It parses makefiles as "documents" and the parsing is lossless. The results are data structures similar to DOM trees. The DOM trees hold every single bit of the information in the original input files, including white spaces, blank lines and makefile comments. That means it's possible to reproduce the original makefiles from the DOM trees. In addition, each node of the DOM trees is modifiable and so is the whole tree, just like the L<PPI> module used for Perl source parsing and the L<HTML::TreeBuilder> module used for parsing HTML source.

If you're looking for a true GNU make parser that generates an AST, please see L<Makefile::Parser::GmakeDB> instead.

The interface of C<Makefile::DOM> mimics the API design of L<PPI>. In fact, I've directly stolen the source code and POD documentation of L<PPI::Node>, L<PPI::Element>, and L<PPI::Dumper>, with the full permission from the author of L<PPI>, Adam Kennedy.

C<Makefile::DOM> tries to be independent of specific makefile's syntax. The same set of DOM node types is supposed to get shared by different makefile DOM generators. For example, L<MDOM::Document::Gmake> parses GNU makefiles and returns an instance of L<MDOM::Document>, i.e., the root of the DOM tree while the NMAKE makefile lexer in the future, C<MDOM::Document::Nmake>, also returns instances of the L<MDOM::Document> class. Later, I'll also consider adding support for dmake and bsdmake.

=head1 Structure of the DOM

Makefile DOM (MDOM) is a structured set of a series of data types. They provide a flexible document model conformed to the makefile syntax. Below is a complete list of the 19 MDOM classes in the current implementation where the indentation indicates the class inheritance relationships.

    MDOM::Element
        MDOM::Node
            MDOM::Unknown
            MDOM::Assignment
            MDOM::Command
            MDOM::Directive
            MDOM::Document
                MDOM::Document::Gmake
            MDOM::Rule
                MDOM::Rule::Simple
                MDOM::Rule::StaticPattern
        MDOM::Token
            MDOM::Token::Bare
            MDOM::Token::Comment
            MDOM::Token::Continuation
            MDOM::Token::Interpolation
            MDOM::Token::Modifier
            MDOM::Token::Separator
            MDOM::Token::Whitespace

It's not hard to see that all of the MDOM classes inherit from the L<MDOM::Element> class. L<MDOM::Token> and L<MDOM::Node> are its direct children. The former represents a string token which is atomic from the perspective of the lexer while the latter represents a structured node, which usually has one or more children, and serves as the container for other L<DOM::Element> objects.

Next we'll show a few examples to demonstrate how to map DOM trees to particular makefiles.

=over

=item Case 1

Consider the following simple "hello, world" makefile:

    all : ; echo "hello, world"

We can use the L<MDOM::Dumper> class provided by L<Makefile::DOM> to dump out the internal structure of its corresponding MDOM tree:

    MDOM::Document::Gmake
      MDOM::Rule::Simple
        MDOM::Token::Bare         'all'
        MDOM::Token::Whitespace   ' '
        MDOM::Token::Separator    ':'
        MDOM::Token::Whitespace   ' '
        MDOM::Command
          MDOM::Token::Separator    ';'
          MDOM::Token::Whitespace   ' '
          MDOM::Token::Bare         'echo "hello, world"'
          MDOM::Token::Whitespace   '\n'

In this example, speparators C<:> and C<;> are all instances of the L<MDOM::Token::Separator> class while spaces and new line characters are all represented as L<MDOM::Token::Whitespace>. The other two leaf nodes, C<all> and C<echo "hello, world"> both belong to L<MDOM::Token::Bare>.

It's worth mentioning that, the space characters in the rule command C<echo "hello, world"> were not represented as L<MDOM::Token::Whitespace>. That's because in makefiles, the spaces in commands do not make any sense to C<make> in syntax; those spaces are usually sent to shell programs verbatim. Therefore, the DOM parser does not try to recognize those spaces specifially so as to reduce memory use and the number of nodes. However, leading spaces and trailing new lines will still be recognized as L<MDOM::Token::Whitespace>.

On a higher level, it's a L<MDOM::Rule::Simple> instance holding several C<Token> and one L<MDOM::Command>. On the highest level, it's the root node of the whole DOM tree, i.e., an instance of L<MDOM::Document::Gmake>.

=item Case 2

Below is a relatively complex example:

    a: foo.c  bar.h $(baz) # hello!
        @echo ...

It's corresponding DOM structure is

  MDOM::Document::Gmake
    MDOM::Rule::Simple
      MDOM::Token::Bare         'a'
      MDOM::Token::Separator    ':'
      MDOM::Token::Whitespace   ' '
      MDOM::Token::Bare         'foo.c'
      MDOM::Token::Whitespace   '  '
      MDOM::Token::Bare         'bar.h'
      MDOM::Token::Whitespace   '\t'
      MDOM::Token::Interpolation   '$(baz)'
      MDOM::Token::Whitespace      ' '
      MDOM::Token::Comment         '# hello!'
      MDOM::Token::Whitespace      '\n'
    MDOM::Command
      MDOM::Token::Separator    '\t'
      MDOM::Token::Modifier     '@'
      MDOM::Token::Bare         'echo ...'
      MDOM::Token::Whitespace   '\n'

Compared to the previous example, here appears several new node types.

The variable interpolation C<$(baz)> on the first line of the original makefile corresponds to a L<MDOM::Token::Interpolation> node in its MDOM tree. Similarly, the comment C<# hello> corresponds to a L<MDOM::Token::Comment> node.

On the second line, the rule command indented by a tab character is still represented by a L<MDOM::Command> object. Its first child node (or its first element) is also an L<MDOM::Token::Seperator> instance corresponding to that tab. The command modifier C<@> follows the C<Separator> immediately, which is of type L<MDOM::Token::Modifier>.

=item Case 3

Now let's study a sample makefile with various global structures:

  a: b
  foo = bar
      # hello!

Here on the top level, there are three language structures: one rule "C<a: b>", one assignment statement "foo = bar", and one comment C<# hello!>.

Its MDOM tree is shown below:

  MDOM::Document::Gmake
    MDOM::Rule::Simple
      MDOM::Token::Bare                  'a'
      MDOM::Token::Separator            ':'
      MDOM::Token::Whitespace           ' '
      MDOM::Token::Bare                   'b'
      MDOM::Token::Whitespace           '\n'
    MDOM::Assignment
      MDOM::Token::Bare                  'foo'
      MDOM::Token::Whitespace           ' '
      MDOM::Token::Separator            '='
      MDOM::Token::Whitespace           ' '
      MDOM::Token::Bare                  'bar'
      MDOM::Token::Whitespace           '\n'
    MDOM::Token::Whitespace            '\t'
    MDOM::Token::Comment               '# hello!'
    MDOM::Token::Whitespace            '\n'

We can see that below the root node L<MDOM::Document::Gmake>, there are L<MDOM::Rule::Simple>, L<MDOM::Assignment>, and L<MDOM::Comment> three elements, as well as two L<MDOM::Token::Whitespace> objects.

=back

It can be observed from the examples above that the MDOM representation for the makefile's lexical elements is rather loose. It only provides very limited structural representation instead of making a bad guess.

=head1 OPERATIONS FOR MDOM TREES

Generating an MDOM tree from a GNU makefile only requires two lines of Perl code:

    use MDOM::Document::Gmake;
    my $dom = MDOM::Document::Gmake->new('Makefile');

If the makefile source code being parsed is already stored in a Perl variable, say, C<$var>, then we can construct an MDOM via the following code:

    my $dom = MDOM::Document::Gmake->new(\$var);

Now C<$dom> becomes the reference to the root of the MDOM tree and its type is now L<MDOM::Document::Gmake>, which is also an instance of the L<MDOM::Node> class.

Just as mentioned above, C<MDOM::Node> is the container for other L<MDOM::Element> instances. So we can retrieve some element node's value via its C<child> method:

    $node = $dom->child(3);
    # or $node = $dom->elements(0);

And we may also use the C<elements> method to obtain the values of all the nodes:

    @elems = $dom->elements;

For every MDOM node, its corresponding makefile source can be generated by invoking its C<content> method.

=head1 BUGS AND TODO

The current implementation of the L<MDOM::Document::Gmake> lexer is
based on a hand-written state machie. Although the efficiency of the
engine is not bad, the code is rather complicated and messy, which
hurts both extensibility and maintanabilty. So it's expected to
rewrite the parser using some grammatical tools like the Perl 6 regex
engine L<Pugs::Compiler::Rule> or a yacc-style one like
L<Parse::Yapp>.

=head1 SOURCE REPOSITORY

You can always get the latest source code of this module from its GitHub repository:

L<http://github.com/agentzh/makefile-dom-pm>

If you want a commit bit, please let me know.

=head1 AUTHOR

Yichun "agentzh" Zhang (章亦春) E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2006-2014 by Yichun "agentzh" Zhang (章亦春).

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<MDOM::Document>, L<MDOM::Document::Gmake>, L<PPI>, L<Makefile::Parser::GmakeDB>, L<makesimple>.

