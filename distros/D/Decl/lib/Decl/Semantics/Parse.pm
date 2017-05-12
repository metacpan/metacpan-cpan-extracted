package Decl::Semantics::Parse;

use warnings;
use strict;

use base qw(Decl::Node);
use Iterator::Simple qw(:all);

=head1 NAME

Decl::Semantics::Parse - implements a parser specification.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

A parser, by nature, converts a text stream into a tree structure.  You can get it to do things I<other> than building a tree structure, but that is its
inherent nature, because we human beings parse our incoming text (in the form of an audio stream) into abstract syntax trees in our heads while understanding
things (well, depending on who you listen to, but it's a useful model).  And of course, our computers work the same way.  So I<somewhere> in the
process of getting from text - that is, code - into actions taken, every computer program or data structure goes through a phase of being an abstract
tree, even if only in a potential sense.

Well, C<Decl> happens to be I<built> of trees, so naturally that's the default output of a parser built into this language.  Now note:
you can also define a parser that, given some text, outputs a callable code object.  The Perl parser is used in just such a manner, and is the default parser
for code in C<Decl>.  But because C<C::D> tries to be as flexible as possible, you can override that, either at the global level or in any
particular code block, as I'll illustrate below.  So if you build a parser that returns a callable object in some way (whether by building code in Perl,
or by doing something fancy with L<Inline::Java> for all I know), then you can use it to define code objects on the fly.

The parsers in C<Decl> are based on those in Mark Jason Dominus' marvelous, marvelous book I<Higher-Order Perl>.  The standard setup in I<HOP>
is to define a lexer (to break the text up into tokens), then to pass the token stream through the parser itself.  This makes the entire process a lot
easier to organize, and since tokenization is already a useful tool, I decided to go with it.

=head2 BASIC EXAMPLE: REGEX

Let's start with one of his examples, shall we?  He provides a regexp parser on page 436 in Chapter 8.  In C<Decl>, it looks like this:

   parse regex
      tokens
         ATOM   "\\x[0-9a-fA-F]{0,2}|\\\d+|\\."
         PAREN  "[()]"
         QUANT  "[*+?]"
         BAR    "|"
         ATOM   "."
         
      rules
         regex
            alternative BAR regex
            alternative
         alternative
            qatom alternative
            (nothing)
         qatom
            atom QUANT
            atom
         atom
            ATOM
            "(" regex ")"
            
Given the input (a|b)+(c|d*) - see below for how to pass input to a parser - this returns the nodal structure

   regex
      alternative
         qatom
            atom
               regex
                  atom
                     ATOM "a"
                  BAR "|"
                  atom
                     ATOM "b"
            QUANT "+"
         atom
            PAREN "("
            regex
               atom
                  ATOM "c"
               BAR
               qatom
                  atom
                     ATOM "d"
                  QUANT "*"
            PAREN ")"
         
That's a pretty lanky structure, but it I<does> serve the purpose of getting text into a data structure
you can do stuff with (like searching it or walking it or passing it off to a template for some other purpose).

We can tweak it a little.  If you tack an asterisk onto any tag in the grammar, the output will omit that
level from the output tree:

   parse regex
      tokens
         ATOM   "\\x[0-9a-fA-F]{0,2}|\\\d+|\\."
         PAREN  "[()]"
         QUANT  "[*+?]"
         BAR    "|"
         ATOM   "."
         
      rules
         regex
            alternative* BAR regex
            alternative*
         alternative
            qatom alternative*
            (nothing)
         qatom
            atom QUANT
            atom
         atom
            ATOM*
            "("* regex* ")"*
            
Given the input (a|b)+(c|d*), this returns the nodal structure

   regex
      qatom
         atom
            atom "a"
            BAR "|"
            atom "b"
         QUANT "+"
      atom
         atom "c"
         BAR
         qatom
            atom "d"
            QUANT "*"
            
That arguably preserves the semantics of the original regex, without keeping the syntactic overhead, and will probably be more useful.

Once our parser is defined, it becomes a new tag, so

   regex "(a|b)+(c|d*)"
   
is now shorthand for the tree structure shown above.  To insert at build time, we use

   <= (regex) "(a|b)+(c|d*)"
   

For a longer non-callable macro insertion, we'll want a better example, but let's assume something like this:

   <= (regex)
      lkjlkjsdf
      lkjljlksjdf
      lkjljsdf
      
=head2 USING A TOKENIZER ALONE

