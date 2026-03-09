package IO::K8s::Api::Networking::V1::IngressPortStatus;
# ABSTRACT: IngressPortStatus represents the error condition of a service port
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s error => Str;


k8s port => Int, 'required';


k8s protocol => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Networking::V1::IngressPortStatus - IngressPortStatus represents the error condition of a service port

=head1 VERSION

version 1.008

=head2 error

error is to record the problem with the service port The format of the error shall comply with the following rules: - built-in error values shall be specified in this file and those shall use CamelCase names - cloud provider specific error values must have names that comply with the format foo.example.com/CamelCase.

=head2 port

port is the port number of the ingress port.

=head2 protocol

protocol is the protocol of the ingress port. The supported values are: "TCP", "UDP", "SCTP"

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
