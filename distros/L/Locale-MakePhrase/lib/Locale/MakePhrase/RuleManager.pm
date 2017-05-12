package Locale::MakePhrase::RuleManager;
our $VERSION = 0.4;
our $DEBUG = 0;

=head1 NAME

Locale::MakePhrase::RuleManager - Language rule sort and evaluation
object.

=head1 SYNOPSIS

The L<Locale::MakePhrase> module uses this plugin module, to implement
the evaluation and sorting phases of text selection.  It explains the
rule expression syntax and evaluation procedure.

It sorts the language rules into a suitable order so that we can
figure out which rule to select, ie. the aim is to sort the rules into
an order so that we can select the first rule.

It evaluates the program arguments against the expressions in the rule.

=head1 PHRASE SYNTAX

To allow an argument to be placed within the middle of a string, we
use square brackets as the notation, plus an underscore, then the
argument number, as in:

  "Please select [_1] files"

where I<[_1]> refers to the first program variable supplied as an
argument with the text to be translated.

To display square brackets within the text string, you will need to
escape the square bracket by using the B<~> (tilde) character, as in:

  "This is ~[ bracketed text ~]"

this will print:

  This is [ bracketed text ]

Of course, if you need to display the B<~> character, you will need to
use two of them, as in:

  "Tilde needs escaping as in ~~"

which ends up printing:

  Tilde needs escaping as in ~

=head1 LINGUISTIC RULES

We have coined the term I<linguistic rules> as a means to describe the
technique which decides which piece of text is displayed, for a given
input text phrase and any/all program arguments.

To understand why we need to generate linguistic rules, consider the
'singular vs. plural' example shown in the L<Locale::MakePhrase/REQUIREMENTS>
section.

In this example, we needed four different text strings, for the
trivial case of what to display for a given program value.

For other examples, the URL's mentioned in that section describe why
there is a need for applying rules on a per-language basis (they also
describe why most current language translation systems fail).

=head2 What is a linguistic rule?

A linguistic rule is the evaluation of the context of a phrase by
using program arguments, for a given program string.  The arguments
are evaluated left-to-right and top-to-bottom.  The first rule to
succeed has its corresponding translated text applied in-place of the
input text.

Note that if a program string takes no arguments, the rule becomes
rather simplistic (in that no arguments need to be evaluated).

Rules can be tested in a number of ways.  The 'Operators' and
'Functions' sections list the available rule expression conjigates
available for use within each rule expression.

Previously we mentioned that the language translation system used
syntax with the form B<[_1]>.  You will notice that we use an
underscore in the placeholder.  This may appear to be meaningless, but
as we will see, we use this rule property to help understand how rules
are evaluated.

=head2 Numeric evaluation

Let's show an example of a simple expression:

  _1 == 0

The use of the underscore signifies that this value is to be
classified as an argument number and is not to be treated literally.
This expression says, 'Does the first argument have a value equal to
zero?'

[Note that we use double-equals; the double-equals operator will use
a numeric context in the equality test.]

=head2 String evaluation

Since an argument can also be a string, we could define an expression
to be:

  _1 eq "some text"

Notice that we use a different operator depending on whether the
argument is numeric or a string.  This is because we need to be able
to figure out what context the argument needs to be evaluated in.

[In this case we use 'eq' as the text context equality operator.]

=head2 Alternate argument representation

In some cases we need to be able to specify the translated string,
based on an alternate representation of the argument.  This is handled
by using a function.  For example, you may use the term 'houses',
which is the main keyword within your application.

To handle alternations of the word 'houses' (such as 'house') we can
define an expression of:

  left(_1,5) eq 'house'

However, in some cases we will use the terms 'apartments' or 'flats'.
In these cases, we only care if the value is in the plural or singular
case:

  right(_1,1) eq "s"

Thus, we are provided with a set of functions which allow some
manipulation of the argument value, prior to evaluation.

=head2 Multiple arguments

In many cases, more than one argument is supplied (as well as the text
to translate) to L<Locale::MakePhrase>.  In those cases, an expression
can be created which tests each argument, as in:

  _1 == 0 && _2 != 1

