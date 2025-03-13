#!/usr/bin/perl

use strict;
use warnings;
use Math::Symbolic 0.613 qw(:all);
use Math::Symbolic::Custom::Matrix 0.2;
use Math::Symbolic::Custom::Collect 0.32;
use Math::Symbolic::Custom::CollectSimplify 0.2;
Math::Symbolic::Custom::CollectSimplify->register();
use Math::Symbolic::Custom::ToShorterString 0.1;
use Math::Symbolic::Custom::Equation 0.2;

use Test::Simple tests => 2;

my $show_working = 1;

# 1. We have a netlist and we want expressions for the voltages at the 
# internal nodes.
# This is a potential divider, three series resistors of equal value and
# 9V across them. We expect the voltage at V_1 to be 3V and the voltage at
# V_2 to be 6V. Show that through analysis.
my $netlist =<<END;
R_1		N0	N1	1000
R_2		N1	N2	1000
R_3		N2	N3	1000
V_S		N3	N0	9
END

if ( $show_working ) {
	print "Netlist is:-\n\n";
	print "\t", join("\n\t", (split(/\n/, $netlist))), "\n\n";
}

# 2. Read in the netlist
# 2.1. Figure out number of nodes
my %nodes;
foreach my $line (split(/\n/, $netlist)) {
	my (undef, $sn, $en) = split(/\s+/, $line);
    $nodes{$sn}++;
    $nodes{$en}++;
}
my $num_nodes = scalar(keys %nodes);

# 2.2 Create a conductance adjacency matrix, and 
# lookup tables for components and their values
my %resistors;
my %voltages;
my $G_adjacency = make_matrix(0, $num_nodes, $num_nodes);
foreach my $line (split(/\n/, $netlist)) {
	my ($ct, $sn, $en, $val) = split(/\s+/, $line);
	
	my $i = substr($sn, 1, 1);
	my $j = substr($en, 1, 1);
	
	if ( $ct =~ /^R/ ) {	# a resistor component. Put in the adjacency matrix
		$G_adjacency->[$i][$j] += parse_from_string("1/$ct");
		# matrix is symmetrical for resistors
		$G_adjacency->[$j][$i] += parse_from_string("1/$ct");
		
		$resistors{$ct} = $val;	# we will plug in the component values later
	}
	elsif ( $ct =~ /^V/ ) {	# a voltage source
		# TODO: handle negative voltages etc.
		# also assuming first node is high voltage, second is low
		my $high_v = 'V_' . $i;
		my $low_v = 'V_' . $j;
		if ( exists $voltages{$low_v} ) {
			$voltages{$high_v} = $voltages{$low_v} + $val;
		}
		elsif ( exists $voltages{$high_v} ) {
			$voltages{$low_v} = $voltages{$high_v} - $val;
		}
		else {
			$voltages{$low_v} = 0;
			$voltages{$high_v} = $val;
		}
	}
	else {
		print "Unrecognized component: '$ct'\n";
	}
}

$G_adjacency = simplify_matrix($G_adjacency);

if ( $show_working ) {
	print "Conductance adjacency:-\n\n\t";
	foreach my $i (0..$num_nodes-1) {
		foreach my $j (0..$num_nodes-1) {
			print $G_adjacency->[$i][$j], ";\t";
		}
		print "\n\t";
	}
	print "\n";
	print "Known voltages at nodes:-\n\n";
	foreach my $voltage (sort keys %voltages) {
		print "\t$voltage = $voltages{$voltage} V\n";
	}
	print "\n";
}

