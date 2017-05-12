package LMU::Test::ab;

use strict;

BEGIN
{
    $| = 1;
}

use Test::More;
use List::MoreUtils 'pairwise';

sub run_tests
{
    test_ab();
    done_testing();
}

sub test_ab
{
    my @A = ( 1, 2, 3, 4, 5 );
    my @B = ( 2, 4, 6, 8, 10 );
    my @C = pairwise { $a + $b } @A, @B;
    is_deeply( \@C, [ 3, 6, 9, 12, 15 ], "pw1" );
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
