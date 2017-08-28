package EPFL::Sciper::List;

use 5.006;
use strict;
use warnings;

use JSON;
use Readonly;
use LWP::UserAgent;

=head1 NAME

EPFL::Sciper::List - Retrieve a list of all public active sciper from EPFL.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Retrieve sciper from EPFL

    use EPFL::Sciper::List qw/retrieveSciper toJson toTsv/;

    my @listPersons = retrieveSciper();
    print toJson(@listPersons);
    print toTsv(@listPersons);

Via the command-line program epfl-sciper-list.pl

=head1 DESCRIPTION

A simple module to retrieve a list of all public active sciper from EPFL.

=cut

use base 'Exporter';
our @EXPORT_OK =
  qw/p_createUserAgent p_getUrl p_buildUrl retrieveSciper toJson toTsv/;

Readonly::Scalar my $TIMEOUT => 1200;

Readonly::Scalar my $MAXREDIRECT => 10;

Readonly::Scalar my $AUTOCOMPLETE_URL =>
  'https://search.epfl.ch/json/autocompletename.action?maxRows=99999999&term=';

=head1 SUBROUTINES/METHODS

=head2 retrieveSciper( )

Return a list of persons from EPFL with information like:

(sciper => 999999, firstname => 'Taylor', name => 'Swift');

=cut

sub retrieveSciper {
  my @listPersons = ();
  my @alphabet    = ( 'a' .. 'z' );

  my $ua = p_createUserAgent();
  foreach my $letter (@alphabet) {
    my $response = p_getUrl( $ua, p_buildUrl($letter) );

    if ( $response->is_success ) {
      my $struct = from_json( $response->decoded_content );
      push @listPersons, @{ $struct->{result} };
    }
  }

  my %hash = ();
  foreach my $per (@listPersons) {
    $hash{ $per->{sciper} } = $per;
  }

  @listPersons = ();
  foreach my $sciper ( sort { $a <=> $b } keys %hash ) {
    push @listPersons, $hash{$sciper};
  }

  return @listPersons;
}

=head2 toJson

Return sciper list in JSON

=cut

sub toJson {
  my @list = @_;

  my $json = JSON->new->allow_nonref;
  return $json->pretty->encode( \@list );
}

=head2 toTsv

Return sciper list in TSV

=cut

sub toTsv {
  my @list = @_;

  my $output = q{};
  foreach my $per (@list) {
    $output .=
      $per->{sciper} . "\t" . $per->{firstname} . "\t" . $per->{name} . "\n";
  }
  return $output;
}

=head1 PRIVATE SUBROUTINES/METHODS

=head2 p_createUserAgent

Return a LWP::UserAgent.
LWP::UserAgent objects can be used to dispatch web requests.

=cut

sub p_createUserAgent {
  my $ua = LWP::UserAgent->new;

  $ua->timeout($TIMEOUT);
  $ua->agent('DevRunBot');
  $ua->env_proxy;
  $ua->max_redirect($MAXREDIRECT);

  return $ua;
}

=head2 p_getUrl

Dispatch a GET request on the given $url
The return value is a response object. See HTTP::Response for a description
of the interface it provides.

=cut

sub p_getUrl {
  my ( $ua, $url ) = @_;

  return $ua->get($url);
}

=head2 p_buildUrl

Return the autocomplete url to retrieve sciper.

=cut

sub p_buildUrl {
  my $letter = shift;

  return $AUTOCOMPLETE_URL . $letter;
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests here L<https://github.com/epfl-devrun/epfl-sciper-list/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc EPFL::Sciper::List

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/EPFL-Sciper-List>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/EPFL-Sciper-List>

=item * Search CPAN

L<http://search.cpan.org/dist/EPFL-Sciper-List/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2017.

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

1;    # End of EPFL::Sciper::List
