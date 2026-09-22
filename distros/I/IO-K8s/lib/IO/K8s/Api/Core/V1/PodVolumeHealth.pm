package IO::K8s::Api::Core::V1::PodVolumeHealth;
# ABSTRACT: PodVolumeHealth contains health information for a volume used by a pod, reported by the CSI node plugin via the kubelet.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s healthConditions => ['Core::V1::VolumeHealthCondition'];


k8s lastTransitionTime => Time;


k8s name => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PodVolumeHealth - PodVolumeHealth contains health information for a volume used by a pod, reported by the CSI node plugin via the kubelet.

=head1 VERSION

version 1.108

=head2 healthConditions

conditions is the set of adverse conditions reported by the CSI node plugin for this volume on this node. At most 16 conditions may be reported.

=head2 lastTransitionTime

lastTransitionTime is when the current set of conditions first appeared.

=head2 name

name matches an entry in pod.spec.volumes.

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
