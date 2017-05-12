package Language::Basic::Statement;

# Part of Language::Basic by Amir Karger (See Basic.pm for details)

=pod

=head1 NAME

Language::Basic::Statement - Package to handle parsing and implementing single
BASIC statements. 

=head1 SYNOPSIS

See L<Language::Basic> for the overview of how the Language::Basic module
works. This pod page is more technical.

A Statement is something like 'GOTO 20' or 'PRINT "HELLO"'. A line of
BASIC code is made up of one or more Statements.

    # Create the statement from an LB::Token::Group and
    # bless it to an LBS::* subclass
    my $statement = new Language::Basic::Statement $token_group;
    $statement->parse; # Parse the statement
    $statement->implement; # Implement the statement

    # Return a string containing the Perl equivalent of the statement
    $str = $statement->output_perl; 

=head1 DESCRIPTION

Take a program like:

 5 LET A = 2

 10 IF A >= 3 THEN GOTO 20 ELSE PRINT "IT'S SMALLER"

Line 5 has just one statement. Line 10 actually contains three. The first
is an IF statement, but the results of the THEN and the ELSE are entire
statements in themselves.

Each type of statement in BASIC has an associated LB::Statement class.
For example, there's LB::Statement::Let and LB::Statement::If. (But no
LB::Statement::Then! Instead the "then" field of the LB::Statement::If
object will point to another statement. In the above program, it would
point to a LB::Statement::Goto.)

Parsing a line of BASIC starts with removing the line number and lexing
the line, breaking it into Tokens which are held in an LB::Token::Group.
LB::Statement::new, refine, and parse, are all called with a Token::Group
argument. These methods gradually "eat" their way through the Tokens.

LBS::new simply creates an LBS object. However, it then calls LBS::refine,
which looks at the first Token of the command and blesses the object to
the correct LBS::* subclass.

Each LBS subclass then has (at least) the methods parse, implement,
and output_perl.

The parse method goes through the text and digests it and sets various
fields in the object, which are used by implement and output_perl.  The
implement method actually implements the BASIC command.  The
output_perl method returns a string (with ; but not \n at the end) of the Perl
equivalent of the BASIC statement.

=cut

use strict;
use Language::Basic::Common;

# sub-packages
{
package Language::Basic::Statement::Data;
package Language::Basic::Statement::Def;
package Language::Basic::Statement::Dim;
package Language::Basic::Statement::End;
package Language::Basic::Statement::For;
package Language::Basic::Statement::Gosub;
package Language::Basic::Statement::Goto;
package Language::Basic::Statement::If;
package Language::Basic::Statement::Input;
package Language::Basic::Statement::Let;
package Language::Basic::Statement::Next;
package Language::Basic::Statement::On;
package Language::Basic::Statement::Print;
package Language::Basic::Statement::Read;
package Language::Basic::Statement::Rem;
package Language::Basic::Statement::Return;
}

# Note: This sub first blesses itself to be class LB::Statement, but then
# class LB::Statement::refine, which blesses the object to a subclass
# depending on what sort of statement it is. The refined object is returned.
#
# Fields:
#     next_statement - reference to next Statment on this Line. (or undef)
#          Note that next doesn't point to an If's Then/Else sub-statements
#
#     lvalue - an LB::Expression::Lvalue object, which represents an
#          expression like X or AR(3+Q), which can be on the left hand
#          side of an assignment statement
#     expression - an LB::Expression:: subclass (e.g., Arithmetic or
#          Relational.) Sometimes there are multiple expressions.
sub new {
    my $class = shift;
    my $token_group = shift;
    my $line_num_ok = shift;
    my $self = {
	"next_statement" => undef,
	"line_number" => undef,
    };

    bless $self, $class;
    $self->refine( $token_group, $line_num_ok );
} # end sub Language::Basic::Statement::new

