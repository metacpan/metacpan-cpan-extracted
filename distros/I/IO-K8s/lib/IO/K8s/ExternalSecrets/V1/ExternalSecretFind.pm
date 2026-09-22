package IO::K8s::ExternalSecrets::V1::ExternalSecretFind;
# ABSTRACT: Used to find secrets based on tags or regular expressions Note: Find does not support sourceRef.Generator or sourceRef.GeneratorRef.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conversionStrategy => Str, { enum => [qw(Default Unicode)] };
k8s decodingStrategy   => Str, { enum => [qw(Auto Base64 Base64URL None)] };
k8s name               => '+IO::K8s::ExternalSecrets::V1::FindName';
k8s nullBytePolicy     => Str, { enum => [qw(Ignore Fail)] };
k8s path               => Str;
k8s tags               => { Str => 1 };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretFind - Used to find secrets based on tags or regular expressions Note: Find does not support sourceRef.Generator or sourceRef.GeneratorRef.

=head1 VERSION

version 1.108

=head2 conversionStrategy

Used to define a conversion Strategy. Defaults to Default when omitted.

=head2 decodingStrategy

Used to define a decoding Strategy. Defaults to None when omitted.

=head2 name

Finds secrets based on the name.

=head2 nullBytePolicy

Controls how ESO handles fetched secret data containing NUL bytes for this find source.

=head2 path

A root path to start the find operations.

=head2 tags

Find secrets based on tags.

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
