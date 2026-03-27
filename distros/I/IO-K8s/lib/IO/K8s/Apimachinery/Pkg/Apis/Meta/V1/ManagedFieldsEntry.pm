package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ManagedFieldsEntry;
# ABSTRACT: ManagedFieldsEntry is a workflow-id, a FieldSet and the group version of the resource that the fieldset applies to.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s apiVersion => Str;


k8s fieldsType => Str;


k8s fieldsV1 => { Str => 1 };


k8s manager => Str;


k8s operation => Str;


k8s subresource => Str;


k8s time => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ManagedFieldsEntry - ManagedFieldsEntry is a workflow-id, a FieldSet and the group version of the resource that the fieldset applies to.

=head1 VERSION

version 1.100

=head2 apiVersion

APIVersion defines the version of this resource that this field set applies to. The format is "group/version" just like the top-level APIVersion field. It is necessary to track the version of a field set because it cannot be automatically converted.

=head2 fieldsType

FieldsType is the discriminator for the different fields format and version. There is currently only one possible value: "FieldsV1"

=head2 fieldsV1

FieldsV1 holds the first JSON version format as described in the "FieldsV1" type.

=head2 manager

Manager is an identifier of the workflow managing these fields.

=head2 operation

Operation is the type of operation which lead to this ManagedFieldsEntry being created. The only valid values for this field are 'Apply' and 'Update'.

=head2 subresource

Subresource is the name of the subresource used to update that object, or empty string if the object was updated through the main resource. The value of this field is used to distinguish between managers, even if they share the same name. For example, a status update will be distinct from a regular update using the same manager name. Note that the APIVersion field is not related to the Subresource field and it always corresponds to the version of the main resource.

=head2 time

Time is the timestamp of when the ManagedFields entry was added. The timestamp will also be updated if a field is added, the manager changes any of the owned fields value or removes a field. The timestamp does not update when a field is removed from the entry because another manager took it over.

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
