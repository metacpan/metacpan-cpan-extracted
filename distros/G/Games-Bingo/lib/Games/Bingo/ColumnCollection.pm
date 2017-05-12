package Games::Bingo::ColumnCollection;

use strict;
use warnings;
use integer;
use Games::Bingo;
use Games::Bingo::Column;
use vars qw(@ISA $VERSION);
use Carp;

@ISA = qw(Games::Bingo);
$VERSION = '0.18';

sub new {
	my $class = shift;

	my $self =  bless [], $class;
	
	push @{$self}, @_ if (@_);

	return $self;
}

sub divide {
	my $self = shift;
	my $number_of_columns = shift;
	my @numbers = @_;

	for (my $number = 0; $number < $number_of_columns; $number++) {
		my @s = ();
		if ($number == 0) {
			@s = splice(@numbers, 0, 9);
		} elsif ($number == 8) {
			@s = splice(@numbers, 0, 11);
		} else {
			@s = splice(@numbers, 0, 10);
		}
		my $column = Games::Bingo::Column->new($number, @s);

		$self->add_column($column);	 
	}
}

sub add_column {
	my ($self, $column, $index) = @_;
	
	if ($index) {
		$self->[$index] = $column; 
	} else {
		push(@{$self}, $column); 
	}
}

sub _remove_column {
	my ($self, $idx) = @_;

	if ($idx < 0 ) {
		carp "cannot remove column, index cannot be a negative number ($idx)\n";
		return undef;
	} elsif ($idx > (scalar @{$self})) {
		carp "cannot remove column, no column with that index ($idx)\n";
		return undef;
	}

	splice(@{$self}, $idx, 1); 
}

sub get_column {
	my ($self, $index, $do_splice, $auto_splice) = @_;

	if ($index !~ m/^(-)?\d+$/) {
		carp "no or illegal index specified";
		return undef;		
	}

	if ($index < 0 ) {
		carp "cannot get column, index cannot be a negative number ($index)\n";
		return undef;
	} elsif ($index > (scalar @{$self})) {
		carp "cannot get column, no columns with that index ($index)\n";
		return undef;
	}
	
	my $column = $self->[$index];
		
	if ($auto_splice and $column) {
		my $length = $column->count_numbers();
		if ($length < 2) {
			$do_splice = 1;
		} else {
			$do_splice = 0;
		}
	}
	
	if ($do_splice) {
		my $v = $self->_remove_column($index);
	}
	return $column;
}

sub get_random_column {
	my ($self, $do_splice, $auto_splice) = @_;
	
	my $index = $self->random(scalar @{$self});	
	my $column;
	
	eval {
		$column = $self->get_column($index, $do_splice, $auto_splice);
	};
	
	if (@!) {
		warn "unable to get random column: $@";
		return undef;	
	} else {
		return $column;
	}
}

sub count_columns {
	my $self = shift;
	
	return scalar(@{$self});
}

1;

__END__

=head1 NAME

Games::Bingo::ColumnCollection -  a collection class for holding columns

=head1 SYNOPSIS

	my $col = Games::Bingo::ColumnCollection-E<gt>new();

	my $c = Games::Bingo::Column-E<gt>new(0, [1, 2, 3, 4, 5, 6, 7, 8, 9]);

	$col-E<gt>add_column($c1);

	my $d = $col-E<gt>get_column(1);

	my $e = $col-E<gt>get_random_column();

=head1 DESCRIPTION

The ColumnCollection is used when building the bingo cards and is a
temporary data structure for holding object of the class Column.

The class is an encapsulated array, which is 1 indexed.

=head1 METHODS

=head2 new

The constructor blesses and array and returns.

=head2 divide

The divided method has nothing as such to do with the class apart from
it is a helper method, which is used to taking a list of numbers (1-90
expected, see Games::Bingo).

It then divided this list into 9 separate arrays of the following
constallations:

=over 4

=item *

1-9

=item *

10-19

=item *

20-29

=item *

30-39

=item *

40-49

=item *

50-59

=item *

60-69

=item *

70-79

=item *

80-90

=back

From these arrays the Columns are built and the column collection is
slowly populated, when done the column collection is returned.

=head2 add_column

This is a push like method, is can be used to add an additional to the
collection.

=head2 remove_column

The method can remove a column specified by its index, the argument
specifies this index.

=head2 get_column

The method returns a column specified by its index, the argument to this
method is the index.

The second argument is an indicator of whether the returned collection
should be removed from the list, B<1> for removed and B<0> for not
removing, the latter is the default.

=head2 get_random_column

This method returns a random columns, the optional parameter can be used
to indicate whether the column should be removed from the list. B<1>
indicates a removed and nothing (the default) that nothing should be
done.

=head2 reset_columns

The method uses the fact that the class contains Columns and a bit of
polymorphy, so this method can be used to set the status of all Columns
contained in the class. ' The parameter is the status which you want to
set, either B<1> or B<0>.

=head2 count_columns

Returns the number of columns in G::B::Column object.

=head1 SEE ALSO

=over 4

=item Games::Bingo

=item Games::Bingo::Column

=back

=head1 TODO

The TODO file contains a complete list for the whole Games::Bingo
project.

=head1 ACKNOWLEDGEMENTS

My friend Allan helped me out with some of the algoritmic stuff and was
in when this class was thought up.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Games-Bingo is (C) by Jonas B. Nielsen, (jonasbn) 2003-2015

Games-Bingo is released under the artistic license 2.0

=cut