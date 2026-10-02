package Langertha::Skeid::Protocol::Refusal;
our $VERSION = '0.003';
# ABSTRACT: A translator's deliberate refusal of a request, with a message for the client
use strict;
use warnings;
use Carp qw( croak );


sub refuse {
  my ( $class, $message ) = @_;
  croak(__PACKAGE__.'->refuse needs a message') unless defined $message && length $message;
  die bless { message => $message }, $class;
}

sub message { $_[0]->{message} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Refusal - A translator's deliberate refusal of a request, with a message for the client

=head1 VERSION

version 0.003

=head1 DESCRIPTION

A request translator that turns a request down on purpose -- a provider built-in tool, an image
source skeid cannot forward -- throws one of these, carrying a one-line message written for the
client. The proxy answers such a refusal with that message as a C<400>. Any other exception is a
failure of the translator's own, its text can quote the request, and the proxy answers it with a
fixed text instead.

=head2 refuse

  Langertha::Skeid::Protocol::Refusal->refuse('tool type is not supported');

Dies with a refusal carrying the message.

=head2 message

The client-facing message of a refusal.

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
