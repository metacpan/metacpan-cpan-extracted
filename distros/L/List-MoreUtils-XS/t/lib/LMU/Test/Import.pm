package LMU::Test::Import;

use strict;

BEGIN
{
    $| = 1;
}

use Test::More;

sub run_tests
{
    use_ok(
        "List::MoreUtils", qw(any all none notall
          any_u all_u none_u notall_u
          true false firstidx lastidx
          insert_after insert_after_string
          apply indexes
          after after_incl before before_incl
          firstval lastval
          each_array each_arrayref
          pairwise natatime
          mesh uniq
          minmax part
          bsearch
          sort_by nsort_by
          first_index last_index first_value last_value zip distinct)
    );
    done_testing();
}

1;

=head1 AUTHOR

Jens Rehsack E<lt>rehsack AT cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 - 2017 by Jens Rehsack

All code added with 0.417 or later is licensed under the Apache License,
Version 2.0 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

All code until 0.416 is licensed under the same terms as Perl itself,
either Perl version 5.8.4 or, at your option, any later version of
Perl 5 you may have available.

=cut
