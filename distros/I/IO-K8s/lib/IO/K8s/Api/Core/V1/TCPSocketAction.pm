package IO::K8s::Api::Core::V1::TCPSocketAction;
# ABSTRACT: TCPSocketAction describes an action based on opening a socket
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s host => Str;


k8s port => IntOrStr, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::TCPSocketAction - TCPSocketAction describes an action based on opening a socket

=head1 VERSION

version 1.100

=head2 host

Optional: Host name to connect to, defaults to the pod IP.

=head2 port

Number or name of the port to access on the container. Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.

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
