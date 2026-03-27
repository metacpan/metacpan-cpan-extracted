package IO::K8s::Api::Core::V1::ModifyVolumeStatus;
# ABSTRACT: ModifyVolumeStatus represents the status object of ControllerModifyVolume operation
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s status => Str, 'required';


k8s targetVolumeAttributesClassName => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ModifyVolumeStatus - ModifyVolumeStatus represents the status object of ControllerModifyVolume operation

=head1 VERSION

version 1.100

=head2 status

status is the status of the ControllerModifyVolume operation. It can be in any of following states:
 - Pending
   Pending indicates that the PersistentVolumeClaim cannot be modified due to unmet requirements, such as
   the specified VolumeAttributesClass not existing.
 - InProgress
   InProgress indicates that the volume is being modified.
 - Infeasible
  Infeasible indicates that the request has been rejected as invalid by the CSI driver. To
	  resolve the error, a valid VolumeAttributesClass needs to be specified.
Note: New statuses can be added in the future. Consumers should check for unknown statuses and fail appropriately.

=head2 targetVolumeAttributesClassName

targetVolumeAttributesClassName is the name of the VolumeAttributesClass the PVC currently being reconciled

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
