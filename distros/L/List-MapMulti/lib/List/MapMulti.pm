package List::MapMulti;

use 5.006;
use strict;
use warnings;
no warnings qw/once void/;

BEGIN
{
	$List::MapMulti::AUTHORITY = 'cpan:TOBYINK';
	$List::MapMulti::VERSION   = '0.004';
	
	# use this module if it's installed.
	# don't panic if it's unavailable.
	eval {
		require autovivification;
		autovivification->unimport('warn');
	};
}

use Carp qw/carp croak/;

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
use base qw/Exporter/;
BEGIN {
	@EXPORT      = qw/mapm/;
	@EXPORT_OK   = (@EXPORT, qw/map_multi iterator_multi/);
	%EXPORT_TAGS = (
		'all'      => \@EXPORT_OK,
		'standard' => \@EXPORT,
		'default'  => \@EXPORT,
		'nothing'  => [],
	);
}

sub iterator_multi
{
	join(q{::}, __PACKAGE__, 'Iterator')->new(@_);
}

sub map_multi (&@)
{
	my ($code, @arrays) = @_;
	my @results;
	
	if (@arrays)
	{
		my $iter = iterator_multi(@arrays);
		
		local $_ = $iter;

		# Localise $a, $b
		my ( $caller_a, $caller_b ) = do {
			my $pkg = caller;
			no strict 'refs';
			\*{$pkg.'::a'}, \*{$pkg.'::b'};
		};
		
		while (my @values = $iter->())
		{
			no strict 'refs';
			(*$caller_a, *$caller_b) = \( @values[0, 1] );			
			push @results, $code->(@values);
		}
	}
	
	wantarray ? @results : scalar(@results);
}

sub mapm (&@); *mapm = \&map_multi;

package List::MapMulti::Iterator;

use strict;
use warnings;
no warnings qw/once void/;

use Carp qw/carp croak/;

use overload
	'&{}' => sub { my $self = shift; sub { $self->next } },
	'@{}' => sub { my $self = shift; [ $self->current ] },
;

BEGIN
{
	$List::MapMulti::Iterator::AUTHORITY = 'cpan:TOBYINK';
	$List::MapMulti::Iterator::VERSION   = '0.004';
	
	autovivification->unimport('warn');
}

sub new
{
	my ($class, @arrays) = @_;
	
	_array_check(\@arrays);
	
	my $self = bless {
		arrays          => \@arrays,
		lengths         => [ map { ;scalar @$_ } @arrays ],
		next_indices    => [ map { ;0 } @arrays ],
		current_indices => undef,
		last            => 0,
	}, $class;
	
	for my $arr (@arrays)
	{
		$self->{'last'}++ unless scalar @$arr;
	}
	
	return $self;
}

sub _array_check
{
	my ($arrays) = @_;
	my $callsub  = [caller(1)]->[3];

	if (warnings::enabled('misc'))
	{
		carp "no arrayrefs were passed to $callsub"
			unless @$arrays;
	}
	
	croak "non-arrayref passed to $callsub"
		if grep { ref ne 'ARRAY' } @$arrays;
}

sub _increment_indices
{
	my ($indices, $lengths) = @_;
	my $inc = $#$indices;
	
	while (1)
	{
		if ($inc < 0)
		{
			@$indices = ();
			return;
		}
		
		$indices->[$inc]++;
		if ($indices->[$inc] >= $lengths->[$inc])
		{
			$indices->[$inc] = 0;
			$inc--;
		}
		else
		{
			return $indices;
		}
	}
}

sub next
{
	my $self = shift;
	
	return if $self->{last};
	
	$self->{current_indices} = [ $self->next_indices ];
	
	my @values = map
		{ $self->{arrays}[$_][$self->{current_indices}[$_]] }
		0 .. $#{$self->{arrays}};
		
	$self->{last} = !_increment_indices($self->{next_indices}, $self->{lengths});
	
	return @values;
}

