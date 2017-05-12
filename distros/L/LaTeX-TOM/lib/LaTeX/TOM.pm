###############################################################################
#
# LaTeX::TOM (TeX Object Model)
#
# Version 1.03
#
# ----------------------------------------------------------------------------
#
# originally written by Aaron Krowne (akrowne@vt.edu)
# July 2002
#
# Virginia Polytechnic Institute and State University
# Department of Computer Science
# Digital Libraries Research Laboratory
#
# now maintained by Steven Schubiger (schubiger@cpan.org)
# April 2008
#
# ----------------------------------------------------------------------------
#
# This module provides some decent semantic handling of LaTeX documents. It is
# inspired by XML::DOM, so users of that module should be able to acclimate
# themselves to this one quickly.  Basically the subroutines in this package
# allow you to parse a LaTeX document into its logical structure, including
# groupings, commands, environments, and comments.  These all go into a tree
# which is built as arrays of Perl hashes.
#
###############################################################################

package LaTeX::TOM;

use strict;
use base qw(LaTeX::TOM::Parser);
use constant true => 1;

our $VERSION = '1.03';

our (%INNERCMDS, %MATHENVS, %MATHBRACKETS,
     %BRACELESS, %TEXTENVS, $PARSE_ERRORS_FATAL,
     $DEBUG);

# BEGIN CONFIG SECTION ########################################################

# these are commands that can be "embedded" within a grouping to alter the
# environment of that grouping. For instance {\bf text}.  Without listing the 
# command names here, the parser will treat such sequences as plain text.
#
%INNERCMDS = map { $_ => true } (
 'bf',
 'md',
 'em',
 'up',
 'sl',
 'sc',
 'sf',
 'rm',
 'it',
 'tt',
 'noindent',
 'mathtt',
 'mathbf',
 'tiny',
 'scriptsize',
 'footnotesize',
 'small',
 'normalsize',
 'large',
 'Large',
 'LARGE',
 'huge',
 'Huge',
 'HUGE',
 );

# these commands put their environments into math mode
#
%MATHENVS = map { $_ => true } (
 'align',
 'equation',
 'eqnarray',
 'displaymath',
 'ensuremath',
 'math',
 '$$',
 '$',
 '\[',
 '\(',
 );

# these commands/environments put their children in text (non-math) mode
#
%TEXTENVS = map { $_ => true } (
 'tiny',
 'scriptsize',
 'footnotesize',
 'small',
 'normalsize',
 'large',
 'Large',
 'LARGE',
 'huge',
 'Huge',
 'HUGE',
 'text',
 'textbf',
 'textmd',
 'textsc',
 'textsf',
 'textrm',
 'textsl',
 'textup',
 'texttt',
 'mbox',
 'fbox',
 'section',
 'subsection',
 'subsubsection',
 'em',
 'bf',
 'emph',
 'it',
 'enumerate',
 'description',
 'itemize',
 'trivlist',
 'list',
 'proof',
 'theorem',
 'lemma',
 'thm',
 'prop',
 'lem',
 'table',
 'tabular',
 'tabbing',
 'caption',
 'footnote',
 'center',
 'flushright',
 'document',
 'article',
 'titlepage',
 'title',
 'author',
 'titlerunninghead',
 'authorrunninghead',
 'affil',
 'email',
 'abstract',
 'thanks',
 'algorithm',
 'nonumalgorithm',
 'references',
 'thebibliography',
 'bibitem',
 'verbatim',
 'verbatimtab',
 'quotation',
 'quote',
 );

# these form sets of simple mode delimiters
#
%MATHBRACKETS = (
 '$$' => '$$',
 '$' => '$',
# '\[' => '\]',   # these are problematic and handled separately now
# '\(' => '\)',
 );

# these commands require no braces, and their parameters are simply the 
# "word" following the command declaration
#
%BRACELESS = map { $_ => true } (
 'oddsidemargin',
 'evensidemargin',
 'topmargin',
 'headheight',
 'headsep',
 'textwidth',
 'textheight',
 'input',
 );

# default value controlling how fatal parse errors are
#
#  0 = warn, 1 = die, 2 = silent
#
$PARSE_ERRORS_FATAL = 0;

# debugging mode (internal use)
#
#  0 = off, 1 = messages, 2 = messages and code
#
$DEBUG = 0;

# END CONFIG SECTION ##########################################################

sub new {
    my $class = shift;

    return __PACKAGE__->SUPER::new(@_);
}

1;

=head1 NAME

