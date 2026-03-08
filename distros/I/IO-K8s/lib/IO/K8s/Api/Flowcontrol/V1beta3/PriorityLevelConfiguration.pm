package IO::K8s::Api::Flowcontrol::V1beta3::PriorityLevelConfiguration;
# ABSTRACT: PriorityLevelConfiguration represents the configuration of a priority level.
our $VERSION = '1.006';
use IO::K8s::APIObject;


k8s spec => 'Flowcontrol::V1beta3::PriorityLevelConfigurationSpec';


k8s status => 'Flowcontrol::V1beta3::PriorityLevelConfigurationStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Flowcontrol::V1beta3::PriorityLevelConfiguration - PriorityLevelConfiguration represents the configuration of a priority level.

=head1 VERSION

version 1.006

=head1 DESCRIPTION

PriorityLevelConfiguration represents the configuration of a priority level.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

C<spec> is the specification of the desired behavior of a "request-priority". More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head2 status

C<status> is the current status of a "request-priority". More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#prioritylevelconfiguration-v1beta3-flowcontrol.apiserver.k8s.io>

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
