# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FSM-Simple.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 83;
use Test::Exception;

BEGIN { use_ok('FSM::Simple') };

my $machine = FSM::Simple->new(trans_history => 1);

# Define states.
lives_ok { $machine->add_state(name => 'init',      sub => \&init)      } 'add state init';
lives_ok { $machine->add_state(name => 'make_cake', sub => \&make_cake) } 'add state make_cake';
lives_ok { $machine->add_state(name => 'eat_cake',  sub => \&eat_cake)  } 'add state eat_cake';
lives_ok { $machine->add_state(name => 'clean',     sub => \&clean)     } 'add state clean';
lives_ok { $machine->add_state(name => 'stop',      sub => \&stop)      } 'add state stop';

# Set initial state - optional (default it is first added state).
lives_ok { $machine->init_state('init') } 'set init state';
ok $machine->init_state eq 'init', 'check returned init state';

# Define transitions.
lives_ok { $machine->add_trans(from => 'init',      to => 'make_cake', exp_val => 'makeCake') } 'add transition 1';
lives_ok { $machine->add_trans(from => 'make_cake', to => 'eat_cake',  exp_val => 1)          } 'add transition 2';
lives_ok { $machine->add_trans(from => 'eat_cake',  to => 'clean',     exp_val => 'good')     } 'add transition 3';
lives_ok { $machine->add_trans(from => 'eat_cake',  to => 'make_cake', exp_val => 'bad')      } 'add transition 4';
lives_ok { $machine->add_trans(from => 'clean',     to => 'stop',      exp_val => 'foo')      } 'add transition 5';
lives_ok { $machine->add_trans(from => 'clean',     to => 'stop',      exp_val => 'done')     } 'add transition 6'; # 'stop' is a key of hash that this transition is replacing previous transitions.


lives_ok { $machine->run() } 'run state machine';


print "\n";
my $ra_trans_history = $machine->trans_history;
ok ref $ra_trans_history eq 'ARRAY',   'check trans_history returned type (1)';
ok scalar @$ra_trans_history,          'check size of history array (1)'; # array has random size but greater than 0
ok shift @$ra_trans_history eq 'init', 'check first element in history array';
ok pop @$ra_trans_history   eq 'stop', 'check last element in history array';

print "\n";
$machine->clear_trans_history;
$ra_trans_history = $machine->trans_history;
ok ref $ra_trans_history eq 'ARRAY',   'check trans_history returned type (2)';
ok 0 == scalar @$ra_trans_history,     'check size of history array (2)';


# Without trans history.
print "\n";
$machine->clear_trans_history;
$machine->clear_trans_stats;
$machine->trans_history_off;
lives_ok { $machine->run() } 'run state machine without transitions history';

$ra_trans_history = $machine->trans_history;
ok ref $ra_trans_history eq 'ARRAY',  'check trans_history returned type (3)';
ok 0 == scalar(@$ra_trans_history),   'check size of history array (3)';


print "\n";
my $rh_trans_stats = $machine->trans_stats;
ok ref $rh_trans_stats eq 'HASH',  'check trans_stats returned type (1)';
ok exists $rh_trans_stats->{init}, 'check init state existence';
ok $rh_trans_stats->{init} == 1,   'check init state counter';

print "\n";
$machine->clear_trans_stats;
$rh_trans_stats = $machine->trans_stats;
ok ref $rh_trans_stats eq 'HASH',     'check trans_stats returned type (2)';
ok exists $rh_trans_stats->{init},    'check init state existence (2)';
ok $rh_trans_stats->{init} == 0,      'check init state counter (2)';

print "\n";
my @trans_array = $machine->trans_array;
ok scalar @trans_array,            'check size of transitions array';
my $index = 0;
foreach my $rh_trans (@trans_array) {
    print "\n";
    ok ref $rh_trans eq 'HASH',  "check type of transitions array element [$index]";
    ok exists $rh_trans->{from}, "check existence of 'from' key in transitions array element [$index]"; 
    ok exists $rh_trans->{to},   "check existence of 'to' key in transitions array element [$index]";
    ok exists $rh_trans->{returned_value}, "check existence of 'returned_value' key in transitions array element [$index]";    
    
    if ($rh_trans->{from} eq 'make_cake') {
        ok $rh_trans->{to} eq 'eat_cake',      'check destination state in transition';
        ok $rh_trans->{returned_value} eq '1', 'check returned value in transition';
    }
    
    $index++;
}

print "\n";
my $graphviz_code = $machine->generate_graphviz_code(name => 'test_graph', size => '7');
ok ref $graphviz_code eq '', 'check generate_graphviz_code returned type (1)';
ok $graphviz_code =~ /digraph test_graph/, 'check name of graphviz definition';
ok $graphviz_code =~ /size="7"/x,          'check value of size in graphviz code (1)';

