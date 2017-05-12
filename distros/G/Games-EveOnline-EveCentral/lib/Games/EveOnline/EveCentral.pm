package Games::EveOnline::EveCentral;
{
  $Games::EveOnline::EveCentral::VERSION = '0.001';
}

use Moo 1.003001;
use MooX::Types::MooseLike 0.25;
use MooX::StrictConstructor 0.006;
use Sub::Quote 1.003001;

# ABSTRACT: A Perl library client for the EVE Central API.


use 5.012;

use LWP::UserAgent::Determined 1.06;
use Try::Tiny 0.18;
use XML::LibXML 2.0108;
use JSON 2.90;


has 'ua' => (
  is => 'lazy',
  isa => quote_sub(q{
    die 'Not a LWP::UserAgent::Determined'
      unless UNIVERSAL::isa($_[0], 'LWP::UserAgent::Determined');
  })
);

has 'libxml' => (
  is => 'lazy',
  isa => quote_sub(q{
    die 'Not a XML::LibXML'
      unless UNIVERSAL::isa($_[0], 'XML::LibXML');
  })
);

has 'jsonparser' => (
  is => 'lazy',
  isa => quote_sub(q{
    die 'Not a JSON'
      unless UNIVERSAL::isa($_[0], 'JSON');
  })
);



sub marketstat {
  my ($self, $request) = @_;

  return $self->_do_http_request($request);
}


sub quicklook {
  my ($self, $request) = @_;

  return $self->_do_http_request($request);
}


sub quicklookpath {
  my ($self, $request) = @_;

  return $self->_do_http_request($request);
}


sub history {
  my ($self, $request) = @_;

  return $self->_do_http_request($request);
}


sub evemon {
  my ($self, $request) = @_;

  return $self->_do_http_request($request);
}


sub route {
  my ($self, $request) = @_;

  return $self->_do_http_request($request);
}


sub _do_http_request {
  my ($self, $request) = @_;

  my $response;
  try {
    $response = $self->ua->get($request);
  }
  catch {
    print STDERR "HTTP request failed: $_";
  };
  return undef unless $response->is_success;

  return $response->decoded_content;
}

sub _build_ua {
  my $ua = LWP::UserAgent::Determined->new;
  $ua->env_proxy;

  return $ua;
}

sub _build_libxml {
  return XML::LibXML->new;
}

sub _build_jsonparser {
  return JSON->new->utf8;
}


1; # End of Games::EveOnline::EveCentral

__END__

=pod

=head1 NAME

Games::EveOnline::EveCentral - A Perl library client for the EVE Central API.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Games::EveOnline::EveCentral;

    my $client = Games::EveOnline::EveCentral->new;
    # ...

=head1 DESCRIPTION

This module provides a client library for the API made available by
L<http://eve-central.com/>.

Full API documentation is available at
L<http://dev.eve-central.com/evec-api/start>.

=head1 METHODS

=head2 new

  use Games::EveOnline::EveCentral;

  my $client = Games::EveOnline::EveCentral->new;

=head2 marketstat

  my $xml = $client->marketstat(
    Games::EveOnline::EveCentral::Request::MarketStat->new(
      type_id => 34, # or [34, 35]. Mandatory.
      hours => 1, # defaults to 24
      min_q => 10000, # defaults to 1
      system => 30000142,
      regions => 10000002, # or [10000002, 10000003],
    )->request
  );

=head2 quicklook

  my $xml = $client->quicklook(
    Games::EveOnline::EveCentral::Request::QuickLook->new(
      type_id => 34, # Mandatory.
      hours => 1, # defaults to 360
      min_q => 10000, # defaults to 1
      system => 30000142,
      regions => 10000002, # or [10000002, 10000003],
    )->request
  );

=head2 quicklookpath

  my $xml = $client->quicklookpath(
    Games::EveOnline::EveCentral::Request::QuickLookPath->new(
      type_id => 34, # Mandatory
      from_system => 'Jita', # or 30000142, mandatory
      to_system => 'Amarr', # or 30002187, mandatory
      hours => 37, # Defaults to 360
      min_q => 100 # Defaults to 1
    )->request
  );

=head2 history

  my $json = $client->history(
    Games::EveOnline::EveCentral::Request::History->new(
      type_id => 34, # Mandatory
      location_type => 'system', # or 'region'.
      location => 'Jita', # Or 30000142, must be present if location_type is
      bid => 'buy' # Or 'sell', mandatory
    )->request
  );

=head2 evemon

  my $xml = $client->evemon(
    Games::EveOnline::EveCentral::Request::EVEMon->new->request
  );

=head2 route

  my $json = $client->route(
    Games::EveOnline::EveCentral::Request::Route->new(
      from_system => 'Jita', # Or 30000142, mandatory
      to_system => 'Amarr', # Or 30002187, mandatory
    )->request
  );

=begin private

=end private

=head1 AUTHOR

Pedro Figueiredo, C<< <me at pedrofigueiredo.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/pfig/games-eveonline-evecentral/issues>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::EveOnline::EveCentral

You can also look for information at:

=over 4

=item * GitHub Issues (report bugs here)

L<https://github.com/pfig/games-eveonline-evecentral/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-EveOnline-EveCentral>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-EveOnline-EveCentral>

=item * CPAN

L<http://metacpan.org/module/Games::EveOnline::EveCentral>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * The people behind EVE Central.

L<http://eve-central.com/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Pedro Figueiredo.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Pedro Figueiredo <me@pedrofigueiredo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Pedro Figueiredo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
