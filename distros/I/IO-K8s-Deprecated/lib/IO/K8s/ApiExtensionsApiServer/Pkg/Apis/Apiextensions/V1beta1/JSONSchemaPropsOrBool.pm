package IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrBool;
# ABSTRACT: REMOVED -- retired Kubernetes API version, see IO::K8s::Deprecated

use strict;
use warnings;

our $VERSION = '1.112';

die __PACKAGE__ . " has been removed. It was part of the apiextensions.k8s.io/v1beta1"
  . " API, which Kubernetes has retired; IO-K8s shipped it only in 0.01"
  . " to 0.03 (2018), and no IO-K8s 1.x release has it. Use"
  . " IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool"
  . " instead:\n"
  . "  perldoc IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool\n"
  . "  cpanm IO::K8s\n"
  . "  https://metacpan.org/dist/IO-K8s\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrBool - REMOVED -- retired Kubernetes API version, see IO::K8s::Deprecated

=head1 VERSION

version 1.112

=head1 DESCRIPTION

This module has been removed. It was part of the
apiextensions.k8s.io/v1beta1 API, which Kubernetes has retired; IO-K8s
shipped it only in 0.01 to 0.03 (2018), and no IO-K8s 1.x release has it.
Its successor is
L<IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool>.

This module is a CPAN redirect stub, part of L<IO::K8s::Deprecated>. It
carries no implementation and B<dies unconditionally> as soon as it is
loaded (C<use>/C<require>). It exists so that C<cpanm
IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrBool>
-- or a cpanfile / code that still references the old name -- surfaces a
clear message instead of installing C<IO-K8s> C<0.03>, the last CPAN
release that carries this name. That release would also replace the
classes of a current IO-K8s, C<IO::K8s> itself included, with their 2018
versions.

=head1 NAME

IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrBool - REMOVED, superseded by IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool

=head1 SEE ALSO

L<IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool>, L<IO::K8s::Deprecated>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/io-k8s-p5-deprecated/issues>.

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

L<https://raudssus.de/>

=cut
