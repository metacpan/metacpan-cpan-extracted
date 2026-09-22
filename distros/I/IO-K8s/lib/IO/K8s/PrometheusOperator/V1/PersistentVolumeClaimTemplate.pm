package IO::K8s::PrometheusOperator::V1::PersistentVolumeClaimTemplate;
# ABSTRACT: Will be used to create a stand-alone PVC to provision the volume.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s metadata => { Str => 1 };
k8s spec     => 'Core::V1::PersistentVolumeClaimSpec', { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PersistentVolumeClaimTemplate - Will be used to create a stand-alone PVC to provision the volume.

=head1 VERSION

version 1.108

=head2 metadata

May contain labels and annotations that will be copied into the PVC
when creating it. No other fields are allowed and will be rejected during
validation.

=head2 spec

The specification for the PersistentVolumeClaim. The entire content is
copied unchanged into the PVC that gets created from this
template. The same fields as in a PersistentVolumeClaim
are also valid here.

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
