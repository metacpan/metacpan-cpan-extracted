package IO::K8s::ExternalSecrets::V1::DopplerProvider;
# ABSTRACT: Doppler configures this store to sync secrets using the Doppler provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth            => '+IO::K8s::ExternalSecrets::V1::DopplerAuth', { required => 'schema' };
k8s config          => Str;
k8s format          => Str, { enum => [qw(json dotnet-json env yaml docker)] };
k8s nameTransformer => Str, { enum => [qw(upper-camel camel lower-snake tf-var dotnet-env lower-kebab)] };
k8s project         => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::DopplerProvider - Doppler configures this store to sync secrets using the Doppler provider

=head1 VERSION

version 1.108

=head2 auth

Auth configures how the Operator authenticates with the Doppler API

=head2 config

Doppler config (required if not using a Service Token)

=head2 format

Format enables the downloading of secrets as a file (string)

=head2 nameTransformer

Environment variable compatible name transforms that change secret names to a different format

=head2 project

Doppler project (required if not using a Service Token)

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
