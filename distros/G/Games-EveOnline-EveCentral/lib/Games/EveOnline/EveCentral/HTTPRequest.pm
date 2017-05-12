package Games::EveOnline::EveCentral::HTTPRequest;
{
  $Games::EveOnline::EveCentral::HTTPRequest::VERSION = '0.001';
}

use Moo 1.003001;
use MooX::Types::MooseLike 0.25;
use MooX::StrictConstructor 0.006;
use MooX::Types::MooseLike::Base qw(AnyOf ArrayRef Enum HashRef Str Undef);


# ABSTRACT: Internal use class to create HTTP::Request objects.


use 5.012;

use HTTP::Request 6.0;
use HTTP::Headers 6.05;
use Readonly 1.03;
use URI::Escape 3.31 qw(uri_escape_utf8);


Readonly::Scalar my $BASE_URL => "http://api.eve-central.com/api";

has 'method' => (
  is => 'ro',
  isa => Enum['GET', 'POST'],
  required => 1
);

has 'path' => (
  is => 'ro',
  isa => Str,
  required => 1
);

has 'headers' => (
  is => 'ro',
  isa => HashRef,
  default => sub { {} }
);

has 'content' => (
  is => 'ro',
  isa => AnyOf[ArrayRef[Str], Undef],
  default => sub { [] }
);



sub http_request {
  my $self = shift;
  my $method = $self->method;
  my $path = $self->_urlencode($self->path);
  my $headers = $self->_create_headers($self->headers);
  my $content = $self->content;

  my $uri = "$BASE_URL/$path";
  my $request = HTTP::Request->new($method, $uri, $headers, $content);

  return $request;
}


sub _urlencode {
  my ($self, $unencoded) = @_;
  return uri_escape_utf8($unencoded, '^A-Za-z0-9_-');
}


sub _create_headers {
  my ($self, $headers) = @_;
  my $http_headers = HTTP::Headers->new;

  while ( my ( $k, $v ) = each %$headers ) {
    $http_headers->header( $k => $v );
  }

  return $http_headers;
}


1; # End of Games::EveOnline::EveCentral::HTTPRequest

__END__

=pod

=head1 NAME

Games::EveOnline::EveCentral::HTTPRequest - Internal use class to create HTTP::Request objects.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $http_request = Games::EveOnline::EveCentral::HTTPRequest->new(
    method => 'GET', # or 'POST'
    path => $api_method,
    headers => $headers,
    content => $content # if using POST, []
  )->http_request;

=head1 DESCRIPTION

This module creates an HTTP::Request object to make the API call with.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method creates an HTTP::Request object.

=begin private

=head2 _urlencode

URL-encode a given path.

=head2 _create_headers

Create an HTTP::Headers object from a hash.



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
