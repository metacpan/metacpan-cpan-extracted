# Copyright 2022 Google LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Google::Auth::Exceptions;

use 5.006;
use strict;
use warnings;

=head1 NAME

Google::Auth::Exceptions - Exceptions used in the Google::Auth package

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

# Base class for all google.auth errors

package Google::Auth::Error;
use Moo;
use overload '""' => \&to_string, fallback => 1;

has message => ( is => 'ro', required => 1 );

sub to_string {
    my ($self) = @_;
    return $self->message;
}

sub throw {
    my ($class, $message) = @_;
    if (ref $class) {
        die $class;
    }
    my $self = $class->new({ message => $message || 'Unknown error' });
    die $self;
}

# Used to indicate an error occurred during an HTTP request
#[%- Perl::Critic::Policy::Modules::ProhibitMultiplePackages %]
package Google::Auth::TransportError;
use Moo;
extends 'Google::Auth::Error';

# Used to indicate failure to refresh the credentials' access token
#[%- Perl::Critic::Policy::Modules::ProhibitMultiplePackages %]
package Google::Auth::RefreshError;
use Moo;
extends 'Google::Auth::Error';

# Used to indicate failure to acquire default credentials
#[%- Perl::Critic::Policy::Modules::ProhibitMultiplePackages %]
package Google::Auth::DefaultCredentialsError;
use Moo;
extends 'Google::Auth::Error';

=head1 AUTHOR

C.J. Collier, C<< <cjac at google.com> >>

=head1 BUGS AND SUPPORT

Please report any bugs or feature requests to the GitHub issue tracker at
L<https://github.com/GoogleCloudPlatform/google-auth-library-perl/issues> or via RT at
L<https://rt.cpan.org/Dist/Display.html?Name=Google-Auth>.

You can also look for information at:

=over 4

=item * GitHub Issue Tracker

L<https://github.com/GoogleCloudPlatform/google-auth-library-perl/issues>

=item * RT: CPAN's Request Tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Google-Auth>

=item * MetaCPAN

L<https://metacpan.org/release/Google-Auth>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020,2021 Google LLC

This program is released under the following license: Apache 2.0


=cut

1;    # End of Google::Auth::Exceptions
