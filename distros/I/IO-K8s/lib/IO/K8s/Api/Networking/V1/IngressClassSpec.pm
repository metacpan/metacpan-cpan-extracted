package IO::K8s::Api::Networking::V1::IngressClassSpec;
# ABSTRACT: IngressClassSpec provides information about the class of an Ingress.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s controller => Str;


k8s parameters => 'Networking::V1::IngressClassParametersReference';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Networking::V1::IngressClassSpec - IngressClassSpec provides information about the class of an Ingress.

=head1 VERSION

version 1.100

=head2 controller

controller refers to the name of the controller that should handle this class. This allows for different "flavors" that are controlled by the same controller. For example, you may have different parameters for the same implementing controller. This should be specified as a domain-prefixed path no more than 250 characters in length, e.g. "acme.io/ingress-controller". This field is immutable.

=head2 parameters

parameters is a link to a custom resource containing additional configuration for the controller. This is optional if the controller does not require extra parameters.

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
