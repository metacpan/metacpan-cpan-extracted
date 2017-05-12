#line 2 "Macrame.pm"
package Macrame;
=head1 NAME

Macrame - filter-time recursive macro framework
providing the feature preventing Perl from being "a Lisp."

=cut
use 5.007001;
use strict;
use warnings;
sub DEBUG(){0};
use Carp;
our $VERSION = '0.13';
=head1 VERSION

This document describes version 0.09 of Macrame, released
April 24, 2009.  Both of Slaven Rezic's reported bugs have been addressed.

Minor changes towards new strictures at PAUSE have been made for version 0.13.

The next step towards getting Macrame to be everything it could become
appears to be fixing Filter::Simple, by either fixing Filter::Simple so
it works better, or by replacing it entirely with a more complex tokenizer,
perhaps L<Filter::PPI>.

Haven't touched this in almost a decade. Wow.


=head1 SYNOPSIS

   macro curry OP A1 A2 { (OP A1), curry OP A2 }
   macro curry OP A { (OP A) }

exactly three macros are always provided, L<macro>, L<EXPAND>, and
L<NOMACROS>.  These are intended as stones sufficiently sturdy
to build any cathedral.

Additionally, a set of L<PUNCTUATION> macros are defined 
which may be  modified to provide macros which will survive
a C<NOMACROS> invocation.

=head1 ABOUT THIS PERLDOC

this perldoc is interspersed through the relevant code implementing
each feature, to minimize disconnection between documentation and
implementation.

Cookbook kinds of things may appear at the bottom.

=head1 DESCRIPTION

=head2 tokenizing

at this version we ignore all whitespace in input and place
whitespace in output only between barewords. Lexical blocks
are treated as single tokens for signature matching purposes,
as are expressions that indicate variables, such as C<%foo::bar>.

the sigil contents eater needs some love before it follows the
same rules as perl's double quoted variable interpolation engine
concerning parsing things like C<$foo::bar->{baz}{blarf}>.

move the following elsewhere:

At this version we use the core-provided Filter::Simple C<FILTER_ONLY>
features to extract quotelikes, which is not quite as robust as Perl's
parsing.  The quotelike parser in Filter::Simple tends to treat
slashes as quoting operators.  When this is a problem, a workaround
is to define a macro to provide the slash, and then use that instead.

   macro divided_by { EXPAND '/' }
   macro F2C F { ( (F) -32 * 5 divided_by 9 ) } 
   macro C2F C { ( (C) divided_by 5 * 9 + 32 ) } 


We are also ignoring line numbers.

=head2 lexcial blocking

Curly, round and square brackets are all recognized,
for macro visibility purposes, as lexical blocks. Inner macros
hide outer macros.

=head2 macro signatures

macros are polymorphic based on syntactic signatures. 
More features of signature match syntax will appear in future
releases of Macrame.  The first, in inner to outer blocking
and then document order, macro that
matches the signature for any macro name, will operate during
Macrame transformation. see L<SIGNATURE SYNTAX> for what is
currently allowed in macro signatures.

=head2 signature matching procedure

when a bareword is identified as a macro, signature matches
are attempted against the untransformed token tree that follows it.
In the event that no match is found, the token tree following the
macro name is transformed, and matching is attempted again.  
That failing too is a fatal error.

=head2 where to find examples

See the t/Macrame.t file included with this distribution for examples,
also there may be a cookbook section in this document.  The examples
in the test file are more certain to work.

=cut

our @Definitions = ();
our $FINAL = 0; # CPAN bug #31200

=head1 @Macrame::Definitions array

localization of macros is provided by unshifting a new definitions
frame onto the beginning of C<@Definitions> whenever Macrame descends
into a lexical block.  Definitions frames are hash references.

=cut

use Filter::Simple 0.82; # get FILTER_ONLY and (un)import

my $mdef;
my $NMdef;
my $Edef;
my %PUNCTUATION;
our %PUNCTUATION_MACROS;

our %tmp_n2l;
=head1 SIGNATURE SYNTAX

The signature is the part of a L<macro> definition between
the name of the macro and the first opening curly bracket
at the same lexical level as the name.

The signature provides two functions.  Firstly, by matching
or not matching, it selects which macro with a given name to
use.  Secondly, while deciding if it matched or not, the
names to lexemes array is loaded with the replacement lexemes
for the placeholder names.

The signature is optional, and when absent, the definition will
always match.

   macro define NAME = VALUE { macro NAME { VALUE } }
   define pi = 3.14159  # a constant
   define pie_predicate = ( $slices_remaining > 0 ) # an inlined sub()

=cut