As we can see here, by using B<&&>, we combine multiple expression
evaluations, into a single rule expression.  In this case the
expression is effectively saying "if argument one is equal to zero AND
argument two is not equal to one".

We support an unlimited number of arguments within the expression
evaluation capability.

=head2 Multiple rule expressions

Consider the following exresssions:

  _1 > 0   produces the output "Lots of files"
  _1 == 0  produces "No files"
  _1 == 1  produces "One file"

Each expression is a valid, but if we evaluate this set of expressions
in the wrong order, we will never be able to produce the text "One
file" as the B<_1 E<gt> 0> expression would evaluate to true, before
we try to evaluate the B<_1 == 1> expression.

To counter this problem, whenever we define a rule expression
(including when there is no rule expression as would be the case when
no arguments are supplied), we must also define a rule priority (where
a larger number gives higher priority).

Knowing this, let's re-consider the previous set of expressions, this
time adding a suitable priority of evaluation for each expression:

  expression:  priority:
    _1 > 1        1
    _1 == 0       2
    _1 == 1       2

Now that we have a rule priority, we can see that the B<_1 == 0>
expression and the B<_1 == 1> expression will get evaluated before the
B<_1 E<gt> 1> expression.

You will notice that two rules have the same priority (i.e. we can
have any number of rules having the same priority); in this case, the
rules are evaluated in a non-deterministic (first found, first
evaluated) manner.  Thus it is important to make sure that a given
rule expression, has a valid rule priority, for the rule set.

=head2 Rule Syntax

Now that we know what a linguistic rule is, we need to explain some
minor but important points.

Each symbol in a rule expression needs to be separated with a space,
i.e. this works:

  _1 > 4
  left(_2,1) eq "f"

this doesn't:

  _1>4
  left(_2,1)eq"f"

Whenever we are using a string operator, we must enquote the value
that we are testing, i.e.  this works:

  _1 eq "fred"

this doesn't:

  _1 eq fred

We support single and double quote characters, including mixed quoting
(for simplistic cases), i.e. these work:

  _1 eq "some text"
  _1 eq 'some text'
  _1 eq "someone's dog"
  _1 eq '"john spoke"'

this doesn't (i.e. there is no quote 'escape' capability):

  _1 eq "\"something\""

Note that expressions are not unary, as in (this checks if the
first argument has any length):

  length(_1)

rather, they should look like:

  length(_1) > 0

=head1 APPLYING RULES TO LANGUAGES

=over 8

=item CAVEAT:

The following description of rule evaluation is correct at the time of
writing. However, as this module evolves, we may alter the
implementation as we get feedback.  If you have used this module and
found that the rule evaluation order is not what you expect, please
contact the maintainer.

=back

So far we have discussed the concept that, a translation exists for a
language/dialect combination.  However, the application may not be
translated into the specific language requested by the user.  In
these cases, L<Locale::MakePhrase> tries to use fallback languages as
the source language for this translation request.  This allows
languages derived from other base languages (eg Spanish and Mexican
share common words) and dialect specific variations of languages (such
as variations of English), to use the parent language as a source for
possible translations.

Thus whenever a phrase cannot be translated directly into the requested
localisation, L<Locale::MakePhrase> will use a fallback mechanisn for
the input phrase.

Also, to support variations in output text which can exist in
locale-specific translations, non-expression rules should be evaluated
after rules which have an expression.

The implementation of which rule to select, has been abstracted into a
seperate module so that you can implement your own process of which
rule is selected based on the available rules.  The default
implementation is defined in L<Locale::MakePhrase::RuleManager>.  It
contains a description of the current implementation.

=head2 Overview of steps to rule evaluation

=over 3

=item 1.

L<Locale::MakePhrase> generates a list of rules which are applicable for
required languages (plus any fallback languages).

=item 2.

The rules are sorted by the L<Locale::MakePhrase::RuleManager> module.

=item 3.

Each expression from the sorted rules are evaluated. If the rule
succeeds, the corresponding text is returned.  If not, the next rule
is evaluated.

=item 4.

