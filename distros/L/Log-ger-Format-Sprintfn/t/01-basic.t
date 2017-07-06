#!perl

use strict;
use warnings;
use Test::More 0.98;

use vars '$ary'; BEGIN { $ary = [] }
use Log::ger::Output 'Array', array => $ary;
use Log::ger::Format 'Sprintfn';
use Log::ger;

log_warn 'a';
log_warn 'b %s', 'x';
log_warn 'b2 %s', [];
log_warn 'c %(name)s %s', {name=>'ujang'}, 'x';
log_warn 'c2 %(foo)s %s', {foo=>[]}, {};

is_deeply($ary, [
    'a',
    'b x',
    'b2 []',
    'c ujang x',
    'c2 [] {}',
]) or diag explain $ary;

DONE_TESTING:
done_testing;
