package Kubernetes::REST::CLI::Role::Connection;
our $VERSION = '1.103';
# ABSTRACT: Shared kubeconfig/auth options for CLI tools
use Moo::Role;
use MooX::Options;
use Kubernetes::REST::Kubeconfig;


option kubeconfig => (
    is => 'ro',
    format => 's',
    doc => 'Path to kubeconfig file',
    default => sub { "$ENV{HOME}/.kube/config" },
);


option context => (
    is => 'ro',
    format => 's',
    short => 'c',
    doc => 'Kubernetes context to use',
);


has api => (
    is => 'lazy',
    builder => sub {
        my $self = shift;
        my $kc = Kubernetes::REST::Kubeconfig->new(
            kubeconfig_path => $self->kubeconfig,
            ($self->context ? (context_name => $self->context) : ()),
        );
        return $kc->api;
    },
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI::Role::Connection - Shared kubeconfig/auth options for CLI tools

=head1 VERSION

version 1.103

=head1 DESCRIPTION

Moo role providing C<--kubeconfig> and C<--context> options and a lazy C<api> attribute that builds a L<Kubernetes::REST> instance from the kubeconfig.

Consumed by L<Kubernetes::REST::CLI> and L<Kubernetes::REST::CLI::Watch>.

=head2 kubeconfig

Path to kubeconfig file. Defaults to C<~/.kube/config>.

=head2 context

Kubernetes context to use from the kubeconfig. Defaults to the current-context.

Short option: C<-c>

=head2 api

Lazy L<Kubernetes::REST> instance built from the kubeconfig.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST::Kubeconfig> - Kubeconfig parser

=item * L<Kubernetes::REST::CLI> - CLI base class

=item * L<Kubernetes::REST::CLI::Watch> - Watch CLI tool

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