# Refine LB::Statement to the correct subclass
# I.e., Read the command this statement starts with, and bless the
# Statement to be a new subclass
sub refine {
    my $self = shift;
    my $token_group = shift;
    my $line_num_ok = shift;
    die "LBS::refine called with weird arg $line_num_ok" if
        defined $line_num_ok && $line_num_ok ne "line_num_ok";

    # Valid BASIC statements
    use constant KEYWORDS => 
            qw(DATA DEF DIM END FOR GOSUB GOTO IF INPUT 
	    LET NEXT ON PRINT READ REM RETURN);
    # TODO In theory, this would let us make STOP exactly synonymous
    # with END, or CLEAR synonymous with CLS, etc.
    my %keywords = map {$_, ucfirst(lc($_))} (KEYWORDS);

    # First word is a command, or a variable (implied LET statment)
    my $tok = $token_group->lookahead;
    Exit_Error("Empty statement?!") unless defined $tok;
    my $command;
    (my $class = ref($tok)) =~ s/^Language::Basic::Token:://;
    if ($class eq "Keyword") {
	my $text = $tok->text;
	if (exists $keywords{$text}) {
	    $token_group->eat;
	    $command = $keywords{$text};
	} else {
	    # Statement started with, e.g., "TO" or "ELSE"
	    Exit_Error("Illegal reserved word '$text' at start of statement");
	}

    } elsif ($class eq "Comment") {
        $command = "Rem";
    } elsif ($class eq "Identifier") {
        $command = "Let";
    # If we're in a THEN or ELSE, a line number means GOTO that line
    } elsif ($line_num_ok && 
            $class eq "Numeric_Constant" &&
            $tok->text =~ /^\d+$/) {
        $command = "Goto";
    } else {
        Exit_Error("Syntax Error: No Keyword or Identifier at start of statement!");
    }
    my $subclass = "Language::Basic::Statement::" . $command;
    #print "New $subclass Statement\n";

    bless $self, $subclass;
} # end sub Language::Basic::Statement::refine

# By default, parsing does nothing. Useful, e.g., for REM
sub parse { }

# By default, implementing does nothing. Useful, e.g., for REM
sub implement { }

# By default, output an empty statement. Note that you need the semicolon,
# because we write a line label for each line.
sub output_perl {return ";";}

sub set_line_number {
    my $self = shift;
    my $num = shift;
    $self->{"line_number"} = $num;
}

######################################################################
# package Language::Basic::Statement::Data
# A DATA statement in a BASIC program.
{
package Language::Basic::Statement::Data;
@Language::Basic::Statement::Data::ISA = qw(Language::Basic::Statement);

sub parse {
    my $self = shift;
    my $token_group = shift;
    my $prog = &Language::Basic::Program::current_program;

    # The rest of the statement is things to dim and how big to dim them
    do {
	my $exp = new Language::Basic::Expression::Constant $token_group;
	$prog->add_data($exp);
    } while ($token_group->eat_if_string(","));
} # end sub Language::Basic::Statement::Data::parse

# no sub implement nec.
# no sub output_perl nec.

} # end package Language::Basic::Statement::Data

######################################################################
# package Language::Basic::Statement::Def
# A DEF statement in a BASIC program.
{
package Language::Basic::Statement::Def;
@Language::Basic::Statement::Def::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    # Function name (and args) is stuff up to equals
    # Call LBE::Function::new with extra argument so it knows not to
    # complain about an unknown function.
    my $funcexp = new Language::Basic::Expression::Function 
            ($token_group, "defining")
	    or Exit_Error("Missing/Bad Function Name or Args in DEF!");
    $token_group->eat_if_string("=") or Exit_Error("DEF missing '='!");

    # We don't actually want the LB::Expression, just the function
    # we've declared.
    my $func = $funcexp->{"function"};

    # Read function definition
    my $exp = new Language::Basic::Expression::Arithmetic $token_group
	or Exit_Error("Missing/Bad function definition in DEF!");

    # Now actually define the function
    $func->define($exp);

    $self->{"function"} = $func;
    # TODO note that output_perl may not work now
} # end sub Language::Basic::Statement::Def::parse

# No sub implement: definition happens at compile time

sub output_perl {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    # LB::Function::Defined object
    my $func = $self->{"function"};

    # Function name
    my $name = $func->output_perl;
    my $desc = "{\n";
    $desc .= "INDENT\n";

    # Function args
    $desc .= "my (";
    my @args = map {$_->output_perl} @{$func->{"arguments"}};
    $desc .= join (", ", @args);
    $desc .= ") = \@_;\n";

    # Function def
    my $exp = $func->{"expression"}->output_perl;
    $desc .= "return " . $exp . ";\n";
    $desc .= "UNINDENT\n}";
    # Tell program to print it out at the end of the perl script
    $prog->need_sub($name, $desc);

    return (";"); # put empty statement in program here
} # end sub Language::Basic::Statement::Def::output_perl

} # end package Language::Basic::Statement::Def

######################################################################
# package Language::Basic::Statement::Dim
# A DIM statement in a BASIC program.
{
package Language::Basic::Statement::Dim;
@Language::Basic::Statement::Dim::ISA = qw(Language::Basic::Statement);

sub parse {
    my $self = shift;
    my $token_group = shift;

    # The rest of the statement is things to dim and how big to dim them
    do {
	my $exp = new Language::Basic::Expression::Lvalue $token_group;
	push @{$self->{"arrays"}}, $exp;
	# TODO test that dims are constants!
    } while ($token_group->eat_if_string(","));
} # end sub Language::Basic::Statement::Dim::parse

sub implement {
    my $self = shift;
    foreach (@{$self->{"arrays"}}) {
	# The Lvalue's Array
        my $array = $_->{"varptr"};
	my @indices = $_->{"arglist"}->evaluate;
	$array->dimension(@indices);
    }
} # end sub Language::Basic::Statement::Dim::implement

# no sub output_perl necessary

} # end package Language::Basic::Statement::Dim

