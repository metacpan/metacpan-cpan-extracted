package IO::K8s::Api::Core::V1::EnvFromSource;
# ABSTRACT: EnvFromSource represents the source of a set of ConfigMaps
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s configMapRef => 'Core::V1::ConfigMapEnvSource';


k8s prefix => Str;


k8s secretRef => 'Core::V1::SecretEnvSource';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::EnvFromSource - EnvFromSource represents the source of a set of ConfigMaps

=head1 VERSION

version 1.008

=head2 configMapRef

The ConfigMap to select from

=head2 prefix

An optional identifier to prepend to each key in the ConfigMap. Must be a C_IDENTIFIER.

=head2 secretRef

The Secret to select from

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
