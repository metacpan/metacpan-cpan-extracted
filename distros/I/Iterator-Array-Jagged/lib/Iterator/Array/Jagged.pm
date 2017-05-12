
package Iterator::Array::Jagged;

use strict;
use warnings 'all';
our $VERSION = '0.05';


#==============================================================================
sub new
{
	my ($class, %args) = @_;
	
	my $s = bless {
		idx => [
			map { 0 } 0...scalar(@{$args{data}}) - 1
		],
		sizes => [
			map { scalar(@$_) - 1 } @{$args{data}}
		],
		data => $args{data},
		_max => scalar(@{$args{data}}),
		_is_finished => 0,
	}, $class;
	
	return $s;
}# end new()


#==============================================================================
sub _increment
{
	my ($s, $index) = @_;
	
	if( $s->{idx}->[ $index ] < $s->{sizes}->[ $index ] )
	{
		$s->{idx}->[ $index ]++;
	}
	else
	{
		$s->{idx}->[ $index ] = 0;
		if( $index + 1 < $s->{_max} )
		{
			$s->_increment( $index + 1 );
		}
		else
		{
			$s->{_is_finished} = 1;
		}# end if()
	}# end if()
}# end _increment()


#==============================================================================
sub next
{
	my ($s) = @_;
	
	return if $s->{_is_finished};
	
	# Calculate and return the current value:
	my @parts = ();
	for( 0...$s->{_max} - 1 )
	{
		my $part_idx = $s->{idx}->[ $_ ];
		push @parts, $s->{data}->[ $_ ]->[ $part_idx ];
	}# end for()
	
	$s->_increment( 0 );
	
	return @parts;
}# end next()


#==============================================================================
sub permute
{
	my ($class, $func, @data) = @_;
	
	my @idx = map { 0 } 0...scalar(@data) - 1;
	my @sizes = map { scalar(@$_) - 1 } @data;
	my $max = scalar(@data);
	PERMUTATION: while( 1 )
	{
		# Prepare a 'set':
		my @parts = ();
		for my $num ( 0...$max - 1 )
		{
			push @parts, $data[ $num ]->[ $idx[ $num ] ];
		}# end for()
		
		# Execute 'func':
		$func->( @parts );
		
		# Increment or finish:
		my $to_increment = 0;
		INCR: while( 1 )
		{
			if( $idx[ $to_increment ] < $sizes[ $to_increment ] )
			{
				$idx[ $to_increment ]++;
				last INCR;
			}
			else
			{
				$idx[ $to_increment ] = 0;
				if( $to_increment + 1 < $max )
				{
					$to_increment += 1;
					next INCR;
				}
				else
				{
					last PERMUTATION;
				}# end if()
			}# end if()
		}# end while()
		
		next PERMUTATION;
	}# end while()
	
}# end permute()


#==============================================================================
sub get_iterator
{
	my ($class, @data) = @_;
	
	my @idx = map { 0 } 0...scalar(@data) - 1;
	my @sizes = map { scalar(@$_) - 1 } @data;
	my $max = scalar(@data);
	my $is_finished = 0;
	
	return sub {
		return if $is_finished;
		# Prepare a 'set':
		my @parts = ();
		for my $num ( 0...$max - 1 )
		{
			push @parts, $data[ $num ]->[ $idx[ $num ] ];
		}# end for()
		
		# Increment or finish:
		my $to_increment = 0;
		INCR: while( 1 )
		{
			if( $idx[ $to_increment ] < $sizes[ $to_increment ] )
			{
				$idx[ $to_increment ]++;
				last INCR;
			}
			else
			{
				$idx[ $to_increment ] = 0;
				if( $to_increment + 1 < $max )
				{
					$to_increment += 1;
					next INCR;
				}
				else
				{
					$is_finished = 1;
				}# end if()
			}# end if()
		}# end while()
		
		# Finally return the parts:
		return @parts;
	};# end sub{...}
}# end get_iterator()

1; #return true:

__END__

=pod

=head1 NAME

Iterator::Array::Jagged - Quickly permute and iterate through multiple jagged arrays.

=head1 SYNOPSIS

	use Iterator::Array::Jagged;
	
	# Build up a set of data:
	my @data = (
		[qw/ a b /],
		[qw/ c d /],
		[qw/ e f g /]
	);
	
	# Iterator in object-oriented mode:
	my $iterator = Iterator::Array::Jagged->new( data => \@data );
	while( my @set = $iterator->next )
	{
		print "Next set: '" . join("&", @set) . "'\n";
	}# end while()
	
	# Iterator is a subref:
	my $itersub = Iterator::Array::Jagged->get_iterator( @data );
	while( my @set = $itersub->() )
	{
		print "Next set: '" . join("&", @set) . "'\n";
	}# end while()
	
	# Functional callback style:
	Iterator::Array::Jagged->permute(sub {
		my (@set) = @_;
		print "Next set: '" . join("&", @set) . "'\n";
	}, @data );

