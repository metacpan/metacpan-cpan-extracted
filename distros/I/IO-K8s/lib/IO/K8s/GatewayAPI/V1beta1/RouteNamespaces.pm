package IO::K8s::GatewayAPI::V1beta1::RouteNamespaces;
# ABSTRACT: Namespaces indicates namespaces from which Routes may be attached to this Listener.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s from     => Str, { enum => [qw(All Selector Same)], default => 'Same' };
k8s selector => 'Meta::V1::LabelSelector';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::RouteNamespaces - Namespaces indicates namespaces from which Routes may be attached to this Listener.

=head1 VERSION

version 1.108

=head2 from

From indicates where Routes will be selected for this Gateway. Possible
values are:

* All: Routes in all namespaces may be used by this Gateway.
* Selector: Routes in namespaces selected by the selector may be used by
  this Gateway.
* Same: Only Routes in the same namespace may be used by this Gateway.

Support: Core

=head2 selector

Selector must be specified when From is set to "Selector". In that case,
only Routes in Namespaces matching this Selector will be selected by this
Gateway. This field is ignored for other values of "From".

Support: Core

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
