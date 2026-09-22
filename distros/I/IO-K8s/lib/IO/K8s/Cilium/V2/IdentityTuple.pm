package IO::K8s::Cilium::V2::IdentityTuple;
# ABSTRACT: IdentityTuple specifies a peer by identity, destination port and protocol.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'dest-port'       => Int;
k8s identity          => Int;
k8s 'identity-labels' => { Str => 1 };
k8s protocol          => Int;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::IdentityTuple - IdentityTuple specifies a peer by identity, destination port and protocol.

=head1 VERSION

version 1.108

=head2 dest-port

No description in the upstream schema.

=head2 identity

No description in the upstream schema.

=head2 identity-labels

No description in the upstream schema.

=head2 protocol

No description in the upstream schema.

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