LaTeX::TOM - A module for parsing, analyzing, and manipulating LaTeX documents.

=head1 SYNOPSIS

 use LaTeX::TOM;

 $parser = LaTeX::TOM->new;

 $document = $parser->parseFile('mypaper.tex');

 $latex = $document->toLaTeX;

 $specialnodes = $document->getNodesByCondition(sub {
     my $node = shift;
     return (
       $node->getNodeType eq 'TEXT'
         && $node->getNodeText =~ /magic string/
     );
 });

 $sections = $document->getNodesByCondition(sub {
     my $node = shift;
     return (
       $node->getNodeType eq 'COMMAND'
         && $node->getCommandName =~ /section$/
     );
 });

 $indexme = $document->getIndexableText;

 $document->print;

=head1 DESCRIPTION

This module provides a parser which parses and interprets (though not fully)
LaTeX documents and returns a tree-based representation of what it finds.
This tree is a C<LaTeX::TOM::Tree>.  The tree contains C<LaTeX::TOM::Node> nodes.

This module should be especially useful to anyone who wants to do processing
of LaTeX documents that requires extraction of plain-text information, or
altering of the plain-text components (or alternatively, the math-text
components).

=head1 COMPONENTS

=head2 LaTeX::TOM::Parser

The parser recognizes 3 parameters upon creation.  The parameters, in order, are 

=over 4

=item parse error handling (= B<0> || 1 || 2)

Determines what happens when a parse error is encountered.  C<0> results in a
warning.  C<1> results in a die.  C<2> results in silence.  Note that particular
groupings in LaTeX (i.e. newcommands and the like) contain invalid TeX or
LaTeX, so you nearly always need this parameter to be C<0> or C<2> to completely
parse the document.

=item read inputs flag (= 0 || B<1>)

This flag determines whether a scan for C<\input> and C<\input-like> commands is
performed, and the resulting called files parsed and added to the parent
parse tree.  C<0> means no, C<1> means do it.  Note that this will happen recursively
if it is turned on.  Also, bibliographies (F<.bbl> files) are detected and
included.

=item apply mappings flag (= 0 || B<1>)

This flag determines whether (most) user-defined mappings are applied.  This
means C<\defs>, C<\newcommands>, and C<\newenvironments>.  This is critical for 
properly analyzing the content of the document, as this must be phrased in terms 
of the semantics of the original TeX and LaTeX commands, not ad hoc user macros.  
So, for instance, do not expect plain-text extraction to work properly with this
option off.

=back

The parser returns a C<LaTeX::TOM::Tree> ($document in the SYNOPSIS).

=head2 LaTeX::TOM::Node

Nodes may be of the following types:

=over 4 

=item TEXT 

C<TEXT> nodes can be thought of as representing the plain-text portions of the
LaTeX document.  This includes math and anything else that is not a recognized
TeX or LaTeX command, or user-defined command.  In reality, C<TEXT> nodes contain
commands that this parser does not yet recognize the semantics of.

=item COMMAND

A C<COMMAND> node represents a TeX command.  It always has child nodes in a tree,
though the tree might be empty if the command operates on zero parameters. An
example of a command is

 \textbf{blah}

This would parse into a C<COMMAND> node for C<textbf>, which would have a subtree
containing the C<TEXT> node with text ``blah.''

=item ENVIRONMENT

Similarly, TeX environments parse into C<ENVIRONMENT> nodes, which have metadata
about the environment, along with a subtree representing what is contained in
the environment.  For example,

 \begin{equation}
   r = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
 \end{equation}

Would parse into an C<ENVIRONMENT> node of the class ``equation'' with a child 
tree containing the result of parsing C<``r = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}.''>

=item GROUP

A C<GROUP> is like an anonymous C<COMMAND>.  Since you can put whatever you want in
curly-braces (C<{}>) in TeX in order to make semantically isolated regions, this
separation is preserved by the parser.  A C<GROUP> is just the subtree of the
parsed contents of plain curly-braces.

It is important to note that currently only the first C<GROUP> in a series of
C<GROUP>s following a LaTeX command will actually be parsed into a C<COMMAND> node.
The reason is that, for the initial purposes of this module, it was not
necessary to recognize additional C<GROUP>s as additional parameters to the
C<COMMAND>.  However, this is something that this module really should do
eventually.  Currently if you want all the parameters to a multi-parametered
command, you'll need to pick out all the following C<GROUP> nodes yourself.

