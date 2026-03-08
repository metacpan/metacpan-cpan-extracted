package IO::K8s::Api::Core::V1::ScaleIOVolumeSource;
# ABSTRACT: ScaleIOVolumeSource represents a persistent ScaleIO volume
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s fsType => Str;


k8s gateway => Str, 'required';


k8s protectionDomain => Str;


k8s readOnly => Bool;


k8s secretRef => 'Core::V1::LocalObjectReference', 'required';


k8s sslEnabled => Bool;


k8s storageMode => Str;


k8s storagePool => Str;


k8s system => Str, 'required';


k8s volumeName => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ScaleIOVolumeSource - ScaleIOVolumeSource represents a persistent ScaleIO volume

=head1 VERSION

version 1.006

=head2 fsType

fsType is the filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. "ext4", "xfs", "ntfs". Default is "xfs".

=head2 gateway

gateway is the host address of the ScaleIO API Gateway.

=head2 protectionDomain

protectionDomain is the name of the ScaleIO Protection Domain for the configured storage.

=head2 readOnly

readOnly Defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.

=head2 secretRef

secretRef references to the secret for ScaleIO user and other sensitive information. If this is not provided, Login operation will fail.

=head2 sslEnabled

sslEnabled Flag enable/disable SSL communication with Gateway, default false

=head2 storageMode

storageMode indicates whether the storage for a volume should be ThickProvisioned or ThinProvisioned. Default is ThinProvisioned.

=head2 storagePool

storagePool is the ScaleIO Storage Pool associated with the protection domain.

=head2 system

system is the name of the storage system as configured in ScaleIO.

=head2 volumeName

volumeName is the name of a volume already created in the ScaleIO system that is associated with this volume source.

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
