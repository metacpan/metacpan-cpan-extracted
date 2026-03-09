package IO::K8s::Api::Core::V1::ObjectReference;
# ABSTRACT: ObjectReference contains enough information to let you inspect or modify the referred object.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s apiVersion => Str;


k8s fieldPath => Str;


k8s kind => Str;


k8s name => Str;


k8s namespace => Str;


k8s resourceVersion => Str;


k8s uid => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ObjectReference - ObjectReference contains enough information to let you inspect or modify the referred object.

=head1 VERSION

version 1.008

=head2 apiVersion

API version of the referent.

=head2 fieldPath

If referring to a piece of an object instead of an entire object, this string should contain a valid JSON/Go field access statement, such as desiredState.manifest.containers[2]. For example, if the object reference is to a container within a pod, this would take on a value like: "spec.containers{name}" (where "name" refers to the name of the container that triggered the event) or if no container name is specified "spec.containers[2]" (container with index 2 in this pod). This syntax is chosen only to have some well-defined way of referencing a part of an object.

=head2 kind

Kind of the referent. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

=head2 name

Name of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names

=head2 namespace

Namespace of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

=head2 resourceVersion

Specific resourceVersion to which this reference is made, if any. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#concurrency-control-and-consistency

=head2 uid

UID of the referent. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#uids

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
