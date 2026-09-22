package IO::K8s::GatewayAPI::V1::GatewayClassStatus;
# ABSTRACT: Status defines the current state of GatewayClass.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions        => ['Meta::V1::Condition'], { default => [{'lastTransitionTime' => '1970-01-01T00:00:00Z','message' => 'Waiting for controller','reason' => 'Pending','status' => 'Unknown','type' => 'Accepted'}] };
k8s supportedFeatures => ['+IO::K8s::GatewayAPI::V1::SupportedFeature'];



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::GatewayClassStatus - Status defines the current state of GatewayClass.

=head1 VERSION

version 1.108

=head2 conditions

Conditions is the current status from the controller for
this GatewayClass.

Controllers should prefer to publish conditions using values
of GatewayClassConditionType for the type of each Condition.

=head2 supportedFeatures

SupportedFeatures is the set of features the GatewayClass support.
It MUST be sorted in ascending alphabetical order by the Name key.

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