Each example in the code above code prints the following:

	Next set: b&c&e'
	Next set: a&d&e'
	Next set: b&d&e'
	Next set: a&c&f'
	Next set: b&c&f'
	Next set: a&d&f'
	Next set: b&d&f'
	Next set: a&c&g'
	Next set: b&c&g'
	Next set: a&d&g'
	Next set: b&d&g'

=head1 DESCRIPTION

C<Iterator::Array::Jagged> can permute through sets of "jagged" arrays - arrays of varying lengths.

C<Iterator::Array::Jagged> works much like the odometer in an automobile.  Except that each set
of "numbers" can have any kind of data you want, and each set can contain 1 or more elements.

C<Iterator::Array::Jagged> is stable and ready for production use as of version C<0.05>.

=head1 METHODS

=head2 new( %args )

Constructor.  C<%args> should included the element C<data> which contains the arrayref of arrayrefs
that you wish to iterate through.

=head2 next( )

Returns an array representing the next iteration of the permutation of your data set.  See the synopsis for an example.

=head2 get_iterator( @data )

Returns a coderef that, when called, returns the next set of data until there are no more permutations.  See the synopsis for an example.

=head2 permute( $subref, @data )

Calls C<$subref> for each permutation in C<@data>.  This is currently B<BY FAR THE FASTEST METHOD AVAILABLE>.

=head1 BENCHMARKS

After the initial release of Iterator::Array::Jagged, some people were wondering if there was any benefit to using
I::A::J over another older module L<Algorithm::Loops> and its C<NestedLoops> method.  So I did some benchmarking and found
some mixed results.

                    Rate I::A::J OO A::L::NL func I::A::J iterator A::L::NL iterator I::A::J permute
  I::A::J OO        4.19/s         --           -3%             -19%              -29%            -45%
  A::L::NL func     4.32/s         3%            --             -16%              -27%            -43%
  I::A::J iterator  5.15/s        23%           19%               --              -12%            -32%
  A::L::NL iterator 5.88/s        40%           36%              14%                --            -22%
  I::A::J permute   7.58/s        81%           75%              47%               29%              --

Depending on the size and depth of the jagged array data passed in, the results vary slightly.  However, the order
in which each method finishes is the same.  Iterator::Array::Jagged->permute is fastest by a signifigant margin over
C<Algorithm::Loops::NestedLoops>.  On the opposite end of the spectrum we have the OO method of Iterator::Array::Jagged
which comes in at nearly half the speed of the C<permute> option.

The benchmark script that was used is shown in the next section.

Benchmarks were done on a server with the following specs:

=over 4

=item CPU:

Intel(R) Core(TM)2 CPU 6400 @ 2.13GHz stepping 02

=item RAM:

2Gb

=back

=head2 The Benchmark Script

  #!/usr/bin/perl -w
  
  use strict;
  use Time::HiRes qw(gettimeofday);
  use Benchmark qw' :all ';
  
  use Algorithm::Loops 'NestedLoops';
  use Iterator::Array::Jagged;
  
  
  my @data = ();
  for my $var ( 1...4 )
  {
    my @set = ();
    my $max = $var % 2 ? 10 : 11;
    for my $val ( 1...$max )
    {
      push @set, "var$var=val$val";
    }# end for()
    push @data, \@set;
  }# end for()
  
  cmpthese( 20, {
    'I::A::J OO'        => sub { do_iterator_array_jagged( @data ) },
    'A::L::NL iterator' => sub { do_nestedloops_iterator( @data ) },
    'A::L::NL func'     => sub { do_nestedloops_func( @data ) },
    'I::A::J permute'   => sub { do_iaj_permute( @data ) },
    'I::A::J iterator'  => sub { do_iaj_iterator( @data ) },
  });
  
  
  sub do_iaj_iterator
  {
    my $iter = Iterator::Array::Jagged->get_iterator( @_ );
    while( my @set = $iter->() )
    {
    }# end while()
  }# end do_iaj_iterator()
  
  
  sub do_iaj_permute
  {
    Iterator::Array::Jagged->permute( sub { }, @_ );
  }# end do_iaj_permute()
  
  
  sub do_iterator_array_jagged
  {
    my @data = @_;
    my $iter = Iterator::Array::Jagged->new( data => \@data );
    while( my $set = $iter->next )
    {
    }# end while()
  }# end do_iterator_array_jagged()
  
  
  sub do_nestedloops_func
  {
    NestedLoops( \@_, sub { } );
  }# end do_nestedloops_func()
  
  
  sub do_nestedloops_iterator
  {
    my @data = @_;
    my $iter = NestedLoops( \@data );
    while( my @set = $iter->() )
    {
    }# end while()
  }# end do_nestedloops()

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Iterator-Array-Jagged> to submit bug reports.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
