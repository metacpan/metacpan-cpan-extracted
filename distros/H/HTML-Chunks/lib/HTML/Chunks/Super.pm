package HTML::Chunks::Super;

use Safe;
use IO::Scalar;
use strict;
use base qw(HTML::Chunks);

our $VERSION = "1.01";

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	return $self;
}

# override basic chunk output to support conditionals
sub outputBasicChunk
{
	my $self = shift;
	my $chunk = shift; 
	my $chunkRef = ref $chunk ? $chunk : \$chunk;

	my $tree = $self->buildTree($chunkRef);
	$self->outputNode($tree, @_);
}

# parse a chunk into a decision tree.  it might be possible to gain some
# efficiencies by doing this parsing when chunks are loaded, but it would
# be tricky to avoid confusing our parent class.
sub buildTree
{
	my $self = shift;
	my ($chunk) = @_;

	my $chunkRef = ref $chunk ? $chunk : \$chunk;
	my $tree = [];
	my @stack;
	my $pos = 0;

	while ($$chunkRef =~ /\G(.*?)<!--\s*(IF|ELSIF|ELSE|ENDIF)\b\s*(.*?)\s*-->/gs)
	{
		my $beginDepth = @stack;
		my $node = $beginDepth ? $stack[-1]->{current} : $tree;

		if (defined $1 && length $1)
		{
			push @{$node}, $1;
		}

		my $cmd = uc($2);

		if ($cmd eq 'ELSE' || $cmd eq 'ELSIF')
		{
			my $branch = @stack ? $stack[-1] : undef;

			if ($branch && $branch->{current} == $branch->{true})
			{
				$node = $branch->{current} = $branch->{false} = [];
			}
		}

		if ($cmd eq 'ENDIF' || $cmd eq 'ELSIF')
		{
			my $branch = pop @stack;
			delete $branch->{current} if $branch;
		}

		if ($cmd eq 'IF' || ($cmd eq 'ELSIF' && $beginDepth))
		{
			my $branch = {
				test => $3,
				true => []
			};

			push @{$node}, $branch;
			push @stack, $branch;
			$branch->{current} = $branch->{true};
		}

		$pos = pos $$chunkRef;
	}

	my $tail = substr $$chunkRef, $pos;
	push @{$tree}, $tail if (defined $tail && length $tail);

	return $tree;
}

sub outputNode
{
	my $self = shift;
	my $node = shift;

	if (defined $node)
	{
		die "what is this? => ", $node, "\n" unless (ref $node eq 'ARRAY');

		foreach my $thing (@{$node})
		{
			if (ref $thing eq 'HASH')
			{
				if (exists $thing->{test} && $self->testsTrue($thing->{test}, @_))
				{
					$self->outputNode($thing->{true}, @_) if (exists $thing->{true});
				}
				else
				{
					$self->outputNode($thing->{false}, @_) if (exists $thing->{false});
				}
			}
			else
			{
				# call the normal HTML::Chunk output routine when we're down to a
				# basic unadulterated chunk
				$self->SUPER::outputBasicChunk(\$thing, @_);
			}
		}
	}
}

sub testsTrue
{
	my $self = shift;
	my $test = shift;
	our %values;
	local %values;

	# Translate any data tokens into scalars containing the actual data values

	$test =~ s/\#\#([\w\.]+)\#\#/
		my $name = $1;
		my $f = new IO::Scalar \$values{$name};
		my $oldfh = select $f;
		$self->outputData($name, @_);
		select $oldfh;
		close $f;

		"\$values{'$name'}";
	/gex;

	# select STDERR, otherwise a 'print' in the test will blow up apache
	my $oldfh = select STDERR;

	# now safely evaluate the test
	my $safe = new Safe;
	$safe->share('%values');
	my $status = $safe->reval($test);

	# put filehandle things back
	select $oldfh;

	warn $@ if $@;

	return $status;
}

1;

__END__

=pod

=head1 NAME

HTML::Chunks::Super - Chunks with superpowers

=head1 VERSION

1.0

=head1 DESCRIPTION

The mutant spawn of HTML::Chunks, this module has all of the abilities of its
parent plus additional emerging superpowers.  The first enhancement to be added
is conditional processing.  For full chunk documentation, please see L<HTML:::Chunks>.
Only HTML::Chunks::Super enhancements will be discussed here.

=head1 CONDITIONAL PROCESSING

While conditional processing does indeed blur the lines between layout/markup
and actual programming logic, it can be very powerful when used sparingly
and appropriately.  We urge you to use this ability only for simple display
logic, keeping the chunk side of life mostly pure and uncomplicated.  With
great power comes great responsibility. :-)

That warning aside, here is the extended chunk syntax:

 <!-- IF condition -->
 normal chunk stuff
 <!-- ELSIF condition -->
 more chunks
 <!-- ELSE -->
 chunky chunk of chunks
 <!-- ENDIF -->

The C<condition> can by most any valid perl expression and will usually
reference one or more chunk data elements.  See the L<HTML::Chunks>
documentation for a full descripton of data elements, but as a refresher,
they look like C<##this##> and refer to dynamic data that is merged into
a chunk at run-time.  For use in conditionals, you can treat them as
read-only scalars.

=head2 Some example conditions

=over

=item ##foo##

True if data element C<##foo##> has a true value (in the perl sense of "true")

=item ##foo## =~ /^bar/

True if C<##foo##> begins with "bar"

=item ##foo## !~ /\W/

True if C<##foo##> contains no non-word characters

=item ##num## >= 1 and ##num## <= 10

True if C<##num##> is between 1 and 10 inclusive

=back

You get the idea.  Most comparisons and conditions that are possible in straight perl will be possible here as well.

=head1 CREDITS

Created, developed and maintained by Mark W Blythe and Dave Balmer, Jr.
Contact dbalmer@cpan.org or mblythe@cpan.org for comments or questions.

=head1 LICENSE

(C)2001-2009 Mark W Blythe and Dave Balmer Jr, all rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
