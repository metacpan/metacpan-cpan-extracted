package IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodTemplate;
# ABSTRACT: Optional pod template used to configure the ACME challenge solver pods used for HTTP01 challenges.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s metadata => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodObjectMeta';
k8s spec     => '+IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodSpec';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEChallengeSolverHTTP01IngressPodTemplate - Optional pod template used to configure the ACME challenge solver pods used for HTTP01 challenges.

=head1 VERSION

version 1.108

=head2 metadata

ObjectMeta overrides for the pod used to solve HTTP01 challenges.
Only the 'labels' and 'annotations' fields may be set.
If labels or annotations overlap with in-built values, the values here
will override the in-built values.

=head2 spec

PodSpec defines overrides for the HTTP01 challenge solver pod.
Check ACMEChallengeSolverHTTP01IngressPodSpec to find out currently supported fields.
All other fields will be ignored.

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
