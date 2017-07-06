#!perl

use strict;
use warnings;
use Test::More 0.98;

use vars '$ary'; BEGIN { $ary = [] }
use Log::ger::Output 'Array', array => $ary;
use Log::ger::Format 'Flogger';
use Log::ger;

log_warn 'simple!';
log_warn [ 'slightly %s complex', 'more' ];
log_warn [ 'and inline some data: %s', { look => 'data!' } ];
log_warn [ 'and we can defer evaluation of %s if we want', sub { 'stuff' } ];
log_warn sub { 'while avoiding sprintfiness, if needed' };

is_deeply($ary, [
    'simple!',
    'slightly more complex',
    'and inline some data: {{{"look": "data!"}}}',
    'and we can defer evaluation of stuff if we want',
    'while avoiding sprintfiness, if needed',
]) or diag explain $ary;

DONE_TESTING:
done_testing;
