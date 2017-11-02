package HTTP::Tiny::Paranoid;
$HTTP::Tiny::Paranoid::VERSION = '0.07';
use strict;
use warnings;

# ABSTRACT: A safer HTTP::Tiny

use HTTP::Tiny 0.070;
use parent 'HTTP::Tiny';
use Net::DNS::Paranoid;
use Class::Method::Modifiers;

my $dns = Net::DNS::Paranoid->new;

sub blocked_hosts { shift; $dns->blocked_hosts(@_) }
sub whitelisted_hosts { shift; $dns->whitelisted_hosts(@_) }

around _open_handle => sub {
  my $next = shift;
  my $self = shift;

  my ($req, $scheme, $host, $port, $peer) = @_;

  if ($peer) {
    my ($ips, $error) = $dns->resolve($peer);
    die "$peer: $error\n" if defined $error;
    $self->$next($req, $scheme, $host, $port, $peer);
  }
  else {
    my ($ips, $error) = $dns->resolve($host);
    die "$host: $error\n" if defined $error;
    die "$host: no IP address found\n" unless @$ips;
    $self->$next($req, $scheme, $host, $port, $ips->[0]);
  }
};

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Paranoid - A safer HTTP::Tiny

=head1 SYNOPSIS

    # use just like HTTP::Tiny
    use HTTP::Tiny::Paranoid;
    my $response = HTTP::Tiny::Paranoid->new->get('http://example.com');

    # block or whitelist specific hosts
    # delegates to Net::DNS::Paranoid
    HTTP::Tiny::Paranoid->blocked_hosts([...]);
    HTTP::Tiny::Paranoid->whitelisted_hosts([...]);

=head1 DESCRIPTION

This module is a subclass of HTTP::Tiny that performs exactly one additional
function: before connecting, it passes the hostname to
L<Net::DNS::Paranoid>. If the hostname is rejected, then the request
is aborted before a connect is even attempted.

By default, L<Net::DNS::Paranoid> rejects connections to private network
ranges. The blocklist & whitelist can be manipulated using the C<blocked_hosts>
and C<whitelisted_hosts> class methods.

=head1 SEE ALSO

=over 4

=item *

L<HTTP::Tiny>

=item *

L<Net::DNS::Paranoid>

=item *

L<LWPx::ParanoidAgent>

=item *

L<LWP::UserAgent::Paranoid>

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/HTTP-Tiny-Paranoid/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/HTTP-Tiny-Paranoid>

  git clone https://github.com/robn/HTTP-Tiny-Paranoid.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
