package IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionStatus;
# ABSTRACT: API server instances report the versions they can decode and the version they encode objects to when persisting objects in the backend.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s commonEncodingVersion => Str;


k8s conditions => ['Apiserverinternal::V1alpha1::StorageVersionCondition'];


k8s storageVersions => ['Apiserverinternal::V1alpha1::ServerStorageVersion'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersionStatus - API server instances report the versions they can decode and the version they encode objects to when persisting objects in the backend.

=head1 VERSION

version 1.009

=head2 commonEncodingVersion

If all API server instances agree on the same encoding storage version, then this field is set to that version. Otherwise this field is left empty. API servers should finish updating its storageVersionStatus entry before serving write operations, so that this field will be in sync with the reality.

=head2 conditions

The latest available observations of the storageVersion's state.

=head2 storageVersions

The reported versions per API server instance.

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
