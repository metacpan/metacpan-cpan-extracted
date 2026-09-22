package IO::K8s::GatewayAPI::V1beta1::HTTPPathMatch;
# ABSTRACT: Path specifies a HTTP request path matcher.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s type  => Str, { enum => [qw(Exact PathPrefix RegularExpression)], default => 'PathPrefix' };
k8s value => Str, { default => '/' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::HTTPPathMatch - Path specifies a HTTP request path matcher.

=head1 VERSION

version 1.108

=head2 type

Type specifies how to match against the path Value.

Support: Core (Exact, PathPrefix)

Support: Implementation-specific (RegularExpression)

=head2 value

Value of the HTTP path to match against.

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
