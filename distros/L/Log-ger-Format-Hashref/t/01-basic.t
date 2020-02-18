#!perl

use strict;
use warnings;
use Test::More 0.98;
use Test::Exception;

use vars '$ary'; BEGIN { $ary = [] }
use Log::ger::Output 'Array', array => $ary;
use Log::ger::Format 'Hashref';
use Log::ger;

log_warn 'arg1';
log_warn {msg=>'arg1'};

dies_ok { log_warn 'arg1', 'arg2', 'arg3' };

log_warn;

log_warn arg1=>"arg2", arg3=>'arg4';

is_deeply($ary, [
    {message=>'arg1'},
    {msg=>'arg1'},

    {},
    {arg1=>"arg2", arg3=>'arg4'},
]) or diag explain $ary;

DONE_TESTING:
done_testing;
