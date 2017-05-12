package Games::Bingo::Column;

use strict;
use warnings;
use integer;
use Games::Bingo;
use vars qw(@ISA $VERSION);

@ISA = qw(Games::Bingo);
$VERSION = '0.18';

sub new {
	my $class = shift;
	my $label = shift;
	my @array = sort _reverse (@_);
	
	my $self = bless {
		label  => $label?$label:0,
		_array  => \@array
	}, $class;
}

sub _reverse { $b <=> $a }

sub populate {
	my ($self, $value) = @_;
	
	push @{$self->{_array}}, $value;
	
	@{$self->{_array}} = sort _reverse @{$self->{_array}};
}

sub get_random_number {
	my ($self, $do_splice) = @_;
	
	my $pos = $self->random($self->count_numbers);
		
	my $number = $self->{_array}->[$pos];
	splice(@{$self->{_array}}, $pos, 1) if $do_splice;
	
	return $number;
}

sub count_numbers {
	my $self = shift;
	
	return scalar @{$self->{_array}};
}

sub get_highest_number {
	my ($self, $do_splice) = @_;

	my $number;
	if ($do_splice) {
		$number = shift(@{$self->{_array}});
		return $number;
	} else {		
		return $self->{_array}->[0];
	}
}

sub get_label {
	my $self = shift;
	
	return $self->{label};
}

1;

__END__

=head1 NAME

Games::Bingo::Column - a column class used for generating bingo cards

=head1 SYNOPSIS

	my $c = Games::Bingo::Column-E<gt>new();

	foreach my $number(@numbers) {
		$c-E<gt>populate($number);
	}

	my @numbers = qw(1 2 3 4 5 6 7 8 9);

	my $c = Games::Bingo::Column-E<gt>new(@numbers);

	my $number = $c-E<gt>get_highest_number();

=head1 DESCRIPTION

The Column is used when building the bingo cards and is a temporary
data structure.

The class has two attributes:

=over 4

=item *

_array

B<_array> is a list of numbers for containment in the class, since the class
actually is nothing but an array with a status flag.

=item *

label

The label being the group to which the numbers in the array belong.

=back

=cut

=head1 METHODS

=head2 new

The contructor optionally takes an array as an argument, and sets the
B<_array> attribute to point to this.

=head2 populate

B<populate> is a simple accessor which can be used to add additional number
to the list of number contained in the class. This is a secondary use of
the class, please refer to the description of the algoritms used in the
program described in the Games::Bingo class.

=head2 get_highest_number

The B<get_highest_number> is also a simple accessor, it returns the
highest number from the list contained in the class.

If the optional parameter is set to true, it splices the list contained
in the class, meaning the class shrinks by B<1>. Default behaviour is
not shrinking.

=head2 get_random_number

The B<get_random__number> is also a simple accessor, it returns a
random number from the list contained in the class.

If the optional parameter is set to true, it splices the list contained
in the class, meaning the class shrinks by B<1>. Default behaviour is
not shrinking. See also B<get_highest_number>.

=head2 _reverse

The method used by Perls sort to sort the list

=head2 get_label

Accessor returning the label of the G::B::Column object.

=head2 count_numbers

Returns the number of numbers contained in a G::B::Column object.

=head1 SEE ALSO

=over 4

=item L<Games::Bingo>

=item L<Games::Bingo::ColumnCollection>

=back

=head1 TODO

The TODO file contains a complete list for the whole Games::Bingo
project.

=head1 ACKNOWLEDGEMENTS

My friend Allan helped me out with some of the algoritmic stuff and was
in on the development when this class was thought up.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Games-Bingo is (C) by Jonas B. Nielsen, (jonasbn) 2003-2015

Games-Bingo is released under the artistic license 2.0

=cut
