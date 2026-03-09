package IO::K8s::Api::Core::V1::Probe;
# ABSTRACT: Probe describes a health check to be performed against a container to determine whether it is alive or ready to receive traffic.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s exec => 'Core::V1::ExecAction';


k8s failureThreshold => Int;


k8s grpc => 'Core::V1::GRPCAction';


k8s httpGet => 'Core::V1::HTTPGetAction';


k8s initialDelaySeconds => Int;


k8s periodSeconds => Int;


k8s successThreshold => Int;


k8s tcpSocket => 'Core::V1::TCPSocketAction';


k8s terminationGracePeriodSeconds => Int;


k8s timeoutSeconds => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::Probe - Probe describes a health check to be performed against a container to determine whether it is alive or ready to receive traffic.

=head1 VERSION

version 1.008

=head2 exec

Exec specifies the action to take.

=head2 failureThreshold

Minimum consecutive failures for the probe to be considered failed after having succeeded. Defaults to 3. Minimum value is 1.

=head2 grpc

GRPC specifies an action involving a GRPC port.

=head2 httpGet

HTTPGet specifies the http request to perform.

=head2 initialDelaySeconds

Number of seconds after the container has started before liveness probes are initiated. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

=head2 periodSeconds

How often (in seconds) to perform the probe. Default to 10 seconds. Minimum value is 1.

=head2 successThreshold

Minimum consecutive successes for the probe to be considered successful after having failed. Defaults to 1. Must be 1 for liveness and startup. Minimum value is 1.

=head2 tcpSocket

TCPSocket specifies an action involving a TCP port.

=head2 terminationGracePeriodSeconds

Optional duration in seconds the pod needs to terminate gracefully upon probe failure. The grace period is the duration in seconds after the processes running in the pod are sent a termination signal and the time when the processes are forcibly halted with a kill signal. Set this value longer than the expected cleanup time for your process. If this value is nil, the pod's terminationGracePeriodSeconds will be used. Otherwise, this value overrides the value provided by the pod spec. Value must be non-negative integer. The value zero indicates stop immediately via the kill signal (no opportunity to shut down). This is a beta field and requires enabling ProbeTerminationGracePeriod feature gate. Minimum value is 1. spec.terminationGracePeriodSeconds is used if unset.

=head2 timeoutSeconds

Number of seconds after which the probe times out. Defaults to 1 second. Minimum value is 1. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