######################################################################
# package Language::Basic::Statement::End
# An END statement in a BASIC program.
{
package Language::Basic::Statement::End;
@Language::Basic::Statement::End::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub implement {
    my $prog = &Language::Basic::Program::current_program;
    $prog->goto_line(undef);
} # end sub Language::Basic::Statement::End::implement

sub output_perl {
    return ("exit;");
} # end sub Language::Basic::Statement::End::output_perl

} # end package Language::Basic::Statement::End

######################################################################
# package Language::Basic::Statement::For
# A FOR statement in a BASIC program.
{
package Language::Basic::Statement::For;
@Language::Basic::Statement::For::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    # Read variable name and "="
    my $lvalue = new Language::Basic::Expression::Lvalue $token_group
	    or Exit_Error("Missing variable in FOR!");
    # No strings allowed, at least for now
    if ($lvalue->isa("Language::Basic::Expression::String")) {
        Exit_Error("FOR statements can't use strings!");
    }
    $self->{"lvalue"} = $lvalue;

    # Read initialization value
    $token_group->eat_if_string("=") or Exit_Error("FOR missing '='!");
    $self->{"start"} = 
        new Language::Basic::Expression::Arithmetic::Numeric $token_group
	or Exit_Error("Missing/Bad initialization expression in FOR!");
    $token_group->eat_if_string("TO") or Exit_Error("FOR missing 'TO'!");

    # Until the token "step" OR the end of the statement, we're copying an
    # expression, namely the variable's increment
    $self->{"limit"} = 
        new Language::Basic::Expression::Arithmetic::Numeric $token_group
	or Exit_Error("Missing/Bad limit expression in FOR!");

    # If there's anything left, it had better be a step...
    # Otherwise, step = 1
    my $step;
    if ($token_group->eat_if_string("STEP")) {
	$step = new Language::Basic::Expression::Arithmetic::Numeric 
	    $token_group
	    or Exit_Error("Missing/Bad step expression in FOR!");
    } else {
	Exit_Error("Unknown stuff after limit expression in FOR!") 
	    if $token_group->stuff_left;
	my $foo = new Language::Basic::Token::Group;
	$foo->lex("1");
	$step = new Language::Basic::Expression::Arithmetic::Numeric $foo;
    }
    $self->{"step"} = $step;
} # end sub Language::Basic::Statement::For::parse

sub implement {
    # TODO BASIC doesn't check for start being greater than limit
    # before doing a loop once. Might want to make a flag to do it.
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $lvalue = $self->{"lvalue"};
    my $var = $lvalue->variable;
    $var->set($self->{"start"}->evaluate);
    # Store this FOR statement, so that we can access it when we 
    # get to "NEXT var"
    $prog->store_for($self);
} # end sub Language::Basic::Statement::For::implement

# Outputs $var = start; and the beginning of a do {}
# We also have to set the step here, because we need to test in the loop
# whether it's positive or negative so we can know whether to test for
# being greater than or less than the limit!
sub output_perl {
    my $self = shift;
    # print var = start
    my $lvalue = $self->{"lvalue"}->output_perl;
    my $exp = $self->{"start"}->output_perl;
    my $ret = join(" ", $lvalue, "=", $exp);
    $ret .= ";\n";

    # set the step
    my $step = $self->{"step"}->output_perl;
    $lvalue =~ /\w+/;
    my $vname = $&;
    $ret .= join(" ", "\$step_for_$vname =", $step);
    $ret .= ";\n";

    # set the limit
    my $limit = $self->{"limit"}->output_perl;
    $ret .= join(" ", "\$limit_for_$vname =", $limit);
    $ret .= ";\n";

    # Now start the do loop
    $ret .= "do {";
    $ret .= "\nINDENT";
    return $ret;
} # end sub Language::Basic::Statement::For::output_perl

} # end package Language::Basic::Statement::For

######################################################################
# package Language::Basic::Statement::Gosub
# A GOSUB statement in a BASIC program.
{
package Language::Basic::Statement::Gosub;
@Language::Basic::Statement::Gosub::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    # The rest of the statement is an expression for the line to go to
    $self->{"expression"} = new Language::Basic::Expression::Arithmetic $token_group
        or Exit_Error("Bad expression in GOSUB!");
} # end sub Language::Basic::Statement::Gosub::parse

