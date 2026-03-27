package IO::K8s::Api::Core::V1::LifecycleHandler;
# ABSTRACT: LifecycleHandler defines a specific action that should be taken in a lifecycle hook. One and only one of the fields, except TCPSocket must be specified.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s exec => 'Core::V1::ExecAction';


k8s httpGet => 'Core::V1::HTTPGetAction';


k8s sleep => 'Core::V1::SleepAction';


k8s tcpSocket => 'Core::V1::TCPSocketAction';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::LifecycleHandler - LifecycleHandler defines a specific action that should be taken in a lifecycle hook. One and only one of the fields, except TCPSocket must be specified.

=head1 VERSION

version 1.100

=head2 exec

Exec specifies the action to take.

=head2 httpGet

HTTPGet specifies the http request to perform.

=head2 sleep

Sleep represents the duration that the container should sleep before being terminated.

=head2 tcpSocket

Deprecated. TCPSocket is NOT supported as a LifecycleHandler and kept for the backward compatibility. There are no validation of this field and lifecycle hooks will fail in runtime when tcp handler is specified.

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
