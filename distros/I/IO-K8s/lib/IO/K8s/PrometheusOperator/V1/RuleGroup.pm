package IO::K8s::PrometheusOperator::V1::RuleGroup;
# ABSTRACT: RuleGroup is a list of sequentially evaluated recording and alerting rules.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s interval                  => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s labels                    => { Str => 1 };
k8s limit                     => Int;
k8s name                      => Str, { required => 'schema' };
# Upstream's own text, kept as the plain string it is: the inline modifier
# has no ECMA262 spelling, so as a qr// (which also picks up an 'i' flag a
# CRD pattern cannot carry) to_crd could not emit it back. This is what
# IO::K8s::CRD::Emitter now renders for a flagged pattern too (k110).
k8s partial_response_strategy => Str, { pattern => '^(?i)(abort|warn)?$' };
k8s query_offset              => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s rules                     => ['+IO::K8s::PrometheusOperator::V1::Rule'];








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::RuleGroup - RuleGroup is a list of sequentially evaluated recording and alerting rules.

=head1 VERSION

version 1.108

=head2 interval

interval defines how often rules in the group are evaluated.

=head2 labels

labels define the labels to add or overwrite before storing the result for its rules.
The labels defined at the rule level take precedence.

It requires Prometheus >= 3.0.0.
The field is ignored for Thanos Ruler.

=head2 limit

limit defines the number of alerts an alerting rule and series a recording
rule can produce.
Limit is supported starting with Prometheus >= 2.31 and Thanos Ruler >= 0.24.

=head2 name

name defines the name of the rule group.

=head2 partial_response_strategy

partial_response_strategy is only used by ThanosRuler and will
be ignored by Prometheus instances.
More info: https://github.com/thanos-io/thanos/blob/main/docs/components/rule.md#partial-response

=head2 query_offset

query_offset defines the offset the rule evaluation timestamp of this particular group by the specified duration into the past.

It requires Prometheus >= v2.53.0.
It is not supported for ThanosRuler.

=head2 rules

rules defines the list of alerting and recording rules.

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