If finally no match is found, the input string is used as the output
string.

=item 5.

Any arguments are then applied to the output string.

=back

=head2 Example rule definitions

Shown below are examples of various rules; some rules have no
expressions and/or arguments; all rules must have at least a priority
of zero or more.

=over 2

=item Rule 1:

 Language:    en_US
 Input text:  Please select some colours.
 Expression:  (none)
 Priority:    0
 Output text: Please select some colors.

=item Rule 2:

 Language:    en
 Input text:  Please select some colours.
 Expression:  (none)
 Priority:    0
 Output text: Please select colours.

=item Rule 3:

 Language:    en_AU
 Input text:  Please select [_1] colours.
 Expression:  (none)
 Priority:    0
 Output text: Please select [_1] colours.

=item Rule 4:

 Language:    en
 Input text:  Please select [_1] colours.
 Expression:  _1 > 0
 Priority:    0
 Output text: Select [_1] colours.

=back

=over 2

=item An example:

Given that the preferred language is 'en_US', if you compare rule 1 vs
rule 2, the linguistic rule evaluation mechanism will be applied to
rule 1 before being applied to rule 2, as it has a higher language-order.

=item A further example:

Compare rule 3 vs rule 4. Given that there is no expression associated
with rule 3, but that the 'en' version does have an expression, rule 4
will be evaluated (and found to be true in some cases) before example
3 is evaluated.

=back

These examples show that it is important to consider the interactions
of the linguistic rules, as they are applied to the current localisation.

=head1 APPLYING ARGUMENTS TO TEXT

With any text translation system, there comes a time when it is
necessary to apply the values of the arguments 'in situ', replacing the
square-bracket argument number, with the corresponding argument value,
so that the output will say something useful.  This happens after all
rules have been applied (if there were any), and after the output text
string has been chosen.

For example:

  Input text:  "Selected [_2] files, [_1] directories"
  Arguments:   3  21

Apply rules...

  Rule text:   "Selected [_2] files, [_1] directories"
  Output text: "Selected 21 files, 3 directories"

=head1 OPERATORS

This is a list of all operators:

 Operator  Context      Meaning                Example
 ----------------------------------------------------------------------
   ==      Numeric  Equal to                   _1 == 4
   !=      Numeric  Not equal to               _1 != 2
   >       Numeric  Greater than               _2 > 1
   <       Numeric  Less than                  _1 < 7
   >=      Numeric  Less than or equal to      _4 >= 21
   <=      Numeric  Greater than or equal to   _3 <= 12
   eq      String   Equal to                   _1 eq "some text"
   ne      String   Not equal to               _2 ne "something else"

=head1 FUNCTIONS

This is a list of available functions:

  Function     Context              Meaning                  Example
 ----------------------------------------------------------------------
 defined(x)       -      Is the argument defined/not-null,  defined(_1)
                         returns 0 or 1
 length(x)        -      Length of value of the argument,   length(_1)
                         returns an integer >= 0
 abs(n)         Number   Numerical absolute of argument     abs(_3)
 lc(s)          String   Lowercase version                  lc(_1)
 uc(s)          String   Uppercase version                  uc(_2)
 left(s,n)      String   LHS of argument from start         left(_3,4)
 right(s,n)     String   RHS of argument from end           right(_1,2)
 substr(s,n)    String   RHS of argument from start         substr(_2,7)
 substr(s,n,l)  String   Sub-part of argument from 'n',     substr(_2,7,4)
                         up to 'l' characters

=head1 API

The following functions are used by the L<Locale::MakePhrase> class.
By sub-classing this module, then overloading these functions,
L<Locale::MakePhrase> can use yor custom RuleManager module.

=cut

use strict;
use warnings;
use utf8;
use base qw();
use Data::Dumper;
use Locale::MakePhrase::Utils qw(is_number left right alltrim die_from_caller);
local $Data::Dumper::Indent = 1 if $DEBUG;

use constant STR_INVALID_TRANSLATED => "<INVALID_TRANSLATION>";

# Available datatypes
use constant UNKNOWN => -1;
use constant UNSPECIFIED => 0;
use constant NUMBER => 1;
use constant STRING => 2;

