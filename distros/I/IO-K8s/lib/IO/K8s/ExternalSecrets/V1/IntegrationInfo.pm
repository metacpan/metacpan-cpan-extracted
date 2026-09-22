package IO::K8s::ExternalSecrets::V1::IntegrationInfo;
# ABSTRACT: IntegrationInfo specifies the name and version of the integration built using the 1Password Go SDK.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name    => Str, { default => '1Password SDK' };
k8s version => Str, { default => 'v1.0.0' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::IntegrationInfo - IntegrationInfo specifies the name and version of the integration built using the 1Password Go SDK.

=head1 VERSION

version 1.108

=head2 name

Name defaults to "1Password SDK".

=head2 version

Version defaults to "v1.0.0".

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
