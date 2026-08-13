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

our $VERSION = '0.12';
XSLoader::load('Google::Auth', $VERSION);

=head1 NAME

Application default credentials.

Google::Auth - Implements application default credentials and project ID detection.


=head1 VERSION

Version 0.12

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Google::Auth;

    my $gauth = Google::Auth->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 default( $scopes, $options )

Gets the default credentials for the current environment.

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

=item GOOGLE_EXTERNAL_ACCOUNT_ALLOW_EXECUTABLES

Set to '1' to allow Pluggable Credentials to execute external commands. Default is '0' (disabled).

=item GOOGLE_EXTERNAL_ACCOUNT_ALLOW_CUSTOM_UNIVERSES

Set to '1' to allow custom universes in credentials files loaded from JSON. Default is '0' (disabled).

=back

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

Copyright 2020 Google LLC and contributors

This program is released under the following license: Apache 2.0


=cut