# Available operators
our %OPERATORS = (
  '==' => NUMBER,
  '!=' => NUMBER,
  '<'  => NUMBER,
  '>'  => NUMBER,
  '<=' => NUMBER,
  '>=' => NUMBER,
  'eq' => STRING,
  'ne' => STRING,
);

# Available functions
our %FUNCTIONS = (
  'defined' => [ UNSPECIFIED, [], sub { defined($_[0]);     } ],
  'length'  => [ UNSPECIFIED, [], sub { length($_[0]);      } ],
  'abs'     => [ NUMBER,      [], sub { abs($_[0]);         } ],
  'lc'      => [ STRING,      [], sub { lc($_[0]);          } ],
  'uc'      => [ STRING,      [], sub { uc($_[0]);          } ],
  'left'    => [ STRING,     [1], sub { left($_[0],$_[1]);  } ],
  'right'   => [ STRING,     [1], sub { right($_[0],$_[1]); } ],
  'substr'  => [ STRING,   [1,2], sub {
                                    return substr($_[0], $_[1]) if @_ == 2;
                                    return substr($_[0], $_[1], $_[2]);
                                  } ],
);

# Predefined regular expression patterns
my $ops_re; { my $tmp = join ('|', keys %OPERATORS); $ops_re = qr/$tmp/; }
my $ltr_re = qr/^_(\d+)\s+($ops_re)\s+(.*)/;
my $rtl_re = qr/(.*)\s+($ops_re)\s+_(\d+)$/;
my $func_ltr_re = qr/^([a-zA-Z0-9_]+)\(_(\d+)([^)]*)\)\s+($ops_re)\s+(.*)$/;
my $func_rtl_re = qr/^(.*)\s+($ops_re)\s+([a-zA-Z0-9_]+)\(_(\d+)([^)]*)\)$/;


#--------------------------------------------------------------------------

=head2 new()

Construct a new instance of L<Locale::MakePhrase::RuleManager> object;
arguments are passed to the init() method.

=cut

# Constructor
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = bless {}, $class;
  return $self->init(@_);
}

#--------------------------------------------------------------------------

=head2 $self init([..])

Allow sub-class a chance to control construction of the object.  You
must return a reference to $self, to 'allow' the construction to
complete (should you decide to derive from it).

=cut

sub init { shift }

#--------------------------------------------------------------------------

=head2 boolean evaluate($expression,@arguments)

This is the expression evaluation engine.  It takes an expression as
described above (for example B<_1 == 4 && _2 eq 'fred'>).  It then
takes any program arguments, applying them in-place of the B<_X>
place holders.  Finally returning true / false, based on the result
of the evaluation of the expression.

=cut

