package Math::SZaru::QuantileEstimator;
use 5.008;
use strict;

use Math::SZaru;

1;
__END__

=head1 NAME

Math::SZaru::QuantileEstimator - Quantile estimation based on Munro-Paterson algorithm

=head1 SYNOPSIS

  use Math::SZaru::QuantileEstimator;
  my $ue = Math::SZaru::QuantileEstimator->new($maxelems);
  $ue->add_elem("foo");
  # add many more elems using add_elem ...
  my $inserted_elems_count = $ue->tot_elems;
  my $estimated_unique_count = $ue->estimate();

=head1 DESCRIPTION

C<Math::SZaru::QuantileEstimator> provides a statistical estimate of
quantiles in a large data set (or stream). It uses the algorithm published
by Munro and Paterson:
I<Munro & Paterson, "Selection and Sorting with Limited Storage", Theoretical Computer Science, Vol 12, p 315-323, 1980>.

=head1 METHODS

=head2 new

Constructor. Expects an integer indicating the number of quantiles to calculate.
In a nutshell, passing 101 will mean that the return value of the C<estimate>
call (see below) will return a list of min, 1st-percentile, 2nd-percentile, ...,
99th-percentile, max (min + 100 = 101). Other values cause the space between min
and max to be differently divided. Asking for only two quantiles will just yield
min/max to be tracked. Asking for three quantiles will add the median (50th percentile).

=head2 add_elem

Given a floating point number, adds the number to the QuantileEstimator.

=head2 add_elems

Same as C<add_elem>, but accepts an arbitrary list of numbers to
insert into the estimator at once.

=head2 tot_elems

Returns the total count of the number of elements that were
added to the estimator.

=head2 estimate

Returns the estimated quantiles in a raference to an array
as described in the C<new> documentation above.

=head1 SEE ALSO

L<Math::SZaru>

SZaru: L<llamerada.github.com/SZaru/>

Sawzall: L<http://code.google.com/p/szl/>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The Perl wrapper of the SZaru library is:

Copyright (C) 2013 by Steffen Mueller

Just like SZaru itself, it is licensed 
under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
