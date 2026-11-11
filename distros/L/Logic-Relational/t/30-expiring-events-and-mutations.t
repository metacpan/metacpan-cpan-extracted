#!/usr/bin/env perl
use v5.38;    ## no critic (ValuesAndExpressions::ProhibitVersionStrings)
use lib ( '../lib', 'lib' );
use Test2::V0;
use Logic::Relational::Program;
use Logic::Relational::Syntax;

# 1. Test Declarative expire_to Fact Mutations
my $p1 = Logic::Relational::Program->new;
$p1->assert_fact(
    term       => [ match_state => 'lit', 'bedroom' ],
    expires_in => 2,
    expire_to  => [ match_state => 'burnt_out', 'bedroom' ],
);

my $state_var = Logic::Relational::DSL::variable('state');
my $room_var  = Logic::Relational::DSL::variable('room');

# Query immediately - state should be 'lit'
my $q1 = $p1->query(
    Logic::Relational::DSL::call( match_state => $state_var, $room_var ) );
my $sol1 = $q1->next;
ok( $sol1, 'Initial solution found before expiration' );
if ($sol1) {
    is( $sol1->value($state_var), 'lit',     'Initial state is lit' );
    is( $sol1->value($room_var),  'bedroom', 'Location is bedroom' );
}

# Sleep 3 seconds for fact to expire and mutate
sleep 3;

# Query again - state should automatically mutate to 'burnt_out'
my $q2 = $p1->query(
    Logic::Relational::DSL::call( match_state => $state_var, $room_var ) );
my $sol2 = $q2->next;
ok( $sol2, 'Solution found after mutation' );
if ($sol2) {
    is( $sol2->value($state_var),
        'burnt_out', 'State mutated to burnt_out after TTL' );
    is( $sol2->value($room_var), 'bedroom', 'Location remains bedroom' );
}
ok( !$q2->next, 'No additional match states' );

# 2. Test Per-Clause on_expire Callbacks
my $p2       = Logic::Relational::Program->new;
my $cb_fired = 0;
my $cb_room  = '';

$p2->assert_fact(
    term       => [ match_lit => 'kitchen' ],
    expires_in => 1,
    on_expire  => sub ( $clause, $prog ) {
        $cb_fired = 1;
        $cb_room  = $clause->head->args->[0];
    },
);

sleep 2;
$p2->cleanup_expired_facts;
ok( $cb_fired, 'Per-clause on_expire callback executed' );
is( $cb_room, 'kitchen', 'Callback received correct clause metadata' );

# 3. Test Program-Level Predicate Listener for on_expire
my $p3          = Logic::Relational::Program->new;
my @expired_log = ();

$p3->on_expire(
    match_lit => sub ( $clause, $prog ) {
        push @expired_log, $clause->head->args->[0];
    }
);

$p3->assert_fact(
    term       => [ match_lit => 'attic' ],
    expires_in => 1,
);
$p3->assert_fact(
    term       => [ match_lit => 'cellar' ],
    expires_in => 1,
);

sleep 2;
$p3->cleanup_expired_facts;
is(
    \@expired_log,
    [ 'attic', 'cellar' ],
    'Program-level on_expire listener received expired events'
);

# 4. Test Snapshot Serialization of expire_to Mutations
my $p4 = Logic::Relational::Program->new;
$p4->assert_fact(
    term       => [ match_state => 'lit', 'den' ],
    expires_in => 10,
    expire_to  => [ match_state => 'burnt_out', 'den' ],
);

my $json_str;
$p4->save_snapshot( \$json_str );
like( $json_str, qr/"expire_to"/x,
    'Snapshot JSON contains encoded expire_to metadata' );

my $p5 = Logic::Relational::Program->new;
$p5->load_snapshot( \$json_str, ttl_mode => 'relative' );

my $q_p5 = $p5->query(
    Logic::Relational::DSL::call( match_state => $state_var, $room_var ) );
my $sol_p5 = $q_p5->next;
ok( $sol_p5, 'Restored match state exists in relative TTL mode' );
if ($sol_p5) {
    is( $sol_p5->value($state_var),
        'lit', 'Restored match state is lit in relative TTL mode' );
}

# 5. Test Re-entrant Query inside on_expire Callback (No Deep Recursion)
my $p6           = Logic::Relational::Program->new;
my $reentrant_ok = 0;
$p6->fact( active_beacon => 'tower' );

$p6->assert_fact(
    term       => [ match_state => 'lit', 'tower' ],
    expires_in => 1,
    on_expire  => sub ( $clause, $prog ) {
        my $v = Logic::Relational::DSL::variable('v');
        my $q =
          $prog->query( Logic::Relational::DSL::call( active_beacon => $v ) );
        if ( my $s = $q->next ) {
            $reentrant_ok = ( $s->value($v) eq 'tower' ) ? 1 : 0;
        }
    },
);

sleep 2;
$p6->cleanup_expired_facts;
ok( $reentrant_ok,
'Re-entrant query inside on_expire callback succeeded without deep recursion'
);

done_testing;