sub Macrame::lexeme::sig_matches{
	my $sig = shift;
	my $candidate = shift;

=head2 bareword matching

Barewords appearing in macro signatures are placeholders
and whatever lexeme appears in that place, be it a bareword,
a sigil expression, a bracketed block, or a quoted expression,
will be saved in the names to lexemes table for insertion.

=cut
	if ($sig->wordp){
		my $copy = $candidate->copy;
		$copy->next = undef;
		$copy->previous = undef;
		$copy->up = undef;
		$tmp_n2l{$sig->text} = $copy;
	}else{

=head2 syntax matching

Everything else (except quoted stuff -- see below) is syntax.
syntax must be present to allow match.  Bracketed blocks
appearing in signatures get descended.

   # this is obviously very powerful; would someone please
   # do something with it and send an example to put here?

=cut
		# syntax must match
		$sig->text eq $candidate->text
			or do {
				%tmp_n2l = ();
				return ();
			};
	   if ($sig->contents){
		defined $candidate->contents or return undef;
		$sig->contents->sig_matches($candidate->contents)
			or do {
				%tmp_n2l = ();
				return ();
			};
	   };
	};

	if (!$sig->next){
		my $NEXT = $candidate->next;
DEBUG and warn "last: ".$candidate->text;
DEBUG and warn "next: ".($NEXT? $NEXT->text: 'undef');
		$candidate->next = undef;
		my $N2L = {%tmp_n2l};
		%tmp_n2l = ();
		return ($N2L,$NEXT)
	};
	$candidate->next or return undef;
	$sig->next->sig_matches($candidate->next)
};

=head2 quoted expressions in signatures

It is expected that the room to shoehorn all kinds of fancy  things
into the signature matching language -- it could become every bit
as complex as pcre -- is in quotelike lexemes.

At this time, the only quotelikes allowed in signatures use apostrophes, also
known as single quotes.  The single quotes may surround a bareword, which
indicates that that word is part of the syntax of the macro and must appear
in the input tree as a bareword.  The bareword may be surrounded by brackets
which means that a block bounded by the same kind of bracket must appear
at that point, and that block will go into the names to lexemes table under
the name of the bracketed bareword.

   {
     macro search '(list)' 'for' regex {(NOMACROS  grep { regex } list )}
     macro search '{pairs}' 'for' '/regex/' {(NOMACROS do {
        my $pair_ref = pairs;
        grep { $pair_ref->{$_} =~ regex } keys %$pair_ref 
     })}
     my @bb = search (qw/foo bar baz/) for /a/;
     my @bc = search {qw/a foo b bar c baz/} for /a/;
     is("@bb","bar baz", "'(syntax)'");
     is("@bc","b c", "'{syntax}'");
   }

=cut

sub Macrame::lexeme::quotelike::sig_matches{
	my $sig = shift;
	my $candidate = shift;
	my $stext = $sig->text;
	my ($bracket,$keyword,$closer) = ( $stext =~/^'([\/\[\{\(]?)(\w+)([\)\}\]\/]?)'$/ );
	defined($keyword) or do {
		DEBUG and warn "quotelike sig_match syntax";
		die "quotelike in macro sig must be '\\w+' not $stext";
	};

	if ($bracket){
		$candidate->text eq $bracket or return undef;
		my $copy = $candidate->deep_copy;
		$copy->next = undef;
		$copy->previous = undef;
		$copy->up = undef;
		$tmp_n2l{$keyword} = $copy;
	}else{
		# 'word' means, match that word as syntax
		$candidate->text eq $keyword or return undef;
	};
=head2 how much gets matched by a macro signature

a matching signature will identify the part of the candidate filter input
that is going to match the signature, and that is the part that gets
replaced by the macro body after argument interpolation.  A way to declare
things like "this names to lexemes table entry represents everything until
the next keyword"  --  in short, regular expression syntax -- would be
totally cool but at this point constitutes paralyzing featuritis.

=cut
	if (!$sig->next){
		my $NEXT = $candidate->next;
DEBUG and warn "last: ".$candidate->text;
DEBUG and warn "next: ".($NEXT? $NEXT->text: 'undef');
		$candidate->next = undef;
		my $N2L = {%tmp_n2l};
		%tmp_n2l = ();
		return ($N2L,$NEXT)
	};
	$candidate->next or return undef;
	$sig->next->sig_matches($candidate->next)
};

BEGIN {
	%PUNCTUATION = (
		Q => "'",
		QQ => '"',
		SLASH => '/',
		LPAREN => '(',
		RPAREN => ')',
		LSQUARE => '[',
		RSQUARE => ']',
		LCURLY => '{',
		RCURLY => '}',
	);
	while (my ($name, $symbol) = each %PUNCTUATION){
		$PUNCTUATION_MACROS{$name} = [sub($){
		 	my $SLASH = shift;
		 	my $slash = $SLASH->copy;
		 	$slash->text = $symbol;
		 	bless $slash, 'Macrame::lexeme::nonword';

		}];
	};

=head1 %Macrame::PUNCTUATION_MACROS

by default, Q, QQ, SLASH, LPAREN, RPAREN, LSQUARE, RSQUARE, LCURLY and RCURLY
appear as well as macro, EXPAND and NOMACROS when the macro set is reset, such
as by invoking NOMACROS.  This list is in a modifiable data structure, so if you
really need C<Q> to mean something other than an apostrophe that will sneak by
the Filter::Simple quotelike parser you could do something like

   EXPAND delete $Macrame::PUNCTUATION_MACROS{Q};

or

   use Macrame();
   BEGIN { delete $Macrame::PUNCTUATION_MACROS{Q} }
   use Macrame;
   my $Qobj = new Qobj;
   macro CombineJQZ X { (X->J . X->Q . X->Z) }
   printf "By default a new Qobj has JQZ of %s\n", CombineJQZ $Qobj;


=cut

# sub slash_macro($) {
# 	# replace our argument with a /
# 	# as a workaround for text::Balanced thinking
# 	# all / are quoting operators
# 
# 	my $SLASH = shift;
# 	my $slash = $SLASH->copy;
# 	$slash->text = '/';
# 	bless $slash, 'Macrame::lexeme::nonword';
# };
} # NIGEB

