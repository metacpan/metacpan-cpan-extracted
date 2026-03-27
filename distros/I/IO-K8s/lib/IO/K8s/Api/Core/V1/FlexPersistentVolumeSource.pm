package IO::K8s::Api::Core::V1::FlexPersistentVolumeSource;
# ABSTRACT: FlexPersistentVolumeSource represents a generic persistent volume resource that is provisioned/attached using an exec based plugin.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s driver => Str, 'required';


k8s fsType => Str;


k8s options => { Str => 1 };


k8s readOnly => Bool;


k8s secretRef => 'Core::V1::SecretReference';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::FlexPersistentVolumeSource - FlexPersistentVolumeSource represents a generic persistent volume resource that is provisioned/attached using an exec based plugin.

=head1 VERSION

version 1.100

=head2 driver

driver is the name of the driver to use for this volume.

=head2 fsType

fsType is the Filesystem type to mount. Must be a filesystem type supported by the host operating system. Ex. "ext4", "xfs", "ntfs". The default filesystem depends on FlexVolume script.

=head2 options

options is Optional: this field holds extra command options if any.

=head2 readOnly

readOnly is Optional: defaults to false (read/write). ReadOnly here will force the ReadOnly setting in VolumeMounts.

=head2 secretRef

secretRef is Optional: SecretRef is reference to the secret object containing sensitive information to pass to the plugin scripts. This may be empty if no secret object is specified. If the secret object contains more than one secret, all secrets are passed to the plugin scripts.

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
