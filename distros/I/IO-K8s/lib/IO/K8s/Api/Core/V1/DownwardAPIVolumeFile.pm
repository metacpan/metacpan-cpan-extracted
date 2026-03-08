package IO::K8s::Api::Core::V1::DownwardAPIVolumeFile;
# ABSTRACT: DownwardAPIVolumeFile represents information to create the file containing the pod field
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s fieldRef => 'Core::V1::ObjectFieldSelector';


k8s mode => Int;


k8s path => Str, 'required';


k8s resourceFieldRef => 'Core::V1::ResourceFieldSelector';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::DownwardAPIVolumeFile - DownwardAPIVolumeFile represents information to create the file containing the pod field

=head1 VERSION

version 1.006

=head2 fieldRef

Required: Selects a field of the pod: only annotations, labels, name, namespace and uid are supported.

=head2 mode

Optional: mode bits used to set permissions on this file, must be an octal value between 0000 and 0777 or a decimal value between 0 and 511. YAML accepts both octal and decimal values, JSON requires decimal values for mode bits. If not specified, the volume defaultMode will be used. This might be in conflict with other options that affect the file mode, like fsGroup, and the result can be other mode bits set.

=head2 path

Required: Path is  the relative path name of the file to be created. Must not be absolute or contain the '..' path. Must be utf-8 encoded. The first item of the relative path must not start with '..'

=head2 resourceFieldRef

Selects a resource of the container: only resources limits and requests (limits.cpu, limits.memory, requests.cpu and requests.memory) are currently supported.

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