Eventually this will become something like a list which is stored in the 
C<COMMAND> node, much like L<XML::DOM>'s treatment of attributes.  These are, in a
sense, apart from the rest of the document tree.  Then C<GROUP> nodes will become
much more rare.

=item COMMENT

A C<COMMENT> node is very similar to a C<TEXT> node, except it is specifically for 
lines beginning with C<``%''> (the TeX comment delimeter) or the right-hand 
portion of a line that has C<``%''> at some internal point.

=back

=head2 LaTeX::TOM::Trees

As mentioned before, the Tree is the return result of a parse.

The tree is nothing more than an arrayref of Nodes, some of which may contain
their own trees.  This is useful knowledge at this point, since the user isn't
provided with a full suite of convenient tree-modification methods.  However,
Trees do already have some very convenient methods, described in the next
section.

=head1 METHODS

=head2 LaTeX::TOM

=head3 new

=over 4

=item C<> 

Instantiate a new parser object.

=back

In this section all of the methods for each of the components are listed and
described.

=head2 LaTeX::TOM::Parser

The methods for the parser (aside from the constructor, discussed above) are :

=head3 parseFile (filename)

=over 4

=item C<>

Read in the contents of I<filename> and parse them, returning a C<LaTeX::TOM::Tree>.

=back

=head3 parse (string)

=over 4

=item C<>

Parse the string I<string> and return a C<LaTeX::TOM::Tree>.

=back

=head2 LaTeX::TOM::Tree

This section contains methods for the Trees returned by the parser.

=head3 copy

=over 4

=item C<>

Duplicate a tree into new memory.

=back

=head3 print

=over 4

=item C<>

A debug print of the structure of the tree.

=back

=head3 plainText

=over 4

=item C<>

Returns an arrayref which is a list of strings representing the text of all
C<getNodePlainTextFlag = 1> C<TEXT> nodes, in an inorder traversal.

=back

=head3 indexableText

=over 4

=item C<>

A method like the above but which goes one step further; it cleans all of the
returned text and concatenates it into a single string which one could consider
having all of the standard information retrieval value for the document,
making it useful for indexing.

=back

=head3 toLaTeX

=over 4

=item C<>

Return a string representing the LaTeX encoded by the tree.  This is especially
useful to get a normal document again, after modifying nodes of the tree.

=back

=head3 getTopLevelNodes

=over 4

=item C<>

Return a list of C<LaTeX::TOM::Nodes> at the top level of the Tree.

=back

=head3 getAllNodes

=over 4

=item C<>

Return an arrayref with B<all> nodes of the tree.  This "flattens" the tree.

=back

=head3 getCommandNodesByName (name)

=over 4

=item C<>

Return an arrayref with all C<COMMAND> nodes in the tree which have a name
matching I<name>.

=back

=head3 getEnvironmentsByName (name)

=over 4

=item C<>

Return an arrayref with all C<ENVIRONMENT> nodes in the tree which have a class
matching I<name>.

=back

=head3 getNodesByCondition (code reference)

=over 4

=item C<>

This is a catch-all search method which can be used to pull out nodes that
match pretty much any perl expression, without manually having to traverse the
tree.  I<code reference> is a perl code reference which receives as its first
argument the node of the tree that is currently scrutinized and is expected to
return a boolean value. See the SYNOPSIS for examples.

=back

=head3 getFirstNode

=over 4

=item C<>

Returns the first node of the tree.  This is useful if you want to walk the tree
yourself, starting with the first node.

=back

=head2 LaTeX::TOM::Node

This section contains the methods for nodes of the parsed Trees.

=head3 getNodeType

=over 4

=item C<>

Returns the type, one of C<TEXT>, C<COMMAND>, C<ENVIRONMENT>, C<GROUP>, or C<COMMENT>, 
as described above.

=back

=head3 getNodeText

=over 4

=item C<>

Applicable for C<TEXT> or C<COMMENT> nodes; this returns the document text they contain.  
This is undef for other node types.

=back

=head3 setNodeText

=over 4

=item C<>

Set the node text, also for C<TEXT> and C<COMMENT> nodes.

=back

=head3 getNodeStartingPosition

=over 4

=item C<>

Get the starting character position in the document of this node.  For C<TEXT>
and C<COMMENT> nodes, this will be where the text begins.  For C<ENVIRONMENT>,
C<COMMAND>, or C<GROUP> nodes, this will be the position of the I<last> character of
the opening identifier.

=back

=head3 getNodeEndingPosition

=over 4

=item C<>

