package EPFL::Service::Open;

use 5.006;
use strict;
use warnings;

=head1 NAME

EPFL::Service::Open - Open the EPFL website (service) associated with the
Git repository.

=head1 VERSION

Version 1.05

=cut

our $VERSION = '1.05';

=head1 SYNOPSIS

Retrieve the EPFL website (service) associated with the Git repository.

    use EPFL::Service::Open qw( getService );

    my $serviceUrl = getService('git@github.com:epfl-idevelop/epfl-theme-elements.git');

=head1 DESCRIPTION

A simple module to retrieve the EPFL website (service) associated with the
Git repository.

=cut

my %REPOSITORY_LIST = (
  'bill2myprint'                => 'https://ofrf.epfl.ch',
  'elements'                    => 'https://epfl-idevelop.github.io/elements',
  'epfl-news'                   => 'https://actu.epfl.ch',
  'epfl-theme-elements'         => 'https://web2018.epfl.ch',
  'homepage-archiveweb.epfl.ch' => 'https://archiveweb.epfl.ch',
  'kis-bootstrap'               => 'https://static.epfl.ch',
  'memento'                     => 'https://memento.epfl.ch',
  'polyblog'                    => 'https://blogs.epfl.ch',
  'polywiki'                    => 'https://wiki.epfl.ch',
  'press-release'               => 'https://rdp.epfl.ch',
  'science-cruise-data-management' => 'https://scdm.epfl.ch',
  'site-diffusion-mediatheque'     => 'https://mediatheque.epfl.ch',
  'web2010'                        => 'https://www.epfl.ch/templates/',
);

use base 'Exporter';
our @EXPORT_OK = qw( getService );

=head1 SUBROUTINES/METHODS

=head2 getService( $repository )

Return the EPFL website (service) associated with the Git repository or undef.

=cut

sub getService {
  my $repository = shift;
  return if not defined $repository;

  my @parts   = split /\//xms, $repository;
  my $gitName = $parts[-1];
  return if not defined $gitName;

  @parts = split /[.]/xms, $gitName;
  pop @parts;
  my $projectName = join q{.}, @parts;

  if ( $REPOSITORY_LIST{$projectName} ) {
    return $REPOSITORY_LIST{$projectName};
  }
  return;
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 SEE ALSO

See L<epfl-service-open> for the command line.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests here
L<https://github.com/innovativeinnovation/epfl-service-open/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc EPFL::Service::Open

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/EPFL-Service-Open>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/EPFL-Service-Open>

=item * Search CPAN

L<http://search.cpan.org/dist/EPFL-Service-Open/>

=back

=head1 LICENSE AND COPYRIGHT

Original work Copyright ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE,
Switzerland, VPSI, 2018.

Modified work Copyright William Belle, 2018-2019.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
