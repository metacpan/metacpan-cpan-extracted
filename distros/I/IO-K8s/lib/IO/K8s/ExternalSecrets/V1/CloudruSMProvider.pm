package IO::K8s::ExternalSecrets::V1::CloudruSMProvider;
# ABSTRACT: CloudruSM configures this store to sync secrets using the Cloud.ru Secret Manager provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth      => '+IO::K8s::ExternalSecrets::V1::CSMAuth', { required => 'schema' };
k8s projectID => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::CloudruSMProvider - CloudruSM configures this store to sync secrets using the Cloud.ru Secret Manager provider

=head1 VERSION

version 1.108

=head2 auth

CSMAuth contains a secretRef for credentials.

=head2 projectID

ProjectID is the project, which the secrets are stored in.

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
