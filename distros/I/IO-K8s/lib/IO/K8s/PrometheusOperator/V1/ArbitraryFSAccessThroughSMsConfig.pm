package IO::K8s::PrometheusOperator::V1::ArbitraryFSAccessThroughSMsConfig;
# ABSTRACT: arbitraryFSAccessThroughSMs when true, ServiceMonitor, PodMonitor and Probe object are forbidden to reference arbitrary files on the file system of the 'prometheus' container.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s deny => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ArbitraryFSAccessThroughSMsConfig - arbitraryFSAccessThroughSMs when true, ServiceMonitor, PodMonitor and Probe object are forbidden to reference arbitrary files on the file system of the 'prometheus' container.

=head1 VERSION

version 1.108

=head2 deny

deny prevents service monitors from accessing arbitrary files on the file system.
When true, service monitors cannot use file-based configurations like BearerTokenFile
that could potentially access sensitive files. When false (default), such access is allowed.
Setting this to true enhances security by preventing potential credential theft attacks.

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
