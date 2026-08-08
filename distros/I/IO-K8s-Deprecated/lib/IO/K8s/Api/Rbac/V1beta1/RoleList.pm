package IO::K8s::Api::Rbac::V1beta1::RoleList;
# ABSTRACT: REMOVED -- superseded by the generic IO::K8s::List, see IO::K8s::Deprecated

use strict;
use warnings;

our $VERSION = '1.105';

die __PACKAGE__ . " has been removed. IO-K8s replaced all per-resource"
  . " *List classes with the single generic IO::K8s::List back in its 1.00"
  . " Moose-to-Moo rewrite; this class only ever emitted a deprecation"
  . " warning since then (it was never a real class in the 1.x series) and"
  . " has now been dropped outright. Use IO::K8s::List instead:\n"
  . "  perldoc IO::K8s::List\n"
  . "  cpanm IO::K8s\n"
  . "  https://metacpan.org/dist/IO-K8s\n";

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Rbac::V1beta1::RoleList - REMOVED -- superseded by the generic IO::K8s::List, see IO::K8s::Deprecated

=head1 VERSION

version 1.105

=head1 DESCRIPTION

This module has been removed. IO-K8s replaced all per-resource C<*List>
classes (this one included) with a single generic L<IO::K8s::List> class
back in the C<1.00> Moose-to-Moo rewrite; C<IO::K8s::Api::Rbac::V1beta1::RoleList> itself was never a real
class in the C<1.x> series -- it only emitted a deprecation warning on load
pointing at C<IO::K8s::List>. IO-K8s C<1.100> was the last CPAN release to
ship even that warning stub; it has now been dropped from the distribution
entirely.

This module is a CPAN redirect stub, part of L<IO::K8s::Deprecated>. It
carries no implementation and B<dies unconditionally> as soon as it is
loaded (C<use>/C<require>), naming the replacement class. It exists only so
that C<cpanm IO::K8s::Api::Rbac::V1beta1::RoleList> -- or a cpanfile / code that still references the old
name -- surfaces a clear, actionable redirect instead of silently
installing the stale, superseded C<IO-K8s> C<1.100> release that still
carries this name.

Use L<IO::K8s::List> instead -- it derives C<api_version>/C<kind>
automatically from the items you give it, so one class now covers what used
to require a separate C<*List> class per resource type.

=head1 NAME

IO::K8s::Api::Rbac::V1beta1::RoleList - REMOVED, superseded by IO::K8s::List

=head1 SEE ALSO

L<IO::K8s::List>, L<IO::K8s::Deprecated>

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
