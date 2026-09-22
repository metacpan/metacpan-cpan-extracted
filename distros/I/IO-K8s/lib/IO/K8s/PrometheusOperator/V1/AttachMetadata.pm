package IO::K8s::PrometheusOperator::V1::AttachMetadata;
# ABSTRACT: attachMetadata defines additional metadata which is added to the discovered targets.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s node => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::AttachMetadata - attachMetadata defines additional metadata which is added to the discovered targets.

=head1 VERSION

version 1.108

=head2 node

node when set to true, Prometheus attaches node metadata to the discovered
targets.

The Prometheus service account must have the `list` and `watch`
permissions on the `Nodes` objects.

Node metadata labels are not automatically added to scraped metrics. They are
exposed as `__meta_kubernetes_node_*` labels and can be copied to timeseries
with relabeling configuration.

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
