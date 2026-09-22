package IO::K8s::Traefik::V1alpha1::FailoverError;
# ABSTRACT: Errors defines which errors should trigger the use of the fallback service.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s maxRequestBodyBytes => Int;
k8s status              => [Str];



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::FailoverError - Errors defines which errors should trigger the use of the fallback service.

=head1 VERSION

version 1.108

=head2 maxRequestBodyBytes

MaxRequestBodyBytes defines the maximum size allowed for the body of the request.
Default value is -1, which means unlimited size.

=head2 status

Status defines the list of status code ranges for which the fallback service should be used.

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
