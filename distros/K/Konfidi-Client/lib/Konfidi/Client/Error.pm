# <@LICENSE>
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# </@LICENSE>

package Konfidi::Client::Error;

use warnings;
use strict;

=head1 NAME

Konfidi::Client::Error - An error from a L<Konfidi::Client>

=head1 DESCRIPTION

See L<Error|http://search.cpan.org/perldoc?Error> for error handling documentation

=head1 VERSION

Version 1.0.4

=cut

our $VERSION = '1.0.4';

use base 'Error::Simple';

1;