A parser can also be run as a tokenizer alone, returning a stream of tokens.  This is used for the text streams in L<PDF::Declarative>, where commands
can be interpersed into the text (that's still a work in progress, of course).  If you override that parser, you can build PDFs using whatever text
stream formalism you find useful.

   example here after it's written
   
To iterate over that stream, we treat it as a filter on a given text stream, like this:

   do {
      ^foreach token in my_text|pdf_tokenizer {
         if (ref $token eq 'ARRAY') {
            # handle a command token
         } else {
            # we have a word
         }
      }
   }

A token stream is a special type of stream, actually - the iterator returns strings for words, and arrayrefs for identified tokens, which are
generally equivalent to commands.  This distinguishes it from normal data iterators, which return an arrayref for each row.  I mention this because
it affects the way you build your ^foreach specification; a data iterator returning arrayrefs would allow you to provide two local variables, but
a token stream can't, because some of the tokens aren't arrayrefs.

To call a tokenizer from outside C<Decl>, you'd do something like this:

   use Decl (-nofilter PDF::Declarative);
   
   $tree = new Decl;
   $tree->load (<<EOF);
      text my_text
         ...
   EOF
   
   $iterator = $tree->iterate ("my_text|pdf_tokenizer");
   while ($token = $iterator->next) {
      if (ref $token eq 'ARRAY') {
         # handle a command token
      } else {
         # we have a word
      }
   }


=head2 CALLABLE PARSED OBJECTS - EXAMPLE: CALCULATE

A parser can also skip right past the nodal structure stage, transforming your language directly into callable code.  The I<Higher-Order Perl>
example that best fits that model is the calculator; Dominus actually uses the calculator as his first example, but I thought the regexp was a simpler
initial example.

First, let's translate the I<HOP> calculator grammar into C<C::D> style, allowing it to generate a nodal structure.  Even if you define a parser
to be able to build a callable object, its parse tree is still available if you ask for it explicitly, so even the decorated parser below, if used
in a non-callable context, will generate a parse tree for you.  It's just easier to illustrate without the extra syntax.

   grammar here
   
Now let's go ahead and add the specifications necessary to generate a callable object.  These are mostly making use of the "actions" feature.

   grammar here
   
Now we have a number of different ways to use this parser.  First is simply as a parser to extract the parse tree of whatever we defined; I'll
skip that, because it was covered in the previous section.

Second, we can call it just like any other code-generating object, say as an event handler.  The default parser for code snippets is "perl", of course,
but you can direct C<Decl> to use any other code-generating parser like this:

   on my_event calculate < {
      something
   }
   
That's pretty boring in this case, because the grammar we've defined doesn't permit us to use parameters, so we will always calculate the same thing.
Eventually, I'll need and use this feature in some actual application, and I'll try to remember to link to it here.

Finally, we can just call the parser from Perl, like this:

   parser calculate
      ...
      
   do {
      print ^calculate ("1 + 2 * (4 - 5)") . "\n";
   }

For simple parsers, this last case will probably be the most useful.


=head2 CALLING A PARSER FROM OUTSIDE CLASS::DECLARATIVE

Of course, we can also call the parser from outside C<Decl>, like this:

   use Decl (-nofilter);
   
   $tree = new Decl;
   $tree->load (<<EOF);
      parse calculate
         ...
   EOF
   
   $result = $tree->parser('calculate')->parse('1 + 2 * (4 - 5)');
   
Here, C<$result> gets the value of -1.  If you call a non-code-generating parser like this, you'll get a Decl::Node structure back.


=head2 EXAMPLE: CLASS::DECLARATIVE'S OWN PARSER
The standard parser for a C<C::D> line is this:

   parse Dline
      tokens
         WORD
         LPAREN    "\("
         RPAREN    "\)"
         LBRACK    "\["
         RBRACK    "\]"
         COMMA     ","
         EQUALS    "="
         STRING    
         PARSEFLAG "<"
      actions
      rules

That's the actual parser used by default in C<Decl>.  You can override the line parser for a given tag; we use this for the 'select'
tag, for instance.  The indentation structure and bracketing is currently handled by C<Parse::Indented>, and that probably won't change (but you never
know).

=head2 EXAMPLE: SELECT PARSER

The select tag uses SQL to retrieve information from data iterators, and since SQL is, well, a standard query language (kind of), it's supported
natively in C<Decl>, mostly because we already have this fancy parser just sitting around ready to do that kind of thing.  The nice thing,
of course, is that means you don't have to write an SQL parser, because I've already done it for you.

   parse SQLselect

=head1 IMPLEMENTATION

This particular class implements the C<parse> node in the specification structure; the class L<Decl::Parser> implements the parser itself.
In other words, here we are concerned with building a C<Decl::Parser> object that will then be asked to do actual parsing.  The tags claimed
by user-defined parsers are also registered in this phase, constituting macros.

=head2 defines(), tags_defined()

Called by Decl::Semantics during import, to find out what xmlapi tags this plugin claims to implement.

=cut
sub defines { ('parse') }
sub tags_defined { Decl->new_data(<<EOF); }
parse (body=vanilla)
EOF

=head2 build_payload ()

The C<build> function is then called when this object's payload is built (i.e. in the stage when we're adding semantics to our
parsed syntax).  It builds the parser and registers its tag with the application.  Instances are handled by L<Decl::Semantics::Macro>.

=cut

sub build_payload {
   my ($self) = @_;
   
   my $p = Decl::Parser->new();
   $self->{payload} = $p;
   
   my $t = $self->find ('tokens');
   foreach ($t->elements) {
      $p->add_tokenizer ($_->name, $_->label); # TODO: error handling and default definitions for selected tokenizers
   }
   
   if ($self->name) {
      my $root = $self->root();
      $root->build_handler($self->name . "*", "", sub { Decl::Macro->new($self, @_) });
   }
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-decl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Decl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Decl::Semantics::Parse
