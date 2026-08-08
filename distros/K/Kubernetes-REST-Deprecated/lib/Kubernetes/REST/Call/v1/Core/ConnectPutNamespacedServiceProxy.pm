package Kubernetes::REST::Call::v1::Core::ConnectPutNamespacedServiceProxy;
# ABSTRACT: REMOVED -- superseded by Kubernetes::REST's unified v1 API, see Kubernetes::REST::Deprecated

use strict;
use warnings;

our $VERSION = '1.105';

die __PACKAGE__ . " has been removed. Kubernetes::REST's v1 rewrite replaced"
  . " the entire old per-endpoint v0 API (one Call class per operation) with"
  . " a single unified object-oriented API; this class only ever emitted a"
  . " deprecation warning since Kubernetes-REST 1.000 (it did nothing else)"
  . " and has now been dropped outright. Use the new API instead:\n"
  . "  perldoc Kubernetes::REST\n"
  . "  cpanm Kubernetes::REST\n"
  . "  https://metacpan.org/dist/Kubernetes-REST\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Call::v1::Core::ConnectPutNamespacedServiceProxy - REMOVED -- superseded by Kubernetes::REST's unified v1 API, see Kubernetes::REST::Deprecated

=head1 VERSION

version 1.105

=head1 DESCRIPTION

This module has been removed. Kubernetes::REST's v1 rewrite (first shipped
in C<1.000>) replaced the entire old per-endpoint v0 API -- one generated
C<Call::*> class per API operation -- with a single unified
object-oriented API directly on the L<Kubernetes::REST> object (C<list>,
C<get>, C<create>, C<update>, C<patch>, C<delete>, C<watch>, ...).
C<Kubernetes::REST::Call::v1::Core::ConnectPutNamespacedServiceProxy> itself was never functional in the C<1.x> series -- it
only emitted a deprecation warning on load pointing at the new API.
Kubernetes-REST C<1.104> was the last CPAN release to ship even that
warning stub; it has now been dropped from the distribution entirely.

This module is a CPAN redirect stub, part of L<Kubernetes::REST::Deprecated>.
It carries no implementation and B<dies unconditionally> as soon as it is
loaded (C<use>/C<require>), naming the replacement. It exists only so that
C<cpanm Kubernetes::REST::Call::v1::Core::ConnectPutNamespacedServiceProxy> -- or a cpanfile / code that still references the
old name -- surfaces a clear, actionable redirect instead of silently
installing the stale, superseded C<Kubernetes-REST> C<1.104> release that
still carries this name.

Use L<Kubernetes::REST> directly instead -- see its POD for the C<list>,
C<get>, C<create>, C<update>, C<patch>, C<delete>, and C<watch> methods that
replace the old per-operation C<Call::*> classes.

Note: the old v0 API's I<group accessor> methods (C<< $api->Core >>,
C<< $api->Apps >>, etc., via L<Kubernetes::REST::V0Group>) are B<not>
affected by this removal and continue to work -- they are a still-functional
backwards-compatibility layer, unlike this class which never did anything
but warn.

=head1 NAME

Kubernetes::REST::Call::v1::Core::ConnectPutNamespacedServiceProxy - REMOVED, superseded by Kubernetes::REST's unified v1 API

=head1 SEE ALSO

L<Kubernetes::REST>, L<Kubernetes::REST::Deprecated>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/kubernetes-rest-deprecated/issues>.

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

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
