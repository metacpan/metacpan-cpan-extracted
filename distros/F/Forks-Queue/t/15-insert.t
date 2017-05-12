use strict;
use warnings;
use Test::More;
use Forks::Queue;
require "t/exercises.tt";

for my $impl (IMPL()) {
    my $q = Forks::Queue->new( impl => $impl, limit => 20,
                               on_limit => 'fail' );

    ok($q, "created queue impl=$impl");
    ok(4 == $q->enqueue(1,2,3,4), 'added items to queue');
    ok(2 == $q->insert(1, qw/foo bar/), 'inserted 2 items');

    ok($q->peek(0) eq '1' &&
       $q->peek(1) eq 'foo', 'insert at pos 1 successful');
    ok($q->peek(2) eq 'bar' &&
       $q->peek(3) eq '2',   'items after insert preserved');

    ok(3 == $q->insert(-1, qw(one two three)), 'insert neg index count ok');
    ok($q->peek(-4) eq 'one' && $q->peek(-3) eq 'two' &&
       $q->peek(-2) eq 'three' && $q->peek(-1) eq '4',
       'insert neg index successful');

    ok(4 == $q->insert(1000, qw(five seven nine eleven)),
       'insert past end');
    ok($q->peek(-5) eq '4' && $q->peek(-4) eq 'five' && 
       $q->peek(-1) eq 'eleven',
       'insert past end successfully added at end');

    ok(4 == $q->insert(-1000, qw/thirteen 15 seventeen 19/),
       'insert past start count ok');
    ok($q->peek(3) eq '19' && $q->peek(4) eq '1',
       'insert past start successfully added at front');

    ok($q->pending == 17, 'count correct so far');
    ok(3 == $q->insert(10, qw[23 29 31 37 41]),
       'queue limit respected on insert');
    ok($q->peek(10) eq '23' && $q->peek(12) eq '31'
       && $q->peek(13) ne '37',
       'only some items were inserted successfully') or $q->_DUMP;
}

done_testing;
