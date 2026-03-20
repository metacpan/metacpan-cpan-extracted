package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::OwnerReference;
# ABSTRACT: OwnerReference contains enough information to let you identify an owning object. An owning object must be in the same namespace as the dependent, or be cluster-scoped, so there is no namespace field.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s apiVersion => Str, 'required';


k8s blockOwnerDeletion => Bool;


k8s controller => Bool;


k8s kind => Str, 'required';


k8s name => Str, 'required';


k8s uid => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::OwnerReference - OwnerReference contains enough information to let you identify an owning object. An owning object must be in the same namespace as the dependent, or be cluster-scoped, so there is no namespace field.

=head1 VERSION

version 1.009

=head2 apiVersion

API version of the referent.

=head2 blockOwnerDeletion

If true, AND if the owner has the "foregroundDeletion" finalizer, then the owner cannot be deleted from the key-value store until this reference is removed. See https://kubernetes.io/docs/concepts/architecture/garbage-collection/#foreground-deletion for how the garbage collector interacts with this field and enforces the foreground deletion. Defaults to false. To set this field, a user needs "delete" permission of the owner, otherwise 422 (Unprocessable Entity) will be returned.

=head2 controller

If true, this reference points to the managing controller.

=head2 kind

Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

=head2 name

Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names#names

=head2 uid

UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names#uids

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