sub implement {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $goto = $self->{"expression"}->evaluate;
    if ($goto !~ /^\d+$/) {Exit_Error("Bad GOSUB: $goto")}
    # Push the current statement onto the subroutine stack;
    $prog->push_stack($self);
    # Then GOTO the new line
    $prog->goto_line($goto);
} # end sub Language::Basic::Statement::Gosub::implement

sub output_perl {
    # Perl script should print a label after the gosub. But before that,
    # it pushes the label name onto the global gosub stack. THen when
    # we hit the RETURN, we can pop the stack & goto back to this lable.
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $exp = $self->{"expression"};
    my $goto = $exp->output_perl;
    my $ret = "";

    # Form the label name to return to
    my $label = "AL" . $prog->current_line_number;
    $ret .= "push \@Gosub_Stack, \"$label\";\n";

    # Form the label name to goto
    # if it's just a number , don't use $tmp
    if ($goto =~ /^\d+$/) {
        $ret .= "goto L$goto;";
    } else {
	# Form the label name
	$ret .= "\$Gosub_tmp = 'L' . " . $goto . ";\n";
	# Go to it
	$ret .= "goto \$Gosub_tmp;";
    }

    # Write the return-to label after the goto
    $ret .= "\n$label:;";

    return ($ret);
} # end sub Language::Basic::Statement::Gosub::output_perl
} # end package Language::Basic::Statement::Gosub

######################################################################
# package Language::Basic::Statement::Goto
# A GOTO statement in a BASIC program.
{
package Language::Basic::Statement::Goto;
@Language::Basic::Statement::Goto::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    # The rest of the statement is an expression for the line to go to
    $self->{"expression"} = new Language::Basic::Expression::Arithmetic $token_group
        or Exit_Error("Bad expression in GOTO!");
} # end sub Language::Basic::Statement::Goto::parse

# Note that this sub allows "GOTO X+17/3", not just "GOTO 20"
sub implement {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $goto = $self->{"expression"}->evaluate;
    if ($goto !~ /^\d+$/) {Exit_Error("Bad GOTO: $goto")}
    $prog->goto_line($goto);
} # end sub Language::Basic::Statement::Goto::implement

sub output_perl {
    my $self = shift;
    # if it's just a number , don't use $tmp
    my $exp = $self->{"expression"};
    my $goto = $exp->output_perl;
    my $ret;
    if ($goto =~ /^\d+$/) {
        $ret = "goto L$goto;";
    } else {
	# Form the label name
	$ret = "\$Goto_tmp = 'L' . " . $goto . ";\n";
	# Go to it
	$ret .= "goto \$Goto_tmp;";
    }

    return ($ret);
} # end sub Language::Basic::Statement::Goto::output_perl
} # end package Language::Basic::Statement::Goto

######################################################################
# package Language::Basic::Statement::If
# An IF statement in a BASIC program.
{
package Language::Basic::Statement::If;
@Language::Basic::Statement::If::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    # Until the token "then", we're copying a conditional expression
    my $exp = new Language::Basic::Expression::Logical_Or $token_group or
        Exit_Error("Bad Condition in IF!");
    $self->{"condition"} = $exp;
    $token_group->eat_if_string("THEN") or Exit_Error("IF missing 'THEN'!");

    # Until the token "ELSE" or the end of the line, is one or more
    # statements to do if the IF is true
    # TODO we need to handle ELSE either within the same statement
    # as the last THEN statement *OR* at the beginning of a statement.
    # Also nested IFs?

    # Take everything up to ELSE into a separate Token::Group &
    # call parsing with that so that other parse routines can complain if
    # there's something left in their token_group. Right now, they'll have
    # problem with ELSE token
    # TODO need a Token::Group::split method or some such
    my $t1 = new Language::Basic::Token::Group;
    $t1->slurp($token_group, "ELSE");

    # Call new with an extra arg so it knows it's parsing a THEN/ELSE.
    # That way, "THEN 20" gets parsed like "THEN GOTO 20"
    my $then = new Language::Basic::Statement $t1, "line_num_ok" or
	Exit_Error("No statement found after THEN");
    $then->parse($t1);
    my $oldst = $then;
    # Eat [: Statement]*
    while (defined($t1->eat_if_class("Statement_End"))) {
	# Plain line number is only allowed in the *first* THEN/ELSE statement
	my $st = new Language::Basic::Statement $t1;
	$st->parse($t1);
	$oldst->{"next_statement"} = $st;
	$oldst = $st;
    }
    # Make sure we don't do the ELSE after the THEN!
    $oldst->{"next_statement"} = undef;

    # If there's anything left in $token_group, it's the ELSE.
    my $else;
    if (defined($token_group->eat_if_string("ELSE"))) {
	# Use up all the leftover tokens
	$else = new Language::Basic::Statement $token_group, "line_num_ok" or
	    Exit_Error("No statement found after THEN");
	$else->parse ($token_group);
	$oldst = $else;
	while (defined($token_group->eat_if_class("Statement_End"))) {
	    my $st = new Language::Basic::Statement $token_group;
	    $st->parse($token_group);
	    $oldst->{"next_statement"} = $st;
	    $oldst = $st;
	}
	$oldst->{"next_statement"} = undef;
	Exit_Error("Unknown stuff after ELSE statement(s)") if 
	    $token_group->stuff_left;
    } else {
	Exit_Error("Unknown stuff after THEN statement(s)") if 
	    $token_group->stuff_left;
    }

    $self->{"then_s"} = $then;
    $self->{"else_s"} = $else; # may be undef
} # end sub Language::Basic::Statement::If::parse

