package IO::K8s::Api::Core::V1::ResourceQuotaSpec;
# ABSTRACT: ResourceQuotaSpec defines the desired hard limits to enforce for Quota.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s hard => { Str => 1 };


k8s scopeSelector => 'Core::V1::ScopeSelector';


k8s scopes => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ResourceQuotaSpec - ResourceQuotaSpec defines the desired hard limits to enforce for Quota.

=head1 VERSION

version 1.100

=head2 hard

hard is the set of desired hard limits for each named resource. More info: https://kubernetes.io/docs/concepts/policy/resource-quotas/

=head2 scopeSelector

scopeSelector is also a collection of filters like scopes that must match each object tracked by a quota but expressed using ScopeSelectorOperator in combination with possible values. For a resource to match, both scopes AND scopeSelector (if specified in spec), must be matched.

=head2 scopes

A collection of filters that must match each object tracked by a quota. If not specified, the quota matches all objects.

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
