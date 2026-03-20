package IO::K8s::Api::Core::V1::LocalVolumeSource;
# ABSTRACT: Local represents directly-attached storage with node affinity (Beta feature)
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s fsType => Str;


k8s path => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::LocalVolumeSource - Local represents directly-attached storage with node affinity (Beta feature)

=head1 VERSION

version 1.009

=head2 fsType

fsType is the filesystem type to mount. It applies only when the Path is a block device. Must be a filesystem type supported by the host operating system. Ex. "ext4", "xfs", "ntfs". The default value is to auto-select a filesystem if unspecified.

=head2 path

path of the full path to the volume on the node. It can be either a directory or block device (disk, partition, ...).

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
