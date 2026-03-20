package IO::K8s::Api::Core::V1::ContainerState;
# ABSTRACT: ContainerState holds a possible state of container. Only one of its members may be specified. If none of them is specified, the default one is ContainerStateWaiting.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s running => 'Core::V1::ContainerStateRunning';


k8s terminated => 'Core::V1::ContainerStateTerminated';


k8s waiting => 'Core::V1::ContainerStateWaiting';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerState - ContainerState holds a possible state of container. Only one of its members may be specified. If none of them is specified, the default one is ContainerStateWaiting.

=head1 VERSION

version 1.009

=head2 running

Details about a running container

=head2 terminated

Details about a terminated container

=head2 waiting

Details about a waiting container

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
