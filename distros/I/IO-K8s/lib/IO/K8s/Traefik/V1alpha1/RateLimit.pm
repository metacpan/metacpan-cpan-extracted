package IO::K8s::Traefik::V1alpha1::RateLimit;
# ABSTRACT: RateLimit holds the rate limit configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s average         => Int, { minimum => 0 };
k8s burst           => Int, { minimum => 0 };
k8s period          => IntOrStr;
k8s redis           => '+IO::K8s::Traefik::V1alpha1::Redis';
k8s sourceCriterion => '+IO::K8s::Traefik::V1alpha1::SourceCriterion';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::RateLimit - RateLimit holds the rate limit configuration.

=head1 VERSION

version 1.108

=head2 average

Average is the maximum rate, by default in requests/s, allowed for the given source.
It defaults to 0, which means no rate limiting.
The rate is actually defined by dividing Average by Period. So for a rate below 1req/s,
one needs to define a Period larger than a second.

=head2 burst

Burst is the maximum number of requests allowed to arrive in the same arbitrarily small period of time.
It defaults to 1.

=head2 period

Period, in combination with Average, defines the actual maximum rate, such as:
r = Average / Period. It defaults to a second.

=head2 redis

Redis hold the configs of Redis as bucket in rate limiter.

=head2 sourceCriterion

SourceCriterion defines what criterion is used to group requests as originating from a common source.
If several strategies are defined at the same time, an error will be raised.
If none are set, the default is to use the request's remote address field (as an ipStrategy).

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
