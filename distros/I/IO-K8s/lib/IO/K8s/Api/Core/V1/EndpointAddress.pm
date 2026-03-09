package IO::K8s::Api::Core::V1::EndpointAddress;
# ABSTRACT: EndpointAddress is a tuple that describes single IP address.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s hostname => Str;


k8s ip => Str, 'required';


k8s nodeName => Str;


k8s targetRef => 'Core::V1::ObjectReference';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::EndpointAddress - EndpointAddress is a tuple that describes single IP address.

=head1 VERSION

version 1.008

=head2 hostname

The Hostname of this endpoint

=head2 ip

The IP of this endpoint. May not be loopback (127.0.0.0/8 or ::1), link-local (169.254.0.0/16 or fe80::/10), or link-local multicast (224.0.0.0/24 or ff02::/16).

=head2 nodeName

Optional: Node hosting this endpoint. This can be used to determine endpoints local to a node.

=head2 targetRef

Reference to object providing the endpoint.

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
