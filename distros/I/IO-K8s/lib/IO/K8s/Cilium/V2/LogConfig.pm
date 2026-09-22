package IO::K8s::Cilium::V2::LogConfig;
# ABSTRACT: Log specifies custom policy-specific Hubble logging configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s value => Str, { pattern => qr/^\PC*$/ };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::LogConfig - Log specifies custom policy-specific Hubble logging configuration.

=head1 VERSION

version 1.108

=head2 value

Value is a free-form string that is included in Hubble flows
that match this policy. The string is limited to 32 printable characters.

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
