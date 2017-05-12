#!/usr/local/bin/perl -w
# $Id: trace_levels.t,v 1.3 2004/11/23 14:07:32 simonf Exp $
use strict;
use Test::More tests => 15;

# Find local libs unless running under Test::Harness
BEGIN { unshift @INC, -d 't' ? 'lib' : '../lib' unless grep /\bblib\b/, @INC }
require_ok('Log::Trace');

my $output;
my $trace = sub {
    $output = shift() . "\n";
};

my $message;
import Log::Trace custom => $trace;
$message = 'sending trace message without levels';
TRACE($message);
is ($output, "$message\n", 'message traced without levels');

$message = 'sending trace message without imported level only';
TRACE({Level => 3}, $message);
is ($output, "$message\n", 'level 3 message traced without levels');

# Now set the levels
import Log::Trace custom => $trace, {Level => 3};
$message = rand(100); $output = '';
TRACE({Level => 1}, $message);
is ($output, "$message\n", 'level 1 message traced at level 3');

$message = rand(100); $output = '';
TRACE({Level => 5}, $message);
is ($output, "", 'level 5 message NOT traced at level 3');

$message = rand(100); $output = '';
TRACE($message);
is ($output, "", 'undefined level message NOT traced at level 3');

# define a list of levels
import Log::Trace custom => $trace, {Level => [0 .. 3]};
$message = rand(100); $output = '';
TRACE({Level => 1}, $message);
is ($output, "$message\n", 'level 1 message traced at specified levels');

$message = rand(100); $output = '';
TRACE({Level => 0}, $message);
is ($output, "$message\n", 'level 0 message traced at specified levels');

$message = rand(100); $output = '';
TRACE({Level => 4}, $message);
is ($output, "", 'level 4 message not traced at specified levels');

$message = rand(100); $output = '';
TRACE($message);
is ($output, "", 'undefined level message NOT traced at specified levels');

# define a list of levels, including 'undef'
import Log::Trace custom => $trace, {Level => [undef, 1 .. 3]};
$message = rand(100); $output = '';
TRACE({Level => 2}, $message);
is ($output, "$message\n", 'level 2 message traced at specified levels');

$message = rand(100); $output = '';
TRACE({Level => 0}, $message);
is ($output, "", 'level 0 message NOT traced at specified levels');

$message = rand(100); $output = '';
TRACE($message);
is ($output, "$message\n", 'undefined level message traced at specified levels');


# use a custom level handler
import Log::Trace custom => $trace, {Level => \&custom_levels};
$message = rand(100); $output = '';
TRACE({Level => 2}, $message);
is ($output, "", 'level 2 message NOT traced at custom levels');

$message = rand(100); $output = '';
TRACE({Level => 0.1}, $message);
is ($output, "$message\n", 'level 0.1 message traced at specified levels');

sub custom_levels {
    my ($packge, $level) = @_;
    # allow 1.1, 2.1, 3.1, etc, but not 1, 2, 3 or 1.2, 2.2
    return $level - int($level) == 0.1;
}

sub TRACE {}
