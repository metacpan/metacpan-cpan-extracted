package Math::SZaru;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Math::SZaru', $VERSION);

1;
__END__

=head1 NAME

Math::SZaru - Perl wrapper for the SZaru C++ library

=head1 SYNOPSIS

  use Math::SZaru;
  # loads Math::SZaru::UniqueEstimator
  # and Math::SZaru::TopEstimator
  # and Math::SZaru::QuantileEstimator

=head1 DESCRIPTION

SZaru is a stand-alone C++ library that extracts some of the
aggregator functionality of Google's Sawzall library or more
specifically, the Open Source I<szl> implementation.
C<Math::SZaru> is a Perl/XS wrapper of SZaru and comes with
a complete copy of the C++ code to build without system-library
dependencies.

The one unifying aspect of the implemented aggregators is that
they work with a single pass and with bounded memory overhead.
In CS terms, they should have near C<O(n)> compute complexity
and C<O(1)> or at least sub-linear memory overhead. The algorithms
may trade accuracy (hence I<*Estimator>) for this goal and are
intended for use with large and/or streaming data sets that
either do not fit in memory or whose total size is unknown.

The functionality is currently divided between three classes:
L<Math::SZaru::UniqueEstimator>, L<Math::SZaru::TopEstimator>,
and L<Math::SZaru::QuantileEstimator>. For details on those,
please refer to their respective documentation.

=head1 SEE ALSO

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
