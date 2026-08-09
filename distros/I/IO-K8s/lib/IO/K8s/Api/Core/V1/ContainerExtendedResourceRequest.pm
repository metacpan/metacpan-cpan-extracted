package IO::K8s::Api::Core::V1::ContainerExtendedResourceRequest;
# ABSTRACT: ContainerExtendedResourceRequest has the mapping of container name, extended resource name to the device request name.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s containerName => Str, 'required';


k8s requestName => Str, 'required';


k8s resourceName => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerExtendedResourceRequest - ContainerExtendedResourceRequest has the mapping of container name, extended resource name to the device request name.

=head1 VERSION

version 1.105

=head2 containerName

The name of the container requesting resources, referring to a container in the pod's containers or initContainers list.

=head2 requestName

The name of the request in the special ResourceClaim which corresponds to the extended resource.

=head2 resourceName

The name of the extended resource in that container which gets backed by DRA.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
