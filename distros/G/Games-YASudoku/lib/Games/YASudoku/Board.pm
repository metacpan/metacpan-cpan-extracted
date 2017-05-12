package Games::YASudoku::Board;

=head1 MODULE

Games::YASudoku::Board

=head1 DESCRIPTION

This module defines the Sudoku board.

=head1 METHODS

=over

=cut


use strict;
use Games::YASudoku::Square;


my $GROUPS = [
    [  0, 1, 2, 9,10,11,18,19,20 ], 
    [  3, 4, 5,12,13,14,21,22,23 ],
    [  6, 7, 8,15,16,17,24,25,26 ],
    [ 27,28,29,36,37,38,45,46,47 ],
    [ 30,31,32,39,40,41,48,49,50 ],
    [ 33,34,35,42,43,44,51,52,53 ],
    [ 54,55,56,63,64,65,72,73,74 ],
    [ 57,58,59,66,67,68,75,76,77 ],
    [ 60,61,62,69,70,71,78,79,80 ],
];


sub new {
    my $proto = shift;
    my $class = ref( $proto ) || $proto;

    my $self = [];

    bless $self, $class;
    $self->_init();

    return $self;
}


=item B<_init>

initialize a new board
The game board is 9 rows by 9 columns, but we will store the board in
a one dimensional array - For example, element 9 will map to row 2,
column 1 (keep in mind that the first element of the array is 0).

=cut

sub _init {
   my $self = shift;
   
   for my $i ( 0 .. 80 ){
       push @{$self}, Games::YASudoku::Square->new( $i );
   }

   return $self;
}


=item B<get_rows/get_row>

Get rows will return a ref to an array of all the rows.  get_row will
just return one row - valid row numbers are 1 - 9.

=cut

sub get_rows {
    my $self = shift;

    my @rows;
    for my $i ( 1 .. 9 ){
        push @rows, $self->get_row( $i );
    }

    return \@rows;
}



sub get_row  {
    my $self = shift;
    my $row_num = shift;

    return undef unless $row_num && ( $row_num >= 1 ) && ( $row_num <= 9);

    my $start = ( $row_num - 1 ) * 9;
    my @row;

    for my $i ( $start .. ( $start + 8 ) ){
        push @row, $self->[ $i ];
    }
    return \@row;
}



=item B<get_cols/get_col>

Get cols will return a ref to an array of all the cols.  get_col will
just return one row - valid col numbers are 1 - 9.

=cut

sub get_cols {
    my $self = shift;

    my @cols;
    for my $i ( 1 .. 9 ){
        push @cols, $self->get_col( $i );
    }

    return \@cols;
}

sub get_col  { 
    my $self = shift;
    my $col_num = shift;

    return undef unless $col_num && ( $col_num >= 1 ) && ( $col_num <= 9);

    my $start = $col_num - 1;
    my @col;

    foreach my $i ( 0 .. 8 ){
        my $column = $start + ( $i * 9 );
        push @col, $self->[ $column ];
    }
    return \@col;
}


=item B<get_grps/get_grp>

Groups are defined as a set of nine boxes group in squares,  there are
three rows of groups and three groups in each row.  They are numbered
as follows.

  1 | 2 | 3
 ---|---|---
  4 | 5 | 6
 ---|---|---
  7 | 8 | 9

get_grps will return a ref to an array of all the groups.  get_grp will
just return one group which can be specified by one of the numbers above.

=cut

sub get_grps {
    my $self = shift;

    my @groups;
    for my $i ( 1 .. 9 ){
        push @groups, $self->get_grp( $i );
    }

    return \@groups;
}

sub get_grp  {
    my $self = shift;
    my $grp_num = shift;

    return undef unless $grp_num && ( $grp_num >= 1 ) && ( $grp_num <= 9);

    my @grp;

    foreach my $i ( @{ $GROUPS->[ $grp_num - 1 ] } ){
        push @grp, $self->[ $i ];
    }
    return \@grp;
}

=item B<get_values>

return a list of all the squares with values set

=cut

sub get_values {
    my $self = shift;

    my @values;
    foreach my $square ( @{ $self } ){
        push @values, $square if ( $square->value );
    }

    return \@values;
}

    

=item B<get_element_membership>

This method will return the three groups that the element is a member of.
One row, one column and one group.

=cut

sub get_element_membership {
    my $self = shift;
    my $element = shift;

    my $element_id = $element->id;

    # what row is the element in
    my $row = int( $element_id / 9 ) + 1;
    my $col = ($element_id % 9) + 1;

    my $grp;
    for my $i ( 0 .. 8 ){
        $grp = ($i + 1) if grep /^$element_id$/, @{ $GROUPS->[ $i ] };
    }

    my @membership;
    push @membership, $self->get_row( $row ),
                      $self->get_col( $col ),
		      $self->get_grp( $grp );

    return \@membership;
}


=item B<show_board>

This method displays the current state of the board

=cut

