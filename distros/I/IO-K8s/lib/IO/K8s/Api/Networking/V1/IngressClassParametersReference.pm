package IO::K8s::Api::Networking::V1::IngressClassParametersReference;
# ABSTRACT: IngressClassParametersReference identifies an API object. This can be used to specify a cluster or namespace-scoped resource.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s apiGroup => Str;


k8s kind => Str, 'required';


k8s name => Str, 'required';


k8s namespace => Str;


k8s scope => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Networking::V1::IngressClassParametersReference - IngressClassParametersReference identifies an API object. This can be used to specify a cluster or namespace-scoped resource.

=head1 VERSION

version 1.006

=head2 apiGroup

apiGroup is the group for the resource being referenced. If APIGroup is not specified, the specified Kind must be in the core API group. For any other third-party types, APIGroup is required.

=head2 kind

kind is the type of resource being referenced.

=head2 name

name is the name of resource being referenced.

=head2 namespace

namespace is the namespace of the resource being referenced. This field is required when scope is set to "Namespace" and must be unset when scope is set to "Cluster".

=head2 scope

scope represents if this refers to a cluster or namespace scoped resource. This may be set to "Cluster" (default) or "Namespace".

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
