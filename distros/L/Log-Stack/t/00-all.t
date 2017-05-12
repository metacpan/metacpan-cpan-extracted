#!perl -wT

use strictures 2;

package # hide from cpan
    Log::Stack::Test;
use Moo 2;
has list => (is => 'ro', default => sub { [] });
sub log { push @{ shift()->list } => \@_ }

package main;

use Test::More;
use Test::Exception;
use Log::Stack;

subtest basic => sub {
    my $stack;

    $stack = Log::Stack->new;

    isa_ok $stack => 'Log::Stack';
    is $stack->_initialized => 0, 'Stack is unintialized';
    is_deeply $stack->_stack => [], 'Stack is empty';

    $stack->log(alert => 'Alert');
    is $stack->_initialized => 1, 'Stack is intialized';
    is_deeply $stack->_stack => [[ 'alert', 'Alert' ]], 'Stack contains an alert message';

    $stack->flush;
    is $stack->_initialized => 0, 'Stack is unintialized';
    is_deeply $stack->_stack => [], 'Stack is empty';
};

subtest order => sub {
    my $stack;

    $stack = Log::Stack->new;

    $stack->log(fatal => 'Fatal');
    $stack->log(alert => 'Alert');
    $stack->log(debug => 'Debug');
    $stack->log(trace => 'Trace');

    is_deeply $stack->_stack => [[
        fatal => 'Fatal'
    ],[
        alert => 'Alert'
    ],[
        debug => 'Debug'
    ],[
        trace => 'Trace'
    ]], 'Stack contains messages in FIFO order';
};

subtest defaults => sub {
    my $stack;

    $stack = Log::Stack->new(sub {}, id => 1);
    $stack->log(0,0);
    is_deeply $stack->_stack => [[0,0,id=>1]], 'Message contains ID 1';

    $stack->set(id=>2);
    $stack->log(1,1);
    is_deeply $stack->_stack => [[0,0,id=>1],[1,1,id=>2]], 'Messages contains ID 1,2';

    $stack->flush;
    $stack->set(id=>sub{\@_});
    $stack->log(2,3);
    is_deeply $stack->_stack => [[2,3,id=>[2,3]]], 'Default with CodeRef';
};

subtest target1 => sub {
    my $stack;
    my $test = [];

    $stack = Log::Stack->new(sub { push @$test => \@_ });
    is_deeply $test => [], 'Target not called yet';

    $stack->log(0,0);
    is_deeply $test => [], 'Target still not called yet';

    $stack->log(1,1);
    is_deeply $test => [], 'Target still not called yet, really';

    $stack->throw;
    is_deeply $test => [[0,0],[1,1]], 'Target finally called';
};

subtest target2 => sub {
    my $stack;
    my $test1 = [];
    my $test2 = [];

    $stack = Log::Stack->new(sub { die "I should not have been called" });

    $stack->log(0,0);
    lives_ok { $stack->throw(sub { push @$test1 => \@_ }) };
    is_deeply $test1 => [[0,0]], 'Real target called';

    $stack->log(1,1);
    lives_ok { $stack->throw(sub { push @$test2 => \@_ }) };
    is_deeply $test1 => [[0,0]], 'Previous target untouched';
    is_deeply $test2 => [[1,1]], 'New target called';
};

subtest target3 => sub {
    my $stack;
    my $logger = Log::Stack::Test->new;

    $stack = Log::Stack->new($logger);
    is_deeply scalar($logger->list), [], 'Target not called yet';

    $stack->log(0,0);
    is_deeply scalar($logger->list) => [], 'Target still not called yet';

    $stack->log(1,1);
    is_deeply scalar($logger->list) => [], 'Target still not called yet, really';

    $stack->throw;
    is_deeply scalar($logger->list) => [[0,0],[1,1]], 'Target finally called';
};

subtest hooks => sub {
    my $stack;
    my $test;
    my $init = 0;
    my $after = 0;
    my $before = 0;
    my $cleanup = 0;

    $stack = Log::Stack->new(sub { $test = "$before - $after" });

    $stack->hook(init => sub { $init++ });
    $stack->hook(after => sub { $after++ });
    $stack->hook(before => sub { $before++ });
    $stack->hook(cleanup => sub { $cleanup++ });

    $stack->log(0,0);
    is $init => 1;
    is $after => 0;
    is $before => 0;
    is $cleanup => 0;

    $stack->log(0,0);
    is $init => 1;
    is $after => 0;
    is $before => 0;
    is $cleanup => 0;

    $stack->throw;
    is $test => '1 - 0';
    is $init => 1;
    is $after => 1;
    is $before => 1;
    is $cleanup => 1;

    $stack->throw;
    is $test => '1 - 0';
    is $init => 1;
    is $after => 1;
    is $before => 1;
    is $cleanup => 1;

    $stack->log(0,0);
    is $init => 2;
    is $after => 1;
    is $before => 1;
    is $cleanup => 1;

    $stack->flush;
    is $init => 2;
    is $after => 1;
    is $before => 1;
    is $cleanup => 2;
};

done_testing;

1;
