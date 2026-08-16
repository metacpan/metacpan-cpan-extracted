package Kubernetes::REST::CLI::Role::Connection;
our $VERSION = '1.107';
# ABSTRACT: Shared kubeconfig/auth options for CLI tools
use Moo::Role;
use MooX::Options;
use Kubernetes::REST::Kubeconfig;


# Deliberately without a default: an option that always has a value is always
# passed on, and Kubernetes::REST::Kubeconfig never reaches its own default of
# $ENV{KUBECONFIG} // ~/.kube/config. Leaving it undef when the user did not ask
# for a path is what lets the environment variable through.
option kubeconfig => (
    is => 'ro',
    format => 's',
    doc => 'Path to kubeconfig file (default: $KUBECONFIG, else ~/.kube/config)',
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
        # kubeconfig_path is only passed when --kubeconfig was given, so an
        # unset option falls through to Kubeconfig's own $ENV{KUBECONFIG}
        # default rather than being overridden by a home-directory guess.
        my $kc = Kubernetes::REST::Kubeconfig->new(
            (defined $self->kubeconfig ? (kubeconfig_path => $self->kubeconfig) : ()),
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

version 1.107

=head1 DESCRIPTION

Moo role providing C<--kubeconfig> and C<--context> options and a lazy C<api> attribute that builds a L<Kubernetes::REST> instance from the kubeconfig.

Consumed by L<Kubernetes::REST::CLI> and L<Kubernetes::REST::CLI::Watch>.

=head2 kubeconfig

Path to kubeconfig file. Without it the C<KUBECONFIG> environment variable is
used, and without that C<~/.kube/config> - the same precedence C<kubectl> and
L<Kubernetes::REST::Kubeconfig> apply. An explicitly given C<--kubeconfig> wins
over C<KUBECONFIG>.

C<KUBECONFIG> may name several files as the C<:>-separated list C<kubectl>
merges, in which case they are merged the same way - see
L<Kubernetes::REST::Kubeconfig/MERGING>. C<--kubeconfig> takes such a list too,
since it is passed straight through.

=head2 context

Kubernetes context to use from the kubeconfig. Defaults to the current-context.

Short option: C<-c>

=head2 api

Lazy L<Kubernetes::REST> instance built from the kubeconfig.

The kubeconfig it is built from is C<--kubeconfig> if given, otherwise
C<$ENV{KUBECONFIG}>, otherwise C<~/.kube/config>. Either of the first two may
be a C<:>-separated list of files, which is merged as C<kubectl> merges it.

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

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
