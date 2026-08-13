package IO::K8s::Api::Storagemigration::V1beta1::StorageVersionMigrationSpec;
# ABSTRACT: Spec of the storage version migration.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s resource => 'Meta::V1::GroupResource', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storagemigration::V1beta1::StorageVersionMigrationSpec - Spec of the storage version migration.

=head1 VERSION

version 1.106

=head2 resource

The resource that is being migrated. The migrator sends requests to the endpoint serving the resource. Immutable.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
