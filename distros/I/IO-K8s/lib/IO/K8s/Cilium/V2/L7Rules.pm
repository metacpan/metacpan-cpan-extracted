package IO::K8s::Cilium::V2::L7Rules;
# ABSTRACT: Rules is a list of additional port level rules which must be met in order for the PortRule to allow the traffic.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s dns  => ['+IO::K8s::Cilium::V2::PortRuleDNS'];
k8s http => ['+IO::K8s::Cilium::V2::PortRuleHTTP'];



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::L7Rules - Rules is a list of additional port level rules which must be met in order for the PortRule to allow the traffic.

=head1 VERSION

version 1.108

=head2 dns

DNS-specific rules.

=head2 http

HTTP specific rules.

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
