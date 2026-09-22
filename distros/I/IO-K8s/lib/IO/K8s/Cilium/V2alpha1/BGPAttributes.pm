package IO::K8s::Cilium::V2alpha1::BGPAttributes;
# ABSTRACT: Attributes defines additional attributes to set to the advertised routes.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s communities     => '+IO::K8s::Cilium::V2alpha1::BGPCommunities';
k8s localPreference => Int;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::BGPAttributes - Attributes defines additional attributes to set to the advertised routes.

=head1 VERSION

version 1.108

=head2 communities

Communities sets the community attributes in the route.
If not specified, no community attribute is set.

=head2 localPreference

LocalPreference sets the local preference attribute in the route.
If not specified, no local preference attribute is set.

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
