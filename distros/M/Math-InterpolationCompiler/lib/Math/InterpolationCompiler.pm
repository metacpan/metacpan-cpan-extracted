package Math::InterpolationCompiler;
use 5.006001;
use Moo 2;
use Types::Standard 1;
use Carp;
use Exporter 'import';

our @EXPORT_OK= qw( linear_clamp_fn linear_extrapolate_fn );

our $VERSION= '0.002000';

# ABSTRACT: Compile interpolations into perl coderefs


has domain        => ( is => 'ro', isa => Types::Standard::ArrayRef, required => 1 );
has range         => ( is => 'ro', isa => Types::Standard::ArrayRef, required => 1 );
has algorithm     => ( is => 'ro', default => sub { 'linear' } );
has beyond_domain => ( is => 'ro', default => sub { 'clamp' } );
has perl_code     => ( is => 'lazy' );
has fn            => ( is => 'lazy' );
has sanitize      => ( is => 'ro', default => sub { 1 } );

sub BUILDARGS {
	my $self= shift;
	my $args= $self->next::method(@_);
	if ($args->{points} && !$args->{domain} && !$args->{range}) {
		my (@domain, @range);
		ref $args->{points} eq 'ARRAY'
			or croak "points must be an arrayref";
		# If points is an arrayref of arrayrefs, assume each point is a 2-element arrayref
		if (ref $args->{points}[0]) {
			for (@{ delete $args->{points} }) {
				push @domain, $_->[0];
				push @range,  $_->[1];
			}
		}
		# else assume points is an arrayref with the x/y in odd/even slots
		else {
			my $flip= 0;
			for (@{ delete $args->{points} }) {
				$flip++ & 1? (push @range,  $_)
					: (push @domain, $_);
			}
			!($flip & 1)
				or croak "odd number of elements in points";
		}
		$args->{domain}= \@domain;
		$args->{range}=  \@range;
	}
	return $args;
}

sub _sanitize_number_array {
	return [
		map {
			defined $_ or croak "<undef> is not a number";
			my $n= "$_";
			$n =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/ or croak "$n is not a number";
			$n
		} @{ $_[0] }
	];
}

sub BUILD {
	my $self= shift;
	@{ $self->domain } == @{ $self->range }
		or croak "Domain and range differ in length (".@{ $self->domain }." != ".@{ $self->range }.")";
	@{ $self->domain } > 1
		or croak "Domain does not contain any intervals";
	my $prev;
	if ($self->sanitize) {
		$self->{domain}= _sanitize_number_array($self->domain);
		$self->{range}=  _sanitize_number_array($self->range);
	}
	for (@{ $self->domain }) {
		croak "Domain is not sorted in non-decreasing order"
			if defined $prev && $_ < $prev;
		$prev= $_;
	}
	$self->can("_gen_".$self->algorithm)
		or croak "Unknown algorithm ".$self->algorithm;
}

sub _build_perl_code {
	my $self= shift;
	my $method= $self->can("_gen_".$self->algorithm);
	return $self->$method;
}

sub _build_fn {
	my $self= shift;
	my $sub= eval $self->perl_code
		or croak "Failed to build function: $@";
	return $sub;
}

