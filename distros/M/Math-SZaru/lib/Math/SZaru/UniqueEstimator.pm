package Math::SZaru::UniqueEstimator;
use 5.008;
use strict;

use Math::SZaru;

1;
__END__

=head1 NAME

Math::SZaru::UniqueEstimator -  Statistical estimator for total number of unique items

=head1 SYNOPSIS

  use Math::SZaru::UniqueEstimator;
  my $ue = Math::SZaru::UniqueEstimator->new($maxelems);
  $ue->add_elem("foo");
  # add many more elems using add_elem ...
  my $inserted_elems_count = $ue->tot_elems;
  my $estimated_unique_count = $ue->estimate();

=head1 DESCRIPTION

C<Math::SZaru::UniqueEstimator> provides a statistical estimate of
the number of unique elements in the input stream.

Quoting the documentation of the SZaru C++ implementation:

  The technique used is:
  - Convert all elements to unique evenly spaced hash keys.
  - Keep track of the smallest N element ("nElemes") of these elements.
  - "nelems" cannot glow beyond maxelems.
  - Based on the coverage of the space, compute an estimate
  of the total number of unique elements, where biggest-small-elem
  means largest element among kept "maxelems" elements.
  
  unique = nElemes < maxelems
  ? nElems
  : (maxelems << bits-in-hash) / biggest-small-elem

=head1 METHODS

=head2 new

Constructor. Expects an integer indicating the total size of the
underlying hash table.

=head2 add_elem

Given a string, adds the string to the UniqueEstimator hash table.

=head2 add_elems

Same as C<add_elem>, but accepts an arbitrary number of strings to
insert into the estimator at once.

=head2 tot_elems

Returns the total count of the number of elements that were
added to the estimator.

=head2 estimate

Returns the estimated number of unique elements that were
added to the estimator so far. See above for a description
of the algorithm.

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
