package IO::K8s::Api::Storage::V1::StorageHealth;
# ABSTRACT: StorageHealth contains storage backend health reported by a CSI driver on a node.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s healthConditions => ['Storage::V1::StorageHealthCondition'];


k8s name => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storage::V1::StorageHealth - StorageHealth contains storage backend health reported by a CSI driver on a node.

=head1 VERSION

version 1.108

=head2 healthConditions

healthConditions are the adverse storage backend conditions reported by the CSI driver. At most 16 conditions may be reported.

=head2 name

name is the CSI driver name, matching CSINodeDriver.name.

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
