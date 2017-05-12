use strict;
use warnings;
package Metabase::Web;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

use Catalyst::Runtime '5.800000';
use Catalyst qw/ConfigLoader/;

__PACKAGE__->config(name => __PACKAGE__);
__PACKAGE__->setup;

=head1 NAME

Metabase::Web - the Metabase web service

=head1 DESCRIPTION

Metabase::Web is a web service front-end to the L<Metabase|Metabase> metadata
database system.

Metabase::Web is a Catalyst application with, at present, only one controller
and one model.  Consult their documentation for more information:

=over

=item * L<Metabase::Web::Controller::Root>

=item * L<Metabase::Web::Model::Metabase>

=item * L<Metabase::Client::Simple> - a simple client to submit facts

=back

=head1 AUTHOR

=over 

=item * David A. Golden (DAGOLDEN)

=item * Ricardo J. B. Signes (RJBS)

=back

=head1 COPYRIGHT AND LICENSE

  Portions copyright (c) 2008-2009 by David A. Golden
  Portions copyright (c) 2008-2009 by Ricardo J. B. Signes

Licensed under the same terms as Perl itself (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a
copy of the License from http://dev.perl.org/licenses/

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
