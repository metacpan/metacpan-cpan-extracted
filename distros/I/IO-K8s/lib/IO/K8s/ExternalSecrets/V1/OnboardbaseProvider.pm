package IO::K8s::ExternalSecrets::V1::OnboardbaseProvider;
# ABSTRACT: Onboardbase configures this store to sync secrets using the Onboardbase provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiHost     => Str, { required => 'schema', default => 'https://public.onboardbase.com/api/v1/' };
k8s auth        => '+IO::K8s::ExternalSecrets::V1::OnboardbaseAuthSecretRef', { required => 'schema' };
k8s environment => Str, { required => 'schema', default => 'development' };
k8s project     => Str, { required => 'schema', default => 'development' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OnboardbaseProvider - Onboardbase configures this store to sync secrets using the Onboardbase provider

=head1 VERSION

version 1.108

=head2 apiHost

APIHost use this to configure the host url for the API for selfhosted installation, default is https://public.onboardbase.com/api/v1/

=head2 auth

Auth configures how the Operator authenticates with the Onboardbase API

=head2 environment

Environment is the name of an environmnent within a project to pull the secrets from

=head2 project

Project is an onboardbase project that the secrets should be pulled from

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
