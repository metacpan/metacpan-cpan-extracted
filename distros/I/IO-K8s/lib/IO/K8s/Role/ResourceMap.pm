package IO::K8s::Role::ResourceMap;
# ABSTRACT: Role for packages that provide a Kubernetes resource map
our $VERSION = '1.009';
use Moo::Role;

requires 'resource_map';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::ResourceMap - Role for packages that provide a Kubernetes resource map

=head1 VERSION

version 1.009

=head1 SYNOPSIS

    package IO::K8s::Cilium;
    use Moo;
    with 'IO::K8s::Role::ResourceMap';

    sub resource_map {
        return {
            CiliumNetworkPolicy => '+IO::K8s::Cilium::V2::CiliumNetworkPolicy',
            NetworkPolicy       => '+IO::K8s::Cilium::V2::NetworkPolicy',
        };
    }

    1;

=head1 DESCRIPTION

This role marks packages that provide a Kubernetes resource map, mapping
short kind names to class paths. Packages consuming this role can be passed
to L<IO::K8s/add> or the L<IO::K8s/with> constructor parameter to merge
their resources into an IO::K8s instance.

The C<resource_map> method must return a hashref mapping kind names (like
C<CiliumNetworkPolicy>) to class paths. Class paths without a C<+> prefix
are relative to C<IO::K8s::>. Class paths with a C<+> prefix are used as-is.

=head1 NAME

IO::K8s::Role::ResourceMap - Role for packages that provide a Kubernetes resource map

=head1 REQUIRED METHODS

=head2 resource_map

Must return a HashRef mapping kind names to class paths.

=head1 SEE ALSO

L<IO::K8s>, L<IO::K8s/add>

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
