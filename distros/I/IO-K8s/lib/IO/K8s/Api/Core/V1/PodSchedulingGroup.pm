package IO::K8s::Api::Core::V1::PodSchedulingGroup;
# ABSTRACT: PodSchedulingGroup is used to associate a Pod with the PodGroup runtime instance it belongs to for gang-scheduling purposes.
our $VERSION = '1.105';
use IO::K8s::Resource;

k8s podGroupName => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PodSchedulingGroup - PodSchedulingGroup is used to associate a Pod with the PodGroup runtime instance it belongs to for gang-scheduling purposes.

=head1 VERSION

version 1.105

=head2 podGroupName

PodGroupName is the name of a PodGroup object in the scheduling.k8s.io group that this pod belongs to for gang-scheduling purposes. The PodGroup must exist in the same namespace as this pod.

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
