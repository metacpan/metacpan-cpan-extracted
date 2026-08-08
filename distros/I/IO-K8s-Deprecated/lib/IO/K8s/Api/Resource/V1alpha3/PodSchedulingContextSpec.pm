package IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextSpec;
# ABSTRACT: REMOVED -- classic DRA control-plane-controller allocation retired, see IO::K8s::Deprecated

use strict;
use warnings;

our $VERSION = '1.105';

die __PACKAGE__ . " has been removed. It was the nested spec type for"
  . " IO::K8s::Api::Resource::V1alpha3::PodSchedulingContext, part of"
  . " Kubernetes' \"classic\" Dynamic Resource Allocation (DRA)"
  . " control-plane-controller allocation flow (resource.k8s.io/v1alpha3,"
  . " alpha-only, never GA). That whole mechanism was retired when DRA"
  . " graduated to GA with a structured-parameters model at"
  . " resource.k8s.io/v1 -- there is no 1:1 successor class. See"
  . " IO::K8s::Api::Resource::V1::ResourceClaim and"
  . " IO::K8s::Api::Resource::V1::DeviceClass for the current DRA API."
  . " Install a current IO::K8s instead:\n"
  . "  cpanm IO::K8s\n"
  . "  https://metacpan.org/dist/IO-K8s\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextSpec - REMOVED -- classic DRA control-plane-controller allocation retired, see IO::K8s::Deprecated

=head1 VERSION

version 1.105

=head1 DESCRIPTION

This module has been removed, not renamed -- there is no 1:1 replacement.
It was the nested C<spec> type for
L<IO::K8s::Api::Resource::V1alpha3::PodSchedulingContext>, part of
Kubernetes' "classic DRA" control-plane-controller allocation flow
(C<resource.k8s.io/v1alpha3>, alpha-only, never GA). Dynamic Resource
Allocation graduated to GA with an architecturally different
structured-parameters model at C<resource.k8s.io/v1>, and this class was
dropped along with the rest of the classic-DRA type family. Last shipped
in C<IO-K8s> C<1.100>.

This module is a CPAN redirect stub, part of L<IO::K8s::Deprecated>. It
carries no implementation and B<dies unconditionally> as soon as it is
loaded. It exists only so that C<cpanm
IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextSpec> -- or a
cpanfile / code that still references the old name -- surfaces a clear
explanation instead of silently installing the stale, superseded
C<IO-K8s> C<1.100> release that still carries this name.

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextSpec - REMOVED, no direct replacement

=head1 SEE ALSO

L<IO::K8s::Api::Resource::V1::ResourceClaim>,
L<IO::K8s::Api::Resource::V1::DeviceClass>, L<IO::K8s::Deprecated>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/io-k8s-p5-deprecated/issues>.

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
