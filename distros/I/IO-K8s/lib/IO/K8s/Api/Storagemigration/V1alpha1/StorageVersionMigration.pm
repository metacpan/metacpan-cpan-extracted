package IO::K8s::Api::Storagemigration::V1alpha1::StorageVersionMigration;
# ABSTRACT: StorageVersionMigration represents a migration of stored data to the latest storage version.
our $VERSION = '1.100';
use IO::K8s::APIObject;


k8s spec => 'Storagemigration::V1alpha1::StorageVersionMigrationSpec';


k8s status => 'Storagemigration::V1alpha1::StorageVersionMigrationStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storagemigration::V1alpha1::StorageVersionMigration - StorageVersionMigration represents a migration of stored data to the latest storage version.

=head1 VERSION

version 1.100

=head1 DESCRIPTION

StorageVersionMigration represents a migration of stored data to the latest storage version.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Specification of the migration.

=head2 status

Status of the migration.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#storageversionmigration-v1alpha1-storagemigration.k8s.io>

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
