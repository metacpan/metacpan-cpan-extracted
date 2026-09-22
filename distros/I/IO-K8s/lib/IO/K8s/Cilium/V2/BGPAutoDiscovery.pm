package IO::K8s::Cilium::V2::BGPAutoDiscovery;
# ABSTRACT: AutoDiscovery is the configuration for auto-discovery of the peer address.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s defaultGateway => '+IO::K8s::Cilium::V2::DefaultGateway';
k8s mode           => Str, { required => 'schema', enum => [qw(DefaultGateway)] };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::BGPAutoDiscovery - AutoDiscovery is the configuration for auto-discovery of the peer address.

=head1 VERSION

version 1.108

=head2 defaultGateway

defaultGateway is the configuration for auto-discovery of the default gateway.

=head2 mode

mode is the mode of the auto-discovery.

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
