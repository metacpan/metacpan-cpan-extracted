#!/usr/bin/env perl
# Test the additional modifiers.
use warnings;
use strict;

use lib 'lib';

use Test::More;
use Log::Report;

use_ok 'Log::Report::Template';

# The modifiers are loaded automagically
my $templater = Log::Report::Template->new;
isa_ok $templater, 'Log::Report::Template';

$templater->addTextdomain(name => 'default', lexicon => '.');

### the usual

my $output = '';
$templater->process(\'[% loc("Present {a}", a => b) %]', {b => 1}, \$output)
    or $templater->error;

is $output, "Present 1", 'usual';


### undef

$output = '';
$templater->process(\'[% loc("Present {a}", a => b) %]', {b => undef}, \$output)
    or $templater->error;

# Template Toolkit translates 'undef b' into an empty string :-(
is $output, "Present ", 'undef';


### missing

dispatcher close => 'default';

$output = '';
try { $templater->process(\'[% loc("Present {a}") %]', {}, \$output)
        or $templater->error };
(my $warning) = $@->exceptions;
is $warning, "warning: Missing key 'a' in format 'Present {a}', in input text\n";

is $output, "Present undef", 'missing';


### missing, but found in environment

$output = '';
$templater->process(\'[% loc("Present {a}") %]', {a => 42}, \$output)
    or $templater->error;

is $output, "Present 42", 'magically collected from stash';


done_testing;
