#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;

my @pure_funcs = qw(any all none notall one
  any_u all_u none_u notall_u one_u
  true false
  insert_after insert_after_string
  apply indexes
  after after_incl before before_incl
  firstidx lastidx onlyidx
  firstval lastval onlyval
  firstres lastres onlyres
  singleton
  each_array each_arrayref
  pairwise natatime
  mesh uniq
  minmax part
  bsearch bsearchidx);
my @v0_33      = qw(sort_by nsort_by);
my %alias_list = (
    v0_22 => {
        first_index => "firstidx",
        last_index  => "lastidx",
        first_value => "firstval",
        last_value  => "lastval",
        zip         => "mesh",
    },
    v0_33 => {
        distinct => "uniq",
    },
    v0_400 => {
        first_result  => "firstres",
        only_index    => "onlyidx",
        only_value    => "onlyval",
        only_result   => "onlyres",
        last_result   => "lastres",
        bsearch_index => "bsearchidx",
    },
);

can_ok(__PACKAGE__, $_) for @pure_funcs;

SKIP:
{
    $INC{'List/MoreUtils.pm'} or skip "List::MoreUtils::XS doesn't alias", 1;
    can_ok(__PACKAGE__, $_) for @v0_33;
    can_ok(__PACKAGE__, $_) for map { keys %$_ } values %alias_list;
}

done_testing;

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


