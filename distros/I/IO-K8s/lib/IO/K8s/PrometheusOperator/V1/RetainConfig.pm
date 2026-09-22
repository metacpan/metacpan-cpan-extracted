package IO::K8s::PrometheusOperator::V1::RetainConfig;
# ABSTRACT: retain defines the config for retention when the retention policy is set to `Retain`.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s retentionPeriod => Str, { required => 'schema', pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::RetainConfig - retain defines the config for retention when the retention policy is set to `Retain`.

=head1 VERSION

version 1.108

=head2 retentionPeriod

retentionPeriod defines how long the scaled-down shard(s) need to be
kept before being deleted.

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
