package IO::K8s::Api::Core::V1::VolumeMountStatus;
# ABSTRACT: VolumeMountStatus shows status of volume mounts.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s mountPath => Str, 'required';


k8s name => Str, 'required';


k8s readOnly => Bool;


k8s recursiveReadOnly => Str;


k8s volumeStatus => 'Core::V1::VolumeStatus';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::VolumeMountStatus - VolumeMountStatus shows status of volume mounts.

=head1 VERSION

version 1.107

=head2 mountPath

MountPath corresponds to the original VolumeMount.

=head2 name

Name corresponds to the name of the original VolumeMount.

=head2 readOnly

ReadOnly corresponds to the original VolumeMount.

=head2 recursiveReadOnly

RecursiveReadOnly must be set to Disabled, Enabled, or unspecified (for non-readonly mounts). An IfPossible value in the original VolumeMount must be translated to Disabled or Enabled, depending on the mount result.

=head2 volumeStatus

volumeStatus represents volume-type-specific status about the mounted volume.

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
