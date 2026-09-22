package IO::K8s::CertManager::V1::CertificateDNSNameSelector;
# ABSTRACT: Selector selects a set of DNSNames on the Certificate resource that should be solved using this challenge solver.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s dnsNames    => [Str];
k8s dnsZones    => [Str];
k8s matchLabels => { Str => 1 };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificateDNSNameSelector - Selector selects a set of DNSNames on the Certificate resource that should be solved using this challenge solver.

=head1 VERSION

version 1.108

=head2 dnsNames

List of DNSNames that this solver will be used to solve.
If specified and a match is found, a dnsNames selector will take
precedence over a dnsZones selector.
If multiple solvers match with the same dnsNames value, the solver
with the most matching labels in matchLabels will be selected.
If neither has more matches, the solver defined earlier in the list
will be selected.

=head2 dnsZones

List of DNSZones that this solver will be used to solve.
The most specific DNS zone match specified here will take precedence
over other DNS zone matches, so a solver specifying sys.example.com
will be selected over one specifying example.com for the domain
www.sys.example.com.
If multiple solvers match with the same dnsZones value, the solver
with the most matching labels in matchLabels will be selected.
If neither has more matches, the solver defined earlier in the list
will be selected.

=head2 matchLabels

A label selector that is used to refine the set of certificate's that
this challenge solver will apply to.

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
