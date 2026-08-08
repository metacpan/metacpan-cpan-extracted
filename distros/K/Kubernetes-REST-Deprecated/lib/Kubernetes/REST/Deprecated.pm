package Kubernetes::REST::Deprecated;
our $VERSION = '1.105';
# ABSTRACT: Registry of CPAN redirect stubs for the removed Kubernetes::REST v0 API

use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Deprecated - Registry of CPAN redirect stubs for the removed Kubernetes::REST v0 API

=head1 VERSION

version 1.105

=head1 DESCRIPTION

C<Kubernetes::REST::Deprecated> is the permanent home for "tombstone" redirect
stub modules: when a Kubernetes::REST class gets renamed or retired, the old
module name stays indexed on PAUSE forever against the last release that
shipped it -- PAUSE has no delete. Anyone still running
C<cpanm Old::Module::Name> would keep installing that stale, superseded code
with no hint a replacement exists.

PAUSE indexes per B<module name>, not per distribution: it resolves each
module name to whichever shipped release -- of any distribution, including a
later release of the I<same> one -- carries the highest C<$VERSION> for that
name. Kubernetes::REST ships all of its API classes from a single
distribution, so a class that is genuinely dropped orphans its name exactly
the same way a cross-distribution rename would: PAUSE does not know or care
that "the dist is still actively released", it only sees that no shipped
release contains that module name above the version of the last one that
did.

B<Not every internally-deprecated Kubernetes::REST class belongs here.>
Kubernetes::REST's C<1.000> "v1 rewrite" (2026-02-13) replaced its entire
old per-endpoint v0 API -- one generated C<Call::*> class per API operation,
plus a handful of v0-only helper modules -- with a single unified
object-oriented API on the main L<Kubernetes::REST> object (C<list>, C<get>,
C<create>, C<update>, C<patch>, C<delete>, C<watch>, ...). Rather than
deleting the old classes outright, C<1.000> through C<1.104> kept shipping
every one of them as a soft-deprecated warning stub (C<warn>, not C<die>) --
so as long as they kept shipping under their own name in every release,
there was no PAUSE orphan and no tombstone was warranted. Only once
Kubernetes::REST actually stopped shipping a class did it become a genuine
tombstone candidate -- which is what the entries below are.

B<The C<Kubernetes::REST::V0Group> family is deliberately NOT tombstoned
here and never will be for this reason alone.> C<V0Group> and its
subclasses (C<Kubernetes::REST::Core>, C<::Apps>, C<::Batch>, etc. -- the
classes behind C<< $api->Core->ListNamespacedPod(...) >> style calls) look
similarly "deprecated" by their C<ABSTRACT> and POD, but unlike the classes
below they are not empty warning stubs -- C<V0Group> is a working
C<AUTOLOAD>-based compatibility shim that still translates old-style calls
into real API calls, and L<Kubernetes::REST> itself still wires up
C<< $api->Core >> / C<< $api->Apps >> etc. as live accessors. A class that
still does its job is not an orphan, no matter how its documentation reads --
confirm with C<grep -rn "extends 'Kubernetes::REST::V0Group'"> before ever
drafting a tombstone for one of these.

This distribution fixes the genuine orphan case with the standard CPAN
redirect-takeover pattern: it ships a small stub package under the OLD
module name, with an explicit C<$VERSION> set strictly higher than the last
CPAN release of C<Kubernetes-REST> that shipped that name. PAUSE then
indexes I<this> distribution as canonical for the old name. The stub does
nothing at runtime except C<die> immediately on load, naming the
replacement module, so C<cpanm Old::Module::Name> (or a cpanfile pinning
it) now installs a clear, actionable message instead of silently
reinstalling dead code.

This dist itself (C<Kubernetes::REST::Deprecated>, this module) has no
runtime behaviour of its own -- it is a documentation landing page and the
dzil main module. Each tombstone module is self-contained and carries no
dependency on Kubernetes::REST core.

=head1 VERSION POLICY

Every file here -- the main module and all 1012 tombstones alike --
versions normally and uniformly with the rest of the distribution
(C<RewriteVersion::Transitional> / C<BumpVersionAfterRelease>, no
C<version_finder> restriction in C<dist.ini>). There is no per-tombstone
hand-frozen C<$VERSION>. The starting version, C<1.105>, was chosen for one
reason: it is the next version after C<Kubernetes-REST 1.104>, the last
CPAN release that shipped any of these module names. Kubernetes::REST will
never ship these names again (they are permanently removed, not merely
between releases), and this distribution's own version only ever increases
from here, so C<1.105> stays ahead of that target for good without further
special-casing.

If a future tombstone is ever added for a name whose last-shipped version
is higher than whatever version this dist has reached by then, confirm
that before releasing and bump first if needed -- an ordinary
version-ordering check, not a reason to reintroduce per-file version
overrides.

For the step-by-step procedure to add a new tombstone when a future rename
or removal happens, see the C<kubernetes-rest-deprecated> skill
(C<.claude/skills/kubernetes-rest-deprecated/SKILL.md> in this repo;
packaged into the sharedir at build time).

