package IO::K8s::PrometheusOperator::V1::PrometheusRuleExcludeConfig;
# ABSTRACT: PrometheusRuleExcludeConfig enables users to configure excluded PrometheusRule names and their namespaces to be ignored while enforcing namespace label for alerts and metrics.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ruleName      => Str, { required => 'schema' };
k8s ruleNamespace => Str, { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PrometheusRuleExcludeConfig - PrometheusRuleExcludeConfig enables users to configure excluded PrometheusRule names and their namespaces to be ignored while enforcing namespace label for alerts and metrics.

=head1 VERSION

version 1.108

=head2 ruleName

ruleName defines the name of the excluded PrometheusRule object.

=head2 ruleNamespace

ruleNamespace defines the namespace of the excluded PrometheusRule object.

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
