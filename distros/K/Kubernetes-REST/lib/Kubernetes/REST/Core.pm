package Kubernetes::REST::Core;
our $VERSION = '1.104';
# ABSTRACT: DEPRECATED - v0 API group for Core resources
use Moo;
extends 'Kubernetes::REST::V0Group';
has '+group' => (default => sub { 'Core' });


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::Core - DEPRECATED - v0 API group for Core resources

=head1 VERSION

version 1.104

=head1 SYNOPSIS

    # DEPRECATED API - use the new v1 API instead

    # Old way (deprecated):
    my $pods = $api->Core->ListNamespacedPod(namespace => 'default');

    # New way:
    my $pods = $api->list('Pod', namespace => 'default');

=head1 DESCRIPTION

B<This module is DEPRECATED>. It provides backwards compatibility for the v0 API (Kubernetes::REST 0.01/0.02 by JLMARTIN) which used method names like C<< $api->Core->ListNamespacedPod(...) >>.

The new v1 API uses simple methods directly on the main L<Kubernetes::REST> object:

    $api->list('Pod', ...)
    $api->get('Pod', 'name', ...)
    $api->create($pod)
    $api->update($pod)
    $api->delete($pod)

All calls to this module emit deprecation warnings unless C<$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}> is set.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main module with v1 API

=item * L<Kubernetes::REST::V0Group> - Base class for v0 compatibility layer

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

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

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
