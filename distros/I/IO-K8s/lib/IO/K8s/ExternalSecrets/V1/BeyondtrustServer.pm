package IO::K8s::ExternalSecrets::V1::BeyondtrustServer;
# ABSTRACT: Auth configures how API server works.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiUrl               => Str, { required => 'schema' };
k8s apiVersion           => Str;
k8s clientTimeOutSeconds => Int;
k8s decrypt              => Bool, { default => 1 };
k8s retrievalType        => Str;
k8s separator            => Str;
k8s verifyCA             => Bool, { required => 'schema' };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::BeyondtrustServer - Auth configures how API server works.

=head1 VERSION

version 1.108

=head2 apiUrl

No description in the upstream schema.

=head2 apiVersion

No description in the upstream schema.

=head2 clientTimeOutSeconds

Timeout specifies a time limit for requests made by this Client. The timeout includes connection time, any redirects, and reading the response body. Defaults to 45 seconds.

=head2 decrypt

When true, the response includes the decrypted password. When false, the password field is omitted. This option only applies to the SECRET retrieval type. Default: true.

=head2 retrievalType

The secret retrieval type. SECRET = Secrets Safe (credential, text, file). MANAGED_ACCOUNT = Password Safe account associated with a system.

=head2 separator

A character that separates the folder names.

=head2 verifyCA

No description in the upstream schema.

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
