package IO::K8s::Api::Storage::V1::VolumeAttachmentStatus;
# ABSTRACT: VolumeAttachmentStatus is the status of a VolumeAttachment request.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s attachError => 'Storage::V1::VolumeError';


k8s attached => Bool, 'required';


k8s attachmentMetadata => { Str => 1 };


k8s detachError => 'Storage::V1::VolumeError';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storage::V1::VolumeAttachmentStatus - VolumeAttachmentStatus is the status of a VolumeAttachment request.

=head1 VERSION

version 1.100

=head2 attachError

attachError represents the last error encountered during attach operation, if any. This field must only be set by the entity completing the attach operation, i.e. the external-attacher.

=head2 attached

attached indicates the volume is successfully attached. This field must only be set by the entity completing the attach operation, i.e. the external-attacher.

=head2 attachmentMetadata

attachmentMetadata is populated with any information returned by the attach operation, upon successful attach, that must be passed into subsequent WaitForAttach or Mount calls. This field must only be set by the entity completing the attach operation, i.e. the external-attacher.

=head2 detachError

detachError represents the last error encountered during detach operation, if any. This field must only be set by the entity completing the detach operation, i.e. the external-attacher.

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
