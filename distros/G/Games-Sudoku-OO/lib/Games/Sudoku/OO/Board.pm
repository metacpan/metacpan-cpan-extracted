package Games::Sudoku::OO::Board;

use strict;
use warnings;

use Games::Sudoku::OO::Set::Row;
use Games::Sudoku::OO::Set::Column;
use Games::Sudoku::OO::Set::Square;
use Games::Sudoku::OO::Cell;
use Carp;

our $VERSION = "0.03";

sub new {
    my $proto = shift;
    my %args = (text_grid=>undef, @_);
    my $self = {};  
    bless ($self);

    if ($args{text_grid}){
	$self->importGrid($args{text_grid});
    }
    return $self;
}



sub importGrid{
    my $self = shift;
    my $text_grid = shift;
    
    open my $fh, $text_grid or confess "can't open $text_grid: $!";    
    my @grid_lines = <$fh>;
    close $fh;

    my $size = $self->{size} = @grid_lines;
    croak "I only support grids of size 9 or 16\n" 
	unless (($size == 9) or ($size == 16)); 
    
    my %possibles;
    my $first;
    if ($size <= 10){
	$first =1;
    }else {
	$first =0;
    }
    for (my $i = 0; $i < $size; $i++){
	$possibles{$i+$first} = 1;
    }
    

    for (my $i = 0; $i < $size; $i++){
	push @{$self->{ROWS}}, Games::Sudoku::OO::Set::Row->new(possibles=>\%possibles);
	push @{$self->{COLUMNS}}, Games::Sudoku::OO::Set::Column->new(possibiles=>\%possibles);
	push @{$self->{SQUARES}}, Games::Sudoku::OO::Set::Square->new(possibles=>\%possibles);
    }

    foreach (my $row =0; $row < $size; $row++){
	foreach (my $column =0; $column < $size; $column++){
	    my $cell = Games::Sudoku::OO::Cell->new(possibles=>\%possibles);
	    my $square = int ($column/sqrt($size)) + int ($row/sqrt($size))*int(sqrt($size));
	    ($self->{ROWS}[$row])->addCell($cell);
	    ($self->{COLUMNS}[$column])->addCell($cell);
	    ($self->{SQUARES}[$square])->addCell($cell);
	    my $value = substr($grid_lines[$row], $column, 1);
	    if ($value =~ /[0-9A-Fa-f]/){
		$cell->setValue(hex $value);
	    }
	}
    }
    1;
}

sub toStr {
    my $self = shift;
    my $string = "";
    foreach my $row(@{$self->{ROWS}}){
	$string .= $row->toStr() . "\n";
    }
    return $string;
}

sub solve {
    my $self = shift;
    my ($type, $i) = @_;
    my $set_name = uc $type . 'S';  #convert row to ROWS, column to COLUMNS
    my $set = $self->{$set_name}[$i];
    $set->solve();
}

sub solveRow {
    my $self = shift;
    $self->solve('row', @_);
}

sub solveColumn {
    my $self = shift;
    $self->solve('column', @_);
}

sub solveSquare {
    my $self = shift;
    $self->solve('square', @_);
 }

sub solveAll {
    my $self = shift;

    my $unsolved = 1;

    for(my $i=0; $i < $self->{size}**2; $i++){
    	$unsolved = 0;
	foreach my $set (@{$self->{ROWS}}, 
			 @{$self->{COLUMNS}}, 
			 @{$self->{SQUARES}})
	{
	    my $cells_remaining = $set->solve();
	    $unsolved ||= $cells_remaining;
	}
	last unless $unsolved;
    }
    return not $unsolved;
}
1;

__END__

=head1 NAME

Games::Sudoku::OO::Board - Object oriented Sudoku solver

=head1 SYNOPSIS

  use Games::Sudoku::OO::Board;
  my $board = Sudoku::OO::Board->new();
  $board->importGrid($txt_grid);

  print $board->toStr;

  # Tell Row 1 to solve itself as much as it can
  $board->solveRow(1);
  print $board->toStr;

  # Solve the whole board
  $board->solveAll;
  print $board->toStr;



=head1 DESCRIPTION

Games::Sudoku::OO takes an object oriented approach to solving Sudoku,
representing the column, row and square as derivatives of a base Set
class, which encapsulates the solving rules. The Board class is also
composed of cells (which know what set they are in) and is only
responsible for loading and updating the cells and interacting with
the users. The sets themselves do the solving.

=head1 USAGE



=head1 BUGS

- Doesn't solve all boards
- Display of unsolved boards is a bit odd


=head1 SUPPORT

- Email me


=head1 AUTHOR

Michael Cope
CPAN ID: COPE
	
cpan@copito.org
http://www.copito.org/perl

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Games::Sudoku::OO::Set Games::Sudoku::OO::Cell

=cut


