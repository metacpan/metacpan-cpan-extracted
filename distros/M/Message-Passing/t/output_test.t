use strict;
use warnings;
use Test::More;
use Try::Tiny;

use Message::Passing::Output::Test;

my $called = 0;

my $test = try { Message::Passing::Output::Test->new(cb => sub { $called++ }) }
    catch { fail "Failed to construct $_" };
ok $test;

try { $test->consume('message') }
    catch { fail "Failed to consume message: $_" };

is $test->message_count, 1;
is_deeply [$test->messages], ['message'];
is $called, 1;

try { $test->clear_messages }
    catch { fail "Could not clear messages: $_" };

is $test->message_count, 0;
is_deeply [$test->messages], [];

done_testing;

