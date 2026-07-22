# Copyright 2022 Google Inc.
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

our $VERSION = '0.04';
XSLoader::load( 'Google::Auth', $VERSION );


=head1 NAME

Application default credentials.

Google::Auth - Implements application default credentials and project ID detection.


=head1 VERSION

Version 0.02

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
sub default
{
    my ( $self, $scopes, $options ) = @_;
    $options //= {};

    my $dc = Google::Auth::DefaultCredentials->new();

    my $creds = $dc->from_env( $scopes, %$options )
             || $dc->from_well_known_path( $scopes, %$options )
             || $dc->from_system_default_path( $scopes, %$options );

    return $creds if $creds;

    if ( Google::Auth::ComputeEngine->on_gce( %$options ) ) {
        return Google::Auth::ComputeEngine->new( scope => $scopes, %$options );
    }

    Google::Auth::DefaultCredentialsError->throw(
        'Your credentials were not found. To set up Application Default '
      . 'Credentials for your environment, see '
      . 'https://cloud.google.com/docs/authentication/external/set-up-adc'
    );
}

# I have no idea why my perlcritic throws this
#[%- Perl::Critic::Policy::Modules::RequireEndWithOne %]
# End of Google::Auth
1;


=head1 AUTHOR

C.J. Collier, C<< <cjac at google.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-google-auth-library-perl at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Google-Auth-Library-Perl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Google::Auth


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-Auth-Library-Perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<annocpan.org/dist/Google-Auth-Library-Perl>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Google-Auth-Library-Perl>

=item * Search CPAN

L<https://metacpan.org/release/Google-Auth-Library-Perl>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2020,2021 Google, LLC

This program is released under the following license: Apache 2.0


=cut

