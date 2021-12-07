#!/usr/bin/env perl 
use strict;
use warnings;

use Log::Any::Adapter qw(DERIV);
use Log::Any qw($log);
use Syntax::Keyword::Try;

sub example_sub {
    $log->infof('Info level');
}

$log->trace('Trace level');
$log->debugf('Debug level, with simple hashref: %s', {xyz => 123});
$log->infof('Info level');
example_sub();
$log->warnf('Warning level');
$log->errorf('Error level');
warn "regular warn line\n";
$log->fatalf('Fatal level', {extra => 'data'});

$log->infof(
    'Nested data structure %s',
    {
        arrayref => ['a' .. 'f'],
        hashref  => {another => {hashref => 'here'}}});

sub will_die {
    die "die form a sub: $_[0]";
}

sub call_will_die {
    will_die(@_);
}

try {
    # die message will not be print in try block
    call_will_die("from try");
} catch {
};

# die message will not be printed in eval string
eval 'call_will_die("from eval string")';
# die message will not be printed in eval string
eval { call_will_die("from eval block") };

# will print die message and die here
call_will_die("from naked");