sub evaluate {
  my $self = shift;
  die("Missing rule expression?!") unless @_;
  my $expression = alltrim(shift);
  print STDERR "Evaluating rule: $expression\n" if $DEBUG > 1;
  print STDERR "Arguments: ". Dumper(\@_) if $DEBUG > 5;
  my $evaluation = 0;
  my @expressions;
  my $arg_count = scalar(@_);

  # Break apart expression into subexpressions, so that it can be validated
  my @subexpressions;
  foreach my $chunk (split('\s+&&\s+',$expression)) {
    my ($arg,$val,$op,$text,$quote,$func,$func_args) = ("","","","","","","");
    my ($val_type,$op_type,$text_type,$func_type) = (UNKNOWN,UNKNOWN,UNKNOWN,UNKNOWN);
  
    # Break apart subexpression
    if ($chunk =~ $ltr_re) {
      ($arg,$op,$text) = ($1,$2,$3);
    } elsif ($chunk =~ $rtl_re) {
      ($text,$op,$arg) = ($1,$2,$3);
    } elsif ($chunk =~ $func_ltr_re) {
      ($func,$arg,$func_args,$op,$text) = ($1,$2,$3,$4,$5);
    } elsif ($chunk =~ $func_rtl_re) {
      ($text,$op,$func,$arg,$func_args) = ($1,$2,$3,$4,$5);
    } else {
      die_from_caller("Invalid subexpression ($chunk) found in expression:",$expression);
    }

    # Grab properties for this subexpression - test for conformity
    die_from_caller("Missing argument ?!") unless $arg;
    die_from_caller("Missing operator ?!") unless $op;
    die_from_caller("Missing text value ?!") unless length $text;
    die_from_caller("Unknown operator: $op") unless exists $OPERATORS{$op};
    die_from_caller("Incorrect number of arguments in expression (trying to use $arg arguments when $arg_count arguments supplied):",$expression) if ($arg > $arg_count);
    if ($text =~ /^(['"])(.*)(["'])$/) {
      $quote = $1 if ($1 eq $3);
      $text = defined $2 ? $2 : "";
    }
    $val = $_[$arg-1];
    $op_type = $OPERATORS{$op};
    $val_type = not defined $val ? UNSPECIFIED : is_number($val) ? NUMBER : STRING;
    $text_type = is_number($text) ? NUMBER : STRING;
    die_from_caller("Missing quote-marks for text value: $text") if ($op_type == STRING and not length $quote);
    die_from_caller("Mis-matched text-value/operator types\n- text-value: $text \n- operator: $op") if ($op_type == NUMBER and $text_type != NUMBER);

    print STDERR "Rule properties:\n- argument: $arg\n- function: $func\n- operator: $op\n- text: $text\n- quote: $quote\n- value: ", defined $val ? $val : "", "\n" if $DEBUG > 1;

    # build expression
    if ($func) {
      die_from_caller("Unknown function: $func") unless exists $FUNCTIONS{$func};
      $func_type = $FUNCTIONS{$func}->[0];
      die_from_caller("Mis-matched function/operator types\n- function: $func\n- operator: $op") if ($func_type != UNSPECIFIED and $func_type != $op_type);
      die_from_caller("Invalid use of undefined argument (argument number: $arg) when used with function: $func") if ($val_type == UNSPECIFIED and $func_type != UNSPECIFIED);
      my $required = $FUNCTIONS{$func}->[1];
      my $sub = $FUNCTIONS{$func}->[2];
      if (@$required) {
        die_from_caller("Incorrect number of arguments for function: $func (need: ". join(',',@$required) ." - none provided)") unless length $func_args;
        $func_args = alltrim($func_args);
        my @func_args = split(/\s*,\s*/,$func_args);
        shift @func_args if @func_args > 1;
        my $found = 0;
        foreach my $required_arg_count (@$required) {
          $found++ if @func_args == $required_arg_count;
        }
        die_from_caller("Incorrect number of arguments for function: $func (need: ". join(',',@$required) ." - provided: ".scalar(@func_args).")") unless $found;
        $val = &$sub($val,@func_args);
      } else {
        $val = &$sub($val);
      }
      $val = 0 unless defined $val;
      $val_type = $op_type;
      print STDERR "Function result: ", defined $val ? $val : "", "\n" if $DEBUG > 5;
    } else {
      die_from_caller("Invalid use of undefined argument (argument number: $arg) expression: $expression") unless (defined $val);
    }

    print STDERR "- op_type $op_type\n- val_type $val_type\n- text_type $text_type\n" if $DEBUG > 3;
  
    die_from_caller("Mis-matched argument/operator types\n- argument: $val\n- operator: $op") if (($op_type == STRING and $val_type != STRING) or ($op_type == NUMBER and $val_type != NUMBER));
    push @subexpressions, "$quote$val$quote $op $quote$text$quote";
  }
  die("Failed building expression") unless @subexpressions;
  my $parsed_expression = join(' && ',@subexpressions);
  
  # Evaluate expression - needs to return some sort or true or false value.
  # Note that under Perl, this is as simple as an 'eval'  :-)
  my $expr_result = eval $parsed_expression;
  $expr_result = $expr_result ? 1 : 0;
  print STDERR "Expression to evaluate: $parsed_expression   result: $expr_result\n" if $DEBUG;
  return $expr_result;
}

#--------------------------------------------------------------------------

=head2 \@rules sort(\@rule_objects,\@languages)

