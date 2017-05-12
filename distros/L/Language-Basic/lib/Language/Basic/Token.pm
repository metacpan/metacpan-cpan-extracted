package Language::Basic::Token;

# Part of Language::Basic by Amir Karger (See Basic.pm for details)

=pod

=head1 NAME

Language::Basic::Token - Module to handle lexing BASIC statements.

=head1 SYNOPSIS

See L<Language::Basic> for the overview of how the Language::Basic module
works. This pod page is more technical.

     # lex a line of basic into a bunch of tokens.
     my $token_group = new Language::Basic::Token::Group;
     $token_group->lex('PRINT "YES","NO" : A=A+1');

     # Look at tokens
     my $tok = $token_group->lookahead && print $tok->text;
     # Eat expected tokens
     my $tok = $token_group->eat_if_string(",");
     my $tok = $token_group->eat_if_class("Keyword");

=head1 DESCRIPTION

BASIC tokens are pretty simple. They include Keywords, Identifiers (Variable
or Function names), String and Numeric Constants, and a few one- or
two-character operators, like ':' and '<='. Tokens aren't very ambiguous, so
for example, you don't need to know what type of Statement you're looking at
in order to lex a line of BASIC. (The only remotely ambiguous thing is that
'=' can be either a Relational Operator or an Assignment statement.)

The subclasses of LB::Token represent the various sorts of tokens. The
Token::Group class isn't really a subclass at all; it's a group of tokens. See
L<"Language::Basic::Token::Group"> for more info.

=cut

use strict;
use Language::Basic::Common;

# sub-packages
{
package Language::Basic::Token::Group;

package Language::Basic::Token::Comment;

package Language::Basic::Token::Arithmetic_Operator;
package Language::Basic::Token::Multiplicative_Operator;
package Language::Basic::Token::Relational_Operator;
package Language::Basic::Token::Logical_Operator;

package Language::Basic::Token::Identifier;
package Language::Basic::Token::Keyword;

package Language::Basic::Token::Separator;
package Language::Basic::Token::Left_Paren;
package Language::Basic::Token::Right_Paren;

package Language::Basic::Token::Statement_End;
}

# Fields:
#     leading_whitespace  Whitespace before the token
#     text		The text in the Token, upcased unless it's a string,
#			    with leading whitespace removed
#     original_text	Original text (non-upcased) including whitespace
#

# Takes the first token off of text string arg1. Upcases the text in the token
# unless it's a string constant, and blesses the Token to a subclass of
# Language::Basic::Token.
# This sub never gets called except from LB::Token::Group::lex

sub _new {
    # TODO error if called from subclass?
    shift; # get rid of class
    my $self = {
        "text" => undef,
    };
    my $textref = shift;

    # Figure out what sub-class to make it
    my $class;
    return undef if ($$textref =~ /^\s*$/);  # end of a whole line

    # Test each possible LBT subclass.
    # Identifier needs to come after all other reserved words since 
    # it allows any letters
    # Other classes basically don't overlap, so their order doesn't matter
    foreach my $c (qw(Keyword 
		Comment
		Logical_Operator
    		Identifier 
		String_Constant Numeric_Constant
		Left_Paren Right_Paren Separator 
		Arithmetic_Operator Multiplicative_Operator Relational_Operator
		Statement_End)) {
	$class = "Language::Basic::Token::" . $c;
	my $regex = $class->regex;
	if ($$textref =~ s/^(\s*)($regex)//) {
	    $self->{"original_text"} = $1 . $2;
	    $self->{"leading_whitespace"} = $1;
	    my $text = $2;
	    $text = uc($text) unless $c eq "String_Constant";
	    $self->{"text"} = $text;
	    last;
	}
	$class = undef;
    }
    Exit_Error("Don't know how to lex '$$textref'!\n") unless defined $class;
    bless $self, $class;
} # end sub Language::Basic::Token::_new

=pod

The "text" method returns the text that makes up the token. Note that text
is stored in upper case (except for string constants, which are stored
exactly as entered).

=cut

sub text {return shift->{"text"}}

# sub regex returns a regex which matches at the beginning of a string if the
# next token is of this class
sub regex {my $class=shift;Exit_Error($class."::regex should never be called!")}

