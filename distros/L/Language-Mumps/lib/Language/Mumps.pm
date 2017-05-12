# PerlMUMPS by Ariel Brosh
# Usage is free, including commercial use, enterprise and legacy use
# However, any modifications should be notified to the maintainer
# Email: smueller@cpan.org

# Note:
# This compiler parses and generates in the same phase, therefore is not
# very maintainable

package Language::Mumps;
$VERSION = '1.08';
use Fcntl;
use strict;
use vars qw($FETCH $STORE $DB $SER $IMPORT @TYING $xpos $ypos
  %symbols $selected_io $flag @handlers @xreg @yreg
  $curses_inside $varstack %RES $RESKEYS %COMMANDS $scope_do
  %FUNCTIONS %FUNS @tmpvars $tmphash $infun $scopes @stack
  @program %bookmarks $lnum $forgiveful $forscope %dbs
  $VERSION);

# Map short form to long form commands

%COMMANDS = qw(B BREAK C CLOSE D DO E ELSE F FOR G GOTO HALT HALT
               H HANG I IF J JOB K KILL L LOCK O OPEN Q QUIT
               R READ S SET U USE V VIEW W WRITE X XECUTE
               ZE HALT ZP ZP ZFUNCTION ZFUNCTION
               ZRETURN ZRETURN ZD ZD);

# Map short form to long form functions

%FUNCTIONS = qw(I IO T TEST P PIECE H HOROLOG J JOB 
                 X X Y Y ZDATE ZD ZA ZN);

# Function schema
# array of: funcname => array of | lval => 1/0, prot => prototype
# If lval is 1, function can be use as lvalue.
# prototype has one char per function parameter.
# I = input O = output L = list T = tuple

%FUNS = (
         'ASCII' => [{'lval' => 0, 'prot' => 'II'},
                     {'lval' => 0, 'prot' => 'I'}],
         'CHAR' => [{'lval' => 0, 'prot' => 'L'}],
         'DATA' => [{'lval' => 0, 'prot' => 'O'}],
         'EXTRACT' => [{'lval' => 0, 'prot' => 'I'},
                       {'lval' => 0, 'prot' => 'II'},
                       {'lval' => 0, 'prot' => 'III'}],
         'FIND' => [{'lval' => 0, 'prot' => 'II'},
                     {'lval' => 0, 'prot' => 'III'}],
         'JOB' => [{'lval' => 0, 'prot' => ''}],
         'JUSTIFY' => [{'lval' => 0, 'prot' => 'II'},
                     {'lval' => 0, 'prot' => 'III'}],
         'HOROLOG' => [{'lval' => 0, 'prot' => ''}],
         'IO' => [{'lval' => 1, 'prot' => ''}],
         'LEN' => [{'lval' => 0, 'prot' => 'II'},
                     {'lval' => 0, 'prot' => 'I'}],
         'NEXT' => [{'lval' => 0, 'prot' => 'O'}],
         'ORDER' => [{'lval' => 0, 'prot' => 'O'}],
         'PIECE' => [{'lval' => 1, 'prot' => 'OII'},
                 {'lval' => 0, 'prot' => 'III'},
                 {'lval' => 0, 'prot' => 'IIII'}],
         'RANDOM' => [{'lval' => 0, 'prot' => 'I'}],
         'SELECT' => [{'lval' => 0, 'prot' => 'T'}],
         'TEST' => [{'lval' => 1, 'prot' => ''}],
         'X' => [{'lval' => 0, 'prot' => ''}],
         'Y' => [{'lval' => 0, 'prot' => ''}],
         'ZAB' => [{'lval' => 0, 'prot' => 'I'}],
         'ZB' => [{'lval' => 0, 'prot' => 'I'}],
         'ZCD' => [{'lval' => 0, 'prot' => ''},
                   {'lval' => 0, 'prot' => 'I'}],
         'ZCL' => [{'lval' => 0, 'prot' => ''},
                   {'lval' => 0, 'prot' => 'I'}],
         'ZD' => [{'lval' => 0, 'prot' => ''}],
         'ZD1' => [{'lval' => 0, 'prot' => ''}],
         'ZD2' => [{'lval' => 0, 'prot' => 'I'}],
         'ZD3' => [{'lval' => 0, 'prot' => 'III'}],
         'ZD4' => [{'lval' => 0, 'prot' => 'III'}],
         'ZD5' => [{'lval' => 0, 'prot' => 'III'}],
         'ZD6' => [{'lval' => 0, 'prot' => 'I'},
                  {'lval' => 0, 'prot' => ''}],
         'ZD7' => [{'lval' => 0, 'prot' => 'I'},
                  {'lval' => 0, 'prot' => ''}],
         'ZD8' => [{'lval' => 0, 'prot' => 'I'},
                  {'lval' => 0, 'prot' => ''}],
         'ZD9' => [{'lval' => 0, 'prot' => 'I'},
                  {'lval' => 0, 'prot' => ''}],
         'ZDBI' => [{'lval' => 0, 'prot' => 'IIIIO'}],
         'ZF' => [{'lval' => 0, 'prot' => 'I'}],
         'ZH' => [{'lval' => 0, 'prot' => 'I'}],
         'ZL' => [{'lval' => 0, 'prot' => 'II'},
                  {'lval' => 0, 'prot' => 'I'}],
         'ZN' => [{'lval' => 0, 'prot' => 'I'}],
         'ZR' => [{'lval' => 0, 'prot' => 'I'}],
         'ZS' => [{'lval' => 0, 'prot' => 'I'}],
         'ZSQR' => [{'lval' => 0, 'prot' => 'I'}],
         'ZT' => [{'lval' => 0, 'prot' => 'I'}],
         'ZVARIABLE' => [{'lval' => 0, 'prot' => 'I'}],
         );

####
## M line to Perl line

sub m2pl {
    my $line = shift;

# Convert 8 spaces to a tab if -f used
# M requires lines to begin with tabs

    $line =~ s/^(\w+) {8}/$1\t/ if ($forgiveful);

# Embedded perl code

    if ($line =~ s/^\%//) {
        return "$line\n";
    }

# Comment

    if ($line =~ s/^\#//) {
        return "";
    }

# Does not begin with a tab - plain text

    unless ($line =~ /\t/) {
        return "Language::Mumps::write('$line');\n";
    }

# Reset variable factory

    &resetvars;

    my ($label, $llin) = split(/\s*\t\s*/, $line, 2);
    $line = $llin;

# Labels must begin with a letter

    die "Illegal label $label" unless (!$label || $label =~ /^[a-z]\w*/i);

# Bookmarks are for source listing. Available only if M program was
# compiled and executed inside the same Perl script

    $bookmarks{$label} = $lnum;
    $label = "__lbl_Mumps_$label\: " if ($label);

# Do the actual work
    $label . &ml2pl($line);
}

sub ml2pl {
    my $line = shift;
    my ($res, $tmp, $code);

# M commands may be several in a line

    while ($line) {
        my ($token, $cond, $pre, $post);

# "Eat" one token, cancelling spaces.

        if ($line =~ s/^\s*(\S*?)\s+//) {
            $token = $1;
        } else {
            $token = $line;
            $line = '';
        }

# Close block

        if ($token eq '}') {
            die "Unexpected right bracket" unless ($scopes--);
            $code .= "}\n";
            next;
        }

# Command:Condition - Run the command conditionally

        if ($token =~ /^([a-z]\w*):(.*)$/i) {
            $token = $1;
            $cond = $2;
        }

        if ($cond) {
            ($pre, $tmp) = &makecond($cond);
            $pre .= "if ($tmp) {\n";
            $post = "\n}";
        }

        $token = uc($token);

#        my ($k, $v);
        foreach (keys %COMMANDS) {
# If $token is either short or long form of command, call function

            if ($_ eq $token || $COMMANDS{$_} eq $token) {
# $line is passed *by reference*

                $res = &{$COMMANDS{$_}}($line);

# Kill spaces

                $line =~ s/^\s*//;
                goto success;
            }
        }
        die "Unrecognized command $token";
success:
        $code .= "$pre$res$post\n";
    }
    $code;
}

####
## Convert a block of M code to a block of Perl code

sub compile {
    my $text = shift;
    my @lines = split(/\r?\n/, $text);
    %bookmarks =();
    @program = @lines;
# Stack based scope for $scopes - push the scope counter to the stack
# until the end of the function

    local($scopes);
    $lnum = 0;
# Iterate over code

    my @code = map {++$lnum; "# $lnum) $_\n" . &m2pl($_);} @lines;
# Ensure we close all blocks

    die "Unclosed brackets" if ($scopes);

# Add essential code
# mumps.cfg will be read only by the compiler, not by programs
    join("", "use Language::Mumps qw(Runtime $IMPORT);\nno strict;\n",  @code,
              "### end\n", &m2pl("\tQUIT"));
}

####
## Compile an M program and evaluate immediately

sub evaluate {
    my $prog = shift;
    my $code = &compile($prog);
    local (@stack);
    $@ = undef;
    eval $code;
    die $@ if ($@);
}

####
## Read an M program from a file, compile and run

sub interprete {
    my $fn = shift;
    open(I, $fn);
    my $prog = join("", <I>);
    close(I);
    evaluate($prog);
}

####
## Translate an M file to a Perl file

sub translate {
    my ($i, $o) = @_;
    open(I, $i);
    my $prog = join("", <I>);
    close(I);
    my $code = &compile($prog);
    open(O, ">$o");
    print O <<EOM;
#############################################################################
# This Perl script was created by the MUMPS to Perl compiler by Ariel Brosh #
#############################################################################

$code

1;
EOM
    close(O);
}