The guts of the sorter; by subclassing this module, you can implement
your own sorting routine.

This module implements the following rules for deciding the sorted
order of the rules.  The aim is to return a list which can be
evaluated in-order.

=over 3

=item 1.

Rules are sorted histest to lowest priority, for the primary language,
for rules which have expressions.

=item 2.

The next available fallback language is chosen as the language to use;
step 1 is repeated.

=item 3.

This process continues until no further fallback languages are available.

=item 4.

The non-expression rules are then evaluated according to the preferred
language.

=item 5.

If that fails, the fallback languages are tried.  This continues for
each fallback language.

=back

=cut

sub sort {
  my ($self,$rule_objs,$languages) = @_;
  my @new_order;
  my @non_ruled;
  foreach my $language (@$languages) {
    my @r;
    my @nr;
    foreach my $r_obj (@$rule_objs) {
      next unless $r_obj->language eq $language;
      if ($r_obj->expression) {
        push @r, $r_obj;
      } else {
        push @nr, $r_obj;
      }
    }
    @r = sort { $b->priority <=> $a->priority } @r;
    push @new_order, @r;
    @nr = sort { $b->priority <=> $a->priority } @nr;
    push @non_ruled, @nr;
  }
  push @new_order, @non_ruled;
  return \@new_order;
}

#--------------------------------------------------------------------------

=head2 $string apply_arguments($makephrase,$translation,@arguments)

This applies any/all arguments, to the outgoing text phrase; if the
argument is text, it (optionally) undergoes the translation process;
if the argument is numeric, it is formatted by the L<Locale::MakePhrase>
C<format_number> method.

=cut

sub apply_arguments {
  my ($self,$makephrase,$translation,@args) = @_;
print "HERE:".Dumper(@args) if $DEBUG;
  my $arg_count = scalar(@args);
  my $output = "";
  my $in_group = 0;
  WHILE_LOOP: while($translation =~ /\G(
                                       [^\~\[\]]+  # non-~[] stuff
                                       |
                                       ~[\[\]\~]   # ~[, ~], ~~
                                       |
                                       \[          # [ presumably opening a group
                                       |
                                       \]          # ] presumably closing a group
                                       |
                                      .*          # any other characters
                                       |
                                       $
                                       )/xgs ){
    my $chunk = defined $1 ? $1 : "";
    if ($chunk eq '[') {
      die_from_caller("Found recursive beginning square-bracket:",$translation) if $in_group;
      $in_group++;
    } elsif ($chunk eq ']') {
      $in_group--;
      die_from_caller("Found recursive ending square-bracket:",$translation) if $in_group;
    } elsif ($in_group) {
      # inside square bracket group
      $chunk = alltrim($chunk);
      if ($chunk =~ /^_/) {
        my ($idx,$options) = split(/\s*,\s*/,$chunk,2);
        $options = { split(/\s*(?:(?:=>)|(?:,))\s*/,$options) } if $options;
        $idx =~ s/^_//;
        $idx = int($idx)-1;
        if ($idx >= $arg_count) {
          die_from_caller("Incorrect number of arguments used in translation - supplied $arg_count, tried to use at least $idx.") if ($makephrase->{die_on_bad_translation});
          $output .= STR_INVALID_TRANSLATED;
          last WHILE_LOOP;
        } else {
          my $val = $args[$idx];
          if (defined $val and length $val) {
            if (is_number($val)) {
              $output .= $makephrase->format_number($val,$options);
            } elsif ($makephrase->{translate_arguments}) {
              $output .= $makephrase->translate($val);
            } else {
              $output .= $val;
            }
          }
        }
      } else {
        if ($makephrase->{die_on_bad_translation}) {
          die_from_caller("Invalid translated string: $translation");
        }
        $output .= STR_INVALID_TRANSLATED;
        last WHILE_LOOP;
      }
    } elsif (substr($chunk,0,1) eq '~') {
      $output .= substr($chunk,1);
    } else {
      $output .= $chunk;
    }
  }

  return $output;
}

1;
__END__
#--------------------------------------------------------------------------

=cut

