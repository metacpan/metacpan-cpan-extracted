package Math::Random::Zipf;

use warnings;
use strict;
use POSIX;

our $VERSION = '0.11';

sub new {
    my ($class, $N, $exp) = @_;

    my $self = bless {
	N => $N,
	alpha => $exp,
	cdf => [],
	pmf => [],
    }, ref($class) || $class;

    my $sum = 0;
    for my $k (1 .. $N) {
	$sum += ($self->{pmf}[$k-1] = 1/($k ** $exp));
	push(@{$self->{cdf}}, $sum);
    }
    my $mult = 1/$sum;
    $self->{cdf}->[$_] *= $mult,  $self->{pmf}->[$_] *= $mult for (0 .. $N - 1);

    return $self;
}

sub rand {
    my $self = shift;
    my $x = shift || rand();

    my $tab = $self->{cdf};
    my $lower = -1;
    my $upper = @$tab - 1;
    my $try = -1;
    my $last_try = -1;
    # binary search
    while (1) {
	my $try = POSIX::floor(($lower + $upper + 1) / 2);
	last if $last_try == $try;

	if ($tab->[$try] >= $x) {
	    $upper = $try;
	}
	else {
	    $lower = $try-1;
	}
	$last_try = $try;
    }
    return $upper + 1;
}

sub inv_cdf {
    my ($self, $P) = @_;
    return $self->rand($P);
}

sub pmf {
    my $self = shift;
    my $x = shift;

    return 0 if $x < 1 || $x > $self->{N} || floor($x) != $x;
    return $self->{pmf}->[$x - 1];
}

sub cdf {
    my $self = shift;
    my $x = shift;

    return 0 if $x < 1 || $x > $self->{N} || floor($x) != $x;
    return $self->{cdf}->[$x - 1];
}
    
sub pmf_ref {
    return shift->{pmf};
}

sub cdf_ref {
    return shift->{cdf};
}


__END__

=head1 NAME

Math::Random::Zipf - Generate Zipf-distributed random integers

=head1 SYNOPSIS

    use Math::Random::Zipf;

    my $zipf = Math::Random::Zipf->new($N, $exponent);

    # generate random deviate based on system rand()
    $rand = $zipf->rand();

    # generated random deviate based on your own version of rand()
    $rand = $zipf->rand(my_uniform_rng());

    # get probability(x)
    $prob = $zipf->pmf($x)

    # get cumulative probability x <= X
    $cdf = $zipf->cdf($X)

    # get X given probability
    $X = $zipf->inv_cdf(P);

=head1 DESCRIPTION

This module generates random integers k that follow the Zipf distribution, 

  P(k) = C / k^s

for k = [ 1, 2, .. N ], s a fixed exponent and C a normalisation constant.  It
is related to the Zeta distribution (infinite N) and Pareto distribution
(continuous equivalent).

The samples are generated using the inverse transform method.

=head1 METHODS

=head2 new

  $zipf = Math::Random::Zipf->new($N, $exponent);

Creates a new Math::Random::Zipf object using parameters $N (maximum integer)
and $exponent ( 's' in P(k) = C / k^s ).

=head2 rand

  $rand = $zipf->rand();
  $rand = $zipf->rand(my_uniform_rng());

Returns a random deviate.  Uses perl's built-in rand() by default, but may be
supplied with samples from an alternative source of uniformly distributed
numbers in the range [0,1].

=head2 pmf_ref, cmf_ref

  $pmf = $zipf->pmf_ref();
  $cdf = $zipf->cdf_ref();

Returns references to arrays of the probability mass and cumulative distribution
functions respectively.

=head2 pmf, cmf

  $p = $zipf->pmf($x)
  $P = $zipf->cdf($x)

Returns probability and cumulative probability respectively of a specific
integer value $x.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Zipf%27s_law>

=head1 AUTHOR

Jon Schutz, C<< <jon at jschutz.net> >> L<http://notes.jschutz.net/>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-random-zipf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Random-Zipf>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Random::Zipf


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Random-Zipf>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Random-Zipf>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Random-Zipf>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Random-Zipf/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Math::Random::Zipf