Same as above, but for last character.  For C<GROUP>, C<ENVIRONMENT>, or C<COMMAND> 
nodes, this will be the I<first> character of the closing identifier.

=back

=head3 getNodeOuterStartingPosition

=over 4

=item C<>

Same as getNodeStartingPosition, but for C<GROUP>, C<ENVIRONMENT>, or C<COMMAND> nodes,
this returns the I<first> character of the opening identifier.

=back

=head3 getNodeOuterEndingPosition

=over 4

=item C<>

Same as getNodeEndingPosition, but for C<GROUP>, C<ENVIRONMENT>, or C<COMMAND> nodes,
this returns the I<last> character of the closing identifier.

=back

=head3 getNodeMathFlag

=over 4

=item C<>

This applies to any node type.  It is C<1> if the node sets, or is contained
within, a math mode region.  C<0> otherwise.  C<TEXT> nodes which have this flag as C<1>
can be assumed to be the actual mathematics contained in the document.

=back

=head3 getNodePlainTextFlag

=over 4

=item C<>

This applies only to C<TEXT> nodes.  It is C<1> if the node is non-math B<and> is
visible (in other words, will end up being a part of the output document). One
would only want to index C<TEXT> nodes with this property, for information 
retrieval purposes.

=back

=head3 getEnvironmentClass

=over 4

=item C<>

This applies only to C<ENVIRONMENT> nodes.  Returns what class of environment the
node represents (the C<X> in C<\begin{X}> and C<\end{X}>).

=back

=head3 getCommandName

=over 4

=item C<>

This applies only to C<COMMAND> nodes.  Returns the name of the command (the C<X> in
C<\X{...}>).

=back

=head3 getChildTree

=over 4

=item C<>

This applies only to C<COMMAND>, C<ENVIRONMENT>, and C<GROUP> nodes: it returns the
C<LaTeX::TOM::Tree> which is ``under'' the calling node.

=back

=head3 getFirstChild

=over 4

=item C<>

This applies only to C<COMMAND>, C<ENVIRONMENT>, and C<GROUP> nodes: it returns the
first node from the first level of the child subtree.

=back

=head3 getLastChild

=over 4

=item C<>

Same as above, but for the last node of the first level.

=back

=head3 getPreviousSibling

=over 4

=item C<>

Return the prior node on the same level of the tree.

=back

=head3 getNextSibling 

=over 4

=item C<>

Same as above, but for following node.

=back

=head3 getParent

=over 4

=item C<>

Get the parent node of this node in the tree.

=back

=head3 getNextGroupNode

=over 4

=item C<>

This is an interesting function, and kind of a hack because of the way the
parser makes the current tree.  Basically it will give you the next sibling
that is a C<GROUP> node, until it either hits the end of the tree level, a C<TEXT>
node which doesn't match C</^\s*$/>, or a C<COMMAND> node.

This is useful for finding all C<GROUP>ed parameters after a C<COMMAND> node (see
comments for C<GROUP> in the C<COMPONENTS> / C<LaTeX::TOM::Node> section).  You
can just have a while loop that calls this method until it gets C<undef>, and
you'll know you've found all the parameters to a command.

Note: this may be bad, but C<TEXT> Nodes matching C</^\s*\[[0-9]+\]$/> (optional
parameter groups) are treated as if they were 'blank'.

=back

=head1 CAVEATS

Due to the lack of tree-modification methods, currently this module is
mostly useful for minor modifications to the parsed document, for instance,
altering the text of C<TEXT> nodes but not deleting the nodes.  Of course, the
user can still do this by breaking abstraction and directly modifying the Tree.

Also note that the parsing is not complete.  This module was not written with
the intention of being able to produce output documents the way ``latex'' does.
The intent was instead to be able to analyze and modify the document on a
logical level with regards to the content; it doesn't care about the document
formatting and outputting side of TeX/LaTeX.

There is much work still to be done.  See the F<TODO> list in the F<TOM.pm> source.

=head1 BUGS

Probably plenty.  However, this module has performed fairly well on a set of
~1000 research publications from the Computing Research Repository, so I
deemed it ``good enough'' to use for purposes similar to mine.

Please let the maintainer know of parser errors if you discover any.

=head1 CREDITS

Thanks to (in order of appearance) who have contributed valuable suggestions and patches:

 Otakar Smrz
 Moritz Lenz
 James Bowlin
 Jesse S. Bangs

=head1 AUTHORS

Written by Aaron Krowne <akrowne@vt.edu>

Maintained by Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
