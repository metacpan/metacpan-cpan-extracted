package IO::K8s::Cilium::V2::PortInfo;
# ABSTRACT: PortInfo specifies L4 port number and name along with the transport protocol
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name     => Str, { pattern => qr/^([0-9]{1,4})|([a-zA-Z0-9]-?)*[a-zA-Z](-?[a-zA-Z0-9])*$/ };
k8s port     => Str, { required => 'schema', pattern => qr/^()([1-9]|[1-5]?[0-9]{2,4}|6[1-4][0-9]{3}|65[1-4][0-9]{2}|655[1-2][0-9]|6553[1-5])$/ };
k8s protocol => Str, { required => 'schema', enum => [qw(TCP UDP)] };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::PortInfo - PortInfo specifies L4 port number and name along with the transport protocol

=head1 VERSION

version 1.108

=head2 name

Name is a port name, which must contain at least one [a-z],
and may also contain [0-9] and '-' anywhere except adjacent to another
'-' or in the beginning or the end.

=head2 port

Port is an L4 port number. The string will be strictly parsed as a single uint16.

=head2 protocol

Protocol is the L4 protocol.
Accepted values: "TCP", "UDP"

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