sub transform($);
sub TruePad($){
	my $truepad = new Macrame::lexeme::nonword;
	$truepad->previous = shift;
	$truepad->text = '';
	$truepad
};

sub macro_macro($) {
    my $SIG_TEST;
    my $SIG_PTR;
    my $start = shift;    # this is a Macrame::lexeme object
    $start->text eq 'macro'
      or Carp::confess "VERY WEIRD:: macro_macro called with different name [[["
      . $start->text . "]]]";
    my $MACRO_NAME = $start->next;
    defined $MACRO_NAME
      or $start->ldie("macro must be immediately followed by name");
    my $NAME = $MACRO_NAME->text;
    $NAME =~ /^\w/ or $start->ldie("macro names must be \\w at this time");
DEBUG and warn "defining macro '$NAME'";

    my $MACRO_PREVIOUS = $start->previous;
    my $MACRO_UP       = $start->up;
    $MACRO_UP ||= new Macrame::lexeme;

    # sig is everything to first opening curly
    my $SIG_START = $MACRO_NAME->next;
    my $BODY;

    if ( $SIG_START->text eq '{' ) {    # NO SIG -- START WITH CURLY
	DEBUG and warn "defining signatureless macro '$NAME'";
        $SIG_TEST = sub {
		return ( {}, $_[0] );
		$_[0] and return ( {}, $_[0]->next );
		return ( {}, undef )
	};
        $BODY = $SIG_START;

    }
    else {
        # have a sig before the first curly, so detach it from surroundings
        defined( $SIG_PTR = $SIG_START )
          or $MACRO_NAME->ldie(
            "macro body is required and must be {in curly braces}");

	DEBUG and warn "$NAME.sig starts with: '".$SIG_START->text."'";
        $SIG_START->previous = undef;
        while ( $SIG_PTR->next->text ne '{' ) {    # } perledit is stupid
            $SIG_PTR->up = undef;
            defined( $SIG_PTR = $SIG_PTR->next )
              or $MACRO_NAME->ldie(
                "macro body is required and must be {in curly braces}");
	    DEBUG and warn "$NAME.sig includes: '".$SIG_PTR->text."'";
        }
        $BODY = $SIG_PTR->next;
        $SIG_PTR->next = undef;

	# expand any macros within the sig
	$SIG_START = transform $SIG_START;


        $SIG_TEST =
          sub { 

$SIG_START->sig_matches( shift() )  # sig_matches will return
		
          };
             # a hashref of names appearing in the sig,
	     # to replacement lexemes, and then the
             # next lexeme after the sig, if any.
    }

    my $MACRO_NEXT = $BODY->next ;
    $BODY->next = undef;
    $BODY->up   = undef;

    # definitions is an array for lexical scoping purposes
    push @{ $Definitions[0]->{$NAME} }, (
        $BODY->contents
        ? sub {
            my $name = shift;
            my (  $names2lexemes,$next ) = $SIG_TEST->( $name->next )
              or do {
		DEBUG and warn "sig test failed";
		return undef;
	      };
DEBUG and warn "next: $next\nn2l: @{[

map {
	($_,'=>',$names2lexemes->{$_}->Stringify,',')
} keys %$names2lexemes

]}\n--";
            # obtain replacement
            my $replacement = $BODY->fill_template($names2lexemes);

            # normalize replacement;
            my $up                 = $name->up;
            my $last_lexeme_in_replacement = $replacement;
            if ( defined $replacement ) {
                my $next_LIR;
                while (
                    defined( $next_LIR = $last_lexeme_in_replacement->next ) )
                {
                    $last_lexeme_in_replacement->up = $up;
                    $last_lexeme_in_replacement = $next_LIR;
                }
            }
            else {
                $last_lexeme_in_replacement = $replacement = $name->next;
            }

            # splice
            $replacement and $replacement->previous = $name->previous;
            if ( my $previous = $name->previous ) {
                $previous->next = $replacement;
            }
            else {
                $up and $up->contents = $replacement;
            }
            $next and $next->previous = $last_lexeme_in_replacement;
            $last_lexeme_in_replacement
              and $last_lexeme_in_replacement->next = $next;

            # return $replacement to allow recursion
            $replacement;
          }
        : sub {
            my $name = shift;
            my $up                 = $name->up;
            my ( $names2lexemes, $next ) = $SIG_TEST->( $name->next )
              or return undef;

            # BODY has undefined contents

            # splice
            $next and $next->previous = $name->previous;
            if ( my $previous = $name->previous ) {
                $previous->next = $next;
            }
            else {
                $up->contents = $next;
            }
            $next and $next->previous = $name->previous;
            $next;

        }
    );

    # excise the macro definition
    if ($MACRO_PREVIOUS) {
        $MACRO_PREVIOUS->next = $MACRO_NEXT;
    }
    else {
        $MACRO_UP->contents = $MACRO_NEXT;
    }
    $MACRO_NEXT and $MACRO_NEXT->previous = $MACRO_PREVIOUS;

    # return next lexeme or a true pad if we are at the end of a lexiblock
    $MACRO_NEXT || TruePad($MACRO_PREVIOUS);
}

