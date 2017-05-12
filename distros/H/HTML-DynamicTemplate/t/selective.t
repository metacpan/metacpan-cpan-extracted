use strict;
use English;

use HTML::DynamicTemplate;

print "1..1\n";

my $template = new HTML::DynamicTemplate('t/templates/test.tmpl');
$template->set_recursion_limit(50);

$template->set(TEST => 'TEST');
$template->set(TEST_ALPHA => 'ALPHA',
               TEST_BETA  => 'BETA',
               TEST_GAMMA => 'GAMMA',
               SET => 'SET',
               INCLUDE => 'INCLUDE',
               INCLUDE_PATH => 'T/TEMPLATES/INCLUDE.TMPL');

$template->clear;

$template->set(TEST => 'Test');
$template->set(TEST_ALPHA => 'Alpha',
               TEST_BETA  => 'Beta',
               TEST_GAMMA => 'Gamma',
               SET => 'Set',
               INCLUDE => 'Include',
               INCLUDE_PATH => 't/templates/include.tmpl');

my @variables = ('TEST',
                 'TEST_ALPHA',
                 'TEST_BETA',
                 'TEST_GAMMA',
                 'SET',
                 'SET_TEST_ALPHA',
                 'SET_TEST_BETA',
                 'SET_TEST_GAMMA',
                 'INCLUDE',
                 'INCLUDE_PATH');

my $result = $template->render(@variables);

my $expected;
open EXPECTED, "t/selective_expected.txt" or die $OS_ERROR;
while(<EXPECTED>) { $expected .= $ARG }
close EXPECTED;

open RESULT, ">t/selective_result.txt" or die $OS_ERROR;
print RESULT $result;
close RESULT;

print "not " unless $result eq $expected;

print "ok 1\n";
