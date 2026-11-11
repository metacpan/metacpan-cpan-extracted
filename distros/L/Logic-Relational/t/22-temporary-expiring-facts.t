#!/usr/bin/env perl
use v5.38;                          ## no critic (ValuesAndExpressions::ProhibitVersionStrings)
use lib ( '../lib', 'lib' );
use Test2::V0 '!call';
no warnings 'redefine';             ## no critic (TestingAndDebugging::ProhibitNoWarnings)
no warnings 'prototype';            ## no critic (TestingAndDebugging::ProhibitNoWarnings)
use Logic::Relational qw(variable call all);
use Logic::Relational::Program;
use feature 'try';
no warnings 'experimental::try';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)

# 1. Test temporary facts with `with_facts`
my $p = Logic::Relational::Program->new;
$p->fact( located_at => 'alice', 'home' );

my $who = variable('who');
my $loc = variable('loc');

# Check initial fact
my $q1   = $p->query( call( located_at => $who, $loc ) );
my $sol1 = $q1->next;
is( $sol1->value($who), 'alice', 'Initial located_at suspect' );
is( $sol1->value($loc), 'home',  'Initial located_at location' );
ok( !$q1->next, 'No more solutions' );

# Run inside with_facts block
my $called = 0;
$p->with_facts(
    [ [ located_at => 'bob', 'castle' ], [ located_at => 'carol', 'forest' ], ],
    sub {
        $called = 1;
        my $q = $p->query( call( located_at => $who, $loc ) );
        my %sols;
        while ( my $sol = $q->next ) {
            $sols{ $sol->value($who) } = $sol->value($loc);
        }
        is(
            \%sols,
            {
                alice => 'home',
                bob   => 'castle',
                carol => 'forest',
            },
            'Temporary facts exist within callback scope'
        );
    }
);
ok( $called, 'Callback was called' );

# Verify they are cleaned up after the block
my $q2 = $p->query( call( located_at => $who, $loc ) );
my %sols2;
while ( my $sol = $q2->next ) {
    $sols2{ $sol->value($who) } = $sol->value($loc);
}
is(
    \%sols2,
    { alice => 'home' },
    'Temporary facts retracted after callback scope'
);

# 2. Test exception safety in `with_facts`
try {
    $p->with_facts(
        [ [ located_at => 'david', 'cave' ] ],
        sub {
            die "Error inside block";    ## no critic (RequireCarping)
        }
    );
}
catch ($e) {
    like( $e, qr/Error \s+ inside \s+ block/x, 'Exception was propagated' );
}

# Verify fact was still cleaned up
my $q3 = $p->query( call( located_at => $who, $loc ) );
my %sols3;
while ( my $sol = $q3->next ) {
    $sols3{ $sol->value($who) } = $sol->value($loc);
}
is(
    \%sols3,
    { alice => 'home' },
    'Temporary facts retracted even if block throws'
);

# 3. Test expiring facts with `assert_fact`
my $p2 = Logic::Relational::Program->new;

# Asserts a fact that expires in 2 seconds
$p2->assert_fact(
    term       => [ carrying => 'bob', 'rope' ],
    expires_in => 2,
);

# Asserts a fact that is already expired (expires_at in the past)
$p2->assert_fact(
    term       => [ carrying => 'alice', 'knife' ],
    expires_at => time - 10,
);

# Query immediately - only bob's carrying fact should be active (alice is already expired)
my $item          = variable('item');
my $q_carrying1   = $p2->query( call( carrying => $who, $item ) );
my $sol_carrying1 = $q_carrying1->next;
ok( $sol_carrying1, 'Bob carrying rope solution found before expiration' );
if ($sol_carrying1) {
    is( $sol_carrying1->value($who),  'bob',  'Bob is carrying rope' );
    is( $sol_carrying1->value($item), 'rope', 'Item is rope' );
}
ok( !$q_carrying1->next, 'Alice is not found because her fact is expired' );

# Wait 3 seconds for bob's fact to expire
sleep 3;

# Query again - no solutions should be found since bob's fact has now expired
my $q_carrying2 = $p2->query( call( carrying => $who, $item ) );
ok( !$q_carrying2->next, 'No facts found because all are expired' );

# 4. Test database pruning and change event dispatching
my $p3 = Logic::Relational::Program->new;
my @events;
$p3->on_change(
    sub ($event) {
        push @events, $event;
    }
);

# Assert an expiring fact (expires in 2 seconds)
$p3->assert_fact(
    term       => [ carrying => 'bob', 'rope' ],
    expires_at => time + 2,
);
is( scalar(@events),       1,        'Assert event received' );
is( $events[0]->operation, 'assert', 'Event operation is assert' );

# Wait for expiration
sleep 3;

# Prune database
my $pruned = $p3->cleanup_expired_facts;
is( $pruned,               1,         'Cleaned up 1 expired fact' );
is( scalar(@events),       2,         'Retract event received' );
is( $events[1]->operation, 'retract', 'Event operation is retract' );

done_testing;
