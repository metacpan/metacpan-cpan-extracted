package IO::K8s::Api::Scheduling::V1alpha3::WorkloadPodGroupResourceClaim;
# ABSTRACT: WorkloadPodGroupResourceClaim references a dynamic resource claim that is shared across pods in the group.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s resourceClaimName => Str;


k8s resourceClaimTemplateName => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha3::WorkloadPodGroupResourceClaim - WorkloadPodGroupResourceClaim references a dynamic resource claim that is shared across pods in the group.

=head1 VERSION

version 1.108

=head2 name

name uniquely identifies this resource claim inside the group. This field is required. It must be a DNS_LABEL.

=head2 resourceClaimName

resourceClaimName is the name of a ResourceClaim object in the same namespace. This field is optional. If it is not specified, no resource claim is used. If set, it must be a DNS subdomain.

=head2 resourceClaimTemplateName

resourceClaimTemplateName is the name of a ResourceClaimTemplate object in the same namespace. This field is optional. If it is not specified, no resource claim template is used. If set, it must be a DNS subdomain.

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
