package Math::SZaru::TopEstimator;
use 5.008;
use strict;

use Math::SZaru;

1;
__END__

=head1 NAME

Math::SZaru::TopEstimator - Statistical estimator of the 'top N' items based on CountSketch algorithm

=head1 SYNOPSIS

  use Math::SZaru::TopEstimator;
  my $ue = Math::SZaru::TopEstimator->new($num_top_elems_to_track);
  $ue->add_elem("foo");
  $ue->add_weighted_elem("bar", 100); # same as ->add_elem times 100
  $ue->add_elems("foo", "bar"); # same as ->add_elem for each one
  $ue->add_weighted_elems("foo" => 10, "bar" => 20);
  # add many more elems ...
  
  my $inserted_elems_count = $ue->tot_elems;
  my $estimated_list_of_top_elements = $ue->estimate();
  
  # $estimated_list_of_top_elements is now something like:
  # [ ["most frequent string", $count], ["second most frequent string, $count],
  #   [...], [...], ..., ["nth most frequent string", $count] ]

=head1 DESCRIPTION

C<Math::SZaru::TopEstimator> provides a statistical estimate of
the 'top N' most frequent data items in a stream.
This is based on CountSketch algorithm from
I<"Finding Frequent Items in Data Streams", Moses Charikar, Kevin Chen and Martin Farach-Colton, 2002>.

=head1 METHODS

=head2 new

Constructor. Expects an integer indicating the number of "top" items to track.

=head2 add_elem

Given a string, adds the string to the TopEstimator.

=head2 add_elems

Same as C<add_elem>, but accepts an arbitrary number of strings to
insert into the estimator at once.

=head2 add_weighted_elem

Given a string and a count N, adds that string N times to the
estimator (with a weight of N). Functionality-wise same as
calling doing C<$est-E<gt>add_elem("foo") for 1..$N>, but
much faster.

=head2 add_weighted_elems

This is to C<add_weighted_elem> what C<add_elems> is to C<add_elem>.
Takes a list of I<string, count, string, count, ...>.

=head2 tot_elems

Returns the total count of the number of elements that were
added to the estimator.

=head2 estimate

Returns a reference to an array containing as many records
as were configured to be tracked at construction time. Each record, in order,
represents the n-th most frequent item in the input stream -- estimated.

Each record is a reference to an array of the value (string)
and its' estimated total number of occurrences in the input.

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
