package IO::K8s::Api::Resource::V1alpha3::ResourceClaimTemplateSpec;
# ABSTRACT: ResourceClaimTemplateSpec contains the metadata and fields for a ResourceClaim.
our $VERSION = '1.006';
use IO::K8s::APIObject;


k8s spec => 'Resource::V1alpha3::ResourceClaimSpec', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::ResourceClaimTemplateSpec - ResourceClaimTemplateSpec contains the metadata and fields for a ResourceClaim.

=head1 VERSION

version 1.006

=head1 DESCRIPTION

ResourceClaimTemplateSpec contains the metadata and fields for a ResourceClaim.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

Spec for the ResourceClaim. The entire content is copied unchanged into the ResourceClaim that gets created from this template. The same fields as in a ResourceClaim are also valid here.

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