####
## Return a line of the program
## Not thread safe - supports only one M program per Perl script

sub list {
    my ($line, $off);
    my $lnum = ($line > 0) ? ($line - 1) : $bookmarks{$line} || die "Unknown label";
    $program[$lnum - 1 + $off];
}

######################################################################
## COMMANDS                                                         ##
######################################################################
## Each function receives a line of code *by reference*, removes    ##
## input tokens as they are "eaten" and returns Perl code to add to ##
## the output.                                                      ##
######################################################################


####
## BREAK - Stop the program

sub BREAK {
    return "exit;";
}

####
## CLOSE
## Add code to create a list of parameters
## Add code to iterate through them and close file objects

sub CLOSE ($) {
    my ($code, $var) = &makelist($_[0]);
    return $code . <<EOM;
foreach ($var) {
    die "Can't CLOSE unit 5" if (\$_ == 5);
    close($Language::Mumps::handlers[\$_]);
}
EOM
}

####
## DO
## DO label - jump to the label. Create a label for returning.
##    Add code to push this label to the stack.
## DO "program" or DO @var - Interprete another program
##    Add code to invoke the interprete method.
##    (Will make program listing useless)
## DO $$<expr> - Call a perl function. Test flag is set to the
##    non zeroeness of the return.

sub DO ($) {
    if ($_[0] =~ s/^\s*([a-z]\w*)\b//i) {
        my $dest = $1;
        ++$scope_do;
        my $lbl = &nextvar("d$scope_do");
        return <<EOM;
push(\@Language::Mumps::stack, '$lbl');
goto __lbl_Mumps_$dest;
$lbl:
EOM
    }
    if ($_[0] =~ /^[\@"]/) {
        $_[0] =~ s/^\@//;
        my ($code, $var) = &makeexp($_[0]);
        return $code . "Language::Mumps::interprete($var);";
    }
    if ($_[0] =~ /^\$\$/) {
        my ($code, $var) = &makeexp($_[0]);
        return $code . "\$Language::Mumps::flag = $var ? 1 : undef;";
    }
    $_[0] =~ s/\s.*$//;
    die "Illegal argument for DO $_[0]";
}

####
## ELSE - Things to do if the test flags is false.
##    Usually but not necessarily after IF.
## Add code to check test flag and -
## If called with { - Increase the scope counter, leave Perl code
## in a block
## If called with a list of commands - call the interpreter recursively
## to interprete the rest of the line, put it inside the conditional
## block.

sub ELSE ($) {
    my $code = "unless (\$Language::Mumps::flag) {";
    if ($_[0] =~ s/^\{\s*//) {
        $scopes++;
        return $code;
    }
    my $block = &ml2pl($_[0]);
    "$code\n$block}";
}

####
## FOR var=token,token,token
##  Make a Foreach over the list.
##  Token can be: start:step:last

sub FOR ($) {
    unless ($_[0]) {
        die "Iterator expected in FOR";
    }

## Construct the iteration variable
    my ($itercode, $lvar) = &makevar($_[0]);

## Get Perl code to represent lvalue
    my $var = $lvar->lval;

## Allocate an iteration var
    my $itervar = &nextvar();

## Allocate a var to hold the list
    my $eachlist = &nextvar('@');
# Allocate vars to hold from, to, step
    my $f = &nextvar('$');
    my $t = &nextvar('$');
    my $s = &nextvar('$');

# Code to attach the Perl iteration var to a symbol table entry of the
# selected LValue. (Needed to support complex access)

    $itercode .= "*$itervar = \\$var;\n";

# From now on, $var is the soft reference to $var

    $var = "\$$itervar";
    die "= expected in FOR" unless ($_[0] =~ s/^\=//);

# Code inside the loop will be stored in a subroutine
# This way we can forward-rely on it
# All procedures will have a unique identifier

    my $procname = "__tmpfor" . ++$forscope;
    my ($flag, $listflag);
    my $first = 1;

# "Eat" the remainder of the parameter
    while (1) {
# Set $flag to true if we are in the end of the input
        $flag = 1 unless ($_[0] && $_[0] !~ /^\s/);
# Unless it is the first token, or input has ended, we must skip a comma
        die "Comma expected in FOR" unless ($first || $_[0] =~ s/^,// || $flag);
# No more first token
        $first = undef;
# "Eat" value
        my ($code, $val) = &makeexp($_[0]);
        if ($flag || $_[0] =~ s/^\://) {
# If we are in the end of input, or we have a compund token,
# we have to flush the simple tokens.
            $itercode .= "foreach \$var ($eachlist) " .
                 "{&$procname;}\n\$eachlist = ();\n" if ($listflag);
            last if ($flag);
# If we got here, it is a compound token
            $listflag = undef;
# Add the code to evaluate the loop start, and to assign it to the
# loop start variable
            $itercode .= $code;
            $itercode .= "$f = $val;\n";

# Get the step value. Note: we have already skipped the colon.
            ($code, $val) = &makeexp($_[0]);
            $itercode .= $code;
            $itercode .= "$s = $val;\n";

# If we have got more input, it must be delimited with a colon

            if ($_[0] && $_[0] !~ /^[,\s]/) {
                die "Upper bound expected in FOR" unless ($_[0] =~ s/^://);
# "Eat" the to value.
                my ($code, $val) = &makeexp($_[0]);
                $itercode .= $code;
                $itercode .= "$t = $val;\n";
            } else {
# Infinite loop requested. (M dictates this syntax)
# If To is two Steps below From, we probably will never
# Reach To.
                $itercode .= "$t = $f - $s * 2;\n";
            }
# Obsolete sick code
#            my $sign = (qw(< == >))[($f <=> $t) + 1];
#            my $step = (qw(+ + -))[($f <=> $t) + 1];
#            my $cond = ($t ? "$var $sign $t" : 1);
#            my $incr = (abs($s) == 1) ? ($var . ($step x 2))
#                    : "$var $step= " . abs($s);

# Generate for(;;) code.
# Make To run away one step. This way the original To value is still
# inside the loop.
# We check if the iterator is still different from To, and if it is
# in the same direction as From was for.
            my $for = "($var = $f, $t += $s; " .
              "$var != $t && ($var <=> $t) == ($f <=> $t); " .
              "$var += $s)";
            $itercode .= "for $for {\&$procname;}\n";
        } else {
# Simple token - add to list
            $itercode .= $code . "push($eachlist, $val);\n";
            $listflag = 1;
        }
    }
# Dismiss soft reference

    $itercode .= "*$itervar = \\\$sysundef;\n";
    $_[0] =~ s/^\s*//;
    die "Code expected in FOR" unless ($_[0]);

# Define the subroutine we "owe"
# Either open a block, or call the interpreter recursively to
# translate the rest of the line into the subroutine

    $itercode .= "sub $procname {\n";
    if ($_[0] =~ s/^\{\s*//) {
        $scopes++;
        return $itercode;
    }
    my $code = &ml2pl($_[0]);
    $_[0] = '';
# Dixi et salvavi, Anima meam!
    return "$itercode$code\n}";
}

####
## GOTO label
## Translate to perl gotos, do not check label existence

sub GOTO ($) {
    if ($_[0] =~ s/^([a-z]\w*)\b//i) {
        return "goto __lbl_Mumps_$1;";
    }
    $_[0] =~ s/\s.*$//;
    die "Illegal label in GOTO: $_[0]";
}

####
## HALT - exit the program

sub HALT {
    return "exit;";
}

####
## HANG - Exit if no parameter, Sleep if parameter attached
sub HANG ($) {
    return "exit;" unless ($_[0]);
    my ($code, $var) = &makeexp($_[0]);
    return $code . "sleep($var);";
}

####
## IF
## Load the test flag, then make a block conditional to the test flag
## Block creation like in FOR or ELSE

sub IF ($) {
    die "Condition expected in IF" unless ($_[0]);
    my ($code, $val) = &makeexp($_[0]);
    my $condcode = $code . "\$Language::Mumps::flag = $val ? 1 : undef;\nif (\$Language::Mumps::flag) {\n";
    $_[0] =~ s/^\s*//;
    die "Code expected in IF" unless ($_[0]);
    if ($_[0] =~ s/^\{//) {
        $scopes++;
        return $condcode;
    }
    $code = &ml2pl($_[0]);
    $_[0] = '';
    return "$condcode$code\n}";
}

####
## JOB - unsopported

sub JOB {
    die "Not implemented: JOB";
}

####
## KILL - kill the whole symbol table
## KILL var - kill one symbol or array
## KILL (var) - kill everything besides one symbol

sub KILL ($) {
## No parameter - kill everything
    unless ($_[0]) {
        return "%Language::Mumps::symbols = ()";
    }
    my $rev;
    my $thecode;
#    my $cond = "if";
# Allocate a var name to hold a copy of the symbol table
    my $tmptbl = &nextvar();

# Check if we have paranthesis
    if ($_[0] =~ s/^\(//) {
        $rev = 1;
    }
# Prepare a hash to store the copied symbol table

    $thecode = "{ my \%$tmptbl;\n";
    my $n;
    while ($_[0] && $_[0] !~ /^\s/) {
        $n++;
        last if ($n == 2 && $rev && $_[0] =~ s/^\)>//);
        die "Variable expected in KILL" unless ($_[0] =~ /^\^?\w/);
        my ($code, $var) = &makevar($_[0]);
        die "Can unkill only regular arrays" if ($rev && ref($var) !~ /var/i);
        my $addr = $var->addr;
# Either extract the variable purge code, or call runtime function
# to deep copy the chosen var into the new symbol table
# entry
        $thecode .= $code . (!$rev
                ?  $var->purge . "\n"
                : "&Language::Mumps::moveimage(\\\%Language::Mumps::symbol, \\\%$tmptbl, " .
                        "$addr);\n"
           );
    }
# If unkilling, deep copy the symbol table back
    if ($rev) {
        $thecode .= <<EOM;
\%Language::Mumps::symbol = ();
foreach (keys \%$tmptbl) {
    \$Language::Mumps::symbol{\$_} = \$$tmptbl\{\$_};
}
EOM
    }
    chomp $thecode;
    $thecode;
}

####
## LOCK ^array - lock an array database. Implemented only for disk mapped
## arrays
## LOCK - With no parameters, remove any previous locks.

sub LOCK ($) {
    unless ($_[0]) {
    return <<EOM;
foreach (\@Language::Mumps::locks) {
    flock(\$_, 8);
}
\@Language::Mumps::locks = ();
EOM
    }
# Get the var
    my ($code, $var) = &makevar($_[0]);
    die "Only one array can be LOCKed" if ($_[0] && $_[0] !~ /^\s/);
# Get the dereferencing to the database
    my $ext = $var->getdb;
    my $tdb = &nextvar('$');
    my $fd = &nextvar('$');
return <<EOM;
$tdb = $ext;
$fd = $tdb->fd;
die "LOCK: flock: $!" unless flock($fd, 6);
push(\@Language::Mumps::locks, $fd);
EOM
}

####
## OPEN file-number:open-string
## open-string = filename/method
## method = NEW|OLD|APPEND

sub OPEN ($) {
# Allocate a variable to hold the stream number
    my $opennum = &nextvar('$');
# Allocate a variable to hold the parse tokens of the open string
    my $tokens = &nextvar('@');
# Allocate two vars to hold the actual tokens
    my $ofn = &nextvar('$');
    my $omet = &nextvar('$');
# "Eat" the expression for the file number
    my ($code, $var) = &makeexp($_[0]);
    die ": expected in OPEN" unless ($_[0] =~ s/^\://);
    $code .= "$opennum = $var;\n";
# "Eat" the open string
    my ($code2, $var2) = &makeexp($_[0]);
# Generate code
    $code . $code2 . <<EOM;
die "Can't reOPEN unit 5" if ($opennum == 5);
($ofn, $omet) = $tokens = split(/\\//, $var2);
die "Illegal OPEN string" unless (scalar($tokens) == 2 &&
    grep /^$omet\$/i, qw(NEW OLD APPEND));
\$Language::Mumps::handlers[$opennum] = "F" . $opennum;
open(\$Language::Mumps::handlers[$opennum],
    {NEW => '>', APPEND => '>>', OLD=> '<'}->{uc($omet)} . $ofn);
\$Language::Mumps::handlers[$opennum] = \*{\$Language::Mumps::handlers[$opennum]};
EOM
}

####
## QUIT
## End a subroutine or the whole program

sub QUIT {
    return <<EOM;
if (\@Language::Mumps::stack) {
    goto &{pop \@Language::Mumps::stack};
}
exit;
EOM
}

####
## READ var,var.... Read variables
## READ *var - Read one keypress, return ASCII code (with Curses)
##    Test flag will be false if we read nothing
## READ ?seconds,var - Read with timeout
## READ "prompt",var

sub READ ($) {
    my ($result, $timeout, $done);
    while ($_[0] && $_[0] !~ /^\s/) {
# Iterate over arguments
        die "Comma expected in READ" unless (!$done++ || $_[0] =~ s/^,//);
# If we have a varname
        if ($_[0] =~ /^\*?[a-z^]/i) {
            my $icode = "&Language::Mumps::read";
# Skip asterik if any, and decide we read one char
            if ($_[0] =~ s/^\*//) {
                $icode = "ord(&Language::Mumps::readkey)";
            }
# In both cases, reading uses a runtime function
            my ($code, $lvar) = &makevar($_[0]);

# Extract lvalue dereferencing code
            my $var = $lvar->lval;
# If we have a timeout, run the code inside an eval() which will be
# interrupted by SIGALARM

            $result .= "\$SIG{ALRM} = sub {die 1;}; \$\@ = undef; alarm $timeout;\n"
                . "eval {\n" if ($timeout);
            $result .= "$var = $icode;\n";
            $result .= "};\n\$SIG{ALRM} = undef; alarm 0;\n\$Language::Mumps::flag = (\$\@ ? undef : 1);\n" if ($timeout);
            $timeout = undef;
        } elsif ($_[0] =~ s/^\?//) {
            my $snip;
            ($snip, $timeout) = &makeexp($_[0]);
            $result .= $snip;
        } else {
# Constants - inteprete as prompts to be written
            my ($code, $var) = &makeexp($_[0]);
            $result .= $code . "&Language::Mumps::write($var);\n";
        }
    }
    chomp $result;
    $result;
}

####
## SET var=value,var=value

sub SET ($) {
    my ($result, $done);
    while ($_[0] && $_[0] !~ /^\s/) {
        die ", expected in SET" unless ($_[0] =~ s/^,// || !$done++);
# "Eat" var
        my ($code, $lvar) = &makevar($_[0]);
# Extract code to dereference lvalue
        my $var = $lvar->lval;
# Enforce equal sign and skip it
        die "= expected in SET" unless ($_[0] =~ s/^\=//);
# "Eat" value
        my ($code2, $val) = &makeexp($_[0]);
        my $lval = &nextvar("");
# Generate code to:
# Make a temporary variable with soft reference, make assignment,
#     dismiss soft referrence
        $result .= $code . "*$lval = \\$var;\n" .
                $code2 . "\$$lval = $val;\n*$lval = \\\$sysundef;\n";
    }
    $result;
}

####
## USE file-number
##    Generate code to save the xpos and ypos values
sub USE ($) {
    my ($code, $val) = &makeexp($_[0]);
    return $code . <<EOM;
\$Language::Mumps::xreg[\$Language::Mumps::selected_io] = \$Language::Mumps::xpos;
\$Language::Mumps::yreg[\$Language::Mumps::selected_io] = \$Language::Mumps::ypos;
\$Language::Mumps::selected_io = $val;
\$Language::Mumps::xpos = \$Language::Mumps::xreg[\$Language::Mumps::selected_io];";
\$Language::Mumps::ypos = \$Language::Mumps::yreg[\$Language::Mumps::selected_io];";
EOM
}

####
## VIEW - Not implemented

sub VIEW {
    die "Not implemented: VIEW";
}

####
## WRITE val,val.....

sub WRITE {
    my ($code, $val) = &makelist($_[0]);
    return $code . <<EOM;
foreach ($val) {
    &Language::Mumps::write(\$_);
}
EOM
}

####
## XECUTE value,value,value
## Evaluate the M code expressed in the parameters
sub XECUTE {
    my ($code, $val) = &makelist($_[0]);
    return $code . <<EOM;
foreach ($val) {
    eval &ml2pl($_);
    die "XECUTE: \$\@" if \$\@;
}
EOM
}

####
## ZP -- Evaluate Perl code until end of the line
## Test flag represents the non zeroeness of the result

sub ZP ($) {
    my $line = $_[0];
    $_[0] = '';
    return "\$Language::Mumps::flag = ($line) ? 1 : undef;";
}

####
## ZD - Evaluate perl code until the end of the line

sub ZD ($) {
    my $line = $_[0];
    $_[0] = '';
    return $line;
}

####
## ZFUNCTION - Incompatible with MumpsVM!
## ZFUNCTION function(var1,var2,var3...)
## ZFUNCTION function
## Functions are called as var calls to perl functions - with DO $$

sub ZFUNCTION ($) {
      my @tokens = ($_[0] =~ s/^\s*([a-z]\w*)(?:\(?:(?:([a-z]\w*)(\,[a-z]\w*)*)?\))?\s*$//i);
      die "Incorrect function header in ZFUNCTION" unless (@tokens);
      die "Cannot nest functions in ZFUNCTION" if ($infun++ > 1);
      my $fun = shift @tokens;
      $tmphash = &nextvar("");
      @tmpvars = @tokens;
      my $code .= "sub $fun {\nmy \%$tmphash;\n";
# Save out of scope variables
      foreach (@tokens) {
          my $obj = new Language::Mumps::var;
          $obj->name($_);
          my $var = $obj->lval;
          $code .= "\$$tmphash\{'$_'} = $var;\n$var = shift;\n";
      }
      $code;
}

####
## ZRETURN - End a function *once*

sub ZRETURN ($) {
    die "Not in a function in ZRETURN" unless ($infun--);
    my ($code, $var) = &makeexp($_[0]);
# Pull out of scope vars from the stack

    foreach (@tmpvars) {
          my $obj = new Language::Mumps::var;
          $obj->name($_);
          my $var = $obj->lval;
          $code .= "$var =\$$tmphash\{'$_'}\n";
    }
    $code . "return $var;\n}";
}

################################################################
## Utility functions - parsing                                ##
################################################################
## Three parameters by reference -                            ##
## 0 - Line of code - parsed tokens are removed               ##
## 1 - depth of parsing - arrays have indexes, functions have ##
##    parameters, etc. Used for scoping.                      ##
## 2 - Number of right paranthesis expected                   ##
################################################################

####
## makevar - "Eat" a reference to a variable
## This can be a variable identifier, a function identifier,
## or a reference to a disk stored array

sub makevar ($) {
    my ($a, $b) = (0, 0);
    makevar2($_[0], $a, $b);
}

sub makevar2 ($$) {
    my ($code, $obj, $val, $var, $isfun, $extra);
## Advance scope
    ++$_[1];
## Variables beginning with '$' are functions

    if ($_[0] =~ s/^\$//) {
# Function - skip the $
        $obj = new Language::Mumps::Func;
        $isfun = 1;
# Tolerate double $ - Perl function calls
        $extra = '$';
    } elsif ($_[0] =~ s/^\^//) {
# Arrays beginning with ^ are actually stored on disk
        $obj = new Language::Mumps::Database;
    } elsif ($_[0] =~ s/^\&//) {
# Variables preceded by & are simply perl vars with the
# corresponding name
        $obj = new Language::Mumps::Freevar;
    } else {
# Regular variables. % is a valid leading char and not skipped
        $extra = '%';
        $_[0] =~ s/^\@//;
        $obj = new Language::Mumps::Var;
    }
    die "Illegal array name" unless ($_[0] =~ /^[a-z$extra]/i);
# Remove alphanumeric token
    $_[0] =~ s/^([a-z$extra]\w*)//i;
    my $alias = $1;
# Resolve function aliases
    $alias = $FUNCTIONS{uc($alias)} || $alias if ($isfun);
    my $this;
# If we have opening paranthesis - awaiting array indices or function
# parameters
    if ($_[0] =~ s/^\(//) {
        unless ($isfun) {
# Array indices arriving
# Call makelist2 - scope to be increased - paranthesis counter
# increased
# Add the code to produce the list.
              ($code, $var) = &makelist2($_[0], $_[1], $_[2] + 1);
              die "No closing brackets" unless ($_[0] =~ /^\)/);
              goto regular;
        }
# This must be a function
        if ($alias =~ s/^(\$)//) {
# If it is a Perl function call, convert the Function
# object to a  Primitive object "partisanically"
# Construct the parameter list
              ($code, $var) = &makelist2($_[0], $_[1], $_[2] + 1);
              bless $obj, 'Language::Mumps::Primitive';
              goto regular;
        }
# This is an M function, therefore case insensitive
        $alias =~ tr/a-z/A-Z/;
# Lookup the function
        my $opt = $FUNS{$alias};
        die "Illegal function $alias" unless (@$opt);
        my $line;
# Check all the calling conventions of the function, to find
#    if any of the prototypes match
        foreach (@$opt) {
# Extract the prototype, copy the code line
            $line = $_[0];
            $@ = undef;
            $obj->prot($_->{'prot'});
# Call makelist2 with the extra parameter defining the prototype
# $line is passed by reference
            eval {
                ($code, $var) = &makelist2($line, $_[1], $_[2] + 1,
                   $obj->prot);
# makelist2 might raise an exception. This die can as well
                die "No closing brackets" unless ($line =~ /^\)/);
            };
# If there were no exceptions, this prototype match
            goto success unless ($@);
        }
# No prototype matched
        die "Unmatched function prototype for $alias: $@";
success:
# Commit the changes to the code line
        $_[0] = $line;
regular:
# If we were handling a regular variable, we are here
# Set the parameter list
        $obj->list($var);
        die "No closing brackets" unless ($_[0] =~ s/^\)//);
    } elsif ($isfun) {
# If there were no paranthesis
        $alias =~ tr/a-z/A-Z/;
        my $opt = $FUNS{$alias};
        die "Illegal function $alias" unless (@$opt);
        my $line;
# Check if any of the candidate functions except empty prototypes
        foreach (@$opt) {
            goto day unless ($_->{'prot'});
        }
        die "Function $alias requires parameters";
day:
    }
    $obj->name($alias);
# Return the code and the variable object reference
# Call ->lval to get a Perl code to dereference it
    ($code, $obj);
}

# Parse an expression
# White spaces are forbidden inside expressions
# As M is defined - parsing is DUMB - left to right.

sub makeexp ($) {
    my ($a, $b) = (0, 0);
    makeexp2($_[0], $a, $b);
}

sub makeexp2 ($$) {
    my ($step);
    my $scope = ++$_[1];
    my ($result, $sum);
# Allocate a Perl variable to hold the result
    my $var = &nextvar('$');
    my $negation;
# Iterate over the code line
# Known delimiters are colons, commas and spaces
    while ($_[0] && $_[0] !~ /^(\,|\s|\:)/) {
        my ($val, $code);
# "Eat" one character from the code line
        $_[0] =~ s/^(.)//;
        my $ch = $1;

# If we found right paranthesis
        if ($ch eq ')') {
# Unget the closing paranthesis - somebody needs it
            $_[0] = $ch . $_[0];
# Ensure we had a pending scope
            last if ($_[2]);
            die "Unexpected right bracket";
        }

# Double quotes start strings
        if ($ch eq '"') {
            my $flag;
# Iterate over the rest of the string
            while (1) {
# "Eat one character
                $_[0] =~ s/^(.)//;
                my $ch = $1;
# If this is a double quote sign, and not escaped, we've done it
                last if ($ch eq '"' && !$flag);
# If it is a backslash and not escapes - we are escaping
                if ($ch eq '\\' && !$flag) {
                    $flag = 1;
                    next;
                }
# If we are escaping - add a backslash. Otherwise add the character,
# taking care of dollar signs and other things that might confuse Perl
                $ch = ($flag ? "\\$ch" : quotemeta($ch));
# We are not escaping anymore
                $flag = undef;
# Add to the token
                $val .= $ch;
# We require closing double quotes
                die "Unterminated string" unless ($_[0]);
            }
# The Perl code to emit is the string in double quotes
            $val = qq!"$val"!;


        } elsif ($ch eq '!') {
# Line feed
            $val = qq!"\\n"!;
        } elsif ($ch eq '#' && !$result) {

# Emit a clear screen instruction, understood by the write() function
            $val = qq!['cls']!;
        } elsif ($ch eq '?' && $result) {

# ? in M can be either a binary operator or a prefix unary operator
# Depending on context

# Parse an M style regexp
            die "Regexp expected" unless ($_[0] =~ s/^(\S+)//);
# Convert to Perl regexp
            $val = &makeregexp($1);
# Compare the whole string to the regexp - 1 or undef
            $result .= "$var = ($var =~ /^$val\$/);\n";
            $sum = undef;
            next;
        } elsif ($ch eq '?') {

# Tab instruction 
            my $var;
            ($code, $var) = makeexp($_[0]);
            $val = qq!['tab', $var]!;
        } elsif ($ch =~ /[0-9\.]/) {

# A number
            my ($exp, $dot);
            $val = $ch;
# Iterate over rest of string, while finding numeric chars
            while ($_[0] =~ s/^(\d+|\.|E)//i) {
                my $ch = $1;
                if ($ch eq '.') {
# Dot only once
                    $dot++;
                    die "Illegal number" if ($dot > 1 || $exp);
                }
                if (uc($ch) eq 'E') {
# Exp only once
                    $exp++;
                    die "Illegal number" if ($exp > 1);
                }
# Add chars
                $val .= $ch;
            }
# Must end in a digit
            die "Illegal number" unless ($val =~ /\d$/);
        } elsif ($ch =~ /[a-z\$\^\@\%\&]/i) {

# Seems like a variable
# Unget the char
            $_[0] = $ch . $_[0];
# Get the var using makevar
            ($code, $val) = &makevar2($_[0], $_[1], $_[2]);
# Get the code to dereference the value of the var
            $val = $val->rval;

        } elsif ($ch =~ /['-]/ && ($sum || !$result)) {
# Unary negation operator
# Save the negation for later use
            $ch =~ s/'/!/;
            $negation = $ch;
            next;
        }
# End of char switch

        if ($ch eq '(') {
            ($code, $val) = &makeexp2($_[0], $_[1], $_[2] + 1);
            die "No closing brackets" unless ($_[0] =~ /^\)/);
        }

# We just passed an operand, not a binary operator
        if (defined($val)) {
# Generate assignment
            $result .= $code;
            $result .= "$var = $negation$val;\n";
# Include prepared computation, if any (See below)
            $result .= "$sum\n" if ($sum);
# Clear computation and negation registers
            $sum = undef;
            $negation = undef;
            next;
        }

# If we had a binary operator but found no right operand
        die "Right operand expected" if ($sum);

# We are expecting an operator now

# Allocate a new variable
        my $oldvar = $var;
        $var = &nextvar('$');
        my $qch = quotemeta($ch);
# Handle basic operators
        if ("+-*/!&_#" =~ /$qch/) {
            $ch =~ s/\!/||/; # ! means OR in M
            $ch =~ s/\&/&&/; 
            $ch =~ s/_/./;   # _ is string concatenation
            $ch =~ s/#/%/;   # '#' is modulu
            $sum = "$var $ch= $oldvar;"; # Prepare implied increment
        }
        if ($ch eq "'") {
# This is a negation
            if ($_[0] =~ /^\=\<\>/) {
                $_[0] =~ s/^(.)//;
                $ch = "* -1 $1"; # $qch does not change
            }
        }
        if ("=<>" =~ /$qch/) {
            $ch =~ s/\=/==/;
            $sum = "$var = ($oldvar <=> $var) || ($var cmp $oldvar);\n" .
                   "$var = ($var $ch 0);";
        }
        if ($ch =~ /\[\]/) {
# $oldvar contains $var
            my ($s1, $s2) = ($var, $oldvar);
            ($s2, $s1) = ($var, $oldvar) if ($ch eq '[');
            $sum = "$s2 = quotemeta($s2);\n$var = (($s1 =~ /$s2/) ? 1 : undef);";
        }
        die "Parse error on $ch" unless ($sum)
    }
    die "Right operand expected" if ($sum);
    die "Right bracket expacted $_[2] $_[0]" if ($_[2] && $_[0] =~ /^\s/);
    ("$result", $var);
}

####
## Parse a list, with optional prototype

sub makelist ($) {
    my ($a, $b) = (0, 0);
    makelist2($_[0], $a, $b, $_[1]);
}

sub makelist2 ($$) {
    my ($step);
    my $scope = ++$_[1];
    my ($result, $sum);
# Allocate a variable to store the list

    my $var = &nextvar('@');

# Allocate a label, used for tuple parsing

    my $lbl = "__lbl_$var";

    my $i;
    my $first = 1;

# Generate code to create empty list

    $result = "$var = ();\n";

# Optional prototype parameter

    my $proto = $_[3];
    while ($_[0] && $_[0] !~ /^\s/) {
# Iterate on code line

# Force comme unless first

        die "Comma expected" unless ($first || $_[0] =~ s/^,//);

# If we had a prorotype, used it up, but there still is input - it's
#    a mismatch

        die "Parameter mismatch" if ($_[3] && !$proto);
        my $typ;

# Fetch one prototype char

        $typ = $1 if ($proto =~ s/^(.)//);
        $proto = 'L' if ($typ eq 'L'); # Nothing to validate in a plain
                                       # list, but must keep $proto
                                       # unepmty
        $proto = 'T' if ($typ eq 'T'); # Tuples are length unlimited
        $typ =~ s/[IL]//; # Nothing to validate in a plain input field

# Define handlers to prototypes

        my %procs = (
## Unprototyped field - call makeexp2 to fetch data
                   "", sub($$) {&makeexp2($_[0], $_[1], $_[2])},
## Output field - get variable signature as a second parameter
                  "O", sub ($$) {
                      my ($code, $var) = &makevar2($_[0], $_[1], $_[2]);
                      ($code, $var->sig);},
## Tuples - add a finish condition every candidate
                  "T", sub ($$) {my ($code, $var2) = &maketuple2($_[0],
                             $_[1], $_[2], 2, ":"); 
                     my ($cond, $res) = @$var2;
                     ("$code $var = ($res);\ngoto $lbl if ($cond);", "undef");
                  },
## Source anchor - Line number, Label, or Label + Line number
                  "S", sub ($$) {
   die "Source anchor expected" unless 
            ($_[0] =~ s/^(\d+|(?:[a-z]\w*)?\+\d+|[a-z]\w*)//i);
                    my ($lbl, $off) = split(/\+/, $1);
                    $off *= 1;
                    my $var = &nextvar('$');
                    ("$var = &Language::Mumps::list('$lbl', $off);\n", $var);}
                  );

# Call the corresponding function

        my ($code, $val) = &{$procs{$typ}}($_[0], $_[1], $_[2]);

# Generate code to add to list
        $result .= $code . "push($var, $val);\n";
        ++$i;
        $first = undef;
        if ($_[0] =~ /^\)/) {
            last if ($_[2]);
            die "Unexpected right bracket";
        }
    }
# Add finish label for tuples

    $result .= "$lbl: " if ($proto eq 'T');
    die "Expected right operand" if ($sum);
    ($result, $var, $i);
}

####
## Make a tuple - a series of values and conditions to choose each
## Arguements: Code line, scopes, paranthesis, number of tokens,
## delimiter

sub maketuple ($) {
    my ($a, $b) = (0, 0);
    maketuple2($_[0], $a, $b, $_[1], $_[2]);
}

sub maketuple2 ($$) {
    my ($done, $result);
    ++$_[1];
    my @ary;
    my $first = 1;
    my $delim = quotemeta($_[4]);
    foreach (1 .. $_[3]) {
# Count times, expect delmiters
        die "$_[4] expected" unless ($first || $_[0] =~ s/^$delim//);
        $first = undef;
# Get expression
        my ($code, $var) = &makeexp2($_[0], $_[1], $_[2]);
        my $save = &nextvar('$');
        $result .= $code . "$save = $var;\n";
        push(@ary, $var);
    }
# Return a compile time list of referrences to tuple members
    ($result, \@ary);
}

#####
## Make regexp

# Map M meta chars to perl regexps

%RES = qw(A [a-zA-Z]
          C [\x0-\x1F0xFF]
          E [\x0-\x7F]
          H [\xE0-\xFA]
          L [a-z]
          N \d
          U [A-Z]);
# Prepare an ascii string of all non alphanumeric characters
# in between a white space and lower case 'a'
# Which is M's definition for P

my $s = pack("C*", (ord(' ') + 1 .. ord('a') - 1));
$s =~ tr/a-z0-9A-Z//;
$RES{'P'} = '[' . quotemeta($s) . ']';
$RESKEYS = join("", keys %RES);

sub makeregexp {
    my $result;
    my $src = shift;
    while ($src) {
# Iterate over string
        if ($src =~ s/^([$RESKEYS])//) {
# Is it a meta char?
            $result .= $RES{$1};
        } elsif ($src =~ s/^".*?"//) {
# Did we just find a literal?
            $result .= quotemeta($1);
        } else {
# Unrecognized
            die "Invalid REGEXP char: " . substr($src, 0, 1);
        }

# These are only after recognized tokens

# Dot - 1 to many
        if ($src =~ s/\.//) {
            $result .= '+';
        }
# Number - times
        if ($src =~ s/^(\d+)//) {
            $result .= "{$1}";
        }
    }
    $result;
}

####
## Manufacture a temporary var (register)

sub nextvar {
    my $pre = shift;
    $varstack++;
    my $sc = "_" x $scopes;
    "$pre$sc\__tmp$varstack";
}

####
## Reuse varnames after each statement, in order not to overpopulate
## symbol table

sub resetvars {
    $varstack = 0;
}

#####################################################################
## Runtime utilities                                               ##
#####################################################################

####
## Load Curses module *once* upon request

sub curse {
    require Curses;
    return undef unless (*Curses::new{CODE});
    Curses::initscr() unless ($curses_inside++);
    1;
}

####
## Clear screen or send form feed

sub cls {
    if ($Language::Mumps::selected_io == 5) {
        &curse;
        Curses::clear();
    } else {
        &write("\l");
    }
    ($xpos, $ypos) = (0, 0);
}

####
## Read a char from the keyboard

sub readkey {
    &curse;
    Curses::getch();
}

####
## Buffered input

sub read {
# Choose file number - 5 is STDIO
    my $file = ($selected_io == 5) ? \*STDIN : $handlers[$selected_io];
    my $s = scalar(<$file>);
    chomp $s;
    $xpos = 0;
    $ypos++;
    $s;
}

####
## Output

sub write {
# Choose file number - 5 is STDIO
    my $file = ($selected_io == 5) ? \*STDOUT : $handlers[$selected_io];
    my $item = shift;
# Do nothing for an empty string
    return unless (defined($item));
    if (UNIVERSAL::isa($item, 'ARRAY')) {
        if ($item->[0] eq 'cls') {
            &cls;
            next;
        }
        if ($item->[0] eq 'tab') {
            &tab($item->[1]);
            next;
        }
    }
# Split to lines
    my @frags = ($item eq "\n" ? ('', '') : split(/\n/, $item));
    my $i;
# Iterate over lines
    foreach (@frags) {
# Print line
        print $file $_;
# Increase xpos
        $xpos = ($xpos + length($_));
# Advance line counter
        if (++$i < @frags) {
            print $file "\n";
            $xpos = 0;
            $ypos++;
        } 
    }
}

####
## Tab the basic style

sub tab {
    my $to = shift;
# Are we past the tab point?
    &write("\n") if ($xpos > $to);
    my $dist = $to - $xpos;
    &write(' ' x $dist);
}

##################################################################
## Class loader                                                 ##
##################################################################
## Users of the class should import both the serializer and the ##
## flat file database engine in order to use disk stored arrays ##
## Compiled programs should import Runtime to initialize        ##
##################################################################

sub import {
    my $class = shift;
    my $state;

    foreach $state (@_) {
        if ($state eq "Runtime") {
# Runtime initialize
            tie %symbols, 'Language::Mumps::Tree';
            tie %dbs, 'Language::Mumps::Forest';
            $selected_io = 5;
        } elsif ($state =~ /^[SNG]?DBM?_File$/) {
# Prepare values to tie a DBM engine
            $@ = undef;
            eval "require $state; import $state;";
            die $@ if ($@);
            @TYING = (O_RDWR|O_CREAT, 0644,
                 ($state eq 'DB_File') ? ($DB_File::DB_HASH) : ());
            $DB = $state;

# Choose a serializer
        } elsif ($state eq 'Data::Dumper') {
            $@ = undef;
            eval "require $state; import $state;";
            die $@ if ($@);
            $FETCH = sub {no strict; eval $_[0];};
            $STORE = \&Data::Dumper::Dumper;
            $SER = $state;
        } elsif ($state eq 'Data::Dump') {
            $@ = undef;
            eval "require $state; import $state;";
            die $@ if ($@);
            $STORE = \&Data::Dump::dump;
            $FETCH = sub {no strict; eval $_[0];};
            $SER = $state;
        } elsif ($state eq 'FreezeThaw' || $state eq 'Storable') {
            $@ = undef;
            eval "require $state; import $state;";
            die $@ if ($@);
            $FETCH = \&{"$SER\::thaw"};
            $STORE = \&{"$SER\::freeze"};
            $SER = $state;
        } elsif ($state eq 'XML::Dumper') {
            $@ = undef;
            eval "require XML::Parser; import XML::Parser;";
            eval "require XML::Dumper; import XML::Dumper;";
            die $@ if ($@);
            $Language::Mumps::Pool::XML = new XML::Dumper;
            $FETCH = sub { 
                my $xml = shift;
                return undef unless ($xml);
                my $parser = new XML::Parser(Style => 'Tree');
                my $tree = $parser->parse($xml);
                $Language::Mumps::Pool::XML->xml2pl($tree); };
            $STORE = sub { $Language::Mumps::Pool::XML->pl2xml(shift); };
            $SER = $state;
        } elsif ($state eq 'Data::DumpXML') {
            $@ = undef;
            eval "require Data::DumpXML; import Data::DumpXML;";
            eval "require Data::DumpXML::Parser; import Data::DumpXML::Parser;";
            $Language::Mumps::Pool::XML = Data::DumpXML::Parser->new();
            die $@ if ($@);
            $STORE = \&Data::DumpXML::dump_xml;
            $FETCH = sub { $Language::Mumps::Pool::XML->parse(@_); };
            $SER = $state;
# Read configuration file
        } elsif ($state eq 'Config') {
            require "/etc/pmumps.cf" if (-f "/etc/pmumps.cf");
            require "~/.pmumps" if (-f "~/.pmumps");
# Variables received from configuration file, call import again
            import Language::Mumps ($DB, $SER);
        } else {
# Error
            die "Unrecognized option $state";
        }
    }
# Save DBM and serializer choice
    $IMPORT = join(" ", grep /./, grep {defined}($DB, $SER));
}

####
## Return a tied hash to a named disk stored array

sub dbs {
    my $db = shift;
# Qualified database name
    my $dbt = "Language::Mumps::DB::_$db";
# Qualified tree name
    my $dbf = "Language::Mumps::DB::Back::_$db";;
# Create database directory
    unless (-d "global") { 
        mkdir "global", 0755 || die "Can't create global/: $!";
    }
# Ensure DBM engine was selected
    die "You must configure database storage" unless ($DB);
# Tie the database flat hash
    tie(%$dbf, $DB, "global/$db.db", @TYING) || die "DB: $!";
# Tie the tree hash
    my $t = tie %$dbt, 'Language::Mumps::Tree', \%$dbf, $FETCH,
        $STORE;
# Returned the tied hash
    \%$dbt;
}

####
## Deep copy a tree/subtree to another tree/subtree

sub moveimage {
    my ($src, $dst, $key) = @_;
    $dst->{$key} = $src->{$key};
    my $t = tied(%$src);
    my @children = $t->query($key);
    foreach (@children) {
        &moveimage($src, $dst, "$key\0$_");
    }
}

######################################################################

package Language::Mumps::Tree;

#######################################################
## Tied hash holding a tree.                         ##
#######################################################
## Possible storing and fetching in a flat hash tied ##
## to a database.                                    ##
#######################################################
## The list of access keys is joined with char #0 to ##
## form the relevant key in the flat hash.           ##
## Each node has its children list attached.         ##
#######################################################


####
## Destroy the tree

sub CLEAR {
    my $self = shift;
    my $hash = $self->{'hash'};
    %$hash = ();
}

####
## Store a value in the tree

sub STORE {
    my ($self, $key, $val) = @_;
    my $hash = $self->{'hash'};
    my $store = $self->{'store'};
    my $fetch = $self->{'fetch'};
# Split the access keys
    my @tokens = split(/\0/, $key);
    my @addr;
    my $addr; # Pointer points to root
# Verify the path exists
    do {
# Fetch one token
        my $this = shift @tokens;
        my $flag; # Flag is non zero only if something new
                  # needed to be created
# Release the structure stored in the current pointer
# If none there, $flags increases, and an empty hash returned
        my $base = &$fetch($hash->{$addr}) || ++$flag && {};
# Ensure the existence of the metadata hash
        $base->{'metadata'} ||= ++$flag && {};
# Ensure the next node is marked used
        $base->{'metadata'}->{$this} ||= ++$flag;
        $hash->{$addr} = &$store($base) if ($flag);
# Advance the pointer
        push(@addr, $this);
        $addr = join("\0", @addr);
    } while (@tokens);
# Iterate until all path ensured

    my $flag;
# Fetch the data
    my $base = &$fetch($hash->{$addr}) || ++$flag && {};
    ($base->{'data'} eq $val) || ++$flag && ($base->{'data'} = $val);
# Do not update storage unless value changed, to save time with
# DBM implemented storage
    $hash->{$addr} = &$store($base) if ($flag);
}

####
## Fetch a value from the tree

sub FETCH {
    my ($self, $key) = @_;
    my $hash = $self->{'hash'};
    my $fetch = $self->{'fetch'};
## Fetch the structure
    return undef unless ($hash->{$key});
    my $base = &$fetch($hash->{$key}) || {};
## Extract the data element
    $base->{'data'};
}

####
## Does a node exist?

sub EXISTS {
    my ($self, $key) = @_;
    my $hash = $self->{'hash'};
    my $fetch = $self->{'fetch'};
    return undef unless ($hash->{$key});
    my $base = &$fetch($hash->{$key}) || {};
    (exists $base->{'data'});
}

####
## Return the children list for a node

sub query {
    my ($self, $key) = @_;
    my $hash = $self->{'hash'};
    my $store = $self->{'store'};
    my $fetch = $self->{'fetch'};
    my $base = &$fetch($hash->{$key}) || {};
    keys %{$base->{'metadata'}};
}

####
## Delete a node

sub DELETE {
    my ($self, $key) = @_;
    my $hash = $self->{'hash'};
    my $store = $self->{'store'};
    my $fetch = $self->{'fetch'};
    my $base = &$fetch($hash->{$key}) || {};
    foreach (keys %{$base->{'metadata'}}) {
        $self->DELETE("$key\0$_");
    }
    delete $hash->{$key};
    unless ($key =~ s/\0([^\0]*)$//) {
        $key =~ s/^(.*)$//;
    }
    delete $hash->{$key}->{'metadata'}->{$1};
}

####
## Return a flat hash with all the structures deserialized
## This is needed to implement keys and values functions

sub extrapolate {
    my ($self, $key) = @_;
    my @sons = $self->query($key);
    my %recur = map {$self->extrapolate($_);} @sons;
    $recur{$key} = $self->FETCH($key) if ($self->EXISTS($key));
    %recur;
}

####
## Return the first pair of the tree

sub FIRSTKEY {
    my $self = shift;
    $self->{'keys'} = {$self->extrapolate("")};
    $self->NEXTKEY;
}

####
## Return the next one

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    each %{$self->{'keys'}};
}

####
## Tie a hash to the class
## Default serializing and deserializing functions are equality
## functions, that do not change the values, for memory arrays
## A hash is tied with the storage hash, fetch function and
## stroage function.

sub TIEHASH {
    my ($class, $hash, $fetch, $store) = @_;
    $fetch ||= sub {$_[0];};
    $store ||= sub {$_[0];};
    $hash ||= {};
    my $self = {'hash' => $hash, 'store' => $store, 'fetch' => $fetch};
    bless $self, $class;
}
##################################################################

package Language::Mumps::Entity;

##################################################
## Base class for variable and function classes ##
##################################################

####
## Trivial constructor

sub new {
    bless {}, shift;
}

####
## Return whether names in the class of an object are case sensitive

sub case {
    my $class = ref(shift);
    ${$class . "::CASE"};
}

####
## Set or get the entity name

sub name {
    my $self = shift;
    $self->{'name'} = shift if (@_);
    $self->case ? $self->{'name'} : uc($self->{'name'});
}

####
## Set or get the list of parameters or indices for an entity

sub list {
    my $self = shift;
    $self->{'list'} = shift if (@_);
    $self->{'list'} || '()';
}

####
## Check if the entity has parameters or indices

sub isatom {
    my $self = shift;
    $self->{'list'} ? undef : 1;
}

####
## Return the rvalue representing an entity
## Does not equal to rval in derived classes

sub rval {
    my $self = shift;
    $self->lval;
}

####
## Return the lvalue for a variable
## By default, points to a element in a hash, holding a variable

sub lval {
    my $self = shift;
    '${' . $self->hash . '}{' . $self->addr . '}';
}

####
## Code to erase an entity

sub purge {
     die "Abstract";
}

####
## Return the hash associated with the entity

sub hash {
     die "Abstract";
}

####
## Return the key in the hash the entity is stored in

sub addr {
     die "Abstract";
}

####
## Return a tuple of the hash name and hash key
## Used mainly for providing functions runtime definitions
## of variables

sub sig {
    my $self = shift;
    "(bless [" . $self->hash . ", " . $self->addr . "], 'varsig')";
}

#####################################################################

package Language::Mumps::Var;
use vars qw(@ISA);
@ISA = qw(Language::Mumps::Entity);

#####################################################
## An object to represent an M var in compile time ##
#####################################################

####
## Erase a variable by erasing it from the symbol table

sub purge {
    my $self = shift;
    my $list = $self->list;
    my $name = $self->name;
    "delete \$Language::Mumps::symbols{'$name', $list};";
}

####
## Hash holding regular arrays

sub hash {
    "Language::Mumps::symbols";
}

####
## Address is either symbol name, or symbol name joined with the value of
## the intermediate variable containing the indices

sub addr {
    my $self = shift;
    my $list = $self->list;
    my $name = $self->name;
    $self->isatom ? "'$name'" : qq!join("\\0", '$name', $list)!;
}

#####################################################################

package Language::Mumps::Primitive;
use vars qw(@ISA $CASE);
@ISA = qw(Language::Mumps::Entity);
$CASE = 1;

####################################################
## Object to represent a perl function            ##
####################################################

####
## Lvalue impossible

sub lval {
    die "Can't use functions as Lvalue";
}

####
## Rvalue is calling the function

sub rval {
    my $self = shift;
    my $name = $self->name;
    my $list = $self->list;
    "$name($list);";
}

#######################################################################

package Language::Mumps::Database;
use vars qw(@ISA);
@ISA = qw(Language::Mumps::Entity);

###########################################################
## Object to represent a variable in a disk stored array ##
###########################################################


####
## Deleteion will be realized using DELETE in the tied hash

sub purge {
    my $self = shift;
    my $list = $self->list;
    my $name = $self->name;
    "delete \$Language::Mumps::dbs{'$name'}->{$list}";
}

####
## Local method to return code to dereference the DBM object (not tied
## hash) tied to the array
## Used in the LOCK function

sub getdb {
    my $self = shift;
    my $name = $self->name;
    "tied(\%{tied(\$Language::Mumps::dbs{'$name'})->{'hash'}})";
}

####
## Return the tree attached to the var

sub hash {
    my $self = shift;
    my $name = $self->name;
    "\$Language::Mumps::dbs{'$name'}";
}

####
## Return the access key to the Tree hash

sub addr {
    my $self = shift;
    my $list = $self->list;
    qq!join("\\0", $list)!;
}

####################################################################

package Language::Mumps::Freevar;
use vars qw(@ISA $CASE);
@ISA = qw(Language::Mumps::Entity);
$CASE = 1;

####################################################
## Object representing a raw perl var             ##
####################################################


####
## Lvalue is a scalar if no keys, otherwise hash with a key

sub lval {
    my $self = shift;
    my $name = $self->name;
    $self->isatom ? "\$$name" : $self->SUPER::lval;
}

####
## Hash name is raw

sub hash {
    my $self = shift;
    $self->name;
}

####
## Joined keys, supported in perl notation as well

sub addr {
    my $self = shift;
    my $list = $self->list;
    qq!join("\\0", $list)!;
}

####################################################################

package Language::Mumps::Func;
use vars qw(@ISA @zwi_tokens);
@ISA = qw(Language::Mumps::Entity);

############################################
## Object to represent an M function call ##
############################################

####
## Set or get the prototype

sub prot {
    my $self = shift;
    $self->{'prot'} = shift if (@_);
    $self->{'prot'};
}

####
## Return Lvalue if applicable

sub lval {
    my $self = shift;
    my $name = $self->name;
    my $prot = $self->prot;
    my $opt = $Language::Mumps::FUNS{$name};
    my $rec;
# Search for the metadata entry fitting the choosed prototype

    foreach $rec (@$opt) {
        last if ($rec->{'prot'} eq $prot);
    }
    die "Lvalue unavailable for function $name" unless ($rec->{'lval'});
# Call the local function to return the Lvalue for this function
    &{"l_$name"}($self);
}

####
## Rvalue - generate code to call the runtime function

sub rval {
    my $self = shift;
    my $name = $self->name;
    my $list = $self->list;
    "&Language::Mumps::Func::$name($list)";
}

####
## $ASCII(string, position = 1) - return ASCII of one char (1 based)

sub ASCII {
    my ($str, $pos) = @_;
    $pos -= ($pos && 1);
    my $ch = substr($str, $pos, 1);
    $ch ? -1 : ord($ch);
}

####
## $CHAR(list) Convert ASCII codes to string

sub CHAR {
    pack("C*", @_);
}

####
## $DATA(array(index,index...))
## Left digit - does it have children? Right digit - does it exist?

sub DATA {
    my ($hash, $addr) = @{$_[0]};
    my $d0 = defined($hash->{$addr});
    my $d1 = scalar(tied(%$hash)->query($addr));
    $d1 * 10 + $d0;
}

####
## $EXTRACT(string, from, to = from) - substring, 1 based locations

sub EXTRACT {
    my ($str, $from, $to) = @_;
    $to ||= $from;
    substr($str, $from - 1, $to - $from + 1);
}

####
## $FIND(long string, short string, start = 1) - find substring

sub FIND {
    my ($str, $sub, $pos) = @_;
    $pos -= ($pos && 1);
    index($str, $sub, $pos);
}

####
## $HOROLOG - Sailor time function (Works for Y2K, will not work after
## 2100)

sub HOROLOG {
    my $years = 1970 - 1841;
    my $leaps = int($years / 4) - 1;
    my $distance = 1 + 365 * $years + $leaps;
    my $now = time;
    my @here = localtime($now);
    my @gmt = gmtime($now);
    my $here = $here[1] + 60 * $here[2];
    my $gmt = $gmt[1] + 60 * $gmt[2];
    my $offset = 60 * ($here - $gmt);
    my $there = $now + $offset;
    my $n1 = int($there / 3600 / 24) + $distance;
    my $n2  = $gmt * 60 + $gmt[0];
    "$n1,$n2";
}

####
## $IO - Currently selected IO channel

sub IO {
    $Language::Mumps::selected_io;
}

sub l_IO {
    '$Language::Mumps::selected_io';
}

####
## $JOB - process id

sub JOB {
    $$;
}

####
## $JUSTIFY(string, length, decimal fraction length) - Right justify.
##     If third parameter is non zero, trailing zeroes are added
##      for numbers.
##

sub JUSTIFY {
    my ($str, $ln, $dec) = @_;
    $str = sprintf("%.${dec}d", $str) if ($dec);
    my $l = $ln - length($str);
    ($l > 0 ? (" " x $ln) : "") . $str;
}

####
## $LEN(string) - Length
## $LEN(string, substring) - How many times substring exists in string

sub LEN {
    my ($str, $token) = @_;
    $token = quotemeta($token) || ".";
    scalar($str =~ s/($token)//g);
}

####
## $NEXT(array(indices...,rightmost index))
## Returns the rightmost index of the array element
## whose rightmost index comes right after the parameter.
## Use array(indices...,-1) to find the first element
## Returns -1 on failure.
## M design bug: -1 is a valid key for an array

sub NEXT {
    my ($hash, $addr) = @{$_[0]};
    my @tokens = split(/\0/, $addr);
    my $right = pop @tokens;
    my @sons = sort (tied(%$hash)->query(join("\0", @tokens)));
    return -1 unless (@sons);
    return $sons[0] if ($right == -1);
    foreach (@sons) {
        return $_ if ($_ gt $right);
    }
    return -1;
}

####
## $ORDER - simillar to NEXT, but with numeric and not lexicographic
##   order

sub ORDER {
    my ($hash, $addr) = @{$_[0]};
    my @tokens = split(/\0/, $addr);
    my $right = pop @tokens;
    my @sons = sort {$a <=> $b} @{tied(%$hash)->query(join("\0", @tokens))};
    foreach (@sons) {
        return $_ if ($_ >= $right || $right == -1);
    }
    return -1;
}

####
## $PIECE(string, delimiter, $from, $to) - Points to to a specific
##   token in a delimited list, or to a range of tokens, including
##   the dleimiters.

sub PIECE {
    my ($str, $delim, $from, $to) = @_;
    if (ref($str) eq 'varsig') {
        my ($hash, $addr) = @$str;
        $str = $hash->{$addr};
    }
    my $qdelim = quotemeta($delim);
    my @tokens = split(/$qdelim/, $str);
    $to ||= $from;
    join($delim, @tokens[($from - 1) .. ($to - 1)]);
}

sub l_PIECE {
    my $list = shift;
    "\${&Language::Mumps::Func::tiePIECE($list)}";
}

sub tiePIECE {
    my $scalar;
    tie $scalar, 'Language::Mumps::Piece', @_;
    \$scalar;
}

####
## $RANDOM(max) - integer random

sub RANDOM {
    my $max = shift;
    int(rand($max));
}

####
## $SELECT(val1:cond1,val2:cond2...)
## Receives pairs of value:condition. Returns the first value for which
## the condition is true
##>> Actual work is done by the tokenizer in makelist2

sub SELECT {
    $_[0];
}

####
## $TEST - The test flag

sub TEST {
    $Language::Mumps::flag;
}

sub l_TEST {
    '$Language::Mumps::flag';
}

## No idea what this is doing here

sub TEXT {
    $_[0];
}

####
## $X - The x position register

sub X {
    \$Language::Mumps::xreg[\$Language::Mumps::selected_io]
}

####
## $Y - The Y position register

sub Y {
    \$Language::Mumps::yreg[\$Language::Mumps::selected_io]
}

########################################################
## Z* Functions are not part of the M specification   ##
##    and are mostly copied from MumpsVM              ##
########################################################

####
## $ZAB(number) - Absolute value

sub ZAB {
    abs(shift);
}

####
## $ZB(string) - Trims spaces

sub ZB {
    $_ = shift;
    s/^\s*//;
    s/\s*$//;
    s/\s+/ /;
    $_;
}

####
## $ZCD(filename)
## Data dumper, for backup and database garbage collection
## Weird API taken from MumpsVM
## If filename is omitted, 8 leftmost digits of UCT time are taken
## with the suffix .dmp
## Dumps all the databases to a text file using the serializer
## Returns the filename

sub ZCD {
    my $fn = shift || substr(time, 0, 8) . ".dmp";
    my $forest = {};
    $! = undef;
# Iterate over the database directory
# Have the hash $forest have references to all the databases

    foreach ((glob "global/*.db"), (glob "global/*.db.*")) {
        s|^global/||;
        s/\.db(\..*)?$//;
#        next if ($forest->{$_});
        eval {
            $forest->{$_} = {%{$Language::Mumps::dbs{$_}}};
        };
    }
    open(DUMP, ">$fn");
    print DUMP &$Language::Mumps::STORE($forest);
    close(DUMP);
# Remove links to unused databases, to free memory
    foreach (values %$forest) {
        my $hash = tied(%$_)->{'hash'};
        untie %$hash;
        undef %$hash;
        untie %$_;
        undef %$_;
    }
    %Language::Mumps::dbs = ();
    $fn;
}

####
## $ZCL - Weird API from MumpsVM
## Restore databases from a dumped file

sub ZCL {
    my $fn = shift || "dump";
    %Language::Mumps::dbs = ();
    open(LOAD, $fn);
    binmode LOAD;
    my $buffer;
    while (read(LOAD, $buffer, 8192, length($buffer))) {}
    close(LOAD);
    my $forest = &$Language::Mumps::FETCH($buffer);
    undef $buffer;
    foreach (keys %$forest) {
        unlink "global/$_.db";
        %{$Language::Mumps::dbs{$_}} = %{$forest->{$_}};
    }
# Remove links to unused databases, to free memory
    foreach (values %$forest) {
        my $hash = tied(%$_)->{'hash'};
        untie %$hash;
        undef %$hash;
        untie %$_;
        undef %$_;
    }
    %Language::Mumps::dbs = ();
}

############################
## Date functions         ##
## API taken from MumpsVM ##
############################

####
## $ZD - Readable local time

sub ZD {
    scalar(localtime);
}

####
## $ZD1 - UTC

sub ZD1 {
    time;
}

####
## $ZD2(utc) - Convert to readable string

sub ZD2 {
    scalar(localtime(shift));
}

####
## $ZD3(year, month, day) - Return day of the year

sub ZD3 {
    my ($y, $m, $d) = @_;
    require Time::Local;
    my $t = Time::Local::timelocal(0, 0, 0, $d, $m - 1, $y - 1900);
    my @t = localtime($t);
    $t[7] + 1;
}

####
## $ZD(year, day of the year) - Returns y + " " + m + " " + d string
## Hint: use $PIECE

sub ZD4 {
    my ($y, $dy) = @_;
    my @mon = qw(31 28 31 30 31 30 31 31 30 31 30 31);
    my $m;
    while ($dy > $mon[$m]) {$dy -= $mon[$m++];}
    join(" ", $y, $m + 1, $dy);
}

####
## $ZD5(year, month, day) - Returns year + "," + year day + "," +
##                (week day - 1)

sub ZD5 {
    my ($y, $m, $d) = @_;
    require Time::Local;
    my $t = Time::Local::timelocal(0, 0, 0, $d, $m - 1, $y - 1900);
    my @t = localtime($t);
    join(",", $y, $t[7] + 1, $t[6]);
}

####
## $ZD6(utc = now) - returns Ho:Mi clock time

sub ZD6 {
    my $t = (shift) || time;
    my @t = localtime($t);
    sprintf("%2d:%02d", $t[2], $t[1]);
}

####
## $ZD7(utc = now) Returns y-m-d

sub ZD7 {
    my $t = (shift) || time;
    my @t = localtime($t);
    join("-", $t[5] + 1900, $t[4] + 1, $t[3]);
}

####
## $ZD8(utc) returns y-m-d,Ho:Mi

sub ZD8 {
    my $t = shift;
    &ZD7($t) . "," . &ZD6($t);
}

####
## $ZD9(utc = now) returns y-m-d,week day - 1,Ho:Mi

sub ZD9 {
    my $t = (shift) || time;
    my @t = localtime($t);
    join(",", &ZD7($t), $t[6], &ZD6($t));
}

########################################
## $DBI - Perl oriented data access   ##
########################################
## $ZDBI(dsn, user, pass, select query, array)
## Performs query. Result API taken from MumpsVM's ZODBC
## Array in 5th parameter get the record number (1 based)
## per any key combination representing the ordered fields.
## This allows you to navigate using the function $NEXT
## Array %tpl gets the keys joined by a backslash in each index
## which is equal to the row number.

sub ZDBI {
    my ($dsn, $u, $p, $query, $ary) = @_;
    require DBI;
    import DBI;
    my $dbh = DBI->connect($dsn, $u, $p);
    my $sth = $dbh->prepare($query) || die $DBI::errstr;
    $sth->execute || die $DBI::errstr;
    my ($i, $rec, $glb);
    $glb = $Language::Mumps::dbs{$1} if ($ary =~ /^\^(.*)$/);
    
    while ($rec = $sth->fetchrow_array) {
        $Language::Mumps::symbol{"%tpl", ++$i} = join("\\", @$rec);
        unless ($glb) {
            $Language::Mumps::symbol{$ary, @$rec} = $i;
        } else {
            $glb->{@$rec} = $i;
        }
    }
    $sth->finish;
    $i;
}

####
## $ZF(filename) - true if file exists

sub ZF {
    (-f shift);
}

####
## $ZH(string) - HTTP encodes

sub ZH {
    my $s = shift;
    $s =~ s/([^ a-zA-Z0-9])/sprintf("%%%02x", $1)/ge;
    $s =~ s/ /+/g;
    $s;
}

####
## $ZL(num) = ln(num)
## $ZL(string, len) = Left justify

sub ZL {
    my ($a1, $a2) = @_;
    return ln($a1) unless (defined($a2));
    substr($a1 . (" " x $a2), 0, $a2);
}

####
## $ZN(string) - Qualify as a database name
## All letters converted uppercase, all non alphanumeric
## characters removed

sub ZN {
    my $s = uc(shift);
    $s =~ s/\W//g;
    $s;
}

####
## $ZP(string, len) - Left justify

sub ZP {
    my ($a1, $a2) = @_;
    substr($a1 . (" " x $a2), 0, $a2);
}

####
## $ZR(x) - Square root

sub ZR {
     sqrt(shift);
}

####
## $ZS(Shell command) - Executes a command sending the output

sub ZS {
    &Language::Mumps::write(`$_[0]`);
}

####
## $ZSQR(num) - Power of two

sub ZSQR {
     my $x = shift;
     $x * $x;
}

####
## $ZT(file nadler) - The position of the cursor

sub ZT {
    my $file = ($Language::Mumps::selected_io == 5) ? \*STDIN : $Language::Mumps::handlers[$Language::Mumps::selected_io];
    tell($file);
}

####
## $ZVARIABLE(name) - Returns a Perl scalar with that name

sub ZVARIABLE {
    ${scalar(caller) . '::' . $_[0]};
}

####
## $ZV1(name) - Checks if the name is an apropriate identifier

sub ZV1 {
    $_[0] =~ /^[a-z]\w*$/;
}

####
## $ZWI(string) loads the token stack with space delimited tokens
## from a string

sub ZWI {
    @zwi_tokens = split(/\s+/, shift);
}

####
## $ZWN Pulls a token from the token stack

sub ZWN {
    shift @zwi_tokens;
}

##################################################################

package Language::Mumps::Piece;

##################################################
## Class to implement the Lvalue $PIECE binding ##
##################################################

# Tie the parameters

sub TIESCALAR {
    my $class = shift;
    bless [@_], $class;
}

# Fetch the $PIECE

sub FETCH {
    my $self = shift;
    &Language::Mumps::Func::PIECE(@$self);
}

# Store

sub STORE {
    my ($self, $val) = @_;
    my ($var, $delim, $from, $to) = @$self;
    $to ||= $from;
    my ($hash, $addr) = @$var;
    my $str = $hash->{$addr};
    $delim = quotemeta($delim);
    my @tokens = split(/$delim/, $str);
    splice(@tokens, $from - 1 , $to - $from - 1, $val);
    $str = join($delim, @tokens);
    $hash->{$addr} = $str;
}

###############################################################

package Language::Mumps::Forest;

#############################################
## Class to implement a grove (aka forest) ##
#############################################


sub TIEHASH {
    bless {'dbs' => {}}, shift;
}

sub FETCH {
    my ($self, $key) = @_;
    my $dbs = $self->{'dbs'};
    $dbs->{$key} ||= &Language::Mumps::dbs($key);
    $dbs->{$key};
}

sub DELETE {
    my ($self, $key) = @_;
    my $dbs = $self->{'dbs'};
    my $hash = $dbs->{$key};
    untie %$hash;
}

sub CLEAR {
    my ($self, $key) = @_;
    my $dbs = $self->{'dbs'};
    my $hash;
    foreach $hash (keys %$dbs) {
        untie %$hash;
    }
    delete $self->{'dbs'};
}
__END__

__END__
# Documentation

=head1 NAME

Language::Mumps - Perl module to translate Mumps programs to perl scripts

=head1 SYNOPSIS

  use Language::Mumps;
  
  $pcode = Language::Mumps::compile(qq{\tw "Hello world!",!\n\th});
  eval $pcode;
  
  Language::Mumps::evaluate(qq{\ts x=1 w x});
  
  Language::Mumps::interprete("example.mps");
  
  Mumps:translate("example.mps", "example.pl");

B<prompt %> C<perl example.pl>

=head1 DESCRIPTION

This module compiles Mumps code to Perl code. The API is simillar to
MumpsVM.

=head1 ENVIRONMENT

Edit ~/.pmumps or /etc/pmumps to set up persistent arrays.

=head1 FILES

=over 6

=item F<$BINDIR/pmumps>
 Interpreter

=item F<~/.pmumps>
 User configuration

=item F</etc/pmumps.cf>
 Site configuration

=back

=head1 AUTHOR

Ariel Brosh.

=head1 COPYRIGHT AND LICENSE

Copyright 2000, Ariel Brosh.

Maintained by Steffen Mueller

Usage of this module is free, including commercial use, enterprise
and legacy use. However, any modifications should be notified to
the maintainer.

=head1 SEE ALSO

L<pmumps>, L<DB_File>.  

