package IO::K8s::GatewayAPI::V1beta1::ListenerNamespaces;
# ABSTRACT: Namespaces defines which namespaces ListenerSets can be attached to this Gateway.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s from     => Str, { enum => [qw(All Selector Same None)], default => 'None' };
k8s selector => 'Meta::V1::LabelSelector';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::ListenerNamespaces - Namespaces defines which namespaces ListenerSets can be attached to this Gateway.

=head1 VERSION

version 1.108

=head2 from

From indicates where ListenerSets can attach to this Gateway. Possible
values are:

* Same: Only ListenerSets in the same namespace may be attached to this Gateway.
* Selector: ListenerSets in namespaces selected by the selector may be attached to this Gateway.
* All: ListenerSets in all namespaces may be attached to this Gateway.
* None: Only listeners defined in the Gateway's spec are allowed

The default value None

=head2 selector

Selector must be specified when From is set to "Selector". In that case,
only ListenerSets in Namespaces matching this Selector will be selected by this
Gateway. This field is ignored for other values of "From".

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