sub deep_fill($$);

sub Macrame::lexeme::fill_template() {
    my $template_start = shift;    # opening curly brace in macro def
    $template_start->text eq '{' or die "INTERNAL BIZARRITY";
    my $names2lexemes  = shift;
    return deep_fill( $template_start->contents, $names2lexemes );
}


sub deep_fill($$) {
    my $in = shift;
    defined $in or return undef;
    my $names2lexemes = shift;
    ref $names2lexemes eq 'HASH' or Carp::confess "weird n2l not hashref";
    my $text = $in->text;
    if ( exists $names2lexemes->{$text} ) {

        # this piece of the template is a parameter
        my $out = $names2lexemes->{$text}->deep_copy;

        $out->next = deep_fill $in->next, $names2lexemes;
        $out->next and $out->next->previous = $out;

	return $out;

    }
    else {

        # copy this piece of the template verbatim
        my $out = $in->copy;

        if ( $out->contents ) {
            $out->contents = deep_fill $out->contents, $names2lexemes;
            my $ptr;
            for ( $ptr = $out->contents ; defined $ptr ; $ptr = $ptr->next ) {
                $ptr->up = $out;
            }
        }

        if ( $out->next ) {
            $out->next = deep_fill $out->next, $names2lexemes;
            $out->next->previous = $out;
        };

	return $out;
    }

    die "FLOW ERROR";

}
=head2 EXPAND ... ;

the predefined EXPAND macro takes all tokens up to the next
semicolon and executes them, inserting the result of the expression
in the token stream.  The execution takes place in the Macrame::_Expand_
package space.

=cut

# =head2 EXPAND ... FOR _topic_ : foo bar baz ;
# 
# all tokens up to the FOR keyword will be inserted into the
# token stream three times, once with _topic_ replaced with foo,
# once with bar, and once with baz.  Multiple topics may be
# specified:
# 
#     EXPAND
#        print 'the word for '.number.' is '.Q word Q."\n" SEMICOLON
#     FOR
#        number word
#     :
#        1      one
#        2      two
#        3      three
#     ;
# 
# 
# =cut
sub EXPAND_macro {
        my $root = shift;
        my ( $string, $next, @FORex) = $root->Stringify2colon;

	DEBUG and warn "string is <<$string>>";
	DEBUG and warn "next is <<".(defined($next)?$next->Stringify
		:'UNDEFINED').">>";
	length $string or return $next;
	DEBUG and warn "do something to escape quotelikes here FIXME";
#	if(@FORex){
#		my @topics = @{shift @FORex};
#		$string = <<PIECE0;
#macro EXPAND_FOR_MACRO @topics {
#    $string
#}
#PIECE0
#		my $topicCount = @topics;
#		while (@FORex){
#			@topics = splice @FORex, 0, $topicCount;
#			$string .= <<PIECE;
#EXPAND_FOR_MACRO @topics
#PIECE
#
#		};
#		DEBUG and warn "EXPAND ... FOR topic: list:\n$string\n--";
#	};
#        my $in_tree = treeify(<<"EXPANSION");
#package Macrame::_Expand_;
#{
#   $string
#}
#EXPANSION
#      		my $expanded = transform $in_tree;
#       		# my $expanded = $in_tree;
#		my $tstring = $expanded->Stringify;
#		my $rstring = join "\n", eval $tstring;
		my $rstring = eval <<EXPANDME;
package Macrame::_Expand_;
$string
EXPANDME
                $@ and $root->ldie(<<GRIPE);
PROBLEM EXPANDING:
$string
PROBLEM:
$@
GRIPE
                my $rtree = treeify($rstring);
		defined $rtree or return $next;
		my $tmp_last = $rtree;
		$tmp_last = $tmp_last -> next while defined $tmp_last->next;
		$tmp_last->next = $next;
		return $rtree;
              }

our $Transforms = 0;

=head1 NOMACROS macro

NOMACROS disables all except the initial core macros
to the end of its visibility.

=cut

sub reset_Definitions() {
    my $mdef = \&macro_macro;
    my $NMdef ;
    my $Edef = \&EXPAND_macro;
    unshift @Definitions, {
        macro => [$mdef],

        NOMACROS => [
            $NMdef = sub {
	        my @tmp_defs;
                my $start = shift;
		DEBUG and warn
		"REACHED NOMACROS with arg ".$start->Stringify;

	    	our $nmcounter;
	    	$nmcounter++ > 5 and Carp::confess;

                # reset @M::D
# our @Definitions = ();
                 @tmp_defs = @Definitions;
		 DEBUG and warn "stashing definits @Definitions";
                 local @Definitions = (
                    {
		    	nmcounter => $nmcounter,
                        macro    => [$mdef],
                        NOMACROS => [$NMdef],
                        EXPAND   => [$Edef],
                        # SLASH   => [$slashdef]
			%PUNCTUATION_MACROS
                    }
                 );
		 DEBUG and warn "definits localized to : @Definitions";
		 # back to localizing warn "FIXME -- not restored";

         #splice self out of tree, aka "excise" -- could make this $node->excise
                my $next  =  transform $start->next;
		$next ||= TruePad($start->previous);
		DEBUG and warn "in NOMACROS, have NEXT: ".$next->Stringify;
0 and do {      # $start->excise;
		if($start->previous){
			$start->previous->next = $next;
		}else{
		    $start->up
		        and $start->up->contents = $next;
		};
};

		@$start = @$next;
		bless $start, ref $next;

		$start->up and 
		   DEBUG and warn "UP-CONTENTS now ".$start->up->contents->Stringify;

		# restore definitions
                # @Definitions  = @tmp_defs ;

		# 
		# suppress reprocessing
            	# $Transforms = 0;
		$FINAL = 1;
		$next;

              }
        ],

	%PUNCTUATION_MACROS,

        EXPAND => [ $Edef ]
    };
};