# Need to set line numbers for THEN and ELSE statements, so we can't
# use the default LBS::set_line_number
sub set_line_number {
    my $self = shift;
    my $num = shift;
    $self->{"line_number"} = $num;
    foreach ("then_s", "else_s") {
        my $st = $self->{"$_"};
	while (defined $st) {
	    $st->set_line_number($num);
	    $st = $st->{"next_statement"};
	}
    }
}

sub implement {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;

    if ($self->{"condition"}->evaluate) {
        $prog->{"next_statement"} = $self->{"then_s"};
    } else {
	# This may be undef, in which case, code will just continue to next line
        $prog->{"next_statement"} = $self->{"else_s"};
    }
} # end sub Language::Basic::Statement::If::implement

sub output_perl {
    my $self = shift;
    my $ret = "if (";
    $ret .= $self->{"condition"}->output_perl;
    $ret .= ") {\n";
    $ret .= "INDENT";
    my $st = $self->{"then_s"};
    do {
        $ret .= "\n" . $st->output_perl;
    } while (defined ($st = $st->{"next_statement"}));

    if (defined $self->{"else_s"}) {
	# TODO only double-\n if there's a long THEN
	$ret .= "\n\nUNINDENT";
        $ret .= "\n} else {\n";
	$ret .= "INDENT";
	$st = $self->{"else_s"};
	do {
	    $ret .= "\n" . $st->output_perl;
	} while (defined ($st = $st->{"next_statement"}));
    }
    $ret .= "\nUNINDENT";
    $ret .= "\n}";

    return ($ret);
} # end sub Language::Basic::Statement::If::output_perl

} # end package Language::Basic::Statement::If

######################################################################
# package Language::Basic::Statement::Input
# An INPUT statement in a BASIC program.
{
package Language::Basic::Statement::Input;
@Language::Basic::Statement::Input::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    # Handle INPUT "FOO"; BAR, BLAH
    # TODO I should really just try to call LBE::Constant::String and not
    # do anything if it returns undef. But currently that warns that what
    # we're trying to input isn't a quoted string if there's not quotation
    # mark.
    if ($token_group->lookahead->
	    isa("Language::Basic::Token::String_Constant")) {
        my $prompt = new 
	    Language::Basic::Expression::Constant::String $token_group;
        $self->{"to_print"} = $prompt;
	$token_group->eat_if_string(";") or
	    Exit_Error("Expected ';' after INPUT prompt!");
    }

    # The rest of the inputs will be separated by commas
    do {
	my $exp = new Language::Basic::Expression::Lvalue $token_group
	    or Exit_Error("Incorrect INPUT!");
	push @{$self->{"lvalues"}}, $exp;
    } while $token_group->eat_if_string(",");
} # end sub Language::Basic::Statement::Input::parse

sub implement {
    my $self = shift;
TRY_AGAIN:
    # Print a prompt, if it exists
    my $to_print = (exists $self->{"to_print"} ? 
        $self->{"to_print"}->evaluate :
	"");
    print "$to_print? ";

    # TODO set Program's "column" field to zero!
    # Read the variables
    my $in = <>;
    chomp($in);
    # TODO read Constants (String or Numeric) followed by commas if nec.
    # TODO type checking: make sure a string is a string
    # (this might be done by a different part of the program)
    # TODO Use "EXTRA IGNORED?" to let user know they need to quote commas?
    my @ins = split(/\s*,\s*/, $in);
    if (@ins != @{$self->{"lvalues"}}) {
	print "Not enough inputs! Try whole statement again...\n";
	# Can't have a BASIC interpreter without a GOTO!
	goto TRY_AGAIN;
    }

    # set the variables to the inputted value
    foreach (@{$self->{"lvalues"}}) {
	my $var = $_->variable; # LB::Variable object
	# TODO Print "??" if they don't input enough. 
	my $value = shift @ins;
	$var->set($value);
    }

    return $self->{"next_statement"};
} # end sub Language::Basic::Statement::Input::implement

