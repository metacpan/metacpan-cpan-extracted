#!/usr/bin/env perl

use v5.38;
use lib ( '../lib', 'lib' );
use Logic::Relational::Syntax;

# Example/tutorial puzzle from "Murdoku" by M. Garand, Penguin Michael Joseph 2005 

logic MurdokuExample {

	# specify the grid
	facts {
		# bottom left is (0, 0) (x, y)
		#  x  y  can occupy?	beside?			contains	room?		
		at(0, 0, 'available', 	'nothing', 		'nothing', 	'main bedroom');
		at(1, 0, 'available',	'nothing',		'bed',		'main bedroom');
		at(2, 0, 'available',	'by plant',		'nothing',	'main bedroom');
		at(3, 0, 'blocked',		'nothing',		'plant',	'main bedroom');
		at(0, 1, 'available', 	'nothing', 		'nothing', 	'main bedroom');
		at(1, 1, 'available',	'nothing',		'bed',		'main bedroom');
		at(2, 1, 'available',	'nothing',		'nothing',	'main bedroom');
		at(3, 1, 'available',	'by window',	'nothing',	'main bedroom');
		at(0, 2, 'blocked', 	'nothing', 		'TV', 		'living room');
		at(1, 2, 'available',	'by TV',		'nothing',	'living room');
		at(2, 2, 'available',	'by table',		'nothing',	'living room');
		at(3, 2, 'available',	'nothing',		'nothing',	'living room');
		at(0, 3, 'available', 	'by TV', 		'nothing', 	'living room');
		at(1, 3, 'available',	'by table',		'nothing',	'living room');
		at(2, 3, 'blocked',		'nothing',		'table',	'living room');
		at(3, 3, 'available',	'by table',		'nothing',	'living room');
	}

	rule Austin( $x, $y, $room ) {
		# Austin is beside a table
		fresh my $p;
		at($x, $y, 'available', 'by table', $p, $room);	
	}
	
	rule Brycen( $x, $y, $room ) {
		# Brycen is on a bed
		fresh my $p;
		at($x, $y, 'available', $p, 'bed', $room);	
	}

	rule Charlene( $x, $y, $room ) {
		# Charlene is by a window
		fresh my $p;
		at($x, $y, 'available', 'by window', $p, $room);
	}
	
	rule solve( $locs ) {
		fresh my ($A_x, $A_y, $B_x, $B_y, $C_x, $C_y, $V_x, $V_y) in 0..3;
		fresh my ($A_r, $B_r, $C_r, $V_r);		
		
		$locs := [	$A_x, $A_y, $A_r, 	# Austin x, y, room
					$B_x, $B_y, $B_r, 	# Brycen x, y, room
					$C_x, $C_y, $C_r,	# Charlene x, y, room
					$V_x, $V_y, $V_r,	# Vinny x, y, room
					];
		
		Austin($A_x, $A_y, $A_r);
		Brycen($B_x, $B_y, $B_r);
		Charlene($C_x, $C_y, $C_r);
		
		# Vinny has to be in the last available space
		fresh my ($p, $q);
		at($V_x, $V_y, 'available', $p, $q, $V_r);
		
		all_different($A_x, $B_x, $C_x, $V_x);
		all_different($A_y, $B_y, $C_y, $V_y);
		
		label($A_x, $A_y, $B_x, $B_y, $C_x, $C_y, $V_x, $V_y);
	}
}

say "Where can Austin be?";
query MurdokuExample::Austin( fresh my $A_x, fresh my $A_y, fresh my $A_room ) -> my $Austin_q;

while ( my $s = $Austin_q->next ) {

	my $x = $s->value($A_x);
	my $y = $s->value($A_y);
	my $room = $s->value($A_room);
	
	say "\tAustin can be at: ($x, $y, $room)";	
}

say "\nWhere can Brycen be?";
query MurdokuExample::Brycen( fresh my $B_x, fresh my $B_y, fresh my $B_room ) -> my $Brycen_q;

while ( my $s = $Brycen_q->next ) {

	my $x = $s->value($B_x);
	my $y = $s->value($B_y);
	my $room = $s->value($B_room);
	
	say "\tBrycen can be at: ($x, $y, $room)";	
}

say "\nWhere can Charlene be?";
query MurdokuExample::Charlene( fresh my $C_x, fresh my $C_y, fresh my $C_room ) -> my $Charlene_q;

while ( my $s = $Charlene_q->next ) {

	my $x = $s->value($C_x);
	my $y = $s->value($C_y);
	my $room = $s->value($C_room);
	
	say "\tCharlene can be at: ($x, $y, $room)";	
}

say "\nAttempt to fix the locations of Austin, Brycen, Charlene and the victim (Vinny) to solve:\n";
query MurdokuExample::solve( fresh my $sol ) -> my $fix_q;

while ( my $s = $fix_q->next ) {

	my $loc = $s->value($sol);
	
	say "Austin location: (", $loc->[0], ",", $loc->[1], ") (", $loc->[2], ")";
	say "Brycen location: (", $loc->[3], ",", $loc->[4], ") (", $loc->[5], ")";
	say "Charlene location: (", $loc->[6], ",", $loc->[7], ") (", $loc->[8], ")";
	say "Vinny (Victim) location: (", $loc->[9], ",", $loc->[10], ") (", $loc->[11], ")\n";
	
	my %rooms;
	push @{$rooms{$loc->[2]}}, 'Austin';
	push @{$rooms{$loc->[5]}}, 'Brycen';
	push @{$rooms{$loc->[8]}}, 'Charlene';
	
	my @with_victim = $rooms{$loc->[11]}->@*;

	if ( scalar(@with_victim) != 1 ) {
		say "Could not isolate killer. More than one person in the same room as the victim!";	
	}
	else {
		say $with_victim[0], " was the killer!";
	}	
}

exit;

