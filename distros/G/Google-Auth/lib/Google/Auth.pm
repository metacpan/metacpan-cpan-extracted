# Copyright 2022 Google LLC and contributors
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

package Google::Auth;

use 5.006;
use strict;
use warnings;

use Google::Auth::EnvironmentVars;
use Google::Auth::DefaultCredentials;
use Google::Auth::ComputeEngine;
use Google::Auth::Exceptions;
use XSLoader;

our $VERSION = '0.15';
XSLoader::load('Google::Auth', $VERSION);

=head1 NAME

Google::Auth - Google Cloud ADC and OAuth 2.0 authentication for Perl

=head1 VERSION

Version 0.15

=head1 SYNOPSIS

    use Google::Auth;

    # Load Application Default Credentials (ADC)
    my $creds = Google::Auth->default(
        ['https://www.googleapis.com/auth/cloud-platform']
    );

    # Fetch a Bearer access token (cached and refreshed automatically)
    my $access_token = $creds->get_token();

    # Use with a Google Cloud client library
    use Google::Cloud::Spanner::V1::SpannerClient;
    my $client = Google::Cloud::Spanner::V1::SpannerClient->new(
        credentials => $creds,
    );

=head1 DESCRIPTION

C<Google::Auth> implements Google Cloud Application Default Credentials (ADC)
and OAuth 2.0 authentication for Perl. It automatically discovers credentials
from the environment in the standard Google Cloud order:

=over 4

=item 1. The C<GOOGLE_APPLICATION_CREDENTIALS> environment variable (service account JSON, authorized user JSON, impersonated service account, or Workload Identity Federation external account config).

=item 2. The well-known Google Cloud CLI ADC path (C<~/.config/gcloud/application_default_credentials.json>).

=item 3. The system default path.

=item 4. The Compute Engine / GKE / Cloud Run metadata server when running on GCP.

=back

It also provides OpenSSL-backed cryptographic helpers (JWT signing and ID token
verification), Workload Identity Federation (AWS EC2 IMDSv2 / ECS Task Roles,
Pluggable/URL/File-sourced credentials), service account impersonation, OAuth
2.0 web/installed-app authorizers, and the C<gcloud-auth> CLI utility.

=head1 METHODS

=head2 default( $scopes, $options )

    my $creds = Google::Auth->default();
    my $creds = Google::Auth->default(
        ['https://www.googleapis.com/auth/cloud-platform'],
        { universe_domain => 'googleapis.com' },
    );

Resolves and returns a credentials object (subclass of
L<Google::Auth::Credentials>) for the current environment. C<$scopes> may be a
single scope string or an ArrayRef of OAuth 2.0 scope URLs. C<$options> is an
optional HashRef of additional parameters forwarded to the credential loader.

Throws C<Google::Auth::DefaultCredentialsError> (defined in
C<Google::Auth::Exceptions>) if no credentials can be found.

=cut

#[%- Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms %]
sub default {
  my ($self, $scopes, $options) = @_;
  $options //= {};

  my $dc = Google::Auth::DefaultCredentials->new();

  my $creds =
       $dc->from_env($scopes, %$options)
    || $dc->from_well_known_path($scopes, %$options)
    || $dc->from_system_default_path($scopes, %$options);

  return $creds if $creds;

  if (Google::Auth::ComputeEngine->on_gce(%$options)) {
    return Google::Auth::ComputeEngine->new(scope => $scopes, %$options);
  }

  Google::Auth::DefaultCredentialsError->throw(
    'Your credentials were not found. To set up Application Default ' .
      'Credentials for your environment, see ' .
      'https://cloud.google.com/docs/authentication/external/set-up-adc');
}

# I have no idea why my perlcritic throws this
#[%- Perl::Critic::Policy::Modules::RequireEndWithOne %]
# End of Google::Auth
1;

=head1 CONFIGURATION AND ENVIRONMENT

=over 4

=item C<GOOGLE_APPLICATION_CREDENTIALS>

Path to a JSON credentials file (service account, authorized user, impersonated
service account, or external account / WIF configuration).

=item C<GOOGLE_CLOUD_QUOTA_PROJECT>

Optional Google Cloud project ID used for quota and billing attribution.

=item C<GOOGLE_EXTERNAL_ACCOUNT_ALLOW_EXECUTABLES>

Set to C<1> to allow Pluggable Credentials to execute external commands. Default is C<0> (disabled).

=item C<GOOGLE_EXTERNAL_ACCOUNT_ALLOW_CUSTOM_UNIVERSES>

Set to C<1> to allow custom universes in credentials files loaded from JSON. Default is C<0> (disabled).

=back

=head1 SEE ALSO

L<Google::Auth::DefaultCredentials>, L<Google::Auth::ServiceAccountCredentials>,
L<Google::Auth::ComputeEngine>, L<Google::Auth::UserRefreshCredentials>,
L<Google::Auth::ImpersonatedServiceAccountCredentials>,
L<Google::Auth::ExternalAccountCredentials>,
L<Google::Auth::IDTokens::Verifier>, L<Google::Auth::WebUserAuthorizer>

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

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Google LLC and contributors

This program is released under the following license: Apache 2.0

=cut