sub output_perl {
    my $self = shift;
    # Print the prompt
    my $ret = "print ";
    if (exists $self->{"to_print"}) {
        $ret .= $self->{"to_print"}->output_perl;
	$ret .= " . "; # concat with the ? below
    }
    $ret .= "\"? \";\n";

    # Input the line
    $ret .= "\$input_tmp = <>;\n";
    $ret .= "chomp(\$input_tmp);\n";

    # Set the values
    my @lvalues = map {$_->output_perl} @{$self->{"lvalues"}};
    my $tmp = join(", ", @lvalues);
    # Make the code a bit simpler for just one input
    my $multi = @lvalues > 1;
    if ($multi) {
	$ret .="($tmp) = split(/\\s*,\\s*/, \$input_tmp);";
    } else {
	$ret .="$tmp = \$input_tmp;";
    }

    return $ret;
} # end sub Language::Basic::Statement::Input::output_perl

} # end package Language::Basic::Statement::Input

######################################################################
# package Language::Basic::Statement::Let
# A LET statement in a BASIC program.
{
package Language::Basic::Statement::Let;
@Language::Basic::Statement::Let::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    # Read variable name and "="
    my $lvalue = new Language::Basic::Expression::Lvalue $token_group
	    or Exit_Error("Missing variable in LET!");
    $self->{"lvalue"} = $lvalue;

    # The rest of the statement is an expression to set the variable equal to
    $token_group->eat_if_string("=") or Exit_Error("LET missing '='!");
    $self->{"expression"} = 
	    new Language::Basic::Expression::Arithmetic $token_group
	    or Exit_Error("Missing right side expression in LET!");
} # end sub Language::Basic::Statement::Let::parse

sub implement {
    my $self = shift;
    my $lvalue = $self->{"lvalue"};
    my $var = $lvalue->variable;
    my $value = $self->{"expression"}->evaluate;
    $var->set($value);

    return $self->{"next_statement"};
} # end sub Language::Basic::Statement::Let::implement

sub output_perl {
    my $self = shift;
    my $lvalue = $self->{"lvalue"}->output_perl;
    my $exp = $self->{"expression"}->output_perl;
    my $ret = join(" ", $lvalue, "=", $exp);
    $ret .= ";";

    return ($ret);
} # end sub Language::Basic::Statement::Let::output_perl

} # end package Language::Basic::Statement::Let

######################################################################
# package Language::Basic::Statement::Next
# A NEXT statement in a BASIC program.
{
package Language::Basic::Statement::Next;
@Language::Basic::Statement::Next::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    my $lvalue = new Language::Basic::Expression::Lvalue $token_group
	    or Exit_Error("Incorrect NEXT!");
    # No strings allowed, at least for now
    if ($lvalue->variable->isa("Language::Basic::Variable::String")) {
        Exit_Error("NEXT statements can't use strings!");
    }
    $self->{"lvalue"} = $lvalue;
} # end sub Language::Basic::Statement::Next::parse

sub implement {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;

    # Get the "FOR var" statement that this NEXT refers to.
    my $for_statement = $prog->get_for($self);
    my ($limit,$step) = 
        map {$for_statement->{$_}->evaluate} qw (limit step);

    # Increment the variable
    my $lvalue = $self->{"lvalue"};
    my $var = $lvalue->variable;
    my $value = $var->value;
    $value += $step;
    $var->set($value);
    #print "next: '$value' '$limit' '$step' '$goto'\n";

    #test
    my $done = ($step > 0 ?  $value > $limit : $value < $limit);
    unless ($done) {
	# Go to the statement *after* the statement the FOR started on
        $prog->goto_after_statement($for_statement);
    }
} # end sub Language::Basic::Statement::Next::implement

# Outputs $var increment and end of do{}until block
sub output_perl {
    my $self = shift;
    # Increment variable
    my $lvalue = $self->{"lvalue"};
    my $lv = $lvalue->output_perl;
    $lv =~ /\w+/;
    my $vname = $&;
    # Note that we add step_for even if it's negative.
    my $ret = join(" ", $lv, "+=", "\$step_for_$vname");
    $ret .= ";\n";
    $ret .= "UNINDENT\n";

    # End the do {} block
    $ret .= "} ";

    # test the until
    $ret .= "until (\$step_for_$vname > 0 ? ";
    $ret .= $lv . " > \$limit_for_$vname : " .$lv. " < \$limit_for_$vname);";
    return $ret;
} # end sub Language::Basic::Statement::Next::output_perl

} # end package Language::Basic::Statement::Next

