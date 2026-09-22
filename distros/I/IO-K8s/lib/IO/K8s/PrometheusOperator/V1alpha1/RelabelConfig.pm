package IO::K8s::PrometheusOperator::V1alpha1::RelabelConfig;
# ABSTRACT: RelabelConfig allows dynamic rewriting of the label set for targets, alerts, scraped samples and remote write samples.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s action       => Str, { enum => [qw(replace Replace keep Keep drop Drop hashmod HashMod labelmap LabelMap labeldrop LabelDrop labelkeep LabelKeep lowercase Lowercase uppercase Uppercase keepequal KeepEqual dropequal DropEqual)], default => 'replace' };
k8s modulus      => Int, { minimum => 0 };
k8s regex        => Str;
k8s replacement  => Str;
k8s separator    => Str;
k8s sourceLabels => [Str];
k8s targetLabel  => Str;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::RelabelConfig - RelabelConfig allows dynamic rewriting of the label set for targets, alerts, scraped samples and remote write samples.

=head1 VERSION

version 1.108

=head2 action

action to perform based on the regex matching.

`Uppercase` and `Lowercase` actions require Prometheus >= v2.36.0.
`DropEqual` and `KeepEqual` actions require Prometheus >= v2.41.0.

Default: "Replace"

=head2 modulus

modulus to take of the hash of the source label values.

Only applicable when the action is `HashMod`.

=head2 regex

regex defines the regular expression against which the extracted value is matched.

=head2 replacement

replacement value against which a Replace action is performed if the
regular expression matches.

Regex capture groups are available.

=head2 separator

separator defines the string between concatenated SourceLabels.

=head2 sourceLabels

sourceLabels defines the source labels select values from existing labels. Their content is
concatenated using the configured Separator and matched against the
configured regular expression.

=head2 targetLabel

targetLabel defines the label to which the resulting string is written in a replacement.

It is mandatory for `Replace`, `HashMod`, `Lowercase`, `Uppercase`,
`KeepEqual` and `DropEqual` actions.

Regex capture groups are available.

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
