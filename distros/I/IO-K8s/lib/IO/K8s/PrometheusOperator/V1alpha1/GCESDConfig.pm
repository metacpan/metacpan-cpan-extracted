package IO::K8s::PrometheusOperator::V1alpha1::GCESDConfig;
# ABSTRACT: GCESDConfig configures scrape targets from GCP GCE instances.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s filter          => Str;
k8s port            => Int, { minimum => 0, maximum => 65535 };
k8s project         => Str, { required => 'schema' };
k8s refreshInterval => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s tagSeparator    => Str;
k8s zone            => Str, { required => 'schema' };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::GCESDConfig - GCESDConfig configures scrape targets from GCP GCE instances.

=head1 VERSION

version 1.108

=head2 filter

filter defines the filter that can be used optionally to filter the instance list by other criteria
Syntax of this filter is described in the filter query parameter section:
https://cloud.google.com/compute/docs/reference/latest/instances/list

=head2 port

port defines the port to scrape metrics from. If using the public IP address, this must
instead be specified in the relabeling rule.

=head2 project

project defines the Google Cloud Project ID

=head2 refreshInterval

refreshInterval defines the time after which the provided names are refreshed.
If not set, Prometheus uses its default value.

=head2 tagSeparator

tagSeparator defines the tag separator is used to separate the tags on concatenation

=head2 zone

zone defines the zone of the scrape targets. If you need multiple zones use multiple GCESDConfigs.

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
