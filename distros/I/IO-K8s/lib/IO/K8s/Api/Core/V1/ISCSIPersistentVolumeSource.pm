package IO::K8s::Api::Core::V1::ISCSIPersistentVolumeSource;
# ABSTRACT: ISCSIPersistentVolumeSource represents an ISCSI disk. ISCSI volumes can only be mounted as read/write once. ISCSI volumes support ownership management and SELinux relabeling.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s chapAuthDiscovery => Bool;


k8s chapAuthSession => Bool;


k8s fsType => Str;


k8s initiatorName => Str;


k8s iqn => Str, 'required';


k8s iscsiInterface => Str;


k8s lun => Int, 'required';


k8s portals => [Str];


k8s readOnly => Bool;


k8s secretRef => 'Core::V1::SecretReference';


k8s targetPortal => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ISCSIPersistentVolumeSource - ISCSIPersistentVolumeSource represents an ISCSI disk. ISCSI volumes can only be mounted as read/write once. ISCSI volumes support ownership management and SELinux relabeling.

=head1 VERSION

version 1.009

=head2 chapAuthDiscovery

chapAuthDiscovery defines whether support iSCSI Discovery CHAP authentication

=head2 chapAuthSession

chapAuthSession defines whether support iSCSI Session CHAP authentication

=head2 fsType

fsType is the filesystem type of the volume that you want to mount. Tip: Ensure that the filesystem type is supported by the host operating system. Examples: "ext4", "xfs", "ntfs". Implicitly inferred to be "ext4" if unspecified. More info: https://kubernetes.io/docs/concepts/storage/volumes#iscsi

=head2 initiatorName

initiatorName is the custom iSCSI Initiator Name. If initiatorName is specified with iscsiInterface simultaneously, new iSCSI interface <target portal>:<volume name> will be created for the connection.

=head2 iqn

iqn is Target iSCSI Qualified Name.

=head2 iscsiInterface

iscsiInterface is the interface Name that uses an iSCSI transport. Defaults to 'default' (tcp).

=head2 lun

lun is iSCSI Target Lun number.

=head2 portals

portals is the iSCSI Target Portal List. The Portal is either an IP or ip_addr:port if the port is other than default (typically TCP ports 860 and 3260).

=head2 readOnly

readOnly here will force the ReadOnly setting in VolumeMounts. Defaults to false.

=head2 secretRef

secretRef is the CHAP Secret for iSCSI target and initiator authentication

=head2 targetPortal

targetPortal is iSCSI Target Portal. The Portal is either an IP or ip_addr:port if the port is other than default (typically TCP ports 860 and 3260).

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
