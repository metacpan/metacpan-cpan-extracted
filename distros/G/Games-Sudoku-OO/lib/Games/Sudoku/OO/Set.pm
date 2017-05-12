#!/usr/local/bin/perl -w

package Games::Sudoku::OO::Set;

use strict;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = (cells=>undef, possibles=>undef, @_);
    my $self = {};  
    if (defined $args{possibles}){
	%{$self->{POSSIBLES}} = %{$args{possibles}};
	%{$self->{UNSOLVED_VALUES}} =  %{$args{possibles}};
    }else {
	$self->{POSSIBLES} = {};
	$self->{UNSOLVED_VALUES} = {};
    }
    
    @{$self->{QUEUED_SOLVED_CELLS}}= ();
    $self->{SOLVED_CELLS} = {};
    $self->{UNSOLVED_CELLS} = {};
    
    foreach my $cell (@{$args{cells}}){
	$self->addCell($cell);
    }
    bless ($self, $class);
    return $self;
}

sub addCell {
    my $self = shift;
    my $cell = shift;
    $self->setBackReference($cell);
    push @{$self->{CELLS}}, $cell;
    if (defined $cell->getValue()){
	$self->{SOLVED_CELLS}{$cell} = $cell;
	delete $self->{UNSOLVED_VALUES}{$cell->getValue()};	
    }else {
	$self->{UNSOLVED_CELLS}{$cell} = $cell;
    }
}

sub solve {
    my $self = shift;
    $self->propagateSolved();
    $self->findHasToBeCells();
    return keys %{$self->{UNSOLVED_CELLS}};
}

sub notifySolved{
    my $self = shift;
    my $cell = shift;
    #print STDERR "notified that ". $cell->toStr ." was solved\n";
    $self->{SOLVED_CELLS}{$cell} = 1;
    delete $self->{UNSOLVED_CELLS}{$cell};
    delete $self->{UNSOLVED_VALUES}{$cell->getValue()};
    push @{$self->{QUEUED_SOLVED_CELLS}}, $cell;
}

sub propagateSolved {
    my $self = shift;
    my @queue = @{$self->{QUEUED_SOLVED_CELLS}};
    return unless (@queue);
    
    @{$self->{QUEUED_SOLVED_CELLS}} = ();
    
    foreach my $solved_cell (@queue){
	#print "propagating :" . $solved_cell->toStr ."\n";
	while( my (undef, $test_cell) = each (%{$self->{UNSOLVED_CELLS}})){
	    $test_cell->notPossible($solved_cell->getValue());
	}
    }

    $self->checkConsistency();
}

sub findHasToBeCells {
    my $self = shift;
    my @unsolved_values = keys (%{$self->{UNSOLVED_VALUES}});
    foreach my $value (@unsolved_values){
	my @couldBe = ();
	foreach my $cell (values %{$self->{UNSOLVED_CELLS}}){
	    if ($cell->couldBe($value)){
		push @couldBe, $cell;
	    }
	}
	if (@couldBe == 1){
	    #print $couldBe[0]->toStr(). " has to be $value\n";
	    $couldBe[0]->setValue($value);
	}elsif(@couldBe){
	    my $saved_row;
	    my $rows_equal=1;
	    my $saved_column ;
	    my $columns_equal=1;
	    my $saved_square;
	    my $squares_equal = 1;
	    foreach my $cell (@couldBe){
		#print $cell->toStr . "could be $value\n";
		
		my $row = $cell->getRow();
		if (defined $saved_row && ($saved_row != $row)){
		 #   print $cell->toStr() . "not in the same row\n";
		    $rows_equal = 0;
		}
		$saved_row = $row;
		
		my $column = $cell->getColumn();
		if (defined $saved_column && ($saved_column != $column)){
		  #  print $cell->toStr() . "not in the same column\n";
		    $columns_equal = 0;
		}
		$saved_column = $column;

		my $square = $cell->getSquare();
		if (defined $saved_square && ($saved_square != $square)){
		    #print $cell->toStr() . "not in the same square\n";
		    $squares_equal = 0;
		}
		$saved_square = $square;
	    }
	    if ($squares_equal && $saved_square != $self){
	        #print "rest of square can't be $value\n";
		$saved_square->setCantBeCells($value,@couldBe);
	    }
	    if ($columns_equal && $saved_column != $self){
		#print "rest of column can't be $value\n";
		$saved_column->setCantBeCells($value,@couldBe);
	    }
	    if ($rows_equal && $saved_row != $self){
		#print "rest of row can't be $value\n";
		$saved_row->setCantBeCells($value,@couldBe);
	    }
	}
    }
}

sub setCantBeCells {
    my $self = shift;
    my $value = shift;
    my @has_to_be = @_;
    foreach my $cell (values %{$self->{UNSOLVED_CELLS}}){
	my $duplicate = 0;
	#print "checking if " . $cell->toStr() . "is a has to be\n";
	foreach my $has_to_be (@has_to_be){
	    if ($cell == $has_to_be){
		$duplicate++;
	    }
	}
	unless ($duplicate){
	    #print $cell->toStr . "can't be $value\n";
	    $cell->notPossible($value);
	}
    }
}

sub checkConsistency {
    my $self = shift;
    my %seen_values;
    foreach my $cell (@{$self->{CELLS}}){
	if(defined $cell->getValue()){
	    if($seen_values{$cell->getValue()}){
		print "INCONSISTENT!!!". $cell->toStr(). "\n";
	    }
	    
	    $seen_values{$cell->getValue()}++;
	}
    }
    
}

1;
