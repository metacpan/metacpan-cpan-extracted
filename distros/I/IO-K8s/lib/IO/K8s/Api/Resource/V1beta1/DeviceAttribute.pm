package IO::K8s::Api::Resource::V1beta1::DeviceAttribute;
# ABSTRACT: DeviceAttribute must have exactly one field set.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s bool => Bool;


k8s bools => [Bool];


k8s int => Int;


k8s ints => [Int];


k8s string => Str;


k8s strings => [Str];


k8s version => Str;


k8s versions => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta1::DeviceAttribute - DeviceAttribute must have exactly one field set.

=head1 VERSION

version 1.107

=head2 bool

BoolValue is a true/false value.

=head2 bools

BoolValues is a non-empty list of true/false values.

=head2 int

IntValue is a number.

=head2 ints

IntValues is a non-empty list of numbers.  This is an alpha field and requires enabling the DRAListTypeAttributes feature gate.

=head2 string

StringValue is a string. Must not be longer than 64 characters.

=head2 strings

StringValues is a non-empty list of strings. Each string must not be longer than 64 characters.  This is an alpha field and requires enabling the DRAListTypeAttributes feature gate.

=head2 version

VersionValue is a semantic version according to semver.org spec 2.0.0. Must not be longer than 64 characters.

=head2 versions

VersionValues is a non-empty list of semantic versions according to semver.org spec 2.0.0. Each version string must not be longer than 64 characters.  This is an alpha field and requires enabling the DRAListTypeAttributes feature gate.

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