##############################################################################
{
package Language::Basic::Token::Group;
# Note: no @ISA, because Token::Group isn't really a Token

=head2 class Language::Basic::Token::Group

This important class handles a group of tokens. Text from the BASIC program
is lexed and turned into LB::Tokens which are stored in a Token::Group. Any
access to these Tokens (including creating them) is through the Token::Group
methods. Other classes' parse methods will usually eat their way through
the tokens in the Token::Group until it's empty.

=over 4

=item new

This method just creates a new LBT::Group.

=cut

sub new {
    my $class = shift;
    my $self = {
        "tokens" => [],
    };
    bless $self, $class;
} # end sub Language::Basic::Token::Group::new

=item lex

This method breaks BASIC text arg1 into LB::Tokens and puts them in
Token::Group arg0.

=cut

sub lex {
    my $self = shift;
    my $text = shift;
    my @tokens = ();
    while (defined (my $tok = _new Language::Basic::Token \$text)) {
	push @tokens, $tok;
    }
    $self->{"tokens"} = \@tokens;
    #print $self->print;
}

=item lookahead

This method returns the next token in the Token::Group without removing
it from the group. That means lookahead can be called many times
and keep getting the same token (as long as eat is never called).
It returns undef if there are no more Tokens left.

=cut

sub lookahead {
    my $self = shift;
    return undef unless @{$self->{"tokens"}};
    my $tok = $self->{"tokens"}->[0];
    return $tok;
} # end sub Language::Basic::Token::Group::lookahead

=item eat

This method eats the next Token from the Token::Group and returns it. 
It returns undef if there are no more Tokens left.

=cut

sub eat {
    my $self = shift;
    return undef unless @{$self->{"tokens"}};
    my $tok = shift @{$self->{"tokens"}};
    return $tok;
} # end sub Language::Basic::Token::Group::eat


=item eat_if_string

This method eats the next token from Group arg0 if it matches string arg1
If it ate a token, it returns it. Otherwise (or if there are no tokens left)
it returns undef.

Note that the string to match should be upper case, since all \w tokens
are stored as uppercase.

=cut

sub eat_if_string {
    my $self = shift;
    my $match = shift;

    my $tok = $self->lookahead;
    return undef unless defined $tok;

    #print "looking for text '$match' and found ",$tok->text,"\n";
    my $matched= $tok->text eq $match;

    $self->eat if $matched;
    return $matched ? $tok : undef;
} # end sub Language::Basic::Token::Group::eat_if_string

=item eat_if_class

This method eats the next token from Group arg0 if the token is of class
"Language::Basic::Token::" . arg1. (I.e., it's called with "Keyword" to 
get a Language::Basic::Token::Keyword Token.) If it ate a token, it returns it.
Otherwise (or if there are no tokens left) it returns undef.

=cut

sub eat_if_class {
    my $self = shift;
    my $match = shift;
    my $tok = $self->lookahead;
    return undef unless defined $tok;

    #print "looking for $match and found ",$tok->text,"\n";
    my $matched= $tok->isa("Language::Basic::Token::" . $match);

    $self->eat if $matched;
    return $matched ? $tok : undef;
} # end sub Language::Basic::Token::Group::eat_if_class

=item slurp

Eats tokens from Group arg1 and puts them in Group arg0 until it gets
to a Token whose text matches string arg2 or it reaches the end of arg1. (The
matching Token is left in arg1.)

=cut

sub slurp {
    my ($to, $from, $string) = @_;
    while (defined(my $tok = $from->lookahead)) {
        last if $tok->text eq $string;
	push @{$to->{"tokens"}}, $from->eat;
    }
} # end sub Language::Basic::Token::Group::slurp

=item stuff_left

Returns true if there's stuff left in the Statement we're parsing (i.e. if
there are still tokens left in the Token::Group and the next token isn't a
colon)

=cut

sub stuff_left {
    my $self = shift;
    my $tok = $self->lookahead;
    return 0 unless defined $tok;
    return (!$tok->isa("Language::Basic::Token::Statement_End"));
} # end sub Language::Basic::Token::stuff_left


=item print

For debugging purposes. Returns the Tokens in Group arg0 nicely formatted.

=cut

sub print {
    my $self = shift;
    my $ret = "";
    foreach (@{$self->{"tokens"}}) {
	($a = ref($_)) =~ s/^Language::Basic::Token/LBT/;
	$ret .= "$a '" . $_->{"text"} . "'\n";
    }
    return $ret;
} # end sub Language::Basic::Token::Group::print

=pod

=back

=cut

} # end package Language::Basic::Token::Group

##############################################################################

=head2 Other Language::Basic::Token subclasses

The other subclasses are actually kinds of Tokens, unlike Token::Group.
There are no "new" methods for these classes. Creation of Tokens is done
by Token::Group::lex. In fact, these classes don't have any public
methods. They're mostly there to use "isa" on.

=over 4

=item Keyword

