package Grid::Coord;
use strict; use warnings;

use Data::Dumper;
use Carp qw/confess/;

our $VERSION = '0.05';
# $Id$

########################################### main pod documentation begin ##

=head1 NAME

Grid::Coord - abstract representation and manipulation of points and rectangles

=head1 SYNOPSIS

  use Grid::Coord
	my $point1 = Grid::Coord->new(5,4);        # point(y=>5, x=>4)
	my $rect1  = Grid::Coord->new(2,3 => 6,5); # rectangle
	print "TRUE" if $rect1->contains($point1);

	my $rect2  = Grid::Coord->new(3,4 => 5,5); # another rectangle
	my $rect3  = $rect1->overlap($rect2)       # (3,4 => 5,5)
	print $rect3->stringify;                   # "(3,4 => 5,5)"
	print $rect3;                              # "(3,4 => 5,5)"
	print "TRUE" if $rect3->equals(Grid::Coord->new(3,4 => 5,5));
	print "TRUE" if $rect3 == Grid::Coord->new(3,4 => 5,5);

=head1 DESCRIPTION

Manage points or rectangles on a grid.  This is generic, and could
be used for spreadsheets, ascii art, or other nefarious purposes.

=head1 USAGE

=head2 Constructor

 Grid->Coord->new($y, $x);
 Grid->Coord->new($min_y, $min_x,  $max_y, $max_x);

=head2 Accessing coordinates

The C<min_y>, C<min_x>, C<max_y>, C<max_x> functions:

 print $coord->max_x; # get value
 $coord->min_x(4);    # set value to 4

=head2 Relationships with other Coords

 $c3 = $c1->overlap($c2);
 print "TRUE" if $rect1->contains($rect2);
 print "TRUE" if $rect1->equals($rect2);

=head2 Overloaded operators

Four operators are overloaded: 

=over 4

=item * the stringification operator

So that C<print $coord> does something reasonable

=item * the equality operator 

so that C<if ($coord1 == $coord2)> 
does the right thing.

=item * the add operator

So that C<$c1 + $c2> is a synonym for C<$c1->offset($c2)>

=item * the subtract operator

So that C<$c1 - $c2> is a synonym for C<$c1->delta($c2)>

=back

=head2 Iterating

The iterator returns a Grid::Coord object for each cell in the current
Grid::Coord range.

  my $it = $grid->cell_iterator; # or ->cell_iterator_rowwise
  # my $it = $grid->cell_iterator_colwise; # top to bottom

  while (my $cell = $it3->()) {
    # do something to $cell
  }

You can also iterate columns/rows with
  $grid->cells_iterator
  $grid->rows_iterator

=head1 BUGS

None reported yet.

=head1 SUPPORT

From the author.

=head1 AUTHOR

	osfameron@cpan.org
	http://osfameron.perlmonk.org/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

use overload
	q("") => \&stringify,
	q(==) => \&equals,
	q(!=) => \&not_equals,
	q(+)  => \&offset,
	q(-)  => \&delta;

sub new
{
	my $class = shift;

	if (@_ == 2) {
		push @_, @_;
	} elsif (@_ != 4) {
		die "Grid::Coord objects must be (y,x) or (miny,minx=>maxy,maxx)\n";
	}
	
	my $self = bless [@_], (ref ($class) || $class);
	return ($self);
}

sub min_y {
	my $self=shift;
	if (! @_) { return $self->[0] } 
	else { $self->[0] = shift }
}
sub min_x {
	my $self=shift;
	if (! @_) { return $self->[1] } 
	else { $self->[1] = shift }
}
sub max_y {
	my $self=shift;
	if (! @_) { return $self->[2] } 
	else { $self->[2] = shift }
}
sub max_x {
	my $self=shift;
	if (! @_) { return $self->[3] } 
	else { $self->[3] = shift }
}

sub is_point {
	my $self = shift;
	for (0..1) {
    my ($min, $max) = ($self->[$_], $self->[$_+2]);
    return unless defined $min && defined $max;
		return unless $min == $max;
	}
	return 1;
}

sub overlap {
	my ($self, $other)=@_;
	if (! $other->isa(__PACKAGE__)) {
		die "Can't overlap with something that isn't a Grid::Coord object!\n";
	}
	my @coords = (
	 max($self->min_y, $other->min_y),
	 max($self->min_x, $other->min_x),
	 min($self->max_y, $other->max_y),
	 min($self->max_x, $other->max_x) 
	);
	return if ($coords[0] > $coords[2] or
			$coords[1] > $coords[3]);
	return $self->new(@coords);
}

sub contains {
	my ($self, $other)=@_;
	if (! $other->isa(__PACKAGE__)) {
		die "Can't 'contains' with something that isn't a Grid::Coord object!\n";
	}
	return ($self->overlap($other) == $other);
}

