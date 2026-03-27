package IO::K8s::Api::Resource::V1alpha3::ResourcePool;
# ABSTRACT: ResourcePool describes the pool that ResourceSlices belong to.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s generation => Int, 'required';


k8s name => Str, 'required';


k8s resourceSliceCount => Int, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::ResourcePool - ResourcePool describes the pool that ResourceSlices belong to.

=head1 VERSION

version 1.100

=head2 generation

Generation tracks the change in a pool over time. Whenever a driver changes something about one or more of the resources in a pool, it must change the generation in all ResourceSlices which are part of that pool. Consumers of ResourceSlices should only consider resources from the pool with the highest generation number. The generation may be reset by drivers, which should be fine for consumers, assuming that all ResourceSlices in a pool are updated to match or deleted.

Combined with ResourceSliceCount, this mechanism enables consumers to detect pools which are comprised of multiple ResourceSlices and are in an incomplete state.

=head2 name

Name is used to identify the pool. For node-local devices, this is often the node name, but this is not required.

It must not be longer than 253 characters and must consist of one or more DNS sub-domains separated by slashes. This field is immutable.

=head2 resourceSliceCount

ResourceSliceCount is the total number of ResourceSlices in the pool at this generation number. Must be greater than zero.

Consumers can use this to check whether they have seen all ResourceSlices belonging to the same pool.

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
