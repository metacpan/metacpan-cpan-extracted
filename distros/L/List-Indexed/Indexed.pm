
package List::Indexed;

$VERSION = "1.0";


################################################################################

# PUBLIC INTERFACE

################################################################################


sub new
{
	my $class = shift();

	my $obj = { };
	bless($obj, $class);
	
	$obj->clear();
	return $obj;
}


sub find
{
	my $obj = shift();
	my ($key) = @_;
	
	my $position = 0;
	foreach my $k (@{$obj->{'keys'}})
	{
		if ($k eq $key) {
			return $position;
		}
		$position++;
	}
	return undef;
}


sub read
{
	my $obj = shift();
	my ($key) = @_;

	my $element;
	if (defined $key)
	{
		my $position = $obj->find($key);
		if (defined $position) {
			$element = $obj->{'elements'}->[$position];
		}
		return $element;
	}
	else 
	{
		my $position = $obj->{'pointer'};
		if (defined $obj->{'keys'}->[$position]) {
			($key, $element) = ($obj->{'keys'}->[$position], $obj->{'elements'}->[$position]);
			$obj->{'pointer'}++;
		}
		return ($key, $element);
	}
}


sub read_at
{
	my $obj = shift();
	my ($position) = @_;

	if (defined $position &&
		defined $obj->{'keys'}->[$position])
	{
		return ($obj->{'keys'}->[$position], $obj->{'elements'}->[$position]);
	}
	return (undef, undef);
}


sub add
{
	my $obj = shift();
	my ($key, $element) = @_;

	if (defined $key ||
		defined $element)
	{
		push(@{$obj->{'keys'}}, $key);
		push(@{$obj->{'elements'}}, $element);
		return 1;
	}
	return 0;
}


sub insert_at
{
	my $obj = shift();
	my ($position, $key, $element) = @_;

	if (defined $position &&
		(defined $key || defined $element))
	{
		$position = $obj->_limit_position($position);

		splice(@{$obj->{'keys'}}, $position, 0, $key);
		splice(@{$obj->{'elements'}}, $position, 0, $element);
		return 1;
	}
	return 0;
}


sub insert_after
{
	my $obj = shift();
	my ($position, $key, $element) = @_;

	if (defined $position &&
		(defined $key || defined $element))
	{
		$position = $obj->_limit_position($position + 1);
	
		splice(@{$obj->{'keys'}}, $position, 0, $key);
		splice(@{$obj->{'elements'}}, $position, 0, $element);
		return 1;
	}
	return 0;
}


sub remove
{
	my $obj = shift();
	my ($key) = @_;
	
	my $element;
	if (defined $key) 
	{
		my $position = $obj->find($key);
		if (defined $position) {
			$element = $obj->{'elements'}->[$position];
			$obj->_remove_position($position);
		}
		return $element;
	}
	else {
		($key, $element) = (shift(@{$obj->{'keys'}}), shift(@{$obj->{'elements'}}));
		return ($key, $element);
	}
}


sub remove_at
{
	my $obj = shift();
	my ($position) = @_;

	if (defined $position &&
		defined $obj->{'keys'}->[$position])
	{
		my ($key, $element) = ($obj->{'keys'}->[$position], $obj->{'elements'}->[$position]);
		$obj->_remove_position($position);
		return ($key, $element);
	}
	return (undef, undef);
}


sub replace
{
	my $obj = shift();
	my ($key, $element) = @_;

	if (defined $key)
	{
		my $position = $obj->find($key);
		if (defined $position) {
			$obj->{'elements'}->[$position] = $element;
			return 1;
		}
	}
	return 0;
}


sub replace_at
{
	my $obj = shift();
	my ($position, $element) = @_;

	if (defined $position &&
		defined $obj->{'keys'}->[$position])
	{
		$obj->{'elements'}->[$position] = $element;
		return 1;
	}
	return 0;
}


sub reset
{
	my $obj = shift();

	$obj->{'pointer'} = 0;
}


sub size
{
	my $obj = shift();

	return @{$obj->{'keys'}};
}


sub empty
{
	my $obj = shift();
	
	return (@{$obj->{'keys'}} == 0);
}


sub clear
{
	my $obj = shift();
	
	$obj->{'keys'} = [];
	$obj->{'elements'} = [];
	$obj->{'pointer'} = 0;
}


################################################################################

# PRIVATE IMPLEMENTATION

################################################################################


sub _remove_position
{
	my $obj = shift();
	my $position = shift();

	splice(@{$obj->{'keys'}}, $position, 1);
	splice(@{$obj->{'elements'}}, $position, 1);
}


