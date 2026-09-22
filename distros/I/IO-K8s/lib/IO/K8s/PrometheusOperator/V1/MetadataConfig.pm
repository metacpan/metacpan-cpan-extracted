package IO::K8s::PrometheusOperator::V1::MetadataConfig;
# ABSTRACT: metadataConfig defines how to send a series metadata to the remote storage.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s maxSamplesPerSend => Int, { minimum => -1 };
k8s send              => Bool;
k8s sendInterval      => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::MetadataConfig - metadataConfig defines how to send a series metadata to the remote storage.

=head1 VERSION

version 1.108

=head2 maxSamplesPerSend

maxSamplesPerSend defines the maximum number of metadata samples per send.

It requires Prometheus >= v2.29.0.

=head2 send

send defines whether metric metadata is sent to the remote storage or not.

The setting is ignored when Remote Write message's version 2.0 is used.

=head2 sendInterval

sendInterval defines how frequently metric metadata is sent to the remote storage.

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
