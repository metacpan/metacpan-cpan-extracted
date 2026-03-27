package IO::K8s::Api::Storage::V1::VolumeAttachment;
# ABSTRACT: VolumeAttachment captures the intent to attach or detach the specified volume to/from the specified node. VolumeAttachment objects are non-namespaced.
our $VERSION = '1.100';
use IO::K8s::APIObject;


k8s spec => 'Storage::V1::VolumeAttachmentSpec', 'required';


k8s status => 'Storage::V1::VolumeAttachmentStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storage::V1::VolumeAttachment - VolumeAttachment captures the intent to attach or detach the specified volume to/from the specified node. VolumeAttachment objects are non-namespaced.

=head1 VERSION

version 1.100

=head1 DESCRIPTION

VolumeAttachment captures the intent to attach or detach the specified volume to/from the specified node.

VolumeAttachment objects are non-namespaced.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

spec represents specification of the desired attach/detach volume behavior. Populated by the Kubernetes system.

=head2 status

status represents status of the VolumeAttachment request. Populated by the entity completing the attach or detach operation, i.e. the external-attacher.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#volumeattachment-v1-storage.k8s.io>

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
