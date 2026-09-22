package IO::K8s::Cilium::V2::ControllerStatus;
# ABSTRACT: ControllerStatus is the status of a failing controller.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s configuration => '+IO::K8s::Cilium::V2::ControllerStatusConfiguration';
k8s name          => Str;
k8s status        => '+IO::K8s::Cilium::V2::ControllerStatusStatus';
k8s uuid          => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::ControllerStatus - ControllerStatus is the status of a failing controller.

=head1 VERSION

version 1.108

=head2 configuration

Configuration is the controller configuration

=head2 name

Name is the name of the controller

=head2 status

Status is the status of the controller

=head2 uuid

UUID is the UUID of the controller

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