# 3. Construct a conductance matrix G such that if we have
# a vector of voltages at each node V then G*V gives the net current at 
# each (internal) node. As per KCL those should all be 0 for a solved network.
my $G = make_matrix(0, $num_nodes, $num_nodes);
foreach my $i (0..$num_nodes-1) {
	foreach my $j (0..$num_nodes-1) {
		if ( $i == 0 ) {
			$G->[$i][$j] = 0;
		}
		elsif ( $i == $num_nodes-1 ) {
			$G->[$i][$j] = 0;
		}
		elsif ( $i == $j ) {
			# G_ii is the sum of the conductances coming into the node i
			foreach my $k (0..$num_nodes-1) {
				next if $k == $j;
				$G->[$i][$j] += $G_adjacency->[$i][$k];
			}
		}
		else {
			# G_ij is the negative of the conductance between the nodes i and j
			$G->[$i][$j] = -1 * $G_adjacency->[$i][$j];
		}
	}
}

$G = simplify_matrix($G);

if ( $show_working ) {
	# TODO: Find some good module for displaying matrices in the terminal.
	print "Matrix G:-\n\n\t";
	foreach my $i (0..$num_nodes-1) {
		foreach my $j (0..$num_nodes-1) {
			print $G->[$i][$j], ";\t";
		}
		print "\n\t";
	}
	print "\n";
}

# 4. Define symbols for the voltages at each node (e.g. 'V_0', 'V_1', ...)
my @voltages;
push @voltages, ["V_" . $_] for (0..$num_nodes-1);
# i.e. the $V matrix will be: [['V_0'],['V_1'],etc.]
my $V = make_symbolic_matrix(\@voltages);

# 5. Multiply G and V to get expressions for the net current I at each node, I = G*V
my $I = multiply_matrix($G, $V);

if ( $show_working ) {
	print "Expressions for each internal node:-\n\n";
	for (1..$num_nodes-2) {
		print "\tAt node $_:\t$I->[$_][0]\n";
	}
	print "\n";
}

# 6. Substitute known values into these expressions
my $I_v = simplify_matrix(implement_matrix($I, { %voltages, %resistors }));

# 7. Extract the expressions for each node and put them into Equation objects 
my %Equations;
foreach my $node_num (1..$num_nodes-2) {
    $Equations{"Node $node_num"} = Math::Symbolic::Custom::Equation->new($I_v->[$node_num][0], '0');
}

if ( $show_working ) {
	print "Putting in known values and equating:-\n\n";
	foreach my $node (sort keys %Equations) {
		print "\t", $node, ":\t", $Equations{$node}->to_string(), "\n";
	}
	print "\n";
}

# 8. Solve the simultaneous equations. Work with Node 1 and Node 2
# Make V_1 the subject of Equation 1
my $V_1_eq1 = $Equations{"Node 1"}->isolate('V_1');  
if ( $show_working ) {
    print "Make V_1 subject of equation for Node 1:-\n\n\t", $V_1_eq1->to_string(), "\n\n";
}
# Substitute this expression for V_1 into Equation 2 and make V_2 the subject
my $V_2_eq1 = $Equations{"Node 2"}->implement('V_1' => $V_1_eq1->RHS());
if ( $show_working ) {
    print "Substitute expression for V_1 into equation for Node 2:-\n\n\t", $V_2_eq1->to_string(), "\n\n";
}
# Isolate V_2 in that new equation and simplify down:
my $V_2_eq2 = $V_2_eq1->isolate('V_2')->simplify(); 
if ( $show_working ) {
    print "Make V_2 the subject of that equation and simplify down:-\n\n\t", $V_2_eq2->to_string(), "\n\n";
}
# V_2 should have resolved. Plug it into the expression for V_1
my $V_1_eq2 = $V_1_eq1->implement('V_2' => $V_2_eq2->RHS())->simplify();
if ( $show_working ) {
    print "Substitute V_2 back into equation for V_1 and simplify down:-\n\n\t", $V_1_eq2->to_string(), "\n\n";
}

# 9. Check the solutions are as expected
ok( $V_1_eq2->RHS()->value() == 3, "Voltage V_1 is 3" );
ok( $V_2_eq2->RHS()->value() == 6, "Voltage V_2 is 6" );

exit 0;

