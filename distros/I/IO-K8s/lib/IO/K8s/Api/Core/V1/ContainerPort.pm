package IO::K8s::Api::Core::V1::ContainerPort;
# ABSTRACT: ContainerPort represents a network port in a single container.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s containerPort => Int, 'required';


k8s hostIP => Str;


k8s hostPort => Int;


k8s name => Str;


k8s protocol => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerPort - ContainerPort represents a network port in a single container.

=head1 VERSION

version 1.008

=head2 containerPort

Number of port to expose on the pod's IP address. This must be a valid port number, 0 < x < 65536.

=head2 hostIP

What host IP to bind the external port to.

=head2 hostPort

Number of port to expose on the host. If specified, this must be a valid port number, 0 < x < 65536. If HostNetwork is specified, this must match ContainerPort. Most containers do not need this.

=head2 name

If specified, this must be an IANA_SVC_NAME and unique within the pod. Each named port in a pod must have a unique name. Name for the port that can be referred to by services.

=head2 protocol

Protocol for port. Must be UDP, TCP, or SCTP. Defaults to "TCP".

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
