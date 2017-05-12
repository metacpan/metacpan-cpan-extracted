package Language::Basic;
# by Amir Karger (See below for copyright/license/etc.)

=pod

=head1 NAME

Language::Basic - Perl Module to interpret BASIC

=head1 SYNOPSIS

    use Language::Basic;

    my $Program = new Language::Basic::Program;
    $Program->input("program.bas"); # Read lines from a file
    $Program->parse; # Parse the Program
    $Program->implement; # Run the Program
    $Program->output_perl; # output Program as a Perl program

    $Program->line("20 PRINT X"); # add one line to existing Program

Featured scripts:

=over 4

=item basic.pl

Runs BASIC programs from the command line.

=item termbasic.pl

Term::Readline program. Input one line of BASIC at a time, then run the
program.

=item basic2pl.pl

Outputs a Perl program that does the same thing as the input BASIC program.

=back

=head1 DESCRIPTION

This module lets you run any BASIC programs you may have lying around, or
may inspire you to write new ones!

The aspects of the language that are supported are described below. Note
that I was pretty much aiming for Applesoft BASIC (tm) ca. 1985, not some
modern BASIC with real subroutines.

=cut

use strict;
require 5.004; # I use 'foreach my'
use IO::File;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
);

# Stolen from `man perlmod`
$VERSION = do { my @r = (q$Revision: 1.44 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

# Sub-packages
use Language::Basic::Common;
use Language::Basic::Expression;
use Language::Basic::Function;
use Language::Basic::Statement;
use Language::Basic::Token;
use Language::Basic::Variable;

# sub-packages
{
package Language::Basic::Program;
package Language::Basic::Line;
}

######################################################################

=head2 Class Language::Basic::Program

This class handles a whole program. A Program is just a bunch of Lines,
each of which has one or more Statements on it. Running the program
involves moving through the lines, usually in numerical order, and
implementing each line.

Methods:

=over 4

=cut

{
package Language::Basic::Program;
use Language::Basic::Common;

# Fields:
# lines		Keys are line numbers, values are LB::Line objects
# curr_line	LB::Line currently being implemented/parsed/whatever
# end_program	Done implementing the program?
# stack		The subroutine stack. In BASIC, it's just a list of
# 		statements we GOSUB'ed from.
# data		The data holder (stuff from DATA statements, read by READ)
# parsed	Has this Program been parsed since the last time 
#		new lines were added?
# needed_subs	Functions whose perl-equivalent subs we need to print out 
#		at the end of the program. (Keys are names of subs, values
#		are sub descriptions.)
# column	Current column of the screen the program is printing to
sub new {
    my ($class, $infile) = @_;

    #Initialize the intrinsic functions
    &Language::Basic::Function::Intrinsic::initialize();

    my $in = {
	"lines" => {},
        "curr_line" => undef,
	"end_program" => 0,
        'stack' => [],
	"for_statements" => {},
        'data' => [],
        'parsed' => 0,
	"needed_subs" => {},
	"column" => 0,
    };
    bless $in, $class;
} # end sub Language::Basic::Program::new

=item current_program

Returns the program currently being parsed/implemented/whatever

=item set_current_program

Sets arg0 to be the Current Program

=cut

my $_Current_Program; # Gasp! It's an Evil Global Variable!
sub current_program {
    return $_Current_Program;
}
sub set_current_program {
    my $self = shift or die "LBP::set_current_program must have argument!\n";
    $_Current_Program = $self;
}

=item current_line

Returns the LB::line currently being parsed/implemented/whatever

=item set_current_line

Sets the current line in Program arg0 to be line I<number> arg1

=item first_line_number

Returns (not surprisingly) the first line number in Program arg0

=cut

sub current_line { return shift->{"curr_line"}; }
sub set_current_line {
    my $prog = shift; 
    my $num = shift;
    if (defined $num && exists $prog->{"lines"}->{$num}) {
	$prog->{"curr_line"} = $prog->{"lines"}->{$num};
    } else {
        $prog->{"curr_line"} = undef;
    }
}
sub first_line_number {return (sort {$a <=> $b} keys %{shift->{"lines"}})[0]; }

=item current_line_number

What line number in Program arg0 are we currently on?

=cut

sub current_line_number {
    my $prog = shift;
    my $line = $prog->current_line;
    return (defined $line ? $line->line_number : undef);
}

=item input

This method reads in a program from a file, whose name is the string arg0. It
doesn't do any parsing, except for taking the line number out of the line.

=cut

sub input {
    my ($self, $filename) = @_;
    $self->set_current_program;
    my $fh = new IO::File $filename;
    die "Error opening $filename: $!\n" unless defined $fh;
    my $old_num = -1;

    while (<$fh>) {
        next if /^\s*$/; # empty lines
	chomp;

	# Line Number
	my $line_num = $self->_add_line($_);
	defined $line_num
	    or die "Missing line number " .
		($old_num > 0 ? "after line $old_num\n" : "on first line\n");

	# In input files, we make sure lines are in numerical order. 
	# If they're not, it's most likely a bug.
	# Same is not true for a Term::Readline interpreter
	if ($line_num <= $old_num) {
	    die "Line $line_num: lines in file must be in increasing order.\n";
	}

	$old_num = $line_num;
    }
    close ($fh);

    # order the lines
    $self->_fix_lines;
    $self->{'parsed'} = 0;

} # end sub Language::Basic::Program::input

=item line

This method takes a line of BASIC (arg1, already chomped), forms a new LB::Line
with it, and adds it to the Program (arg0). It doesn't do any parsing,
except for taking the line number out of the line.

=cut

sub line {
    my $self = shift;
    $self->set_current_program;
    my $line = shift; # sans \n

    defined $self->_add_line($line) or die "Missing line number in line()!\n";
    $self->_fix_lines;
    $self->{'parsed'} = 0;
} # end sub Language::Basic::Program::line

sub _add_line {
    # takes the line (sans \n), returns the line number read or undef if there
    # is none.
    # You must call _fix_lines between _add_line and returning to the
    # user's program!

    my $self = shift;
    my $line = shift;

    # Line Number
    $line =~ s/^\s*(\d+)\s+// or return;
    my $line_num = $1;

    # Create an LB::Line with what's left of the line
    $self->{'lines'}{$line_num} = new Language::Basic::Line($line, $line_num);

    return $line_num;
} # end sub Language::Basic::Program::_add_line

# fix the ordering of the lines in the program
sub _fix_lines {
    my $self = shift;

    my @line_numbers = sort {$a <=> $b} keys %{$self->{"lines"}};

    for (my $i = 0; $i < @line_numbers - 1; $i++) { # process all but last
	my $line = $self->{'lines'}{ $line_numbers[$i] };
	$line->set_next( $line_numbers[ $i+1 ] );
    } 

    $self->{'lines'}{ $line_numbers[-1] }->set_next( undef );
} # end sub Language::Basic::Program::_fix_lines 

=item parse

This method parses the program, which just involves looping over the lines
in the program and parsing each line.

=cut

sub parse {
    my $self = shift;
    $self->set_current_program;

    return if $self->{'parsed'};

    $self->set_current_line($self->first_line_number);

    # Loop through the lines in the program, parse each
    while (defined (my $line = $self->current_line)) {
	#print $line->line_number," ",$line->{"text"},"\n";
	$line->parse;
	$self->set_current_line($line->get_next);
    }

    $self->{'parsed'} = 1;
} # end sub Language::Basic::Program::parse

=item implement

This method actually runs the program. That is, it starts on the first line,
and implements statements one at a time. It performs the statements on a
line in order, and goes from line to line in numerical order, unless a GOTO,
NEXT, etc. sends it somewhere else. It stops when it hits an END statement or
"falls off" the end of the program.

=cut

sub implement {
    my $self = shift;
    $self->set_current_program;
    # In case you're lazy & call implement w/out parsing first
    $self->parse unless $self->{'parsed'};

    # Zero stack, etc., start at beginning of program
    $self->start;
    # Mini-kludge to get the program running
    $self->goto_line($self->current_line_number);

    # Loop over statements while there are statements
    while (defined(my $curr_statement = $self->increment)) {

	# TODO create a "trace" command that prints out line numbers
	# for debugging
	#my $line = $self->current_line;
	#print $line->line_number," ",$line->{"text"},"\n";

	# Do the statement!
	# Hooray for OO; just call "implement" on everything!
	#print "Statement class ",ref($curr_statement),"\n";
	# Note that this may well change where the next &increment will go
	$curr_statement->implement;
    }

    #Done!
    # TODO Exit more gracefully?
} # end sub Language::Basic::Program::implement

# Return the next Statement we're supposed to execute, based on the Program's
# next_statement field. And set the default action for the subsequent call
# to increment, which is to do the next Statement in order. (Or return
# undef if the program is done.)
#
# In the simplest case, next_statement will just be the Statement after the
# current one on the current Line, although it my well be in a totally
# different place due to GOTOs, RETURNs, ELSEs or other interesting programming
# tools.
#
# If next_statement is undefined, we're done with this line (and haven't been
# directed to go somewhere more interesting), so go to the next line in order.
#
# TODO should this method be podded?
sub increment {
    my $self = shift;

    my $next;
    unless (defined($next = $self->{"next_statement"})) {
	# Program is at the end of a line
	my $line = $self->current_line;
	my $number = $line->get_next;

	# goto_line will set Program's next_statement
	# ($number = undef will set "end_program")
	$self->goto_line($number);
	$next = $self->{"next_statement"};
    }
    # Did we hit an END or "fall off" the last line of the program?
    return undef if $self->{"end_program"};

    # By default, we're going to go on to the next statement after this one
    $self->{"next_statement"} = $next->{"next_statement"};

    # Whether or not we were at end of line, we now know what next
    # Statement is, so return it.
    return $next;

}

=item start

This method erases program stack and moves line pointer to beginning of program

It should be called any time we start going through the program.
(Either implement or output_perl.)

=cut

# Don't erase "data". It's set during parsing.
sub start {
    my $self = shift;
    $self->{"stack"} = [];
    $self->{"for_statements"} = {};
    $self->{"column"} = 0;

    # Start on the first line of the program
    $self->set_current_line($self->first_line_number);
} # end sub Language::Basic::Program::start

=item goto_line

Continue Program execution at the first Statement on line number arg1. 

=cut

sub goto_line {
    my $self = shift;
    my $next_line = shift;

    if (defined $next_line) {
	$self->set_current_line($next_line);
        my $line = $self->current_line or
	    Exit_Error("Can't find line $next_line!");
	$self->{"next_statement"} = $line->{"first_statement"};
    } else {
        $self->{"end_program"} = 1;
    }

} # end sub Language::Basic::Program::set_next_line

=item goto_after_statement

Kind of like goto_line, except go to the Statement I<after> Statement arg1.
(Or the first statement on the line just after Statement arg1, if it's the last
Statement on its line.) E.g., when you RETURN from a GOSUB, you want to return
to the GOSUB line but start execution after the GOSUB. Same with FOR.

=cut

sub goto_after_statement {
    my $self = shift;
    my $st = shift;
    $self->{"next_statement"} = $st;
    # May have jumped to (the beginning or middle of) a new line,
    # so we have to reset this. (It stays the same if we're jumping w/in
    # one line, but that's OK.)
    $self->set_current_line($st->{"line_number"});

    # Goto the statement, and set Program's next_statement field, so
    # that when Program::implement calls increment, it goes to the
    # statement *after* this one.
    $self->increment;

} # end sub Language::Basic::Program::goto_after_statement

=pod

=back

The following methods are called from LB::Statement parse or implement
methods to implement various BASIC commands.

=over 4

=item push_stack

(GOSUB) Call a subroutine, i.e. push the current Statement::Gosub onto the
Program's calling stack

=item pop_stack

(RETURN) Return from a subroutine, i.e., pop the top Statement::Gosub off of
the Program's calling stack

=cut

sub push_stack {
    my $self = shift;
    my $st = shift;
    push @{ $self->{'stack'} }, $st;
}

sub pop_stack {
    my $self = shift;
    return pop @{ $self->{'stack'} };
}

=item store_for

(FOR) Store a Statement::For arg1, so that when we get to the corresponding
Statement::Next, we know where to go back to

=item pop_stack

(NEXT) Get the Statement::For corresponding to Statement::Next arg1

=cut

sub store_for {
    my $self = shift;
    my $for_statement = shift;
    my $lvalue = $for_statement->{"lvalue"};
    my $name = $lvalue->{"name"};
    $self->{"for_statements"}->{$name} = $for_statement;
} # end sub Language::Basic::Program::store_for

sub get_for {
    my $self = shift;
    my $next_statement = shift;
    my $lvalue = $next_statement->{"lvalue"};
    my $name = $lvalue->{"name"};
    if (exists $self->{"for_statements"}->{$name}) {
        return $self->{"for_statements"}->{$name};
    } else {
	Exit_Error("NEXT $name without FOR!");
    }
} # end sub Language::Basic::Program::get_for

=item add_data

(DATA) Add a piece of data to the Program's data storage, to be accessed
later.

=cut

sub add_data {
    my $self = shift;
    my $thing = shift;
    push @{ $self->{'data'} }, $thing;
}

=item get_data

(READ) Get a piece of data that was stored earlier. 

=cut

sub get_data {
    my $self = shift;
    @{ $self->{'data'} } or Exit_Error("More items READ than input in DATA!");
    my $thing = shift @{ $self->{'data'} }; 
    return $thing;
}

=pod

=back

Finally, there are methods for translating a Program to Perl.

=over 4

=item output_perl

This method translates a program to Perl and outputs it. It does so by
looping through the Lines of the program in order, and calling output_perl on
each one.  It also prints some pre- and post- data, such as any subroutines it
needs to declare (e.g., subs that imitate BASIC functionality, as well as subs
that correspond to BASIC DEF statements).

It attempts to print everything out nicely, with added whitespace et al.  to
make the code somewhat readable.  (Note that all of the subpackages'
output_perl methods I<return> strings rather than printing them, so we can
handle all of the printing, indenting, etc. here.)

=cut

sub output_perl {
    my $self = shift;
    $self->set_current_program;
    # In case you're lazy & call implement w/out parsing first
    $self->parse unless $self->{'parsed'};

    my $sep = '#' x 78;
    # TODO these variables should be changeable by switches to basic2pl!
    my $spaces_per_indent = 4;
    # Indenting for outputted Perl
    my $Output_Indent = 2; # eight spaces by default

    # Beginning of the program
    # TODO should basic2pl do these two lines?
    print '#!/usr/bin/perl -w';
    print "\n#Translated from BASIC by basic2pl\n\n";

    if (@{$self->{"data"}}) {
	print "$sep\n# Setup\n#\n";
	print "# Read data\n";
        print "while (<DATA>) {chomp; push \@Data, \$_}\n\n";
    }

    # Zero program stack, etc., start at beginning of program
    $self->start;

    # Loop through the lines in the program
    print "$sep\n# Main program\n#\n";
    while (defined (my $line = $self->current_line)) {
	my $line_num = $line->line_number;
	#warn "Line $line_num\n";
	my $label = "L$line_num:";

	# What's the line?
	my $out = $label . $line->output_perl;
	
	# Print labels all the way against the left edge of the line,
	# then indent the rest of the line.
	# Split with -1 so final \n's don't get ignored
	foreach (split (/\n/, $out, -1)) {
	    # Change indenting for next time?
	    $Output_Indent += 1, next if $_ eq "INDENT";
	    $Output_Indent -= 1, next if $_ eq "UNINDENT";
	    warn "weird indenting $Output_Indent\n" if $Output_Indent < 2;

	    # If we didn't hit an indent-changing command, print the
	    # label (if any) and the actual string
	    # TODO only print out the labels we have to!
	    $label = (s/^A?L\d+:// ? $& : "");
	    # minus for left justify
	    my $indent = -$Output_Indent * $spaces_per_indent; 
	    printf("%*s", $indent, $label);

	    # print the actual string
	    print $_;
	    print "\n"; # the \n we lost from split, or the last \n
	}

	# Go through lines in order
	$self->set_current_line($line->get_next);
    }

    # TODO why not indent these nicely?
    my $n = $self->{"needed_subs"};
    print "\n$sep\n# Subroutine Definitions\n#\n" if %$n;
    # Print out required subroutines
    foreach (sort keys %$n) {
        my $out = join(" ", "sub", $_, $n->{$_}, "# end sub $_\n\n");
	$Output_Indent = 0;

	foreach (split (/\n/, $out, -1)) {
	    # Change indenting for next time?
	    $Output_Indent += 1, next if $_ eq "INDENT";
	    $Output_Indent -= 1, next if $_ eq "UNINDENT";
	    warn "weird indenting $Output_Indent\n" if $Output_Indent < 0;

	    # If we didn't hit an indent-changing command, print the string
	    my $indent = $Output_Indent * $spaces_per_indent; 
	    print " " x $indent;

	    # print the actual string
	    print $_;
	    print "\n"; # the \n we lost from split, or the last \n
	}
    }

    # If there were any DATA statements...
    if (@{$self->{"data"}}) {
        print "\n\n$sep\n# Data\n#\n__DATA__\n";
	print join("\n", map {$_->output_perl} @{$self->{"data"}});
	print "\n";
    }
} # end sub Language::Basic::Program::output_perl

=item need_sub

Tells the Program that it needs to use the sub named arg0 (whose definition
is in arg1). This is used for outputting a Perl translation of a BASIC
program, so that you only write "sub mid_str {...}" if MID$ is used in
the BASIC program.

=back

=cut

sub need_sub {
    my $self = shift;
    my $n = $self->{"needed_subs"};
    my ($func_name, $func_desc) = @_;
    return if exists $n->{$func_name};
    $n->{$func_name} = $func_desc;
} # end sub Language::Basic::Program::need_sub

} # end package Language::Basic::Program

######################################################################

=head2 Class Language::Basic::Line

This class handles one line of a BASIC program, which has one or more
Statements on it.

This class has no implement method. The reason is that sometimes, you'll
jump to the middle of a line. (E.g., returning from the GOSUBs in
10 FOR A=1 TO 10: GOSUB 1000: NEXT A)

Methods:

=over 4

=cut

{
package Language::Basic::Line;
use Language::Basic::Common;

# Make a new LB::Line with the text given (don't parse it yet)
sub new {
    my $class = shift;
    my $text = shift;
    my $line_number = shift;
    my $in = {
	# literal text of the line (not including line number)
	"text" => $text,
	# Pointer to first LB::Statement on the line
	"first_statement" => 0,
	# number of next line (accessed with set/get_next)
	'next_line' => undef,
	# BASIC line number of this Line
	"line_number" => $line_number,
    };
    bless $in, $class;
} # end sub Language::Basic::Line::new

=item get_next

Returns the Line's line number

=cut

sub line_number { shift->{"line_number"} }

=item get_next

Returns the next line number in the Program

=item set_next

Sets the next line number in the Program to be arg1.

=cut

sub get_next { return shift->{'next_line'}; }

# TODO Should this be _set_next and undocumented? Only gets called by _fix_lines
sub set_next {
    my $self = shift;
    my $next = shift;

    $self->{'next_line'} = $next;
} # end sub Language::Basic::Line::set_next

=item parse

This method breaks the line up into Statements (and removes whitespace, except
in strings), then parses the Statements in order.

=cut

sub parse {
    my $self = shift;

    # Break the line up into Tokens for later eating/parsing
    my $token_group = new Language::Basic::Token::Group;
    $token_group->lex($self->{"text"});
    my $oldst;

    # Parse Statement(s) in the Line
    do {
	# Create the new Statement and figure out what kind of statement it
	# is.  $statement will be an object of a subclass LB::Statement::*)
	my $statement = new Language::Basic::Statement $token_group;

	# Actually parse the Statement
	$statement->parse($token_group);

	# Each statement needs to know which line it's on, in case we
	# RETURN or NEXT into the middle of a line.
	$statement->set_line_number($self->{"line_number"});

	# Create a linked list of the Statements in the line
        if (defined $oldst) {
	    $oldst->{"next_statement"} = $statement
	} else {
	    $self->{"first_statement"} = $statement;
	}
	$oldst = $statement;

    # If there's a colon, eat it and parse the next Statement on the Line
    } while ($token_group->eat_if_class("Statement_End"));

    # TODO make this error prettier
    if ($token_group->stuff_left) {
        my $p = "Extra tokens left after parsing!\n" . $token_group->print;
	chomp($p);
	Exit_Error($p);
    }
}

=item output_perl

This method simply calls output_perl on each of the Line's Statements in
order.

=back

=cut

sub output_perl {
    my $self = shift;
    my $statement = $self->{"first_statement"};
    my $out = $statement->output_perl;
    # Do each statement in the line in order
    # Put each statement on a separate line.
    while (defined ($statement = $statement->{"next_statement"})) {
	$out .= "\n";
	$out .= $statement->output_perl;
    }

    # Output the statement
    return $out;
} # end sub Language::Basic::Line::output_perl

} # end package Language::Basic::Line


# end package Language::Basic
1;

__END__
# More Docs

=head1 BASIC LANGUAGE REFERENCE

This is a (hopefully current) description of what Language::Basic supports.
For each command, I give an example use of that command, and possible
a comment or two about it.

Also see L<Language::Basic::Syntax>, which describes
the exact syntax for each statement, expressions, variable names, etc.

=head2 Commands

=over 4

=item DATA

DATA 1,2,"HI". These will be read sequentially by READ statements. Note
that currently all string constants must be quoted.

=item DEF

DEF FNA(X)= INT(X + .5). 

=item DIM

DIM A(20), B(10,10). Arrays default to size 10 (or actually 11 since they
start at zero.)

=item END

END.

=item FOR

FOR I = 1 TO 10 STEP 3. STEP defaults to 1 if not given, and may be negative.
(For loops are always implemented at least once.)

=item GOTO

GOTO 30. Note that GOTO 30+(X*3) is also supported.

=item GOSUB

GOSUB 10+X. Gosub is just like GOTO, except that when the program gets to
a RETURN statement, it will come back to the statement just after the GOSUB.

=item IF

IF X > Y THEN 30 ELSE X = X + 1. ELSE is not required. In a THEN or ELSE,
a lone number means GOTO that number (also known as an implied GOTO).

=item INPUT

INPUT A$, B$. Also allowed is INPUT "FOO"; BAR. This prints "FOO?" instead of
just "?" as the input prompt.

=item LET

LET X=4. The word "LET" isn't required; i.e. X=4 is just like LET X=4.

=item NEXT

NEXT I. Increment I by STEP, test against its limit, go back to the FOR
statement if it's not over (or under, for a descending loop) its limit.

=item ON

ON X-3 GOSUB 10,20. This is equivalent to: 
  IF X-3 = 1 THEN GOSUB 10
  IF X-3 = 2 THEN GOSUB 20

ON ... GOTO is also allowed.

=item PRINT

PRINT FOO; BAR$, 6*BLAH. semicolon means no space (or one space after printing
numbers!), comma is like a 14-character tab (or \n past column 56).
Print \n after the last expression unless there's a semicolon after it.

=item READ

READ A, B(I), C$. Reads data from DATA statements into variables

=item REM

REM WHATEVER. Anything after the REM is ignored (including colons and
succeeding statements!)

=item RETURN

RETURN. Return to the statement after the last GOSUB.

=back

=head2 Intrinsic functions

The following functions are currently supported:

Numeric Functions: INT (like Perl's int), RND (rand), ASC (ord), 
LEN (length), VAL (turn a string into a number; in Perl you just + 0 :))

RND just calls Perl's rand; you can't seed it or anything.

String functions: CHR$, MID$, STR$

=head2 Overall Coding Issues

=over 4

=item *

Multiple statements can appear on one line, separated by colons. E.g.:
10 FOR I = 1 TO 10: PRINT I: NEXT I, or 20 FOR A = 1 TO 4: GOSUB 3000: NEXT A.
Note that after a THEN, all statements are considered part of the THEN,
until a statement starting with ELSE, after which all remaining statements are
part of the ELSE. A REM slurps up everything until the end of the line,
including colons.

=item * 

Hopefully your code doesn't have many bugs, because there isn't
much error checking.

=item *

Everything except string constants is converted to upper case, so 'a' and 'A'
are the same variable. (But note that the string "Yes" <> "YES", at least
for now.)

=item *

Spaces are (currently) required around various pieces of the program, like
THEN, ELSE, GOTO. That is, GOTO20 won't work. This may or may not change
in the future.

=item *

When you use basic.pl (&LB::Program::input), the lines in the input file must
be in numerical order. When using termbasic.pl (&LB::Program::line), this
rule doesn't apply.

=back


=head1 BUGS

This is an alpha release and likely contains many bugs; these are merely
the known ones.

If you use multiple B<Language::Basic::Program> objects in a Perl program,
functions and variables can leak over from one to another.

It is possible to get some Perl warnings; for example, if you input a string
into a numerical variable and then do something with it.

B<PRINT> and so forth all go to the select-ed output handle; there really 
ought to be a way to set for a B<Program> the output handle.

There needs to be better and consistent error handling, and a more
extensive test suite.

=head1 AUTHOR

Amir Karger (akarger@cpan.org)

David Glasser gave ideas and feedback, hunted down bugs, and sent in a major
patch to help the LB guts.

=head1 COPYRIGHT

Copyright (c) Amir Karger 2000

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 HISTORY

BASIC stands for Beginner's All-purpose Symbolic Instruction Code. Since it
was considered pretty hot stuff in the early 80's, it's the first language that
I and a lot of folks my age learned, so it holds a special place in my heart.
Which is the only reason I spent so many hours writing an interpreter for it
long after it was superseded by real interpreted languages that had subroutines
and didn't rely quite so much on GOTO.

I originally wrote this interpreter in C, as the final project for my first
C programming class in college. Its name at that point was COMPLEX, which
stood for "C-Oriented Major Project which did not use LEX".

When I learned Perl, I felt like its string handling capabilities would be
much better for an interpreter, so eventually I ported and expanded it. 
(Incidentally, I was right. I had surpassed the original program's
functionality in less than a week, and I was able to run wumpus in 2.)

A big goal for the Perl port is to support enough of the language that I can
run wumpus, another legacy from my childhood.  The interpreter's name could be
changed from COMPLEX to "Perl Eclectic Retro interpreter which did not use
Parse::LEX", or PERPLEX, but I settled for Language::Basic instead.

=head1 SEE ALSO

All of the L<Language::Basic::*>s associated with Language::Basic sub-modules

L<Language::Basic::Syntax>, which describes the syntax supported by
the Language::Basic module

perl(1), wump(6)

=cut
