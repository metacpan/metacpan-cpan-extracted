package Decl::Parser;

use warnings;
use strict;
use Decl::Util;
use Iterator::Simple qw(:all);
use Data::Dumper;
use Text::Balanced qw(extract_codeblock);

=head1 NAME

Decl::Parser - implements a parser to be defined using Decl::Semantics::Parse.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

The L<Decl::Semantics::Parse> module uses the structure of a "parse" tag to build a parser.  The parser it builds, though,
is implemented using this class.  And in fact this class also exposes a procedural API for building parsers, if you need to bypass the
parser builder.  It's the work of but a moment to realize that you need to bypass the parser builder when building a parser to parse parser
specifications. (If you could parse I<that>, I'm impressed.)

The idea is to build this parser with as few external dependencies as possible.  Then it might be useful outside the framework as well.

These parsers are based on those in Mark Jason Dominus' fantastic book I<Higher-Order Perl>.  They consist of a tokenizer that is a chain
of lesser tokenizers, registered actions that can be carried out on intermediate parses, and rules that build structure from a sequence
of tokens.

=head2 new()

Instantiates a blank parser.

=cut

sub new {
   my $class = shift;
   return bless {
      tokenizers => [],
      lexer => undef,
      actions => {},
      rules => {},
      rulelist => [],
      cmps => {},
      parser => undef,
      user => {}, # A place to stash action-specific data gleaned from input or ... wherever.
   }, $class;
}

=head1 BUILDING THE PARSER

To build a parser, we add tokenizers, rules, and actions.

=head2 add_tokenizer()

Each parser has a tokenizer, which is a list of atomic tokenizers consisting of regular expressions to examine incoming text and spit it back
out in categorized chunks of low-level meaning.

Each atomic tokenizer consists of a label, a regex pattern, and an optional callback to be called to produce the token.  Intervening text that
does not match the token's pattern is passed through unchanged, allowing later tokenizers in the chain to break that up.

The C<add_tokenizer> function just pushes an atomic tokenizer onto the list.  Later, C<lexer> is called to tie those all together into a full
lexer.

Possible extension: C<$pattern> could be a coderef instead of a string, to permit more flexibility in the design of tokenizers.

=cut

sub add_tokenizer {
   my ($self, $label, $pattern, $handler) = @_;

   push @{$self->{tokenizers}}, [$label, $pattern, $handler ? $handler : sub { [ $_[1], $_[0] ] }];
}

=head2 action()

Adds a named action to the list of actions that can be integrated into the parser.  Also used to retrieve a named action.

=cut

sub action {
   my ($self, $name, $action) = @_;
   
   $self->{actions}->{$name} = $action if defined $action;
   $self->{actions}->{$name};
}

=head2 add_rule($name, $rule), get_rule($name), list_rules(), clear_rule($name);

The C<add_rule> function adds a rule.  The rule is expressed in a sort of restricted Perl to assemble the available parser atoms into something useful. 
Rule cross-references
can be indicated by enclosing the name of the rule in angle brackets <>; that will be substituted by a reference to a parser built with that rule.  The purpose
of this API is to provide a simple but procedural way to assemble a basic parser - one that we can then use to parse our declarative structures.

The target Perl code again leans heavily on Dominus, with some extensions and simplifications to make things easier in our context.

Multiple rules added under the same name will be considered alternatives, and treated as such when the parser is built.

The C<clear_rule> function clears the information associated with a rule name.  I'm not sure it will ever be used, but it just seems so easy that it would
be silly not to put it in here.  It does I<not> delete the rule from the list of rules, so the rule's precedence (if any) will be unchanged.

=cut

sub add_rule {
   my ($self, $name, $rule) = @_;
   $self->{rules}->{$name} = $rule;
   $self->{cmps}->{$name} = $self->make_component('', '\&nothing');
   push @{$self->{rulelist}}, $name unless grep { $_ eq $name} @{$self->{rulelist}};  
}
sub list_rules { @{$_[0]->{rulelist}} }
sub get_rule { $_[0]->{rules}->{$_[1]} }
sub clear_rule {
   my ($self, $name) = @_;
   $self->{rules}->{$name} = [];
   $self->{cmps}->{$name} = $self->make_component('', '\&nothing');
}

=head1 USING THE PARSER

=head2 lexer($input), _t()

The C<lexer> function creates a lexer using the list of tokenizers already registered, using the input stream provided.  The lexer is an iterator, with a peek function to 
check the next token without consuming it.  Tokens are arrayrefs or plain strings.

This leans heavily on Dominus.

Note that the input may itself be a token stream.

If called in a list context, returns the full list of tokens instead of an iterator.  I hope that's what you wanted.

The C<_t> function does most of the heavy lifting, and *really* leans on Dominus.  I've extended his lexer framework with two features: first, if a lexer
is simply passed a string as its input, it will still work, by creating a single-use interator.  Second, token labels that end in an asterisk are filtered
out of the final token string.

Dominus's framework provides for suppression of tokens using the token building function (e.g. sub {''} to suppress whitespace in the outgoing token stream),
but there's a surprising problem with that approach - if the resulting stream is fed into the next atomic tokenizer in a chain, neighboring unparsed text
will be pushed back together!  This is a natural result of the fact that blockwise reading of files needs to be supported without breaking tokens that span
block boundaries; the final tokenizer in the chain necessarily treats the output of earlier tokenizers like blocks.

But what if I want to tokenize into whitespace first, then, say, find all words starting with 't' and treat them as special tokens?  OK, so this was a silly
test case, and yet it seems intuitively to be something like what I'd want to do in some situations.  The naive approach is this:

  parse t
     tokens 
        WHITESPACE "\s+"   { "" }
        TWORDS     "^t.*"
        
If I give that the string "this is a test string", I don't get five tokens, two of which are TWORDS.  I get one TWORD token with the value
"thisisateststring".  That is because by swallowing the "tokenicity" of the whitespace, we're actually just ignoring the whitespace.

Bad!

So instead, we put an asterisk on the whitespace specification, so that it will be suppressed I<after> the tokenizing process is complete, that is, at
the end of the tokenizer chain.  In the meantime, though, the whitespace tokens are still there to hold their place in the queue.

   parse t
      tokens
         WHITESPACE*  "\s+"
         TWORDS       "^t.*"

=cut

sub lexer {
   my ($self, $input) = @_;
   
   return $self->tokens($input) if wantarray;
   
   my @tokenizers = @{$self->{tokenizers}};
   while (@tokenizers) {
      my $t = shift @tokenizers;

      if ($t->[0] eq 'CODEBLOCK') {
         my $pattern = $t->[1] || "{}";
         my $prefix = "[^\\" . substr($pattern,0,1) . "]*";
         $t->[1] = sub { my @r = eval { extract_codeblock ($_[0], $pattern, $prefix) }; defined $r[0] && $r[0] ne '' ? ($r[2], $r[0], $r[1]) : $_[0] } unless ref $pattern;
      }
      $input = _t($input, @$t);
   }
   ifilter $input, sub {
      return $_ unless ref $_;
      return $_ unless $$_[0] =~ /\*$/;  # Skip tokens whose labels end in *.
      return;
   }
}

sub _t {
   my ($input, $label, $pattern, $handler) = @_;
   my @tokens;
   my $buf = '';
   unless (ref $input) {
      $input = iter ([$input]);   # Make $input iterable if it's just a string.
   }
   my $split = $pattern;
   $split = sub { split /($pattern)/, $_[0] } unless ref $pattern;
   iterator {
      while (@tokens == 0 && defined $buf) {
         my $i = $input->();
         
         if (ref $i) {  # $i is itself a token!
            my ($sep, $tok) = $split->($buf);
            $tok = $handler->($tok, $label) if defined $tok;
            push @tokens, grep defined && $_ ne "", $sep, $tok, $i;
            $buf = "";
            last;
          }
            
         # $i is just a bunch of new text.
         $buf .= $i if defined $i;
         my @newtoks = $split->($buf);
         while (@newtoks > 2 || @newtoks && ! defined $i) {
            push @tokens, shift(@newtoks);
            push @tokens, $handler->(shift(@newtoks), $label) if @newtoks;
         }
         $buf = join '', @newtoks;
         undef $buf if ! defined $i;
         @tokens = grep $_ ne "", @tokens;
      }
      return (defined $_[0] and $_[0] eq 'peek') ? $tokens[0] : shift (@tokens);
   }
}


=head2 tokens($input)

If you know you've got a limited number of tokens and just want to grab the whole list, use C<tokens>, which just returns a list.

=cut

sub tokens {
   my ($self, $input) = @_;
   my $lexer = $self->lexer ($input);
   my @list = ();
   while (defined (my $t = $lexer->())) {
      push @list, $t;
   }
   return @list;
}

=head2 tokenstream($input)

Finally, if you need a lazily evaluated stream for your token output (and hey, who doesn't?) call tokenstream.  (Note: you'll want a stream
if you're passing your lexer to a recursive-descent parser as below, because you need to be able to unwind the stream if one of your rules doesn't
match.)

=cut

sub tokenstream {
   my ($self, $input) = @_;
   my $lexer = $self->lexer ($input);
   lazyiter ($lexer);
}

=head2 PARSER COMPONENTS: parser, nothing, anything, end_of_input, token, token_silent, literal, word, p_and, p_or, series, one_or_more, list_of, optional, debug, debug_next_token

These are not methods; they're functions.  They are the little subparsers that we hack together to make a full parser.  The output of each of these
parsers is an arrayref containing a flat list of tokens it has matched in the token stream it's given as input.  Each token is itself an arrayref of
two parts (a cons pair), with the first being the type, and second the token value.  Bare words surviving the lexer are converted into individual
tokens of type '' (empty string), allowing tokens to be treated uniformly.

=cut

sub parser (&) { $_[0] }
sub nothing {
   my $input = shift;
   return (undef, $input);
}
sub debug {
   my $message = shift;
   return \&nothing unless $message;
   my $parser = parser {
      my $input = shift;
      print STDERR $message;
      return (undef, $input);
   }
}
sub debug_next_token {
   my $input = shift;
   print STDERR "at this point the input stream is:\n" . Dumper($input);
   if (not defined $input) {
      print STDERR "no more tokens\n";
   } else {
      my $next = car($input);
      if (not defined $next) {
         print STDERR "car(input) is not defined\n";
      } else {
         my $carn = car($next) || '<undefined>';
         my $cdrn = cdr($next) || '<undefined>';
         print STDERR "next token: ['$carn', '$cdrn']\n";
      }
   }
   return (undef, $input);
}   
sub end_of_input {
   my $input = shift;
   defined($input) ? () : (undef, undef);
}
sub token {
   my $wanted = shift;
   $wanted = [$wanted] unless ref $wanted;
   my $parser = parser {
      my $input = shift;
      return unless defined $input;
      my $next = car($input);
      return unless defined $next;
      return unless ref $next;
      for my $i (0 .. $#$wanted) {
         next unless defined $wanted->[$i];
         return unless $wanted->[$i] eq $next->[$i];
      }
      $next = ['', $next] unless ref $next;
      return ($next, cdr($input));
   };
   
   return $parser;
}
sub token_silent {
   my $wanted = shift;
   $wanted = [$wanted] unless ref $wanted;
   my $parser = parser {
      my $input = shift;
      return unless defined $input;
      my $next = car($input);
      return unless defined $next;
      return unless ref $next;
      for my $i (0 .. $#$wanted) {
         next unless defined $wanted->[$i];
         return unless $wanted->[$i] eq $next->[$i];
      }
      $next = ['', $next] unless ref $next;
      return (undef, cdr($input));
   };
   
   return $parser;
}
sub literal {
   my $wanted = shift;
   my $parser = parser {
      my $input = shift;
      return unless defined $input;
      my $next = car($input);
      return unless defined $next;
      my $value;
      if (ref $next) {
         $value = $next->[1];
      } else {
         $value = $next;
      }
      return unless $value eq $wanted;
      $next = ['', $next] unless ref $next;
      return ($next, cdr($input));
   };
   
   return $parser;
}
sub word { # Need this for undecorated, non-token text.
   my $input = shift;
   return unless defined $input;
   my $next = car($input);
   return unless defined $next;
   return if ref $next;
   return (['', $next], cdr($input));
}
sub anything {
   my $input = shift;
   return unless defined $input;
   my $next = car($input);
   return unless defined $next;
   return ($next, cdr($input)) if ref $next;
   return (['', $next], cdr($input));
}
sub p_and {
   my @p = @_;
   return \&nothing if @p == 0;
   
   my $parser = parser {
      my $input = shift;
      my $v;
      my @values;
      for (@p) {
         ($v, $input) = $_->($input) or return;
         if (ref car($v)) {
            foreach (@$v) {
               push @values, $_ if defined $v;
            }
         } else {
            push @values, $v if defined $v;
         }
      }
      return (\@values, $input);
   }
}
sub p_or {
   my @p = @_;
   return parser { return () } if @p == 0;
   return $p[0]                if @p == 1;
   my $parser = parser {
      my $input = shift;
      my ($v, $newinput);
      for (@p) {
         if (($v, $newinput) = $_->($input)) {
            return ($v, $newinput);
         }
      }
      return;
   }
}
sub series {  # TODO: long series (like, oh, series of lines in a parsed body of over 150 lines or so) generate deep recursion warnings.
              #       So this is elegant - but not a good solution.  Instead, we should collect matches until one doesn't match, i.e.
              #       make "series" a primary parser instead of relying on and/or.
   my $p = shift;
   my $p_star;
   $p_star = p_or(p_and($p, parser {$p_star->(@_) }), \&nothing);
}
sub one_or_more {
   my $p = shift;
   p_and ($p, series($p));
}
sub list_of {
   my ($element, $separator) = @_;
   if (defined $separator and not ref $separator) {
      if ($separator =~ /\*$/) {
         $separator =~ s/\*$//;
         $separator = token_silent($separator);
      } else {
         $separator = token ($separator);
      }
   }
   $separator = token($separator) if ref $separator eq 'ARRAY';
   $separator = token_silent('COMMA') unless defined $separator;
   return p_and($element, series(p_and ($separator, $element)));
}
sub optional { p_or (p_and (@_), \&nothing) }

=head2 build(), make_component($name, $spec), get_parser($name), parse($input), execute($defined input)

The C<build> function takes the rules that have been added to the parser, and builds the actual parser using C<make_parser>, which is also available for
external use.  The C<make_parser> function runs in the context of the parser itself and uses C<eval> to build its parser.  Each parser built with C<build>
or C<make_parser> is named.  Its output, if it matches, is a two-part arrayref, with the first element being its name and the second the arrayref list of
tokens or subvalues that it matched.

An anonymous parser (name '' or undef) just returns the list of tokens, without the level of structure.  The same applies to any name ending in an asterisk.

This should probably be covered in more detail in the tutorial, but the principle used here is that of the recursive-descent parser.  A recursive-descent
parser can effectively be constructed as a series of little parsers that are glued together by combination functions.  Each of these parsers consumes a series
of tokens, and returns a value; the default value is an arrayref (a pair, if you're Pythonic) consisting of the name or tag of the parser, followed
by the list of tokens consumed.  The sum total of all those arrayrefs is an abstract syntax tree for the expression being parsed.

When a parser is invoked in a macro context, that syntax tree is converted into a structure of Decl::Node objects (a nodal structure), with or
without subclass decoration, depending on where the macro is expanded.  But when we call a parser from Perl directly, we get the arrayrefs.

By defining actions and invoking them during the parse, we can also modify that structure as it's being built, or even build something else entirely, like
a numeric result of a calculation or perhaps some callable code.  This is still pretty hand-wavy, as I still haven't got my head around actual applications.

At any rate, the rule specifications passed to C<add_rule> are pretty straightforward:

C<token(['TOKEN'])>  matches a token by that name.
C<token['type', 'text'])> matches a specific token.
C<literal('text')> matches either a token by text, or a bare word.  It converts the bare word to ['', 'word'].
C<regex('regex')> matches a bare word using a regex.  If the regex has parentheses in it, the output value may be one or more tokens with the contents.
C<<parser>> matches a named parser rule, and expands to C<$eta_parser> in order to permit self-reference.  (See Dominus Chapter 8.)
C<\&nothing> is the null parser, used to build complex rules.
C<\&anything> is the universal token, used to match things like comments.
C<\&end_of_input> is the end of input.
C<\&word> is any bare word (non-token text).  It also converts the bare word to ['', 'word'].
C<p_or()> is Dominus's "alternate" function, because I don't like to type that much.
C<p_and()> is Dominus's "concatenate" function, for the same reason.
C<series()> is just a function that matches a series of whatever it's called on.
C<list_of()> is a function.  It matches a delimited series of its first argument, delimited by tokens of its second argument.  If omitted, the delimiter is COMMA.
C<optional()> is a function that matches either its contents or nothing.

Note that the only code-munging done here is reference to other rules.  It's difficult for me to avoid code generation because it's so fun, but since parser
specifications are supposed to be pretty general code, it's really not safe.

The order of addition of rules determines the order they'll be processed in.  When the parser is built, it will check for consistency and dangling rule
references (i.e. rules you mention but don't define), perform the eta expansions needed for self-reference, and build all the subparsers.

=cut
sub make_component {
   my ($self, $name, $code) = @_;
   my $parser;
   
   while ($code =~ /<(\w+)>/) {
      my $pref = $1;
      $self->{cmps}->{$pref} = $self->make_component('', '\&nothing') unless $self->{cmps}->{$pref};
      $code =~ s/<$pref>/parser { \$pref->(\@_) }/g;
   }
   $parser = eval ($code);
   warn "make_component: $@\n>>> $code" if $@;
   return $parser unless $name;
   parser {
      my $input = shift;
      my $v;
      ($v, $input) = $parser->($input) or return;
      [$name, $v];
   }
}
sub get_parser { $_[0]->{cmps}->{$_[1]} }
sub build {
   my ($self) = @_;
   $self->{cmps} = {};  # Start from scratch on every build, of course.
   
   my $code = "sub {\n";
   foreach my $name ($self->list_rules()) {
      $code .= "my (\$p__$name, \$p__${name}_anon);\n";
   }
   foreach my $name ($self->list_rules()) {
      #$self->{cmps}->{$name} = $self->make_component($name, $self->get_rule($name));
      my $rule = $self->get_rule($name);
      while ($rule =~ /<(\w+)>/) {
         my $pref = $1;
         $rule =~ s/<$pref>/parser { \$p__$pref->(\@_) }/g;
      }

      $code .= "\n\$p__${name}_anon = $rule;\n";
      $code .= "\$p__$name = parser {\n";
      $code .= "  my \$input = shift;\n";
      $code .= "  my \$v;\n";
      #$code .= "  print STDERR \"Calling parser $name\\n\";\n";
      $code .= "  (\$v, \$input) = \$p__${name}_anon->(\$input) or return;\n";
      #$code .= "  print STDERR \"Parser $name succeeded\\n\";\n";
      $code .= "  (['$name', \$v], \$input);\n";
      $code .= "};\n";
      $code .= "\$self->{cmps}->{'$name'} = \$p__$name;\n";
   }
   $code .= "}\n";
   #print STDERR $code;
   my $builder = eval $code;
   warn "building: $@" if $@;
   $self->{parser} = $builder->();
}

sub parse {
   my ($self, $input) = @_;
   $input = $self->tokenstream($input) unless ref $input eq 'ARRAY';
   my @rules = $self->list_rules();
   my $first = $self->get_parser($rules[0]);
   my ($output, $remainder) = $first->($input);
   return $output;
}

sub execute {
   my ($self) = @_;
   my $input_builder = $self->action('input') || sub { $_[1] };
   my $parse_result = $self->parse($input_builder->(@_));
   my $output_builder = $self->action('output') || sub { $_[0] };
   $output_builder->($parse_result, @_);
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

1; # End of Decl::Parser
