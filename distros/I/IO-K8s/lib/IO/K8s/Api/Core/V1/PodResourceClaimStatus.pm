package IO::K8s::Api::Core::V1::PodResourceClaimStatus;
# ABSTRACT: PodResourceClaimStatus is stored in the PodStatus for each PodResourceClaim which references a ResourceClaimTemplate. It stores the generated name for the corresponding ResourceClaim.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s resourceClaimName => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PodResourceClaimStatus - PodResourceClaimStatus is stored in the PodStatus for each PodResourceClaim which references a ResourceClaimTemplate. It stores the generated name for the corresponding ResourceClaim.

=head1 VERSION

version 1.006

=head2 name

Name uniquely identifies this resource claim inside the pod. This must match the name of an entry in pod.spec.resourceClaims, which implies that the string must be a DNS_LABEL.

=head2 resourceClaimName

ResourceClaimName is the name of the ResourceClaim that was generated for the Pod in the namespace of the Pod. If this is unset, then generating a ResourceClaim was not necessary. The pod.spec.resourceClaims entry can be ignored in this case.

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
