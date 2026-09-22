package IO::K8s::PrometheusOperator::V1::OTLPConfig;
# ABSTRACT: otlp defines the settings related to the OTLP receiver feature.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s convertHistogramsToNHCB              => Bool;
k8s ignoreResourceAttributes             => [Str];
k8s keepIdentifyingResourceAttributes    => Bool;
k8s labelNamePreserveMultipleUnderscores => Bool;
k8s labelNameUnderscoreSanitization      => Bool;
k8s promoteAllResourceAttributes         => Bool;
k8s promoteResourceAttributes            => [Str];
k8s promoteScopeMetadata                 => Bool;
k8s translationStrategy                  => Str, { enum => [qw(NoUTF8EscapingWithSuffixes UnderscoreEscapingWithSuffixes NoTranslation UnderscoreEscapingWithoutSuffixes)] };










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::OTLPConfig - otlp defines the settings related to the OTLP receiver feature.

=head1 VERSION

version 1.108

=head2 convertHistogramsToNHCB

convertHistogramsToNHCB defines optional translation of OTLP explicit bucket histograms into native histograms with custom buckets.
It requires Prometheus >= v3.4.0.

=head2 ignoreResourceAttributes

ignoreResourceAttributes defines the list of OpenTelemetry resource attributes to ignore when `promoteAllResourceAttributes` is true.

It requires `promoteAllResourceAttributes` to be true.
It requires Prometheus >= v3.5.0.

=head2 keepIdentifyingResourceAttributes

keepIdentifyingResourceAttributes enables adding `service.name`, `service.namespace` and `service.instance.id`
resource attributes to the `target_info` metric, on top of converting them into the `instance` and `job` labels.

It requires Prometheus >= v3.1.0.

=head2 labelNamePreserveMultipleUnderscores

labelNamePreserveMultipleUnderscores enables preserving of multiple consecutive underscores in label names when translation_strategy uses
underscore escaping.
When true (default), multiple consecutive underscores are preserved during label name sanitization.

Notice: This one has no impact if `nameEscapingScheme` is `AllowUTF8`.

It requires Prometheus >= v3.8.0.

=head2 labelNameUnderscoreSanitization

labelNameUnderscoreSanitization controls whether to enable prepending of 'key_' to labels starting with '_'.
Reserved labels starting with '__' are not modified.
This is only relevant when translation_strategy uses underscore escaping (e.g., "UnderscoreEscapingWithSuffixes" or "UnderscoreEscapingWithoutSuffixes").

Notice: This one has no impact if `nameEscapingScheme` is `AllowUTF8`.

It requires Prometheus >= v3.8.0.

=head2 promoteAllResourceAttributes

promoteAllResourceAttributes promotes all resource attributes to metric labels except the ones defined in `ignoreResourceAttributes`.

Cannot be true when `promoteResourceAttributes` is defined.
It requires Prometheus >= v3.5.0.

=head2 promoteResourceAttributes

promoteResourceAttributes defines the list of OpenTelemetry Attributes that should be promoted to metric labels, defaults to none.
Cannot be defined when `promoteAllResourceAttributes` is true.

=head2 promoteScopeMetadata

promoteScopeMetadata controls whether to promote OpenTelemetry scope metadata (i.e. name, version, schema URL, and attributes) to metric labels.
As per the OpenTelemetry specification, the aforementioned scope metadata should be identifying, i.e. made into metric labels.
It requires Prometheus >= v3.6.0.

=head2 translationStrategy

translationStrategy defines how the OTLP receiver endpoint translates the incoming metrics.

It requires Prometheus >= v3.0.0.

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
