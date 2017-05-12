
package List::Tuples ;

use strict;
use warnings ;

BEGIN
{
use Sub::Exporter -setup => 
	{
	exports => [ qw(tuples hash_tuples ref_mesh) ],
	groups  => 
		{
		all  => [ qw(tuples hash_tuples ref_mesh) ],
		}
	};
	
use vars qw ($VERSION);
$VERSION = '0.04' ;
}

#-------------------------------------------------------------------------------

use Readonly ;
use Carp::Diagnostics qw(cluck carp croak confess) ;

#-------------------------------------------------------------------------------

=head1 NAME

List::Tuples - Makes tuples from lists

=head1 SYNOPSIS

	use List::Tuples qw(:all) ;
	
	my @tuples = tuples[2] => (1 .. 6) ;
		
	# is equivalent to:
	
	my @tuples = 
		(
		[1, 2],
		[3, 4],
		[5, 6],
		) ;
	
	#-------------------------------------------------------
	
	my @meshed_list = ref_mesh([1 .. 3], ['a' .. 'b'], ['*']) ;
		
	# is equivalent to:
	
	my @meshed_list = (1, 'a', '*', 2, 'b', undef, 3, undef, undef) ;
	
	#-------------------------------------------------------
	
	my @hashes = hash_tuples ['key', 'other_key'] => (1 .. 5) ;
		
	# is equivalent to :
	
	my @hashes = 
		(
		{key => 1, other_key => 2},
		{key => 3, other_key => 4},
		{key => 5, other_key => undef},
		) ;

=head1 DESCRIPTION

This module defines subroutines that let you create tuples.

=head1 DOCUMENTATION

Ever got frustrated that you couldn't easily get tuples into map{} or
create multiple hashes from an ordered list?

Jonathan Scott in In "Everyday Perl 6" L<http://www.perl.com/pub/a/2007/05/10/everyday-perl-6.html> writes:

    # Perl 6                        # Perl 5
    for @array -> $a     { ... }    for my $a (@array) { ... }
    for @array -> $a, $b { ... }    # too complex :)

The following subroutines will simplify your job. They could certainly be more effective implemented
directly in the language, IE in Perl6. If you have millions of tuples to handle, you may want monitor memory usage.

=head1 SUBROUTINES

=cut

#----------------------------------------------------------------------

sub tuples
{

=head2 tuples([$limit], \@size, @list)

B<tuples> will extract B<$size> elements from B<@lists> and group them in an array reference.
It will extract as many tuples as possible up to the, optional, B<$limit> you pass as argument.

	tuples 3 => [2] => (1 .. 14); # 3 tuples with 2 elements are returned
	tuples[2] => (1 .. 14); # 7 tuples with 2 elements are returned
	
	for my $tuple (tuples[2] => @array) 
		{
		print "[$tuple->[0], $tuple->[1]]\n" ;
		}
	

B<Arguments>

=over 2

=item * $limit - an optional maximum number of tuples to create

=item * \@size - an array reference containing the number of elements in a tuple

=item * @list - a list to be split into tuples

=back

B<Return>

=over 2

=item * A list of tuples (array references)

=back

=head3 Input list with insufficient elements

	my @tuples = tuples[2] => (1 .. 3)) ; 
	
	# is equivalent to:
	
	my @tuples =
		(
		[1, 2],
		[3],
		) ;

=head3 Diagnostics

=cut

my ($limit, $size, @array) = @_ ;

if ('ARRAY' eq ref $limit)
	{
	# handle optional limit
	unshift @array, $size if defined $size ;
	$size = $limit ;
	$limit = undef ;
	}

my $number_of_tuples = 0 ;