print "\n";
$graphviz_code = $machine->generate_graphviz_code;
ok ref $graphviz_code eq '', 'check generate_graphviz_code returned type (2)';
ok $graphviz_code =~ /digraph finite_state_machine/, 'check default name of graphviz definition';
ok $graphviz_code =~ /size="8"/x,                    'check default value of size in graphviz code (2)';

print "\n";
$graphviz_code = $machine->generate_graphviz_code(name => 'test_graph3');
ok ref $graphviz_code eq '', 'check generate_graphviz_code returned type (3)';
ok $graphviz_code =~ /digraph test_graph3/, 'check another name of graphviz definition';
ok $graphviz_code =~ /size="8"/x,           'check default value of size in graphviz code (3)';


# Checking die when is non existing returned value.
lives_ok { $machine->add_state(name => 'wrong_ret_val', sub => \&wrong_ret_val) } 'add state which returns wrong value';
lives_ok { $machine->init_state('wrong_ret_val')                                } 'set new init state (1)';
dies_ok  { $machine->run()                                                      } 'run state machine again and die (1)';

# Checking die when returned value from custom sub is not a SCALAR.
lives_ok { $machine->add_state(name => 'wrong_ret_val_type', sub => \&wrong_ret_val_type) } 'add state which returns wrong value type';
lives_ok { $machine->init_state('wrong_ret_val_type')                                } 'set new init state (2)';
dies_ok  { $machine->run()                                                      } 'run state machine again and die (2)';



# Without trans history.
print "\n";
my $machine2 = FSM::Simple->new(); 

# Define states.
lives_ok { $machine2->add_state(name => 'init', sub => \&init) } 'add state init';
lives_ok { $machine2->add_state(name => 'stop', sub => \&stop) } 'add state stop';

# Define transitions.
lives_ok { $machine2->add_trans(from => 'init', to => 'stop', exp_val => 'makeCake') } 'add transition 1';

lives_ok { $machine2->run() } 'run state machine without transitions history';

my $ra_trans_history2 = $machine2->trans_history;
ok ref $ra_trans_history2 eq 'ARRAY', 'check trans_history returned type (4)';
ok 0 == scalar(@$ra_trans_history2),  'check size of history array (4)';


# With trans history.
print "\n";
my $machine3 = FSM::Simple->new(); # 

# Define states.
lives_ok { $machine3->add_state(name => 'init', sub => \&init) } 'add state init';
lives_ok { $machine3->add_state(name => 'stop', sub => \&stop) } 'add state stop';

# Define transitions.
lives_ok { $machine3->add_trans(from => 'init', to => 'stop', exp_val => 'makeCake') } 'add transition 1';

lives_ok { $machine3->trans_history_on } 'turn on transitions history';
lives_ok { $machine3->run() } 'run state machine with turned on transitions history';

my $ra_trans_history3 = $machine3->trans_history;
ok ref $ra_trans_history3    eq 'ARRAY', 'check trans_history returned type (5)';
ok 2 == scalar(@$ra_trans_history3),  'check size of history array (5)';
ok shift @$ra_trans_history3 eq 'init', 'check first element in history array (5)';
ok shift @$ra_trans_history3 eq 'stop', 'check last element in history array (5)';



##########################################################################################
### User defined subroutines.
##########################################################################################

sub init {
	my $rh_args = shift;
	print "Let's make a cake\n";
	
	$rh_args->{returned_value} = 'makeCake';
	return $rh_args;
}

sub make_cake {
	my $rh_args = shift;
	print "I am making a cake\n";

    $rh_args->{returned_value} = 1;
    return $rh_args;
}

sub eat_cake {
	my $rh_args = shift;
	print "I am eating a cake\n";
	
	# If the cake is tasty then return 'good' otherwise 'bad'.
	srand;
	if (rand(1000) < 400) {
		$rh_args->{returned_value} = 'good';
	}
	else {
		$rh_args->{returned_value} = 'bad';
	}
    
    return $rh_args;
}

sub clean {
	my $rh_args = shift;
	print "I am cleaning the kitchen\n";

    $rh_args->{returned_value} = 'done';
    return $rh_args;
}

sub stop {
	my $rh_args = shift;
	print "Stop machine\n";

    $rh_args->{returned_value} = undef;
    return $rh_args;
}

sub wrong_ret_val {
    my $rh_args = shift;
    
    $rh_args->{returned_value} = 'not_expecting_value';
    return $rh_args;
}

sub wrong_ret_val_type {
    my $rh_args = shift;
    
    $rh_args->{returned_value} = ['some_value'];
    return $rh_args;
}

1;