A BASIC keyword (reserved word)

=cut

{
package Language::Basic::Token::Keyword;
@Language::Basic::Token::Keyword::ISA = qw(Language::Basic::Token);

my @Keywords = qw (
    DATA DEF DIM END FOR GOSUB GOTO IF INPUT 
    LET NEXT ON PRINT READ RETURN
    TO STEP THEN ELSE
    );
# Make sure not to accept something like "FORT"
sub regex { "(?i)(" . join("|", @Keywords) . ")\\b"}

} # end package Language::Basic::Token::Keyword

=item Identifier

An Identifier matches /[A-Z][A-Z0-9]*\$?/. It's a variable or function
name.

=cut

{
package Language::Basic::Token::Identifier;
@Language::Basic::Token::Identifier::ISA = qw(Language::Basic::Token);

sub regex { '(?i)[A-Z][A-Z0-9]*\\$?'}

} # end package Language::Basic::Token::Identifier

=item String_Constant

Stuff inside double quotes.

=cut

{
package Language::Basic::Token::String_Constant;
@Language::Basic::Token::String_Constant::ISA = qw(Language::Basic::Token);

sub regex { '".*?"'}

} # end package Language::Basic::Token::String_Constant

=item Numeric_Constant

A float (or integer, currently)

=cut

{
package Language::Basic::Token::Numeric_Constant;
@Language::Basic::Token::Numeric_Constant::ISA = qw(Language::Basic::Token);

sub regex { '(\\d*\\.)?\\d+'}

} # end package Language::Basic::Token::Numeric_Constant

=item Left_Paren

A "("

=cut

{
package Language::Basic::Token::Left_Paren;
@Language::Basic::Token::Left_Paren::ISA = qw(Language::Basic::Token);

sub regex { '\\('}

} # end package Language::Basic::Token::Left_Paren

=item Right_Paren

A ")"

=cut

{
package Language::Basic::Token::Right_Paren;
@Language::Basic::Token::Right_Paren::ISA = qw(Language::Basic::Token);

sub regex { '\\)'}

} # end package Language::Basic::Token::Right_Paren

=item Separator

Comma or semicolon (separators in arglists, PRINT statements)

=cut

{
package Language::Basic::Token::Separator;
@Language::Basic::Token::Separator::ISA = qw(Language::Basic::Token);

sub regex { '[,;]'}

} # end package Language::Basic::Token::Separator

=item Arithmetic_Operator

Plus or minus

=cut

{
package Language::Basic::Token::Arithmetic_Operator;
@Language::Basic::Token::Arithmetic_Operator::ISA = qw(Language::Basic::Token);

sub regex { '[-+]'}

} # end package Language::Basic::Token::Arithmetic_Operator

=item Multiplicative_Operator

Multiply or divide operators ('*' and '/')

=cut

{
package Language::Basic::Token::Multiplicative_Operator;
@Language::Basic::Token::Multiplicative_Operator::ISA = qw(Language::Basic::Token);

sub regex { '[*/]'}

} # end package Language::Basic::Token::Multiplicative_Operator

=item Relational_Operator

Greater than, less than, equals, and their combinations. Note that
equals sign is also used to assign values in BASIC.

=cut

{
package Language::Basic::Token::Relational_Operator;
@Language::Basic::Token::Relational_Operator::ISA = qw(Language::Basic::Token);

# <> <= < >= > =
# Note that Equals can be Rel. Op. or Assignment!
sub regex { '<[=>]?|>=?|='}

} # end package Language::Basic::Token::Relational_Operator

=item Logical_Operator

AND, OR, NOT

=cut

{
package Language::Basic::Token::Logical_Operator;
@Language::Basic::Token::Logical_Operator::ISA = qw(Language::Basic::Token);

sub regex {
    my @Keywords = qw (AND OR NOT); 
    "(?i)(" . join("|", @Keywords) . ")\\b"
}

} # end package Language::Basic::Token::Logical_Operator

=item Comment

REM statement (includes the whole rest of the line, even if there are colons
in it)

=cut

{
package Language::Basic::Token::Comment;
@Language::Basic::Token::Comment::ISA = qw(Language::Basic::Token);

sub regex { '(?i)REM\\s.*'}

} # end package Language::Basic::Token::Comment

=item Statement_End

End of a statement (i.e., a colon)

=cut

{
package Language::Basic::Token::Statement_End;
@Language::Basic::Token::Statement_End::ISA = qw(Language::Basic::Token);

sub regex { ':'}

} # end package Language::Basic::Token::Statement_End

1; # end package Language::Basic::Token