INIT { reset_Definitions() };

use Data::Dumper;

sub DumpNtreeify {
    my $DD = Data::Dumper->new( [ \$_[0] ] );
    $DD->Indent(0);
    $DD->Purity(1);
    $DD->Terse(1);
    return treeify( $DD->Dump );
}

INIT { reset_Definitions; };


sub transform($) {
    my $root = shift;
    defined $root or return undef;

    my $deflist;
    my $text;

  toploop: 
        $text = $root->text;
	0 and DEBUG and warn "transforming: $root ($text)";
	DEBUG and warn "transforming: ".$root->Stringify;
        if ( $root->wordp ){
		@Definitions or do {
			DEBUG and warn "resetting definitions";
			reset_Definitions;
		};
		DEBUG and warn "Definitions: @Definitions";
                $deflist = [
                    map {

                       # map through the scopes, finding the arr-ref under the
                        # name at each level.

                        exists $_->{$text}
                          ?

                          @{ $_->{$text} }

                          : ()

                      } @Definitions
                ];
          @$deflist and do {
                DEBUG and warn "$text deflist [@$deflist]";
            my $r;
            DEBUG and warn "OLD: ".$root->Stringify;
            for (@$deflist) {
	    	DEBUG and warn "checking $_ for signature match";
                $r = $_->($root);
                if ( defined $r ) {
		    DEBUG and warn "ran $_; got [$r]";
		    DEBUG and warn "TMP: ".$root->Stringify;
		    DEBUG and warn "r is $r: [".$r->text.']';
                    $root = $r;
		    DEBUG and warn "NEW: ".$root->Stringify;
		    $Transforms++;
                    if($FINAL){
		      $FINAL = 0;
		        $Transforms = 0;
		    	return $root;
		    };
		    goto toploop;
                };
		DEBUG and  warn "sig check on $_ failed";

            };
            # DEBUG and $root->lwarn(
            DEBUG and warn(
                    "NO MATCHING SIGNATURE FOUND FOR MACRO " .
                    $root->text
	    );
            local $Transforms = 0;
            $root->next = transform $root->next;
	    $Transforms and goto toploop;
  	  };

        };

	# process contents with local macro scope
        if ( defined $root->contents ) {
            unshift @Definitions, {};
            $root->contents = transform $root->contents;
            shift @Definitions;
        };

	# process next
        $root->next = transform $root->next;


	# return transformed self
	$root;
};

=head1 notes on Macrame lexing process
 
At this version, Macrame uses a trivial lexer that is not capable of splitting
 non-word tokens.    It does not know one operator from another.    It does however
 respect whitespace, and commas, as separators.    This means that it does not know
 that C <<!! >> or C <<~~ >> are two separate tokens, while C <<++ >> is one token, in Perl.
 
=cut

my %TypeofToken;
sub treeify2($);
my $previous;
my $up;

sub ShowQuotes($){
	my $string = shift;
	$string =~ s/$Filter::Simple::placeholder/QUOTELIKE/g;
	$string;
};

