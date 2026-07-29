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

package Google::Auth::EnvironmentVars;

use 5.006;
use strict;
use warnings;

use Moo;

=head1 NAME

Google::Auth::EnvironmentVars - Environment variables used by Google::Auth

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

Canonical package for reading environment variables used with Google::Auth

=head1 METHODS

=head2 PROJECT

This env variable is used by Google::Auth to explicitly set a project
ID. This environment variable is also used by the Google Cloud Perl
Library.

=cut

has PROJECT => (
    is            => 'ro',
    builder       => sub { $ENV{GOOGLE_CLOUD_PROJECT} },
    documentation => 'Environment variable defining default project',
);

=head2 LEGACY_PROJECT

This environment variable is used instead of the current one in some
situations (such as Google App Engine).

=cut

has LEGACY_PROJECT => (
    is            => 'ro',
    builder       => sub { $ENV{GCLOUD_PROJECT} },
    documentation =>
        'Previously used environment variable defining the default project',
);

=head2 CREDENTIALS

Environment variable defining the location of Google application
default credentials

=cut

has CREDENTIALS => (
    is            => 'ro',
    builder       => sub { $ENV{GOOGLE_APPLICATION_CREDENTIALS} },
    documentation =>
'Environment variable defining the location of Google application default credentials',
);

=head2 CLOUD_SDK_CONFIG_DIR

The environment variable name which can replace ~/.config if set

=cut

has CLOUD_SDK_CONFIG_DIR => (
    is            => 'ro',
    builder       => sub { $ENV{CLOUDSDK_CONFIG} },
    documentation =>
q{Environment variable defines the location of Google Cloud SDK's config files},
);

=head2 GCE_METADATA_ROOT

This and the following variable allow for customization of the
addresses used when contacting the GCE metadata service.

=cut

has GCE_METADATA_ROOT => (
    is            => 'ro',
    builder       => sub { $ENV{GCE_METADATA_ROOT} },
    documentation =>
'Environment variable providing an alternate hostname or host:port to be '
        . 'used for GCE metadata requests',
);

=head2 GCE_METADATA_IP

=cut

has GCE_METADATA_IP => (
    is            => 'ro',
    builder       => sub { $ENV{GCE_METADATA_IP} },
    documentation =>
'Environment variable providing an alternate ip:port to be used for ip-only '
        . 'GCE metadata requests',
);

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

1;    # End of Google::Auth
