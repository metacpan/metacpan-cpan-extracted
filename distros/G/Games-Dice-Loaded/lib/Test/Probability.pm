package Test::Probability;
{
  $Test::Probability::VERSION = '0.002';
}

use strict;
use warnings;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/dist_ok/;

require AutoLoader; # Statistics::Distributions should do this, but doesn't.
use Statistics::Distributions 1.02 qw/chisqrdistr/;
use Test::More;
use List::Util qw/sum/;
use List::MoreUtils qw/pairwise/;
use Carp;

sub chisq {
	my ($observed, $expected) = @_;
	return sum(pairwise {
		my $denom = $b > 0.5 ? $b : 0.5;
		($a - $b)**2 / $denom;
	} @$observed, @$expected);
}

sub fits_distribution {
	my ($observed, $dist, $confidence) = @_;
	croak "First arg not an array or arrayref" unless ref $observed eq 'ARRAY';
	croak "Second arg not an array or arrayref" unless ref $dist eq 'ARRAY';
	croak "Size of observed domain does not match size of distribution domain"
		unless scalar(@$observed) == scalar(@$dist);
	my $observations = sum @$observed;
	my $scalefactor = $observations / (sum @$dist);
	my @expected = map { $_ * $scalefactor } @$dist;
	my $chisq = chisq($observed, \@expected);
	my $dof = @$dist - 1;	# degrees of freedom
	my $threshold = chisqrdistr($dof, 1 - $confidence);
	return $chisq <= $threshold;
}

sub dist_ok {
	my ($observed, $dist, $confidence, $message) = @_;
	ok(fits_distribution($observed, $dist, $confidence), $message);
}

1;

__END__

=head1 NAME

Test::Probability - test if results are distributed correctly

=head1 SYNOPSIS

  use Test::Probability;

  my @results;
  for (0 .. 1000) {
	$results[rand_fn()]++;
  }
  my @probabilities = (0.5, 0.2, 0.3);
  my $confidence = 0.9;
  dist_ok(@results, @probabilities, $confidence,
    "results match expected with confidence $confidence");

=head1 DESCRIPTION

Does your random-number generating function output the distribution you expect?
Now you can find out! This module performs a chi-squared test at the specified
confidence interval.

=head1 EXPORTS

=over

=item dist_ok

  dist_ok(@results, @probabilities, $confidence,
    "results match probabilities with confidence $confidence");

=back
  
=head1 AUTHOR

Miles Gould, E<lt>mgould@cpan.orgE<gt>

=head1 CONTRIBUTING

This module is currently distributed along with Games::Dice::Loaded.
Please fork
L<the GitHub repository|http://github.com/pozorvlak/Games-Dice-Loaded>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Miles Gould

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

=over

=item L<Statistics::ChiSquared> (only handles even distributions).

=item L<Statistics::Distributions> (used internally by this module).

=back

=cut
