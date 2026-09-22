package IO::K8s::CertManager::V1::OtherName;
# ABSTRACT: OtherName
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s oid       => Str;
k8s utf8Value => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::OtherName - OtherName

=head1 VERSION

version 1.108

=head2 oid

OID is the object identifier for the otherName SAN.
The object identifier must be expressed as a dotted string, for
example, "1.2.840.113556.1.4.221".

=head2 utf8Value

utf8Value is the string value of the otherName SAN.
The utf8Value accepts any valid UTF8 string to set as value for the otherName SAN.

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
