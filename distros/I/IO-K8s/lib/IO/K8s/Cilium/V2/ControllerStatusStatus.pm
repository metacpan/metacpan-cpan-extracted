package IO::K8s::Cilium::V2::ControllerStatusStatus;
# ABSTRACT: Status is the status of the controller
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'consecutive-failure-count' => Int;
k8s 'failure-count'             => Int;
k8s 'last-failure-msg'          => Str;
k8s 'last-failure-timestamp'    => Str;
k8s 'last-success-timestamp'    => Str;
k8s 'success-count'             => Int;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::ControllerStatusStatus - Status is the status of the controller

=head1 VERSION

version 1.108

=head2 consecutive-failure-count

No description in the upstream schema.

=head2 failure-count

No description in the upstream schema.

=head2 last-failure-msg

No description in the upstream schema.

=head2 last-failure-timestamp

No description in the upstream schema.

=head2 last-success-timestamp

No description in the upstream schema.

=head2 success-count

No description in the upstream schema.

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
