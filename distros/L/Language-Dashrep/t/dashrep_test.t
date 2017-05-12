#!perl -T

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {

use_ok('Language::Dashrep');


#-------------------------------------------
#  Declare variables.

my $results_text;
my $phrase_name;
my $numeric_return_value;
my $string_return_value;
my $list_count;
my $one_if_ok;
my $dashrep_code;
my $content_with_expanded_parameters;
my $html_code;
my $captured_text;
my $being_tested;
my $test_OK_counter;
my $test_number_count;
my $prior_list_count;
my $pointer;
my $accumulated_string;
my $test_failed_counter;
my $filename;
my @string_array_return_value;

$test_number_count = 0;
$test_OK_counter = 0;
$results_text = "";


#-------------------------------------------
#  Test defining a hyphenated phrase
#  to be associated with its replacement text.

$being_tested = "defined hyphenated phrase -- ";
$test_number_count ++;
$numeric_return_value = &dashrep_define( "page-name" , "name of page" );
if ( $numeric_return_value eq 1 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test getting defined hyphenated phrase.

$being_tested = "retrieved replacement text -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "page-name" );
if ( $string_return_value eq "name of page" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "attempt to retrieve undefined phrase -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "phrase-not-defined" );
if ( $string_return_value eq "" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test defining second phrase and then
#  getting list of all defined phrases.

@string_array_return_value = &dashrep_get_list_of_phrases;
$prior_list_count = $#string_array_return_value + 1;

$being_tested = "defined hyphenated phrase -- ";
$test_number_count ++;
if ( $numeric_return_value eq 1 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
$numeric_return_value = &dashrep_define( "page-name-second" , "name of second page" );
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };;

$being_tested = "counted defined phrases -- ";
$test_number_count ++;
@string_array_return_value = &dashrep_get_list_of_phrases;
$list_count = $#string_array_return_value + 1;
if ( $list_count == $prior_list_count + 1 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "verified name in list of phrase names -- ";
$test_number_count ++;
$one_if_ok = 0;
for ( $pointer = 0 ; $pointer <= ( $list_count - 1 ) ; $pointer ++ )
{
    if ( $string_array_return_value[ $pointer ] =~ /page/ ) { $one_if_ok = 1; last; };
}
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test deleting hyphenated phrase.

$numeric_return_value = &dashrep_define( "temporary-phrase" , "anything here" );

$being_tested = "deleted hyphenated phrase -- ";
$test_number_count ++;
$string_return_value = &dashrep_delete( "temporary-phrase" );
if ( $numeric_return_value eq 1 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "attempt to retrieve deleted phrase -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "temporary-phrase" );
if ( $string_return_value eq "" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

#-------------------------------------------
#  Specify Dashrep code that will be used in
#  tests below.

$dashrep_code = <<TEXT_TO_IMPORT;

*---- Do NOT change the following numbers or the tests will fail ----*
list-of-numbers: 3,12,7,13,4
--------

test-of-special-operators:
[-test-assignment = 17-]
[-should-be-17 = [-test-assignment-]-]
[-should-be-zero = [-zero-one-multiple: 0-]-]
[-should-be-one = [-zero-one-multiple: 1-]-]
[-should-be-multiple = [-zero-one-multiple: 2-]-]
[-should-be-size-zero = [-count-of-list: -]-]
[-should-be-size-one = [-count-of-list: 4-]-]
[-should-be-size-three = [-count-of-list: 4,5,6-]-]
[-should-be-count-zero = [-zero-one-multiple-count-of-list: -]-]
[-should-be-count-one = [-zero-one-multiple-count-of-list: 12-]-]
[-should-be-count-multiple = [-zero-one-multiple-count-of-list: [-list-of-numbers-]-]-]
[-should-be-item-three = [-first-item-in-list: [-list-of-numbers-]-]-]
[-should-be-item-four = [-last-item-in-list: [-list-of-numbers-]-]-]
[-should-be-empty = [-empty-or-nonempty: -]-]
[-should-be-nonempty = [-empty-or-nonempty: something-]-]
[-item-one = waltz-]
[-item-two = dance-]
[-should-be-same = [-same-or-not-same: [-item-one-]-[-item-one-]-]-]
[-should-be-not-same = [-same-or-not-same: [-item-one-]-[-item-two-]-]-]
[-action-showothervoterranking-[-same-or-not-same: [-input-validated-participantid-]-[-users-participant-id-]-]-]
[-should-be-sorted = [-sort-numbers: [-list-of-numbers-]-]-]
[-test-counter = 17-]
[-test-value = 3-]
[-test-yes-numbers-equal = [-yes-or-no-first-number-equals-second-number: 16 16-]-]
[-test-no-numbers-not-equal = [-yes-or-no-first-number-equals-second-number: 18 19-]-]
[-test-yes-number-greater-than = [-yes-or-no-first-number-greater-than-second-number: 21 20-]-]
[-test-no-number-not-greater-than = [-yes-or-no-first-number-greater-than-second-number: 20 20-]-]
[-test-yes-number-less-than = [-yes-or-no-first-number-less-than-second-number: 21 22-]-]
[-test-no-number-not-less-than = [-yes-or-no-first-number-less-than-second-number: 22 22-]-]
nothing else
--------

test-of-comment-delimiters:
beginning text
*---- comment text ----*
middle text
/---- comment text ----/
ending text
--------

test-of-auto-increment:
[-auto-increment: test-counter-]
--------

test-of-unique-value:
[-unique-value: test-value-]
--------

non-breaking-space:
&nbsp;
--------

test-of-special-spacing:
abc no-space def one-space ghi jkl  span-non-breaking-spaces-begin mno pqr stu span-non-breaking-spaces-end vwx non-breaking-space yz
--------

test-of-special-line-phrases:
abc
empty-line
def
new-line
ghi
--------

test-of-tabs:
abc tab-here def tab-here ghi
--------

test-of-parameter-substitution:
[-prefix-text-]-def-[-middle-text-]-jkl-[-suffix-text-]
--------

prefix-text:
abc
--------

middle-text:
ghi
--------

suffix-text:
mno
--------

intended-result-of-parameter-substitution:
abc-def-ghi-jkl-mno
--------

single-phrase-to-replace:
replaced-phrase
--------

page-participants-list:
[-create-list-named: participant-names-full-]
[-auto-increment: test-counter-]
[-unique-value: test-value-]
format-begin-heading-level-1
words-web-page-title
format-end-heading-level-1
tag-begin ul tag-end
generated-list-named-participant-names-full
tag-begin /ul tag-end
--------
entire-standard-web-page:
web-page-begin-1-of-2
web-page-begin-2-of-2
[-page-participants-list-]
web-page-end
--------
words-web-page-title:
List of participants
--------
tag-begin: < no-space
--------
tag-end: no-space >
--------
web-page-begin-1-of-2:
tag-begin !DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" tag-end
tag-begin html tag-end
tag-begin head tag-end
tag-begin title tag-end no-space
words-web-page-title
no-space tag-begin /title tag-end
--------
web-page-begin-2-of-2:
tag-begin /head tag-end
new-line
tag-begin body tag-end
--------
web-page-end:
tag-begin /body tag-end
tag-begin /html tag-end
--------
format-begin-heading-level-1:
tag-begin h1 tag-end no-space
--------
format-end-heading-level-1:
no-space  tag-begin /h1 tag-end
--------

case-info-idlistparticipants: [-list-of-numbers-]
--------
template-for-list-named-participant-names-full: tag-begin li tag-end no-space participant-fullname-for-participantid-[-parameter-participant-id-] no-space tag-begin /li tag-end
--------
parameter-name-for-list-named-participant-names-full:
parameter-participant-id
--------
list-of-parameter-values-for-list-named-participant-names-full:
[-case-info-idlistparticipants-]
--------
participant-fullname-for-participantid-3
James (Conservative)
---------------
participant-fullname-for-participantid-12
Nicole (Bloc Qu&eacute;b&eacute;cois)
---------------
participant-fullname-for-participantid-7
Eduard (Liberal)
---------------
participant-fullname-for-participantid-13
Robert (New Democratic)
---------------
participant-fullname-for-participantid-4
Diane (Conservative)
---------------
TEXT_TO_IMPORT


#-------------------------------------------
#  Test import hyphenated phrases with
#  replacement text.

$being_tested = "imported replacements using Dashrep code -- ";
$test_number_count ++;
$numeric_return_value = &dashrep_import_replacements( $dashrep_code );
if ( $numeric_return_value > 10 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test expanding parameters.

$being_tested = "expanded parameters in one string -- ";
$test_number_count ++;
$content_with_expanded_parameters = &dashrep_expand_parameters( "test-of-parameter-substitution" );
$string_return_value = &dashrep_get_replacement( "intended-result-of-parameter-substitution" );
if ( $content_with_expanded_parameters eq $string_return_value ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "expanded parameters in one variable-named string -- ";
$test_number_count ++;
$phrase_name = "test-of-parameter-substitution" ;
$content_with_expanded_parameters = &dashrep_expand_parameters( $phrase_name );
$string_return_value = &dashrep_get_replacement( "intended-result-of-parameter-substitution" );
if ( $content_with_expanded_parameters eq $string_return_value ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "expanded parameters -- ";
$test_number_count ++;
$content_with_expanded_parameters = &dashrep_expand_parameters( "page-participants-list" );
if ( $content_with_expanded_parameters =~ /format-begin-heading-level-1 words-web-page-title format-end-heading-level-1 tag-begin ul tag-end generated-list-named-participant-names-full tag-begin .* tag-end/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test special operators.

$string_return_value = &dashrep_expand_parameters( "test-of-special-operators" );

$being_tested = "test equal sign assignment -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-17" );
if ( $string_return_value eq "17" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test zero operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-zero" );
if ( $string_return_value eq "zero" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test one operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-one" );
if ( $string_return_value eq "one" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test multiple operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-multiple" );
if ( $string_return_value eq "multiple" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test list-size operator for zero -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-size-zero" );
if ( $string_return_value eq "0" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test list-size operator for one -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-size-one" );
if ( $string_return_value eq "1" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test list-size operator for three -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-size-three" );
if ( $string_return_value eq "3" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test zero count operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-count-zero" );
if ( $string_return_value eq "zero" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test one count operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-count-one" );
if ( $string_return_value eq "one" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test multiple count operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-count-multiple" );
if ( $string_return_value eq "multiple" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test first item in list operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-item-three" );
if ( $string_return_value eq "3" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test last item in list operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-item-four" );
if ( $string_return_value eq "4" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test empty operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-empty" );
if ( $string_return_value eq "empty" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test nonempty operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-nonempty" );
if ( $string_return_value eq "nonempty" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test same operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-same" );
if ( $string_return_value eq "same" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test not same operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-not-same" );
if ( $string_return_value eq "not-same" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test numbers equal operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "test-yes-numbers-equal" );
if ( $string_return_value eq "yes" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test numbers equal operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "test-no-numbers-not-equal" );
if ( $string_return_value eq "no" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test greater than operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "test-yes-number-greater-than" );
if ( $string_return_value eq "yes" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test greater than operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "test-no-number-not-greater-than" );
if ( $string_return_value eq "no" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test less than operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "test-yes-number-less-than" );
if ( $string_return_value eq "yes" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test less than operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "test-no-number-not-less-than" );
if ( $string_return_value eq "no" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test sort operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "should-be-sorted" );
if ( $string_return_value eq "3,4,7,12,13" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test auto-increment operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_parameters( "test-of-auto-increment" );
$string_return_value = &dashrep_get_replacement( "test-counter" );
if ( $string_return_value eq "18" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test unique-value operator -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_parameters( "test-of-unique-value" );
$string_return_value = &dashrep_get_replacement( "test-value" );
if ( $string_return_value ne "3" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test comment delimiters.

$being_tested = "test comment delimiters -- ";
$test_number_count ++;
$string_return_value = &dashrep_get_replacement( "test-of-comment-delimiters" );
if ( $string_return_value !~ /comment/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test expansion without special phrases.

$being_tested = "test expansion without special phrases -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_phrases_except_special( "test-of-special-spacing" );
if ( $string_return_value =~ /abc no\-space def one\-space ghi jkl/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test expansion of specific special phrases.

$being_tested = "test no-space directive -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_phrases( "abc  no-space  def" );
if ( $string_return_value =~ /abcdef/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test one-space directive -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_phrases( "abc  one-space  def" );
if ( $string_return_value =~ /abc def/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test four-space indentation -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_phrases( "abc new-line  no-space  one-space  one-space  one-space  one-space  no-space  def" );
if ( $string_return_value =~ /abc\n    def/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test single phrase replacement -- ";
$test_number_count ++;
$phrase_name = "single-phrase-to-replace";
$string_return_value = &dashrep_expand_phrases( $phrase_name );
if ( $string_return_value ne "replaced-phrase" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test non-breaking-space directives -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "abc non-breaking-space def" );
if ( $string_return_value =~ /abc&nbsp;def/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test non-breaking-spaces-begin/end directive -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "jkl  span-non-breaking-spaces-begin mno pqr stu span-non-breaking-spaces-end vwx" );
if ( $string_return_value =~ /jkl mno&nbsp;pqr&nbsp;stu vwx/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test tab-here directive -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "abc tab-here def" );
if ( $string_return_value =~ /abc\tdef/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test empty-line and new-line directives -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "abc empty-line def new-line ghi" );
if ( $string_return_value =~ /abc\n\ndef\nghi/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test special line-related phrases.

$being_tested = "test line break phrase -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_phrases( "test-of-special-line-phrases" );
if ( $string_return_value =~ /\n/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test special-phrase line break -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "test-of-special-line-phrases" );
if ( $string_return_value =~ /\n/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test tab-here phrase.

$being_tested = "test tab-here phrase -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_phrases( "test-of-tabs" );
if ( $string_return_value ne "abc\tdef\tghi" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test the "ignore-begin-here" and
#  "ignore-end-here" directives.

$being_tested = "test ignore directives on same line -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "test-abc ignore-begin-here def ghi ignore-end-here test-jkl" );
if ( $string_return_value =~ /test-abc[^a-z]*test-jkl/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test ignore directives on different lines -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "test-abc" );
$accumulated_string = $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "ignore-begin-here" );
$accumulated_string .= $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "def ghi" );
$accumulated_string .= $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "ignore-end-here" );
$accumulated_string .= $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "test-jkl" );
$accumulated_string .= $string_return_value;
if ( $accumulated_string =~ /test-abc[^a-z]*test-jkl/i ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test the "capture-begin-here" and
#  "capture-end-here" directives.

$being_tested = "test capture directives on same line -- ";
$test_number_count ++;
$numeric_return_value = &dashrep_define( "dashrep-tracking-on-or-off" , "on" );
$string_return_value = &dashrep_expand_special_phrases( "test-abc capture-begin-here def ghi capture-end-here test-jkl" );
$captured_text = &dashrep_get_replacement( "captured-text" );
if ( ( $string_return_value =~ /test-abc[^a-z]*test-jkl/ ) && ( $captured_text =~ /^[^a-z]*def +ghi[^a-z]*$/ ) ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test capture directives on different lines -- ";
$test_number_count ++;
$string_return_value = &dashrep_expand_special_phrases( "test-abc" );
$accumulated_string = $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "capture-begin-here" );
$accumulated_string .= $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "def ghi" );
$accumulated_string .= $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "capture-end-here" );
$accumulated_string .= $string_return_value;
$string_return_value = &dashrep_expand_special_phrases( "test-jkl" );
$accumulated_string .= $string_return_value;
$captured_text = &dashrep_get_replacement( "captured-text" );
$numeric_return_value = &dashrep_define( "dashrep-tracking-on-or-off" , "off" );
if ( ( $accumulated_string =~ /test-abc *test-jkl/ ) && ( $captured_text =~ /def +ghi/ ) ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Test expanding a single hyphenated
#  phrase into an entire web page, including
#  a table that lists participants.

$being_tested = "expanded hyphenated phrase using all replacements -- ";
$test_number_count ++;
$content_with_expanded_parameters = &dashrep_expand_parameters( "entire-standard-web-page" );
$html_code = &dashrep_expand_phrases( $content_with_expanded_parameters );
if ( length( $html_code ) gt 100 ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "found specific expanded text, including list items -- ";
$test_number_count ++;
if ( ( $html_code =~ /List of participants/ ) && ( $html_code =~ /Nicole/ ) ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Print the web page to a file with the .html
#  extension.
#  As a further test, you can open the file
#  with a web browser.

$filename = "output_test_web_page.html";
open ( OUTFILE , ">" . $filename );
print OUTFILE $html_code;
close OUTFILE;


#-------------------------------------------
#  Test top-level actions.

$being_tested = "test top-level action: append-from-phrase-to-phrase -- ";
$test_number_count ++;
$numeric_return_value = &dashrep_define( "dashrep-test-source-phrase" , "some content here" );
$numeric_return_value = &dashrep_define( "dashrep-test-target-phrase" , "" );
$string_return_value = &dashrep_top_level_action( "append-from-phrase-to-phrase dashrep-test-source-phrase dashrep-test-target-phrase" );
$string_return_value = &dashrep_get_replacement( "dashrep-test-target-phrase" );
if ( $string_return_value =~ /some content here/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test top-level actions that create file, append to file, and copy from file to phrase -- ";
$test_number_count ++;
$string_return_value = &dashrep_top_level_action( "delete-file output_test_target_file.txt" );
$string_return_value = &dashrep_top_level_action( "create-empty-file output_test_target_file.txt" );
$string_return_value = &dashrep_top_level_action( "copy-from-phrase-append-to-file dashrep-test-source-phrase output_test_target_file.txt" );
$string_return_value = &dashrep_top_level_action( "copy-from-file-to-phrase output_test_target_file.txt dashrep-test-target-phrase" );
$string_return_value = &dashrep_get_replacement( "dashrep-test-target-phrase" );
if ( $string_return_value =~ /some content here/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test top-level action: clear-all-dashrep-phrases -- ";
$test_number_count ++;
$string_return_value = &dashrep_top_level_action( "write-all-dashrep-definitions-to-file output_test_definitions_file.txt" );
$string_return_value = &dashrep_top_level_action( "clear-all-dashrep-phrases" );
$string_return_value = &dashrep_get_replacement( "page-name" );
if ( $string_return_value eq "" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test top-level actions that save and get definitions in file -- ";
$test_number_count ++;
$string_return_value = &dashrep_top_level_action( "get-definitions-from-file  output_test_definitions_file.txt" );
$string_return_value = &dashrep_get_replacement( "page-name" );
if ( $string_return_value eq "name of page" ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test top-level action: linewise-translate-from-file-to-file -- ";
$test_number_count ++;
$string_return_value = &dashrep_top_level_action( "delete-file output_test_source_file.txt" );
$string_return_value = &dashrep_top_level_action( "create-empty-file output_test_source_file.txt" );
$numeric_return_value = &dashrep_define( "dashrep-test-target-phrase" , "non-replaced-content" );
$numeric_return_value = &dashrep_define( "non-replaced-content" , "replaced content" );
$string_return_value = &dashrep_top_level_action( "copy-from-phrase-append-to-file dashrep-test-target-phrase output_test_source_file.txt" );
$string_return_value = &dashrep_top_level_action( "linewise-translate-from-file-to-file output_test_source_file.txt output_test_target_file.txt" );
$string_return_value = &dashrep_top_level_action( "copy-from-file-to-phrase output_test_target_file.txt dashrep-test-target-phrase" );
$string_return_value = &dashrep_get_replacement( "dashrep-test-target-phrase" );
if ( $string_return_value =~ /replaced content/ ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

# Subroutine dashrep_linewise_translate is NOT tested because it uses STDIN and STDOUT.


#-------------------------------------------
#  Test xml-to-dashrep translation.

$being_tested = "test subroutine named dashrep_xml_tags_to_dashrep -- ";
$test_number_count ++;
$numeric_return_value = &dashrep_define( "dashrep-first-xml-tag-name" , "xml" );
$string_return_value = &dashrep_xml_tags_to_dashrep( "<xml><head>xyz</head></xml>" );
if ( $string_return_value =~ /begin-xml-head.*xyz.*end-xml-head/s ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };

$being_tested = "test top-level action: linewise-translate-xml-tags-in-file-to-dashrep-phrases-in-file -- ";
$test_number_count ++;
$numeric_return_value = &dashrep_define( "dashrep-first-xml-tag-name" , "html" );
$numeric_return_value = &dashrep_define( "dashrep-test-xml-phrase" , "" );
$string_return_value = &dashrep_top_level_action( "delete-file output_test_xml_phrases_file.txt" );
$string_return_value = &dashrep_top_level_action( "create-empty-file output_test_xml_phrases_file.txt" );
$string_return_value = &dashrep_top_level_action( "linewise-translate-xml-tags-in-file-to-dashrep-phrases-in-file output_test_web_page.html output_test_xml_phrases_file.txt" );
$string_return_value = &dashrep_top_level_action( "copy-from-file-to-phrase output_test_xml_phrases_file.txt dashrep-test-xml-phrase" );
$string_return_value = &dashrep_get_replacement( "dashrep-test-xml-phrase" );
if ( $string_return_value =~ /begin-html-head.*participants.*end-html-head/s ) { $one_if_ok = 1; } else { $one_if_ok = 0; };
if ( $one_if_ok == 1 ) { $test_OK_counter ++ };
if ( $one_if_ok == 1 ) { $results_text .= $being_tested . "OK\n" } else { $results_text .= $being_tested . "ERROR\n\n" };


#-------------------------------------------
#  Remove temporary files.
#  (Comment out if need to view files for debugging.)

$string_return_value = &dashrep_top_level_action( "delete-file output_test_source_file.txt" );
$string_return_value = &dashrep_top_level_action( "delete-file output_test_target_file.txt" );
$string_return_value = &dashrep_top_level_action( "delete-file output_test_definitions_file.txt" );
$string_return_value = &dashrep_top_level_action( "delete-file output_test_xml_phrases_file.txt" );


#-------------------------------------------
#  Write results, including the count of
#  successful tests.

if ( $test_OK_counter == $test_number_count )
{
    $results_text .= "All " . $test_OK_counter . " tests were successful!\n";
} else
{
    $test_failed_counter = $test_number_count - $test_OK_counter ;
    $results_text .= "Failed " . $test_failed_counter . " tests!\nSee test output file for details.\n";
}
$filename = "output_test_results.txt";
open ( OUTFILE , ">" . $filename );
print OUTFILE $results_text ;
close OUTFILE;


#-------------------------------------------
#  If all test results OK, indicate pass for
#  CPAN module test.

if ( $test_OK_counter == $test_number_count ) {
    pass("Passed all $test_OK_counter tests out of $test_number_count");
} else {
    fail("Failed $test_failed_counter tests out of $test_number_count, see file $filename for details");
}


#-------------------------------------------
#  All done testing.

}