######################################################################
# package Language::Basic::Statement::On
# An ON statement in a BASIC program.
{
package Language::Basic::Statement::On;
@Language::Basic::Statement::On::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;

    $self->{"expression"} = 
	new Language::Basic::Expression::Arithmetic $token_group
        or Exit_Error("Missing Arith. Exp. in ON!");
    # Until the token "GOSUB/GOTO", we're copying an arithmetic expression
    my $tok = $token_group->eat_if_class("Keyword");
    defined $tok and $tok->text =~ /^GO(SUB|TO)$/ 
	or Exit_Error("ON missing GOSUB/GOTO!");
    my $type = $tok->text;
    $self->{"type"} = $type;

    # The rest of the inputs will be separated by commas
    do {
	my $exp = 
	    new Language::Basic::Expression::Arithmetic::Numeric $token_group
	    or Exit_Error("Incorrect Expression in ON ... $type!");
	push @{$self->{"gotos"}}, $exp;
    } while $token_group->eat_if_string(",");
} # end sub Language::Basic::Statement::On::parse

sub implement {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $type = $self->{"type"};
    my $value = $self->{"expression"}->evaluate;
    if ($value !~ /^\d+$/ || $value > @{$self->{"gotos"}}) {
        Exit_Error("Bad value in ON: $value")
    }

    my $goto = ${$self->{"gotos"}}[$value-1]->evaluate;
    if ($goto !~ /^\d+$/) {Exit_Error("Bad GOTO in ON: $goto")}
    $prog->goto_line($goto);

    # And if it's a GOSUB, push the program stack so we can get back
    $prog->push_stack($self) if $type eq "GOSUB";
} # end sub Language::Basic::Statement::On::implement

sub output_perl {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $type = $self->{"type"};

    # List of lines to go to
    my @gotos = map {$_->output_perl} @{$self->{"gotos"}};
    my $ret = "\@Gotos_tmp = map {'L' . ";
    # If there's any expressions, be more fancy
    if (grep {$_ !~ /^\d+$/} @gotos) {$ret .= "eval "}
    $ret .= "\$_} (";
    $ret .= join(", ", @gotos);
    $ret .= ");\n";

    # Index in the list
    my $branch = $self->{"expression"}->output_perl;
    $ret .= "\$index_tmp = ";
    $ret .= $branch . ";\n";

    # Form the label name to return to
    my $label;
    if ($type eq "GOSUB") {
	$label = "AL" . $prog->current_line_number;
	$ret .= "push \@Gosub_Stack, \"$label\";\n";
    }

    # Go to it
    $ret .= "goto \$Gotos_tmp[\$index_tmp-1];";

    # Write the return-to label after the goto
    if ($type eq "GOSUB") {
	$ret .= "\n$label:;";
    }

    return ($ret);
} # end sub Language::Basic::Statement::On::output_perl

} # end package Language::Basic::Statement::On

######################################################################
# package Language::Basic::Statement::Print
# A PRINT statement in a BASIC program.
{
package Language::Basic::Statement::Print;
@Language::Basic::Statement::Print::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

sub parse {
    my $self = shift;
    my $token_group = shift;
    # empty print statement?
    unless ($token_group->stuff_left) {
        $token_group = new Language::Basic::Token::Group;
	$token_group->lex('""');
    }

    my $endchar;
    do {
	my $exp = new Language::Basic::Expression::Arithmetic $token_group
	    or Exit_Error("Weird thing to print in PRINT statement!");
	my $tok;
	if ($tok = $token_group->eat_if_class("Separator")) {
	    # It's a comma or semicolon
	    $endchar = $tok->text;
	} elsif (! $token_group->stuff_left) {
	    $endchar = "";
	} else {
	    Exit_Error("Unexpected extra thing in PRINT statement!");
	}
	push @{$self->{"to_print"}}, [$exp , $endchar];

    } while ($token_group->stuff_left);
} # end sub Language::Basic::Statement::Print::parse

sub implement {
    # TODO More than one expression to print! Use an array of LB::Expressions
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    foreach my $thing (@{$self->{"to_print"}}) {
	my ($exp, $endchar) = @$thing;
	my $string = $exp->evaluate;

	# Never print after column 70
	# But "print ''" shouldn't print two \n's!
	if ($prog->{"column"} >= 70 && length($string)) {
	    print "\n";
	    $prog->{"column"} = 0;
	}

	# Print the string
	print $string;
	$prog->{"column"} += length($string);

	# Handle the thing after the string
	if ($endchar eq ",") {
	    # Paraphrased from a BASIC manual:
	    # If the printhead (!) is at char 56 or more after the expression,
	    # print \n, else print spaces until the printhead is at the
	    # beginning of the next 14-character field
	    if ($prog->{"column"} >= 56) {
	        print "\n";
		$prog->{"column"} = 0;
	    } else {
		my $c = 14 - $prog->{"column"} % 14;
		print (" " x $c);
		$prog->{"column"} += $c;
	    }
	} elsif ($endchar eq ";") {
	    # In BASIC, you always print a space after numbers, but not
	    # after strings. That seems a bit dumb, but that's how it is.
	    if (ref($exp) =~ /::Numeric$/) {
	        print " ";
		$prog->{"column"}++;
	    }
	} else {
	    print "\n";
	    $prog->{"column"} = 0;
	}
    } # end foreach loop over expressions to print
} # end sub Language::Basic::Statement::Print::implement

sub output_perl {
    my $self = shift;
    my $ret = "print(";
    my @to_print = @{$self->{"to_print"}};
    # TODO create a Print subroutine that takes exp/endchar array & prints
    # in the exact way BASIC does. (How do we make that subroutine print
    # a space after numerical expressions?!)
    while (my $thing = shift @to_print) {
	my ($exp, $endchar) = @$thing;
	my $string = $exp->output_perl;
	$ret .= $string;
	$ret .= ",' '" if ref($exp) =~ /Numeric$/;
	if ($endchar eq ",") {
	    $ret .= ", \"\\t\"";
	} elsif ($endchar eq "") {
	    $ret .= ", \"\\n\"";
	    # This had better be the last exp!
	    warn "Internal error: obj. w/out endchar isn't last!" if @to_print;
	} # otherwise it's ';', we hope

	if (@to_print) {
	    $ret .= ", ";
	} else {
	    $ret .= ");";
	}
    }

    return ($ret);
} # end sub Language::Basic::Statement::Print::output_perl

} # end package Language::Basic::Statement::Print

