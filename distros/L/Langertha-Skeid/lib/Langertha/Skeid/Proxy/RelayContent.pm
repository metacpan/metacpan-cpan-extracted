package Langertha::Skeid::Proxy::RelayContent;
our $VERSION = '0.003';
# ABSTRACT: Upstream response content that is always relayed as raw bytes
use Mojo::Base 'Mojo::Content::Single';


sub is_sse {0}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Proxy::RelayContent - Upstream response content that is always relayed as raw bytes

=head1 VERSION

version 0.003

=head1 DESCRIPTION

The content object the proxy puts on a streaming upstream response before starting it: a
L<Mojo::Content::Single> that never takes Mojolicious's own Server-Sent Events path.

Mojolicious parses a response body itself when its C<Content-Type> is exactly
C<text/event-stream> (no parameters) and the body is not chunked: the bytes become C<sse> events
and no C<read> event is ever emitted. The relay reads the upstream on C<read>, so such an
upstream would be relayed as nothing and metered as a served request without tokens. Skeid
reads the SSE frames itself and relays them byte for byte, so it needs the bytes whatever the
exact media type or framing.

  my $tx = $ua->build_tx(POST => $url, \%headers, json => $body);
  $tx->res->content(Langertha::Skeid::Proxy::RelayContent->new);
  $tx->res->content->unsubscribe('read')->on(read => sub { ... });

=head2 is_sse

Always false, so the body is parsed as plain content and every byte arrives on C<read>.

=head1 SEE ALSO

L<Langertha::Skeid::Proxy>, L<Mojo::Content::Single>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
