package IO::K8s::Role::Namespaced;
our $VERSION = '1.008';
# ABSTRACT: Role for Kubernetes resources that live in a namespace
use Moo::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::Namespaced - Role for Kubernetes resources that live in a namespace

=head1 VERSION

version 1.008

=head1 SYNOPSIS

    package IO::K8s::Api::Core::V1::Pod;
    use IO::K8s::APIObject;
    with 'IO::K8s::Role::Namespaced';

=head1 DESCRIPTION

This role marks Kubernetes resources that are namespace-scoped (as opposed to
cluster-scoped). Resources like Pods, Services, Deployments, etc. consume this
role. Cluster-scoped resources like Nodes, Namespaces, ClusterRoles do not.

You can check if a resource is namespaced:

    if ($class->does('IO::K8s::Role::Namespaced')) {
        print "This resource is namespace-scoped\n";
    }

=head1 NAME

IO::K8s::Role::Namespaced - Role for Kubernetes resources that live in a namespace

=head1 SEE ALSO

L<IO::K8s::Role::APIObject>, L<IO::K8s::APIObject>

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
