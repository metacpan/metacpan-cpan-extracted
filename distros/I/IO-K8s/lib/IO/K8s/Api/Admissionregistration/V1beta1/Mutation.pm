package IO::K8s::Api::Admissionregistration::V1beta1::Mutation;
# ABSTRACT: Mutation specifies the CEL expression which is used to apply the Mutation.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s applyConfiguration => 'Admissionregistration::V1beta1::ApplyConfiguration';


k8s jsonPatch => 'Admissionregistration::V1beta1::JSONPatch';


k8s patchType => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Admissionregistration::V1beta1::Mutation - Mutation specifies the CEL expression which is used to apply the Mutation.

=head1 VERSION

version 1.106

=head2 applyConfiguration

applyConfiguration defines the desired configuration values of an object. The configuration is applied to the admission object using L<structured merge diff|https://github.com/kubernetes-sigs/structured-merge-diff>. A CEL expression is used to create apply configuration.

=head2 jsonPatch

jsonPatch defines a L<JSON patch|https://jsonpatch.com/> operation to perform a mutation to the object. A CEL expression is used to create the JSON patch.

=head2 patchType

patchType indicates the patch strategy used. Allowed values are "ApplyConfiguration" and "JSONPatch".

Required.

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