sub _limit_position
{
	my $obj = shift();
	my $position = shift();

	if ($position < 0) {
		return 0;
	}
	elsif ($position > @{$obj->{'keys'}}) {
		return scalar(@{$obj->{'keys'}});
	}
	else {
		return $position;
	}
}


1;

__END__

=head1 NAME

List::Indexed - A sequence of elements with random access.

=head1 SYNOPSIS

 use List::Indexed;

 # Construction 
 my $list = new List::Indexed;

 # Read the elements in order
 $list->reset();
 while (($key, $element) = $list->read() && defined $element) {
 	...
 }
 
 # Search/Read an element
 $position = $list->find($key);
 if (defined $position) {
 	($key, $element) = $list->read_at($position);
 	...
 }
 # Or
 $element = $list->read($key);
 if (defined $element) {
 	...
 }

 # Add an element to the end of the list
 $list->add($key, $element);

 # Insert an element in the list
 $list->insert_at($position, $key, $element);
 # Or
 $list->insert_after($position, $key, $element);

 # Remove the first element
 ($key, $element) = $list->remove();

 # Search/Remove an element
 $position = $list->find($key);
 if (defined $position) {
 	($key, $element) = $list->remove_at($position);
 }
 # Or
 $element = $list->remove($key);
 if (defined $element) {
 	...
 }

 # Search/Replace an element
 $position = $list->find($key);
 if (defined $position) {
	$list->replace_at($position, $new_element);
 }
 # Or
 $list->replace($key, $new_element);

=head1 DESCRIPTION

The List::Indexed combines the functionality of hashes with those of lists, 
meaning it is possible to access the elements of the list using their keys, but 
the order of the insertion in the list is preserved.

=head1 PUBLIC INTERFACE

=head2 Constructor

=over

=item new ()

Creates a new empty list.

=back

=head2 Methods

All methods which have at least an output parameter (have to return some 
values), return replacement undef values if the requested element cannot be 
found. 

The success of an operation can be determined by the return value. An operation 
which should return an element (possibly a key - element pair) or a position can 
be declared successful if the returned value is not undef. The other operations 
return a true value (1) on success, and false (0) otherwise.

=over

=item find (KEY)

Searches for the element with the given key and returns its position in the 
list.

=item read ([KEY])

If KEY is not defined, it just reads the next element from the list, pointed 
internally by a variable. In order to restart the iteration over the list, the 
reset() operation should be used. Both the element and its key are returned.

If KEY is defined, an attempt is made to find the element having the given key.
Returns the element associated with the key.

=item read_at (POSITION)

Reads the element from a given position. POSITION is usually returned by a 
previous find() operation. Both the element and its key are returned.

=item add (KEY, ELEMENT)

Adds the (KEY, ELEMENT) pair to the end of the list.

=item insert_at (POSITION, KEY, ELEMENT)

Inserts the given (KEY, ELEMENT) pair at the given position in list. POSITION 
is usually returned by a previous find() operation. If the position is greater
than the size of the list, the element is added to the end of the list, similar
to the add() operation. If the position is 0 or negative the element is inserted
at the beginning of the list.

=item insert_after (POSITION, KEY, ELEMENT)

Is similar to the insert_at() operation, just the element is inserted after and not 
at the given position in the list.

=item remove ([KEY])

If KEY is not defined, the first element from the list is removed. Both the element 
and its key are returned.

If KEY defined, an attempt is made to find the element having the given key.
Returns the element associated with the key.

=item remove_at (POSITION)

Removes the element from a given position. POSITION is usually returned by a 
previous find() operation. Both the element and its key are returned.

=item replace (KEY, ELEMENT)

If KEY is defined, an attempt is made to find the element having the given key.
Returns the element associated with the key.

=item replace_at (POSITION, ELEMENT)

Replaces the element at the given position. POSITION is usually returned by a 
previous find() operation.

=item reset ()

Resets the list pointer, thus the iteration can be restarted from the first 
element of the list. Used together with the read() operation.

=item size ()

Returns the size of the list.

=item empty ()

Returns a boolean value indicating whether the list is empty or not.

=item clear ()

Removes all elements from the list and resets the list pointer.

=back

=head1 NOTES

The find() operation searches after a key iterating sequentially over the list, 
which means that for large lists the find operation and all operations using 
keys have poor performance. 

However, it should be noted that the clarity of the interface was preferred 
over the performance of the implementation. At least for now, this works for me; 
better performance in the future...(if needed)

=head1 AUTHOR

Farkas Arpad <arpadf@spidernet.co.ro>

=cut
