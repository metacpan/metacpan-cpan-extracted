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

Version 0.02

=cut

our $VERSION = '0.02';

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

C.J. Collier, C<< <cjcollier at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-google-auth-library-perl at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Google-Auth-Library-Perl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Google::Auth::Exceptions


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-Auth-Library-Perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Google-Auth-Library-Perl>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Google-Auth-Library-Perl>

=item * Search CPAN

L<https://metacpan.org/release/Google-Auth-Library-Perl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020,2021 Google LLC

This program is released under the following license: Apache 2.0


=cut

1;    # End of Google::Auth::Exceptions