sub show_board {
    my $self = shift;

    my $board_text;
    my $reg_row_mark = '+...' x 9 . '+';
    my $big_row_mark = '+---' x 9 . '+';

    for my $i ( 0 .. 80 ){
        if ( ($i % 9) == 0 ) {
	    if ( ($i % 27 ) == 0 ){
	        $board_text .= "\n$big_row_mark\n|";
	    } else {
	        $board_text .= "\n$reg_row_mark\n|";
	    }
	}
        my $value = $self->[$i]->value;
	if ( $value ){
	    $board_text .= sprintf( " %1d ", $self->[$i]->value );
	} else {
	    $board_text .= "   ";
	}
	if ( (( $i +1 ) % 3 ) == 0 ){
	    $board_text .= '|';
	} else {
	    $board_text .= ':';
	}
    }	 

    $board_text .= "\n$big_row_mark\n";

    return $board_text;
}

=item B<show_board_detail>

This method displays the current state of the board including the possible
values for each unsolved square.

=cut


sub show_board_detail {
    my $self = shift;

    my $board_text;
    my $reg_row_mark = '+.........' x 9 . '+';
    my $big_row_mark = '+---------' x 9 . '+';

    for my $i ( 0 .. 80 ){
        if ( ($i % 9) == 0 ) {
	    if ( ($i % 27 ) == 0 ){
	        $board_text .= "\n$big_row_mark\n|";
	    } else {
	        $board_text .= "\n$reg_row_mark\n|";
	    }
	}
        my $value = $self->[$i]->value;
	if ( $value ){
	    $board_text .= sprintf( " %7d ", $self->[$i]->value );
	} else {
	    $board_text .= sprintf("(%7s)", join('', @{ $self->[$i]->valid }));
	}
	if ( (( $i +1 ) % 3 ) == 0 ){
	    $board_text .= '|';
	} else {
	    $board_text .= ':';
	}
    }	 

    $board_text .= "\n$big_row_mark\n";

    return $board_text;
}


=item B<run_board>

this method solve the board

=cut

sub run_board {
    my $self = shift;

    my $new_values = 0;
    my $values = @{$self->get_values};
    my $passes = 0;
    while ( $values != $new_values ){
        $self->pass_one;
        $self->pass_two;

        $passes++;
        $values = $new_values;
	$new_values = @{$self->get_values};
    }
    return $passes;
}


=item B<pass_one>

the first pass looks for values and reduces valid_num arrays

=cut

sub pass_one {
    my $self = shift;
    
    my $new_values = 0;
    my $values = @{$self->get_values};
    while ( $values != $new_values ){
    
        foreach my $element ( @{ $self } ){
            next if $element->value;
            my $ms = $self->get_element_membership( $element );
	    
            foreach my $member ( @{ $ms } ){
                foreach my $e ( @{ $member } ){
                    next unless $e->value;
		    
                    $element->valid_del( $e->value );
		    if ( @{ $element->valid } == 0 ){
		        warn $self->show_board_detail;
			use Data::Dumper;
			warn Dumper $element;
			warn Dumper $e;
			warn Dumper $member;
		        die "Something very wrong here!!!!";
		    }
                }
            }

            my @valid = $element->valid;
            if ( @{ $element->valid } == 1 ){
                $element->value( $element->valid->[0] );
            }
        }

        $values = $new_values;
	$new_values = @{$self->get_values};
    }
    return @{$self->get_values};
}

=item B<pass_two>

this pass looks for valid_num arrays which have a unique value
and therefore need to have that value assigned to them

Example: Square 1 can be (1,2,3)
         Square 2 can be (2,3,4,6)
         Square 3 can be (2,3,4,5)
         Square 4 can be (5,6)
 Since square 1 is the only one with a '1', it needs to be 1

=cut

sub pass_two {
    my $self = shift;
    
    foreach my $element ( @{ $self } ){
        next if $element->value;


        # get all the groups this square is an member of
        foreach my $member ( @{$self->get_element_membership($element)}){
	    my %valid_nums;
            map { $valid_nums{ $_ } = $_ } @{ $element->valid };

            foreach my $e ( @{$member} ){
	        # don't work on the current element
	        next if ( $e->id == $element->id );
		next if ( $e->value ); # skip element that is already processed

                foreach my $valid ( @{ $e->valid } ){
                    delete $valid_nums{ $valid };
		    last if (( keys %valid_nums ) == 0 );
		}
            }
	    
            if ( (keys %valid_nums) == 1 ){
		my @keys = keys %valid_nums;
                $element->value( $keys[0] );
		$self->pass_one;
	        last;
	    }
        }
    }
    
    return @{$self->get_values};
}


1;


=head1 AUTHOR

Andrew Wyllie <wyllie@dilex.net>

=head1 BUGS

Please send any bugs to the author

=head1 COPYRIGHT

The Games::YASudoku moudule is free software and can be redistributed
and/or modified under the same terms as Perl itself.

