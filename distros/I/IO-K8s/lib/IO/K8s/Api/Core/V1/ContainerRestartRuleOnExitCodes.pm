package IO::K8s::Api::Core::V1::ContainerRestartRuleOnExitCodes;
# ABSTRACT: ContainerRestartRuleOnExitCodes describes the condition for handling an exited container based on its exit codes.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s operator => Str, 'required';


k8s values => [Int];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerRestartRuleOnExitCodes - ContainerRestartRuleOnExitCodes describes the condition for handling an exited container based on its exit codes.

=head1 VERSION

version 1.106

=head2 operator

Represents the relationship between the container exit code(s) and the specified values. Possible values are: - In: the requirement is satisfied if the container exit code is in the set of specified values. - NotIn: the requirement is satisfied if the container exit code is not in the set of specified values. Additional values are considered to be added in the future. Clients should read the 'reason' field to determine if the value is supported by the current version of Kubernetes.

=head2 values

Specifies the set of values to check for container exit codes. At most 255 elements are allowed.

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
