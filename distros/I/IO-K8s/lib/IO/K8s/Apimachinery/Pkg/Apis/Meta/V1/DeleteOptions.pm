package IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::DeleteOptions;
# ABSTRACT: DeleteOptions may be provided when deleting an API object.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s apiVersion => Str;


k8s dryRun => [Str];


k8s gracePeriodSeconds => Int;


k8s kind => Str;


k8s orphanDependents => Bool;


k8s preconditions => 'Meta::V1::Preconditions';


k8s propagationPolicy => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::DeleteOptions - DeleteOptions may be provided when deleting an API object.

=head1 VERSION

version 1.100

=head2 apiVersion

APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

=head2 dryRun

When present, indicates that modifications should not be persisted. An invalid or unrecognized dryRun directive will result in an error response and no further processing of the request. Valid values are: - All: all dry run stages will be processed

=head2 gracePeriodSeconds

The duration in seconds before the object should be deleted. Value must be non-negative integer. The value zero indicates delete immediately. If this value is nil, the default grace period for the specified type will be used. Defaults to a per object value if not specified. zero means delete immediately.

=head2 kind

Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

=head2 orphanDependents

Deprecated: please use the PropagationPolicy, this field will be deprecated in 1.7. Should the dependent objects be orphaned. If true/false, the "orphan" finalizer will be added to/removed from the object's finalizers list. Either this field or PropagationPolicy may be set, but not both.

=head2 preconditions

Must be fulfilled before a deletion is carried out. If not possible, a 409 Conflict status will be returned.

=head2 propagationPolicy

Whether and how garbage collection will be performed. Either this field or OrphanDependents may be set, but not both. The default policy is decided by the existing finalizer set in the metadata.finalizers and the resource-specific default policy. Acceptable values are: 'Orphan' - orphan the dependents; 'Background' - allow the garbage collector to delete the dependents in the background; 'Foreground' - a cascading policy that deletes all dependents in the foreground.

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
