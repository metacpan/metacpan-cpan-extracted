#!/usr/bin/env perl
# Test that (some of) the examples work.
use warnings;
use strict;

use Test::More;
use Log::Report;

use_ok 'Log::Report::Template';

# The modifiers are loaded automagically
my $templater = Log::Report::Template->new;
isa_ok $templater, 'Log::Report::Template';

$templater->addTextdomain(name => 'default', lexicon => '.');

### test chaining IF

my $output = '';
$templater->process(\'[% a = b; IF a %]YES[%END%]', {b => 1}, \$output)
    or $templater->error;

is $output, "YES", 'chain yes';

$output = '';
$templater->process(\'[% a = b; IF a %]YES[%ELSE%]NO[%END%]', {b => 0}, \$output)
    or $templater->error;

is $output, "NO", 'chain no';


done_testing;
