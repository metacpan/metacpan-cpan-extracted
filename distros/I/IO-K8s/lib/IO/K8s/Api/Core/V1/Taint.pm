package IO::K8s::Api::Core::V1::Taint;
# ABSTRACT: The node this Taint is attached to has the "effect" on any pod that does not tolerate the Taint.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s effect => Str, 'required';


k8s key => Str, 'required';


k8s timeAdded => Time;


k8s value => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::Taint - The node this Taint is attached to has the "effect" on any pod that does not tolerate the Taint.

=head1 VERSION

version 1.009

=head2 effect

Required. The effect of the taint on pods that do not tolerate the taint. Valid effects are NoSchedule, PreferNoSchedule and NoExecute.

=head2 key

Required. The taint key to be applied to a node.

=head2 timeAdded

TimeAdded represents the time at which the taint was added. It is only written for NoExecute taints.

=head2 value

The taint value corresponding to the taint key.

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