######################################################################
# package Language::Basic::Statement::Read
# A READ statement in a BASIC program.
{
package Language::Basic::Statement::Read;
@Language::Basic::Statement::Read::ISA = qw(Language::Basic::Statement);

sub parse {
    my $self = shift;
    my $token_group = shift;

    # The rest of the statement is lvalues to read in
    do {
	my $exp = new Language::Basic::Expression::Lvalue $token_group
	    or Exit_Error("Incorrect READ statement!");
	push @{$self->{"lvalues"}}, $exp;
    } while $token_group->eat_if_string(",");
} # end sub Language::Basic::Statement::Read::parse

sub implement {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    foreach (@{$self->{"lvalues"}}) {
        my $var = $_->variable;
	my $data = $prog->get_data();
	# Data will just be a LBE::Constant, but we still have to &evaluate it
	my $value = $data->evaluate;
	$var->set($value);
    }
} # end sub Language::Basic::Statement::Read::implement

sub output_perl {
    my $self = shift;
    # Set a list...
    my $ret = "(";
    my @lvalues = map {$_->output_perl} @{$self->{"lvalues"}};
    $ret .= join(", ", @lvalues);
    $ret .= ") = ";

    # equal to a splice from @Data
    my $num = @lvalues;
    $ret .= "splice(\@Data, 0, $num);";

    return ($ret);
} # end sub Language::Basic::Statement::Read::output_perl

} # end package Language::Basic::Statement::Read

######################################################################
# package Language::Basic::Statement::Rem
# A REM statement in a BASIC program.
{
package Language::Basic::Statement::Rem;
@Language::Basic::Statement::Rem::ISA = qw(Language::Basic::Statement);
sub parse {
    # Eat the whole line (including colons if any)
    my $self = shift;
    my $token_group = shift;
    my $tok = $token_group->eat_if_class("Comment");
    # Use original text to retain spaces and case.
    my $text = $tok->{"original_text"};
    $text =~ s/REM//;
    $self->{"comment"} = $text;
} # end sub Language::Basic::Statement::Rem::parse

sub output_perl {
    my $self = shift;
    # Need to have a semicolon because the line label requires a
    # statement after it. (And we need a line label in case we GOTO this line
    my $ret = "; # " . $self->{"comment"};
    return $ret;
} # end sub Language::Basic::Statement::Rem::output_perl

} # end package Language::Basic::Statement::Rem

######################################################################
# package Language::Basic::Statement::Return
# A RETURN statement in a BASIC program.
{
package Language::Basic::Statement::Return;
@Language::Basic::Statement::Return::ISA = qw(Language::Basic::Statement);
use Language::Basic::Common;

# No need to have a sub parse

sub implement {
    my $self = shift;
    my $prog = &Language::Basic::Program::current_program;
    my $gosub = $prog->pop_stack or
        Exit_Error("RETURN without GOSUB");
    # Start at the statement *after* the GOSUB statement
    $prog->goto_after_statement($gosub);
} # end sub Language::Basic::Statement::Return::implement

sub output_perl {
    my $ret = "\$Return_tmp = pop \@Gosub_Stack;\n";
    $ret .= "goto \$Return_tmp;";

    return ($ret);
} # end sub Language::Basic::Statement::Return::output_perl

} # end package Language::Basic::Statement::Return

1; # end of package Language::Basic::Statement
