package IO::K8s::Api::Core::V1::Affinity;
# ABSTRACT: Affinity is a group of affinity scheduling rules.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s nodeAffinity => 'Core::V1::NodeAffinity';


k8s podAffinity => 'Core::V1::PodAffinity';


k8s podAntiAffinity => 'Core::V1::PodAntiAffinity';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::Affinity - Affinity is a group of affinity scheduling rules.

=head1 VERSION

version 1.009

=head2 nodeAffinity

Describes node affinity scheduling rules for the pod.

=head2 podAffinity

Describes pod affinity scheduling rules (e.g. co-locate this pod in the same node, zone, etc. as some other pod(s)).

=head2 podAntiAffinity

Describes pod anti-affinity scheduling rules (e.g. avoid putting this pod in the same node, zone, etc. as some other pod(s)).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