# Create a linear interpolation
sub _gen_linear {
	my $self= shift;
	my $domain= $self->domain;
	my $range= $self->range;
	my @expressions;
	for (my $i= 1; $i < @$domain; $i++) {
		# skip discontinuities
		next if $domain->[$i] == $domain->[$i-1];
		# calculate slope and offset at x0
		my $m= ($range->[$i] - $range->[$i-1]) / ($domain->[$i] - $domain->[$i-1]);
		my $b= $range->[$i-1] - $domain->[$i-1] * $m;
		# generate code
		push @expressions, [ $domain->[$i-1], '$x * '.$m.' + '.$b ];
	}
	if ($self->beyond_domain eq 'clamp') {
		unshift @expressions, [ undef, $range->[0] ];
		push    @expressions, [ $domain->[-1], $range->[-1] ];
	}
	elsif ($self->beyond_domain eq 'extrapolate') {
		# just let the edge expressions do their thing
		# ... unless there were discontinuities at the edges
		unshift @expressions, [ undef, $range->[0] ]
			if $domain->[0] == $domain->[1];
		push    @expressions, [ $domain->[-1], $range->[-1] ]
			if $domain->[-1] == $domain->[-2];
	}
	elsif ($self->beyond_domain eq 'undef') {
		unshift @expressions, [ undef, 'undef' ];
		push    @expressions, [ $domain->[-1], '$x == '.$domain->[-1].'? ('.$range->[-1].') : undef' ];
	}
	elsif ($self->beyond_domain eq 'die') {
		unshift @expressions, [ undef, 'Carp::croak("argument out of bounds (<'.$domain->[0].')")' ];
		push    @expressions, [ $domain->[-1], '$x == '.$domain->[-1].'? ('.$range->[-1].') : Carp::croak("argument out of bounds (>'.$domain->[-1].')")' ];
	}
	else {
		croak "Algorithm 'linear' does not support domain-edge '".$self->beyond_domain."'";
	}
	# Now tree-up the expressions
	while (@expressions > 1) {
		my ($i, $dest);
		for ($i= 1, $dest= 0; $i < @expressions; $i+= 2) {
			$expressions[$dest++]= [
				$expressions[$i-1][0],
				'$x < '.$expressions[$i][0]."?"
				.' ('.$expressions[$i-1][1].")"
				.':('.$expressions[$i][1].")"
			];
		}
		# odd number?
		if ($i == @expressions) {
			$expressions[$dest++]= $expressions[-1];
		}
		# truncate list
		$#expressions= $dest-1;
	}
	# finally, wrap with function
	return "sub {\n my \$x= shift;\n return ".$expressions[0][1].";\n}\n";
}


sub linear_clamp_fn {
	Math::InterpolationCompiler->new(
		algorithm => 'linear',
		beyond_domain => 'clamp',
		points => $_[0]
	)->fn;
}


