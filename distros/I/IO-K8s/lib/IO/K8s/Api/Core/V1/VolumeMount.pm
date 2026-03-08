package IO::K8s::Api::Core::V1::VolumeMount;
# ABSTRACT: VolumeMount describes a mounting of a Volume within a container.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s mountPath => Str, 'required';


k8s mountPropagation => Str;


k8s name => Str, 'required';


k8s readOnly => Bool;


k8s recursiveReadOnly => Str;


k8s subPath => Str;


k8s subPathExpr => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::VolumeMount - VolumeMount describes a mounting of a Volume within a container.

=head1 VERSION

version 1.006

=head2 mountPath

Path within the container at which the volume should be mounted.  Must not contain ':'.

=head2 mountPropagation

mountPropagation determines how mounts are propagated from the host to container and the other way around. When not set, MountPropagationNone is used. This field is beta in 1.10. When RecursiveReadOnly is set to IfPossible or to Enabled, MountPropagation must be None or unspecified (which defaults to None).

=head2 name

This must match the Name of a Volume.

=head2 readOnly

Mounted read-only if true, read-write otherwise (false or unspecified). Defaults to false.

=head2 recursiveReadOnly

RecursiveReadOnly specifies whether read-only mounts should be handled recursively.

If ReadOnly is false, this field has no meaning and must be unspecified.

If ReadOnly is true, and this field is set to Disabled, the mount is not made recursively read-only.  If this field is set to IfPossible, the mount is made recursively read-only, if it is supported by the container runtime.  If this field is set to Enabled, the mount is made recursively read-only if it is supported by the container runtime, otherwise the pod will not be started and an error will be generated to indicate the reason.

If this field is set to IfPossible or Enabled, MountPropagation must be set to None (or be unspecified, which defaults to None).

If this field is not specified, it is treated as an equivalent of Disabled.

=head2 subPath

Path within the volume from which the container's volume should be mounted. Defaults to "" (volume's root).

=head2 subPathExpr

Expanded path within the volume from which the container's volume should be mounted. Behaves similarly to SubPath but environment variable references $(VAR_NAME) are expanded using the container's environment. Defaults to "" (volume's root). SubPathExpr and SubPath are mutually exclusive.

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
