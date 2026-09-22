package IO::K8s::Traefik::V1alpha1::InFlightReq;
# ABSTRACT: InFlightReq holds the in-flight request middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s amount          => Int, { minimum => 0 };
k8s sourceCriterion => '+IO::K8s::Traefik::V1alpha1::SourceCriterion';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::InFlightReq - InFlightReq holds the in-flight request middleware configuration.

=head1 VERSION

version 1.108

=head2 amount

Amount defines the maximum amount of allowed simultaneous in-flight request.
The middleware responds with HTTP 429 Too Many Requests if there are already amount requests in progress (based on the same sourceCriterion strategy).

=head2 sourceCriterion

SourceCriterion defines what criterion is used to group requests as originating from a common source.
If several strategies are defined at the same time, an error will be raised.
If none are set, the default is to use the requestHost.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/inflightreq/#sourcecriterion

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