sub next_indices
{
	my $self = shift;
	
	if (@_)
	{
		$self->{next_indices} = [@_[ 0 .. $#{$self->{arrays}} ]];
	}
	
	@{ $self->{next_indices} };
}

sub current
{
	my $self = shift;
	
	if (@_)
	{
		my @ix = $self->current_indices;
		for my $i (0 .. $#_)
		{
			$self->{arrays}[$i][ $ix[$i] ] = $_[$i];
		}
	}
	
	my @values = map
		{ $self->{arrays}[$_][$self->{current_indices}[$_]] }
		0 .. $#{$self->{arrays}};
}

sub current_indices
{
	@{ (shift)->{current_indices} };
}

__PACKAGE__
__END__

=head1 NAME

List::MapMulti - map through multiple arrays at once

=head1 SYNOPSIS

 use feature qw/say/;
 use List::MapMulti qw/mapm/;
 
 my @numbers = (2..10, qw/Jack Queen King Ace/);
 my @suits   = qw/Clubs Diamonds Hearts Spades/;
 my @cards   = mapm { "$_[0] of $_[1]" } \@numbers, \@suits;
 
 say scalar(@cards);     # says '52'
 say $cards[0];          # says '2 of Clubs'
 say $cards[1];          # says '2 of Diamonds'
 say $cards[-1];         # says 'Ace of Spades'

=head1 DESCRIPTION

List::MapMulti provides shortcuts for looping through several lists in a
nested fashion. Think about all the times you've needed to do something
like:

 foreach my $x (@exes) {
   foreach my $y (@whys) {
     # do something with $x and $y
   }
 }

There are two different solutions available to you: C<map_multi> (which
has an alias C<mapm>) and C<iterator_multi>.

The only thing this module exports by default is C<mapm>.

=head2 C<< map_multi { BLOCK } \@list1, \@list2 ... >>

=begin private

=item C<mapm> - for pod::coverage

=end private

(Or C<mapm>!)

Calls the codeblock with every possible combination of values from each
list. If you imagine it as calling within a set of nested loops, then the
final list is the innermost loop; and the first loop is the outermost
loop.

Note that within the codeblock, the items from each list are available
as C<< $_[0] >>, C<< $_[1] >>, etc. The C<< $_ >> variable is set to a
List::MapMulti::Iterator object which is used internally by C<map_multi>.

For the special (but common) case where you're just mapping over two lists,
C<< $a >> and C<< $b >> are aliased to C<< $_[0] >> and C<< $_[1] >>. You
may need to do C<< our ($a, $b) >> to suppress warnings about variables
being used only once.

C<mapm> is exported by default, but C<map_multi> needs to be requested
explicitly.

=head2 C<< iterator_multi(\@list1, \@list2, ...) >>

This allows constructions like this:

 my $iterator = iterator_multi(\@numbers, \@suits);
 while (my ($number, $suit) = $iterator->())
 {
   say "$number of $suit";
 }

Although C<map_multi> is arguably a nicer syntax, the iterator provides
you with an important advantage: you don't have to iterate through every
possible combination. You can control flow using, say, C<next>, C<last>
or C<redo>.

=head2 List::MapMulti::Iterator

This is advanced fu that you probably don't need to know about.

While iterators act like coderefs (you get the next set of values via
C<< $iterator->() >>), internally they are blessed objects that overload
C<< &{} >>. As they are objects, they are able to provide some methods.

These are the methods they provide:

=head3 C<< new(\@list1, \@list2, ...) >>

Constructor. The C<iterator_multi> function is just a shortcut for this.

=head3 C<< next >>

Calling C<< $iterator->next >> is exactly equivalent to calling
C<< $iterator->() >>.

=head3 C<< current >>

Returns the same thing as the previous call to C<< next >> (unless
the original arrays have changed since then).

This can also be used as a setter, in which case it writes back to
the appropriate slots in the original arrays. 

=head3 C<< next_indices >>

Returns the array indices that will be used to read from the
original arrays next time C<next> is called. Again, this can be
used as a setter.

=head3 C<< current_indices >>

Returns the array indices that was used to read from the original
arrays last time C<next> was called.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=List-MapMulti>.

=head1 SEE ALSO

L<List::Util>,
L<List::MoreUtils>,
L<List::Pairwise>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
