package Langertha::Request::HTTP;
# ABSTRACT: A HTTP Request inside of Langertha
our $VERSION = '0.305';
use Moose;
use MooseX::NonMoose;

extends 'HTTP::Request';


has request_source => (
  is => 'ro',
  does => 'Langertha::Role::HTTP',
);


has response_call => (
  is => 'ro',
  isa => 'CodeRef',
);


sub FOREIGNBUILDARGS {
  my ( $class, %args ) = @_;
  return @{$args{http}};
}

sub BUILDARGS {
  my ( $class, %args ) = @_;
  delete $args{http};
  return { %args };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Request::HTTP - A HTTP Request inside of Langertha

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    # Created internally by Langertha::Role::HTTP
    my $request = Langertha::Request::HTTP->new(
        http => [ 'POST', $url, $headers, $body ],
        request_source => $engine,
        response_call  => sub { ... },
    );

=head1 DESCRIPTION

A subclass of L<HTTP::Request> that carries two extra pieces of Langertha
context: the engine object that created the request (C<request_source>) and
a callback to parse the HTTP response into the appropriate return value
(C<response_call>).

Constructed internally by L<Langertha::Role::HTTP/generate_http_request> and
dispatched by L<Langertha::Role::Chat>. You normally do not need to create
these directly.

=head2 request_source

The engine object that created this request. Must consume
L<Langertha::Role::HTTP>.

=head2 response_call

A CodeRef that accepts an L<HTTP::Response> and returns the parsed result
expected by the caller. Invoked by L<Langertha::Role::Chat/simple_chat> after
a successful response.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::HTTP> - Creates instances of this class via C<generate_http_request>

=item * L<Langertha::Role::Chat> - Dispatches the request and calls C<response_call>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