sub stringify {
	my $self=shift;
  my @rep = map { defined $_ ? $_ : 'null' } @$self;
	if ($self->is_point) {
		return "($rep[0],$rep[1])"
	} else {
		return "($rep[0],$rep[1], $rep[2],$rep[3])";
	}
}
sub equals {
	my ($self, $other) = @_;
	for (0..3) {
		return unless 
      (defined $self->[$_]) ?
        defined $other->[$_] && $self->[$_] == $other->[$_]
      : ! defined $other->[$_];
	}
	return $self;
}
sub not_equals {
    # new versions of Test::Builder seem to make cmp_ok fail on this
	my ($self, $other) = @_;
    return ! $self->equals($other);
}

sub offset { # 'add' 2 ranges together, offsetting them
	my $self=shift;
	if (ref $_[0] eq "Grid::Coord") {
		my $other = shift;
		my @coords;
		for (0..3) {
			push @coords, only($self->[$_],$other->[$_],sub { return $_[0]+$_[1] })
		}
		return $self->new(@coords);
	} else {
		return $self->offset($self->new(@_));
	}
}
sub delta { # 'subtract' 2 ranges together, calculating the offest 
	my $self=shift;
	if (ref $_[0] eq "Grid::Coord") {
		my $other = shift;
		my @coords;
		for (0..3) {
			push @coords, only($self->[$_],$other->[$_],sub { return $_[1]-$_[0] })
		}
		return $self->new(@coords);
	} else {
		return $self->offset($self->new(@_));
	}
}

sub head { my $self=shift; return $self->new($self->[0], $self->[1]) }
sub tail { my $self=shift; return $self->new($self->[2], $self->[3]) }

sub row {my $self=shift; return $self->new($self->[0],undef,$self->[0],undef)}
sub col {my $self=shift; return $self->new(undef, $self->[1],undef,$self->[1])}

sub min     { return only(@_) || (($_[0] < $_[1]) ? $_[0] : $_[1]) }
sub max     { return only(@_) || (($_[0] > $_[1]) ? $_[0] : $_[1]) }



=begin developer

=head3 only

A convenience function.  Has 2 forms.

 only($a, $b);

The 2 arg form returns the other argument if one argument is undef.  
(As a consequence, if both are null, it returns null).  If neither are undef,
it also returns null.  This is useful for the min and max functions, where
we want to be able to calculate intersections, but also of row and column
ranges where one side may be undef).

 only($a, $b, sub { ... });

Again, returns the other argument if one argument is undef.  However, if neither
is undef it passes both arguments to the coderef.  This is useful in calculating
offsets, where we want this kind of behaviour:

       0 + 0     = 0
   undef + 0     = 0
	 undef + undef = undef

=cut

sub only {
	if (! defined $_[0]) { return $_[1]}
	if (! defined $_[1]) { return $_[0]}
	if (my $coderef=$_[2]) {
		return $coderef->(@_)
	} else {
		return
	}
}

{
no warnings 'once';
*cell_iterator=\&cell_iterator_rowwise;
}
sub cell_iterator_rowwise {
	my $self=shift;
	return $self->_cell_iterator(
			$self->rows_iterator, 
			sub{$self->cols_iterator});
}
sub cell_iterator_colwise {
	my $self=shift;
	return $self->_cell_iterator(
			$self->cols_iterator,
			sub{$self->rows_iterator}); 
}

sub _cell_iterator {
# We pass in the major-line iterator as an iterator.
# However, as the minor-line iterator will be created
# various times, we pass in a factory function instead!

	my ($self, $maj_it, $min_fac) = @_;
	my $min_it = $min_fac->();

	my $maj=$maj_it->();
	return sub {
		{
			return unless $maj;
			if (my $min=$min_it->()) {
				return $maj->overlap($min)
			} else {
				$maj = $maj_it->();
				$min_it = $min_fac->();
				redo;
			}
		}
	}
}
sub rows_iterator {
	my $self=shift;
	my $row=$self->row;
	return $self->line_iterator($row, 1, undef);
}
sub cols_iterator {
	my $self=shift;
	my $col=$self->col;
	return $self->line_iterator($col, undef, 1);
}

sub line_iterator {
	my ($self, $orig_line, $y, $x)=@_;
	my $line=$orig_line;
	return sub {

    # TODO: warning on next line in eq
    #if ($_[0] eq 'clone') { die;return line_iterator($self,$orig_line, $y,$x) }

		my $old_line = $line;
		if ($line) {
			$line = $line->offset($y,$x);
			if (! $line->overlap($self)) {
				$line=undef;
			}
		}
		return $old_line;
	}
}

1; #this line is important and will help the module return a true value
__END__