sub treeify($) {

    # take code as input, output a macrame tree
    my $source = shift;
    0 and print STDERR "have source  <<$source >> at ", __LINE__, "\n";

    # $Filter::Simple::placeholder
    length($source) or return undef;

    # convert line number comments to __Macrame_LINE directives
    #          $source =~ s/^#line (\d+) "(.+)"/__Macrame_LINE($1,$2)/mg;
    # strip comments
    # $source =~ s/^(.+[^\$])#.*/$1/mg;
    # 1 while $source =~ s/^(.+[^\$])#.*/$1/m;
    # $source =~ s/^(.*[^\$]|)#.*/$1/mg;
    1 while ($source =~ s/^(.*[^\$]|)#.*/$1/m);
    DEBUG and warn "stripped comments to get\n".ShowQuotes($source)."\n--END sans commenti--";

    #$source =~ s/^(.+[^\$])#.+/$1/mg;
    0 and print STDERR "stripped comments to get BEGIN --\n$source\n-- END commentless at ", __LINE__,
      "\n";

    #          # normalize whitespace
    #          $source =~ s/\s+/ /g;    # no line number tracking for now
    # anyway quotelike extraction would ruin it

# my @pieces = split /(\w+|\s+|$Filter::Simple::placeholder|[$@%(){}\[\]])/, $source;
# my @pieces = split /(\w+| |$Filter::Simple::placeholder|[,;$@%(){}\[\]])/, $source;
    $previous = $up = undef;

# treeify2 [split /(\w+| |$Filter::Simple::placeholder|[,;$@%(){}\[\]])/, $source];
# non-captured whitespace will just go away
    my $return_tree = treeify2 [
        grep {
		0 and DEBUG  and print STDERR "token: <$_>\n";
		defined $_ and length $_ and /\S/
	}
          split qr/
 
                           \s+          # discard -- just split on it -- all whitespace
                   |(                   # these will become lexemes
                            \w+
                   |
               #             $Filter::Simple::placeholder
	       #  f::s::ph unacceptably captures its 32-bit counter
	                     \Q$;\E.{4}\Q$;\E
                   |
                            [,;$@%(){}\[\]]
                   )
 
         /xm, $source
    ];
    # DEBUG and $return_tree->DumpToStderr;
    $return_tree;
}

my %bracketmatch = qw/ { } [ ] ( ) ) ( } { ] [ /;
our $SIGILARG = 0;

{    my ( $line, $file );
 sub treeify2($) {
    defined( my $source = $_[0] ) or return undef;
    0 and DEBUG and print STDERR join '|', @$source;
    0 and DEBUG and print STDERR "\n";
    my $text = shift @$source;
  linenumber_check:
    defined $text or return undef;
    if ( $text eq '__Macrame_LINE' ) {

        #          $source should start with an expansion of ($line, $filename)
        '(' eq shift @$source or die "LINE MACRO WEIRDNESS";
        $line = shift @$source;
        ',' eq shift @$source or die "LINE MACRO WEIRDNESS";
        $file = shift @$source;
        while ( $source->[0] ne ')' ) {
            $file .= shift @$source;
            @$source
              or die "OUT OF SOURCE LOOKING FOR CLOSEPAREN IN LINE MACRO";
        }
        shift @$source;    # lose ')'
        $text = shift @$source;    # next token
        goto linenumber_check;
    }

    0 and DEBUG and print STDERR "Text: $text at " . __LINE__ . "\n";

    # see above # $text eq ' ' and goto &treeify2; # ignore whitespace
    my $this = Macrame::lexeme->new;
    $this or die "new failed";
    $this->text = $text;
    $this or die "new failed";
    $this->line     = $line;
    $this->file     = $file;
    $this->up       = $up;
    $this->previous = $previous;

#bless $this,
#          (/^\w+$/ ? 'Macrame::lexeme::word' :
#                   (/^$Filter::Simple::placeholder$/o ? 'Macrame::lexeme::quotelike' :
#                   $TypeofToken{$_} || 'Macrame::lexeme::nonword')));

    # if ($text =~ /^\w+$/){
    if ( $text =~ /^\w/ )
    {    # all we need to check for due to splitting discipline

        $previous = $this;
        $this->next = &treeify2;
        return bless $this, 'Macrame::lexeme::word';
    }

    elsif ( $text =~ /^$Filter::Simple::placeholder$/o ) {
	# my $index = $PHcounter++;
	my ($phno) = ($text =~ /\Q$;\E(.{4})\Q$;\E/m) or die
             "Check Filter::Simple syntax at version $Filter::Simple::VERSION" ;
	# $this->text = $index;
	# $quotelikes[$index] =
	$this->text = $text = 
	    ${$Filter::Simple::components[unpack('N',$phno)]};
	0 and   warn "unpacked [$phno] to get <$text> ("
		.($this->text).')';
        $previous = $this;
        $this->next = &treeify2;
        return bless $this, 'Macrame::lexeme::quotelike';
    }

    elsif ( $text =~ /[\]\}\)]/ ) {

        # defined ($this->up) or $up->ldie( "BRACKET UNDERFLOW" );
        defined( $this->up ) or die("BRACKET UNDERFLOW");
        $text eq $bracketmatch{ $this->up->text }
          or $up->ldie("BRACKET MISMATCH");
        $previous = $up;
        $up       = $up->up;
        return undef;
    }

    elsif ( $text =~ /[\[{(]/ ) {
        $previous       = undef;
        $up             = $this;
        $this->contents = &treeify2;
        $this->next     = &treeify2;
        return bless $this, 'Macrame::lexeme::opener';
    }

    elsif ( $text =~ /[\$\@\%]/ ) {
	{
    		# my $next = shift @$source;
    		my $next = $source->[0];
		defined $next or die "sigil $text not allowed as final token";
        	if($next eq '{'){
			$this->contents = &treeify2;
		}elsif($next =~ /^\w|^(?:::)+$/){
			
			# plain variable, like $::::::::foo 
			$this->contents = new Macrame::lexeme;
			$this->contents->text = '';
			while( $source->[0] =~ /^\w|^(?:::)+$/){
			   $this->contents->text .= shift @$source;
			};
			DEBUG and warn "clumsy variable name parsing got ".
			   $this->contents->text;
		}else{
			# something like $[ or $$ or $" or $; -- a "LNV"
			shift @$source;
			$this->contents = new Macrame::lexeme;
			$this->contents->text = $next;
		}
	};
        $this->next     = &treeify2;
        return bless $this, 'Macrame::lexeme::sigil';
    }

    # Otherwise,
    $previous = $this;
    $this->next = &treeify2;
    bless $this, 'Macrame::lexeme::nonword';
 }
} # lexical scope surrounding treeify2



sub Macrame {
    if (wantarray) {
        return map { ( transform treeify($_) )->Stringify } @_;
    }
    return join "\n# NEXT BLOCK\n", &Macrame;
}

sub doMacrame() {

    # strip line numbers from quotelikes
    #          s/\n__Macrame_LINE\(.+\)// foreach @Filter::Simple::components;
    # $_ = Macrame::Macrame($_)
1 and DEBUG and warn "operating on:\n$_\n--no gnitarepo";
    my $tree = treeify($_);
    if(defined $tree){
       $_ = ( transform $tree )->Stringify;
    }else{
       $_ = ' ';
    };
1 and DEBUG and warn "yielded:\n$_\n--dedleiy";
}

sub AddLineNumbers {
    my ( $package, $file, $line ) = caller(3);
    my @lines = split /\n/, $_;
    my @linesout;
    for (@lines) {
        if (    # see perldoc perlsyn
            /^\#       \s* line \s+ (\d+)       \s* (?:\s("?)([^"]+)\2)? \s* $/x
          )
        {
            ( $line, $file ) = ( $1, $3 );
            $file =~ s/([^\w\/\-\.])/sprintf("#%X#",chr($1))/ge;
            next;
        }

        #                   push @linesout,    $line++, '"$file"');
        #          $source =~ s/^#line (\d+) "(.+)"/__Macrame_LINE($1,$2)/mg;
        push @linesout, '__Macrame_LINE(' . $line++ . ",'$file')";
        push @linesout, $_;
    }
    $_ = join "\n", @linesout;
};

FILTER_ONLY 

#  all  => sub {
#    print STDERR "begin filter input -----\n";
#    print STDERR $_;
#    print STDERR "\n------ end filter input\n";
#  },
  #          all => \&AddLineNumbers,
  code => \&doMacrame,
#  all  => sub {
#    print STDERR "begin filter output-----\n";
#    print STDERR $_;
#    print STDERR "\n------ end filter output\n";
#  }
;

sub deepcopy($) {
    ref( $_[0] ) and return $_[0]->deepcopy;
    $_[0];
}

# class hierarchy for Macrame trees

package Macrame::lexeme;

our $index_counter;

BEGIN {    # essentially TipJar::fields
    $index_counter = -1;
    eval join "\n", map {
        $index_counter++;

        # with Macrame, I wouldn't have to worry about escaping the $
        <<ACCESSOR;
 sub $_ : lvalue {
          \$_[0][$index_counter]
 }
 sub $_\_i() { $index_counter }
ACCESSOR
 

      } qw/ text next contents previous up file line /

}
    # DEBUG and $return_tree->DumpToStderr;
my $DumpDepth = 0;
sub DumpToStderr{
	my $node = shift;
	print STDERR "DUMP:".('   'x$DumpDepth).$node->text."\n";
	if(defined $node->contents){
		$DumpDepth++;
		DumpToStderr($node->contents);
		--$DumpDepth;
		print STDERR "DUMP:".('   'x$DumpDepth)."CLOSE\n";
	};
	defined $node->next or return;
	DumpToStderr($node->next);
};

sub excise() {    # remove a node from surroundings
    my $start = shift;
    my $next  = $start->next;
    my $prev  = $start->previous;
    defined $next and $next->previous = $prev;
    if(defined $prev){
    	$prev->next = $next;
    }else{
	$start->up and $start->up->contents = $next;
    };


    #         $start->contents and $start->lwarn("excising node with contents");
    return $start;
}

sub contentsAsArray() {
    my $node = shift;
    my @C;
    my $tmp;
    $tmp = $node->contents;
    while ( defined $tmp ) {
        push @C, $tmp;
        $tmp = $tmp->next;
    }
    wantarray and return (@C);
    \@C;

}

sub series_set_up($$) {
    my $node = shift;
    my $up   = shift;
    while ( defined $node ) {
        $node->up = $up;
        $node = $node->next;
    }
}

sub last($) {
    my $node = shift;
    defined $node->next or return $node;
    unshift @_, $node->next;
    goto &last;
}

sub _deepcopy($$$);

sub deep_copy($) {
    my $COPY =  $_[0]->copy;
    # Macrame::DEBUG and warn "deep_copy-ing ".$COPY->text; 
    $COPY->contents &&= $COPY->contents->deep_copy;
    $COPY->next &&= $COPY->next->deep_copy;
    $COPY;
}

sub deepcopy($) {
    _deepcopy( $_[0], $_[0]->previous, $_[0]->up );
}

sub _deepcopy($$$) {
    # $x::CLM = Carp::longmess;
    my ( $orig, $prev, $up ) = @_;
    my $old  = shift;
    my $copy = [@$orig];
    bless $copy, ref $orig;
    $copy->previous = $prev;
    $copy->up       = $up;
    defined $copy->contents
      and $copy->contents = $orig->contents->_deepcopy( undef, $copy );
    defined $copy->next and $copy->next = $orig->next->_deepcopy( $copy, $up );
    $copy;
}

sub excise_redundant($) {

    # remove a node
    my $this = shift;

    # if you excise something
    # with contents, the contents go away.
    # $this->contents and die "

    if ( $this->previous ) {
        $this->previous->next = $this->next;

    }
    else {
        $this->up->contents = $this->next;
    }

    if ( $this->next ) {
        $this->next->previous = $this->previous;

    }
}

sub linecomment($) {
    qq{\n#line $_[0]->[line_i] "$_[0]->[file_i]"\n};
}

sub ldie($) {
    die "$_[1] at $_[0]->[file_i] line $_[0]->[line_i]\n";
}

sub quotep{!1};
sub new {
    bless [], shift;
}

sub copy {
	bless [@{$_[0]}], ref($_[0]);
};

sub wordp  { !1 }
sub string { &text }

sub Stringify {
    my $start = shift;
    my $prev ;
    my @pieces;
    while ( defined $start ) {
	(
          (defined $prev and $prev->wordp and $start->wordp) 
        or  $start->quotep  # should take care of CPAN bug #31201
        ) and push @pieces, ' ';

        push @pieces, $start->string;  # openers do their thing
# warn "after $start have: @pieces";
 	# $start->linecomment,
	$prev = $start;
        $start = $start->next;
    }
    join '', @pieces;
}

sub Stringify2colon($) {
    defined( my $start = shift ) or return ('',undef);
    defined( $start = $start->next ) or return ('',undef);
    my @pieces;
    while ( defined($start) and $start->text ne ';' ) {
        push @pieces,
	# $start->linecomment,
	$start->string;
        $start = $start->next;
    };
    my $next;
    defined $start and $next = $start->next;
    my $string = join '', @pieces;
    return ($string, $next);
}

package Macrame::lexeme::opener;    # [({[]
our @ISA = ('Macrame::lexeme');

sub string {
    my $c = $_[0]->contents;
    $_[0]->text . ($c?$_[0]->contents->Stringify:'') . $bracketmatch{ $_[0]->text };
}

package Macrame::lexeme::closer;    # [})\]]       optimized out
our @ISA = ('Macrame::lexeme');

package Macrame::lexeme::quotelike;    # see Filter::Simple documentation
our @ISA = ('Macrame::lexeme');
sub quotep{!0};

sub string {

    # cribbed from Filter::Simple
    my $bit = shift;
    # my $string = $_[0]->text;
    my $string = $bit->text;
 #   warn "quotelike string yielding [$string]";
	
 #	warn "have string <$string>";
 # Filter:;Simple takes care of untransformiing quotelikes
 #  however we may need this for EXPAND operations
 #   $string =~
 #     s/\Q$;\E(\C{4})\Q$;\E/${$Filter::Simple::components[unpack('N',$1)]}/;
 # when \C became a syntax error, f::s switched to . instead.
    $string;
}

package Macrame::lexeme::sigil;        # [$@%]
our @ISA = ('Macrame::lexeme');
sub string {
    $_[0]->text . $_[0]->contents->Stringify ;
}

package Macrame::lexeme::word;         # \w+
sub wordp { 1 }
our @ISA = ('Macrame::lexeme');

package Macrame::lexeme::token;   # Wikipedia entry on "maximal munch" suggests
                                  # that we might want to give each operator and
                                  # so on its own entry in the tree instead
    # of simply splitting on characters.    For Macrame 1.0
    # however, ::nonword will be sufficient
our @ISA = ('Macrame::lexeme');

package Macrame::lexeme::nonword;    # everything else, split by character
                                     # nah, grouped. That way we can throw out
                                     # the whitespace earlier.
our @ISA = ('Macrame::lexeme');

package Macrame::EXPAND;
our $AUTOLOAD;

sub AUTOLOAD(@) {

    my ($mname) = $AUTOLOAD =~ /^Macrame::EXPAND::(.+)/
      or die "AUTOLOAD name error -- see source code";
    my $deflistref = Macrame::finddeflist($mname);
    defined $deflistref or do {
        local $" = ', ';
        die "UNRECOGNIZED MACRO IN EXPAND: $mname(@_)\n";
    };

    my $argtree = Macrame::nextify(
        Macrame::splice_commas(
            map { ref($_) ? Macrame::DumpNtreeify($_) : $_ }

              #FIXME something about coderefs... just document the failing
              @_
        )
    );
    for my $m (@$deflistref) {

        # each $m is [sigfunction, replacefunction]

        $m->SIGp->($argtree) or next;

        Macrame::EXPAND_push( $m->[1]->($argtree) );
        return;

    }
    die "EXPAND: NO APPROPRIATE SIGNATURE FOR $AUTOLOAD(@_)\n";

}

1;

__END__

=head1 KNOWN BUGS

slashes don't work well as punctuation because Text::Balanced,
from Filter::Simple, tends to interpret them as match operators
instead of divisions.

similarly, quotes in comments can wreck your day.  Apostrophes
are quotes.
 
=head1    Internals
 
=head2    @Macrame::Definitions
 
Definitions is an array of hash references, one for each level of
 bracketing encountered in the source code.    The hashes are
 keyed by macro name and their values are ordered list of signature,
 replace pairs.    The signature is a Macrame Regular Expression and the
 replace is a reference to code, which takes the current treeified
 source code position as argument and returns a replacement.
 
=head2 line numbers  (broken)

When repaired, ...
 
line numbers are tracked by inserting L <<#line directives|perlsyn >>
 in a prepass, then converting them to a __Macrame_LINE(line,file)
 item during the lexing, so please don't call anything __Macrame_LINE.
 \W characters in file names are escaped.
 
=head2 gory internals
 
I'm afraid you're going to have to look at the source code.    Suffice
 it to say that this module reserves all tokens matching /^__Macrame_[A-Z]+/
 for internal use.
 
=head1 HISTORY
 
=head1 Copyright and License
 
Copyright 2007 David Nicol  <<davidnico@cpan.org >>
 
released under same terms as Perl 5
 
=cut
 