sub linear_extrapolate_fn {
	Math::InterpolationCompiler->new(
		algorithm => 'linear',
		beyond_domain => 'extrapolate',
		points => $_[0]
	)->fn;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::InterpolationCompiler - Compile interpolations into perl coderefs

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

  my $fn= Math::InterpolationCompiler->new(
    domain        => [ 1,   2,   3,   4,   5    ],
    range         => [ 1.9, 1.3, 1.2, 1.1, 1.05 ],
    algorithm     => 'linear',
    beyond_domain => 'die',
  )->fn;
  print $fn->(3);   # 1.2
  print $fn->(3.5); # 1.15
  print $fn->(9);   # throws exception
  
  # The generated code:  (whitespace added for readability)
  #
  # sub {
  #   my $x= shift;
  #   return $x < 4?
  #     ( $x < 2?
  #        ( $x < 1? (croak "argument out of bounds (<1)") : ($x * -0.6 + 2.5) )
  #       :( $x < 3? ($x * -0.1 + 1.5) : ($x * -0.0999999999999999 + 1.5) )
  #     )
  #     :( $x < 5?
  #        ( $x * -0.05 + 1.3)
  #       :( $x == 5? (1.05) : croak "argument out of bounds (>5)" )
  #     );
  # }

=head1 DESCRIPTION

This module is much the same theme as L<Math::Interpolate> and
L<Math::Interpolator::Linear> but it compiles the interpolations into actual
Perl code, and pre-calculates all the numbers so that the end result is
Log2(N) comparisons and a multiply and an add, all done at the
interpreter level.  This makes it very fast for repeated calls.

Use this module if you have a few smallish data plots which you want to
evaluate very quickly over and over again.

DO NOT use this module if you have an extremely large data array that changes
frequently, if your data points are not plain scalars, or if you are extremely
worried about code-injection attacks.
(this module sanitizes the numbers you give it, but it is still generating
perl code and in security-critical environments with untrusted input your
best bet is to just avoid all string evals).

This generator is written as a Perl object which produces a coderef.  This
makes the generator easy to extend and re-use pieces for various goals.
However the OO design is somewhat unnecessary, and really just a convenient
implementation thanks to L<Moo>.  In other words, the object doesn't have
much use other than performing a one-time job.

=head1 ATTRIBUTES

=head2 domain

The input values ('x') of the function.
Domain must be sorted in non-decreasing order.
Repeated values can represent discontinuities in the line.

=head2 range

The output values ('y') of the function.

=head2 algorithm

The name of the algorithm to create:

=over

=item linear

Create a linear interpolation, where an input ('x') is matched to the domain
interval containing that value, and the return value is

  y = x * (y_next - y_prev) / (x_next - x_prev)

If a domain 'x' coordinate is specified more than once (describing infinite
slope) it is treated as a discontinuity.  The 'x' values less than the
discontinuity are interpolated using the segment before the discontinuity, and
the 'x' values equal or greater than the discontinuity use the segment after
the discontinuity.

Example:

  # domain => [ 1, 2, 2, 3 ],
  # range  => [ 0, 0, 1, 2 ],
  $fn->(1);   # equals 0
  $fn->(1.9); # equals 0
  $fn->(2);   # equals 1
  #fn->(3);   # equals 2

When beyond_domain is 'extrapolate' and a discontinuity occurs at the edge of
the domain, the slope of the imaginary line outside of the domain is
considered to be 0 (causing an effect like C<beyond_domain =E<gt> 'clamp'>).

Example:

  # points => [[0,0], [0,1]]
  # beyond_domain => 'extrapolate'
  $fn->(x) # equals 0 for x < 0 and 1 for x >= 0

=back

=head2 beyond_domain

The behavior of the generated function when an input value ('x') lies outside
the domain of the function.

=over

=item clamp

Constrain 'x' to the valid domain of the function.

=item extrapolate

Extrapolate the curve at the nearest edge of the domain.
Details of the extrapolation depend on the 'algorithm' being used.

=item undef

Return undef for any 'x' outside the domain of the function.

=item die

Die with an error for any 'x' outside of the domain of the function.

=back

=head2 perl_code

Lazy-build the perl code for this function using the other attributes.
Returns a string of perl code.

=head2 fn

Lazy-build the perl coderef for the L<perl_code> attribute.

=head2 sanitize

Boolean.  Whether or not to sanitize the domain and range with a 'number'
regex during the constructor.  Defaults to true.

Setting this to false leaves you open to code injection attacks, but you might
choose to do that if you trust your input and you need a little performance
boost on constructing this object.

=head1 METHODS

=head2 new

Standard object constructor accepting any of the above attributes, but also
accepting:

=over

=item points

  ->new( points => [ [1,1], [2,2], [3,2], ... ] );
  # or
  ->new( points => [ 1 => 1, 2 => 2, 3 => 2, ... ] );

For convenience, you can specify your domain and range as an arrayref of (x,y)
pairs.  During BUILDARGS, this will get separated into the domain and range
attributes.  The pairs can either be individual arrayrefs, or just odd/even
elements of a single arrayref (but not a mix of the two).

=back

=head1 EXPORTS

This module contains a few exportable functions for convenience.

=head2 linear_clamp_fn

  $fn= linear_clamp_fn( \@points )
  
  # equivalent to:
  $fn= Math::InterpolationCompiler->new(
      algorithm => 'linear',
      beyond_domain => 'clamp',
      points => \@points
    )->fn;

=head2 linear_extrapolate_fn

  $fn= linear_clamp_fn( \@points )
  
  # equivalent to:
  $fn= Math::InterpolationCompiler->new(
      algorithm => 'linear',
      beyond_domain => 'extrapolate',
      points => \@points
    )->fn;

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