=head1 CURRENT TOMBSTONES

=head2 The old per-endpoint v0 API (1012 classes)

Kubernetes::REST's C<1.000> "v1 rewrite" replaced one generated C<Call::*>
class per API operation, across every API group and version, plus 10
v0-only helper modules (result/parameter translation, the old top-level
group-getters), with the single unified API described above. Every one of
the 1012 classes below shared the exact same shape: a 7-line stub whose only
runtime effect was C<warn __PACKAGE__ . " is deprecated, use the new
Kubernetes::REST API instead">, continuously since C<1.000>.
Kubernetes-REST C<1.104> was the last CPAN release to ship them; all 1012
were then dropped from the distribution outright.

Given the scale (1012 names, most differing from their siblings only by API
version/group/operation), the exhaustive canonical list is not duplicated
here -- it lives in C<t/01-tombstones.t>'s C<@deprecated_classes> array,
which both the test suite and this POD's summary below are generated from.
Duplicating it verbatim in prose here (unlike the much smaller lists this
convention started with) would just be ~1000 lines of drift-prone text with
no added value over the array. What follows is the breakdown by API
version/group so an audit can sanity-check coverage without reading 1012
lines:

  Call class count by apiVersion/group (Kubernetes::REST::Call::<version>::<group>::*):

    v1/Core                        240
    v1beta1/Extensions              87
    v1/Apps                         77
    v1beta2/Apps                    77
    v1beta1/Apps                    47
    v1/RbacAuthorization            41
    v1alpha1/RbacAuthorization      41
    v1beta1/RbacAuthorization       41
    (discovery -- flat under Call/)  24
    v1beta1/Policy                  24
    v1beta1/Admissionregistration   19
    v1beta1/Storage                 19
    v1/Autoscaling                  15
    v1/Batch                        15
    v1beta1/Batch                   15
    v2alpha1/Batch                  15
    v2beta1/Autoscaling             15
    v2beta2/Autoscaling             15
    v1beta1/Certificates            14
    v1/Apiregistration              13
    v1beta1/Apiextensions           13
    v1beta1/Apiregistration         13
    v1/Networking                   12
    v1alpha1/Settings               12
    v1beta1/Coordination            12
    v1beta1/Events                  12
    v1/Storage                      10
    v1alpha1/Admissionregistration  10
    v1alpha1/Auditregistration      10
    v1alpha1/Scheduling             10
    v1alpha1/Storage                10
    v1beta1/Scheduling              10
    v1/Authorization                 5
    v1beta1/Authorization            5
    v1/Authentication                2
    v1beta1/Authentication           2
                                  ----
    subtotal                      1002

  Plus 10 v0-only helper modules (no per-operation Call:: shape):

    Kubernetes::REST::Apis            -- old top-level API-group discovery
    Kubernetes::REST::Auditregistration -- old Auditregistration group getter
                                          (API group itself was removed from
                                          Kubernetes, not just from this dist)
    Kubernetes::REST::CallContext     -- old per-call context object
    Kubernetes::REST::Extensions      -- old Extensions group getter (API
                                          group itself removed from Kubernetes)
    Kubernetes::REST::ListToRequest   -- old list-to-HTTP-request translator
    Kubernetes::REST::Logs            -- old top-level log-call helper
    Kubernetes::REST::Result2Hash     -- old response-to-hashref translator
                                          (new API returns typed IO::K8s
                                          objects directly)
    Kubernetes::REST::Result2Object   -- old response-to-object translator
                                          (superseded the same way)
    Kubernetes::REST::Settings        -- old Settings group getter
    Kubernetes::REST::Version         -- old cluster-version helper
                                          (superseded by
                                          $api->cluster_version)

All 1012 redirect to the same successor: the unified API on L<Kubernetes::REST>
itself.

=head1 CONSIDERED BUT NOT TOMBSTONED

The C<Kubernetes::REST::V0Group> family -- C<V0Group> itself plus 17
subclasses (C<Core>, C<Apps>, C<Batch>, C<Networking>, C<RbacAuthorization>,
C<Admissionregistration>, C<Apiextensions>, C<Apiregistration>,
C<Authentication>, C<Authorization>, C<Autoscaling>, C<Certificates>,
C<Coordination>, C<Events>, C<Policy>, C<Scheduling>, C<Storage>) -- carries
C<DEPRECATED> in its C<ABSTRACT> and POD, same as the 1012 above, but is a
working C<AUTOLOAD>-based compatibility shim, not an empty warning stub:
it still translates old-style calls (e.g. C<< $api->Core->ListNamespacedPod(...) >>)
into real calls against the new API, and L<Kubernetes::REST> still wires up
C<< $api->Core >> / C<< $api->Apps >> etc. as live accessors calling into it.
No tombstone is warranted for any of these 18 classes -- they still ship,
under their own name, and still work. Recorded here so a future audit
doesn't rediscover and mistakenly tombstone a class that merely reads as
deprecated in its documentation.

=head1 SEE ALSO

L<Kubernetes::REST>, L<Kubernetes::REST::V0Group>

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
