package IO::K8s::Traefik::V1alpha1::CircuitBreaker;
# ABSTRACT: CircuitBreaker holds the circuit breaker configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s checkPeriod      => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s expression       => Str;
k8s fallbackDuration => IntOrStr;
k8s recoveryDuration => IntOrStr, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s responseCode     => Int, { minimum => 100, maximum => 599 };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::CircuitBreaker - CircuitBreaker holds the circuit breaker configuration.

=head1 VERSION

version 1.108

=head2 checkPeriod

CheckPeriod is the interval between successive checks of the circuit breaker condition (when in standby state).

=head2 expression

Expression is the condition that triggers the tripped state.

=head2 fallbackDuration

FallbackDuration is the duration for which the circuit breaker will wait before trying to recover (from a tripped state).

=head2 recoveryDuration

RecoveryDuration is the duration for which the circuit breaker will try to recover (as soon as it is in recovering state).

=head2 responseCode

ResponseCode is the status code that the circuit breaker will return while it is in the open state.

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
