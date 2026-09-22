package IO::K8s::PrometheusOperator::V1::Authorization;
# ABSTRACT: authorization section for the ScrapeClass.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s credentials     => 'Core::V1::ConfigMapKeySelector';
k8s credentialsFile => Str;
k8s type            => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::Authorization - authorization section for the ScrapeClass.

=head1 VERSION

version 1.108

=head2 credentials

credentials defines a key of a Secret in the namespace that contains the credentials for authentication.

=head2 credentialsFile

credentialsFile defines the file to read a secret from, mutually exclusive with `credentials`.

=head2 type

type defines the authentication type. The value is case-insensitive.

"Basic" is not a supported value.

Default: "Bearer"

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
