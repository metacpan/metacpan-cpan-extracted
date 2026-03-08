package IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionNames;
# ABSTRACT: CustomResourceDefinitionNames indicates the names to serve this CustomResourceDefinition
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s categories => [Str];


k8s kind => Str, 'required';


k8s listKind => Str;


k8s plural => Str, 'required';


k8s shortNames => [Str];


k8s singular => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionNames - CustomResourceDefinitionNames indicates the names to serve this CustomResourceDefinition

=head1 VERSION

version 1.006

=head2 categories

categories is a list of grouped resources this custom resource belongs to (e.g. 'all'). This is published in API discovery documents, and used by clients to support invocations like `kubectl get all`.

=head2 kind

kind is the serialized kind of the resource. It is normally CamelCase and singular. Custom resource instances will use this value as the `kind` attribute in API calls.

=head2 listKind

listKind is the serialized kind of the list for this resource. Defaults to "`kind`List".

=head2 plural

plural is the plural name of the resource to serve. The custom resources are served under `/apis/<group>/<version>/.../<plural>`. Must match the name of the CustomResourceDefinition (in the form `<names.plural>.<group>`). Must be all lowercase.

=head2 shortNames

shortNames are short names for the resource, exposed in API discovery documents, and used by clients to support invocations like `kubectl get <shortname>`. It must be all lowercase.

=head2 singular

singular is the singular name of the resource. It must be all lowercase. Defaults to lowercased `kind`.

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