if('ARRAY' eq ref $size)
	{
	$size = $size->[0] ;
	
	if(defined $size)
		{
		if($size > 0)
			{
			$number_of_tuples = @array / $size ;
			$number_of_tuples++ if @array % $size ;
			}
		else
			{
			confess
				(
				'Error: List::Tuples::tuples expects tuple size to be positive!',
				<<'END_OF_POD',

=over

=item * Error: List::Tuples::tuples expects tuple size to be positive!

example:

	my @tuples = tuples[2] => @list ;
	                    ^
	                    `- size must be positive 

=back

=cut

END_OF_POD
				) ;
			}
		}
	else
		{
		confess 
			(
			'Error: List::Tuples::tuples expects a tuple size!',
			<<'END_OF_POD',

=over

=item * Error: List::Tuples::tuples expects a tuple size!

example:

	my @tuples = tuples[2] => @list ;
	                    ^
	                    `- size must be defined

=back

=cut

END_OF_POD
				) ;
		}
		
	if(defined $limit)
		{
		if($limit > 0)
			{
			$number_of_tuples = $number_of_tuples > $limit ? $limit : $number_of_tuples ;
			}
		else
			{
			confess 
				(
				'Error: List::Tuples::tuples expects tuple limit to be positive!',
				<<'END_OF_POD',

=over

=item * Error: List::Tuples::tuples expects tuple limit to be positive !

example:

	my @tuples = tuples 3 => [2] => @list ;
	                    ^
	                    `- limit must be positive 

=back

=cut

END_OF_POD
				) ;
			}
		}
	}
else
	{
	confess 
		(
		'Error: List::Tuples::tuples expects an array reference as size argument!',
		<<'END_OF_POD',

=over

=item * Error: List::Tuples::tuples expects an array reference as size argument!

example:

	my @tuples = tuples[2] => @list ;
			   ^
	                   `- size must be in an array reference

=back

=cut

END_OF_POD
		) ;
	}
	
if(@array)
	{
	return
		(
		map{[splice(@array, 0, $size)] } (1 .. $number_of_tuples)
		) ;
	}
else
	{
	return ;
	}
}


#-------------------------------------------------------------------------------------------------------------

sub ref_mesh
{

=head2 ref_mesh(\@array1, \@array2, ...)

Mixes elements from arrays, one element at the time.

	my @list = 
		ref_mesh
			['mum1', 'mum2', 'mum3'],
			['dad1', 'dad2'],
			[['child1_1', 'child1_2'], [], ['child3_1']] ;
	
	# is equivalent to :
	
	my @list = 
		(
		'mum1',
		'dad1',
		[child1_1, 'child1_2'],
		'mum2',
		'dad2',
		[],
		'mum3', 
		'undef,
		[child3_1]
		) ;

This is equivalent to B<mesh> from L<List::MoreUtils> except the fact it takes arrays references instead for lists.
The implementation is directly taken from L<List::MoreUtils>.

B<Arguments>

=over 2

=item * a list of array reference

=back

B<Return>

=over 2

=item * a list consisting of the first elements of each array reference, then the second, then the third, etc, until all arrays are exhausted

=back

=head3 Diagnostics

=cut

my (@array_references) = @_ ;

Readonly my $INVALID_MAXIMUM_VALUE => -1 ;

my $max = $INVALID_MAXIMUM_VALUE ;
my $index = 0 ;

for my $array_ref (@array_references)
	{
	confess 
		(
		"Error: List::Tuples::ref_mesh: element '$index' is not an array reference!",
		<<"END_OF_POD",

=over

=item * Error: List::Tuples::ref_mesh: element '$index' is not an array reference!

example:

	my \@list = ref_mesh([1, 2], [5, 10], [10, 20], ...) ;
			    ^
	                    `-  arguments must be array references

=back

=cut

END_OF_POD
		) unless 'ARRAY' eq ref $array_ref  ;
		
	$max < $#{$array_ref}   &&  ($max = $#{$array_ref} )  ;
	
	$index++ ;
	}

return
	(
	map 
		{ 
		my $ix = $_ ;
		map {$_->[$ix]}
			@array_references 
		} 
		0..$max
	) ;
}

#-------------------------------------------------------------------------------------------------------------

sub hash_tuples
{

=head2 hash_tuples([$limit], \@hash_keys, @input_array)

B<hash_tuples> uses elements from \@input_array and combine them with \@hash_keys to create hash references.
It will create as many hashes as possible up to the, optional,  $limit.

	my @hashes  = 
		hash_tuples
			['Mum',   'Dad',   'Children'] =>
			'Lena',   'Nadim', ['Yasmin', 'Miriam'],
			'Monika', 'ola',   ['astrid'] ;
	
	# is equivalent to:
	
	my @hashes =
		(
			{
			'Mum' => 'Lena',
			'Children' => ['Yasmin','Miriam'],
			'Dad' => 'Nadim'
			}, 
			{
			'Mum' => 'Monika',
			'Children' => ['astrid'],
			'Dad' => 'ola'
			}
		) ;
	
	
	for my $tuple (hash_tuples(['a', 'b'] => @array)) 
		{
		print $tuple->{a} . "\n" ;
		print $tuple->{b} . "\n" ;
		}

B<Arguments>

=over 2

=item * $limit - an optional maximum number of hashes to create

=item * \@hash_keys - an array reference containing the list of keys apply to the input array

=item * \@input_array- an array reference. the array contains the elements to extract 

=back

B<Return>

=over 2

=item * A list of hashes

=back

=head3 Diagnostics

=cut

my ($limit, $hash_keys, @input_array) = @_ ;

if ('ARRAY' eq ref $limit)
	{
	unshift @input_array, $hash_keys  if defined $hash_keys ;
	$hash_keys = $limit ;
	$limit = undef ;
	}
	
if('ARRAY' eq ref $hash_keys)
	{
	unless(@{$hash_keys})
		{
		confess 
			(
			'Error: List::Tuples::hash_tuples expects at least one key in the key list!',
			<<'END_OF_POD',

=over

=item * Error: List::Tuples::hash_tuples expects at least one key in the key list!

example:

	my @hashes  = hash_tuples['Mum',   'Dad',   'Children'] => @list ;
			         ^
				 `-  key list must contain at least one keys

=back

=cut

END_OF_POD
			) ;
		}
		
	if(defined $limit)
		{
		if($limit <= 0)
			{
			confess 
				(
				'Error: List::Tuples::hash_tuples expects tuple limit to be positive!',
				<<'END_OF_POD',

=over

=item * Error: List::Tuples::hash_tuples expects tuple limit to be positive!

example:

	my @hashes  = hash_tuples 3 => ['Mum',   'Dad',   'Children'] => @list ;
			          ^
				  `-  limit must be positive

=back

=cut

END_OF_POD
				) ;
			}
		}
	}
else
	{
	confess 
		(
		'Error: List::Tuples::hash_tuples expects an array reference to define the keys!',
		<<'END_OF_POD',

=over

=item * Error: List::Tuples::hash_tuples expects an array reference to define the keys!

example:

	my @hashes  = hash_tuples ['Mum',   'Dad',   'Children'] => @list ;
			          ^
				  `-  key list must be an array reference

=back

=cut

END_OF_POD
		) ;
	}
	
if(@input_array)
	{
	return
		(
		map	
			{
				{
				ref_mesh($hash_keys => $_)
				}
			}
			tuples $limit => [scalar(@{$hash_keys})] => @input_array
		) ;
	}
else
	{
	return ;
	}
}


#-------------------------------------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::Tuples

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Tuples>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-list-tuples@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/List-Tuples>

=back

=head1 SEE ALSO

L<List::MoreUtils>

=cut
