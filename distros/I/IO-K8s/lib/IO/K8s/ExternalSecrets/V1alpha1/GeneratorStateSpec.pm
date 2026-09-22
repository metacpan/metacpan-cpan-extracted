package IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateSpec;
# ABSTRACT: GeneratorStateSpec defines the desired state of a generator state resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s garbageCollectionDeadline => Time;
k8s resource                  => Str, { required => 'schema', preserve_unknown => 1 };
k8s state                     => Str, { required => 'schema', preserve_unknown => 1 };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::GeneratorStateSpec - GeneratorStateSpec defines the desired state of a generator state resource.

=head1 VERSION

version 1.108

=head2 garbageCollectionDeadline

GarbageCollectionDeadline is the time after which the generator state
will be deleted.
It is set by the controller which creates the generator state and
can be set configured by the user.
If the garbage collection deadline is not set the generator state will not be deleted.

=head2 resource

Resource is the generator manifest that produced the state.
It is a snapshot of the generator manifest at the time the state was produced.
This manifest will be used to delete the resource. Any configuration that is referenced
in the manifest should be available at the time of garbage collection. If that is not the case deletion will
be blocked by a finalizer.

=head2 state

State is the state that was produced by the generator implementation.

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
