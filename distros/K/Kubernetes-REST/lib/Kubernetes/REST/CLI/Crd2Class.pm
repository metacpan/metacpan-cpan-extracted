package Kubernetes::REST::CLI::Crd2Class;
our $VERSION = '1.108';
# ABSTRACT: Generate IO::K8s classes from a CustomResourceDefinition
use Moo;
with 'Kubernetes::REST::CLI::Role::Connection';
use MooX::Options;
use Carp qw( croak );
use Path::Tiny qw( path );
use IO::K8s::CRD ();
use IO::K8s::CRD::Emitter ();


option file => (
    is => 'ro',
    format => 's',
    short => 'f',
    doc => 'Path to a CustomResourceDefinition YAML/JSON file',
);


option namespace => (
    is => 'ro',
    format => 's',
    short => 'n',
    doc => 'Base package for the generated classes (default: derived from the CRD group)',
);


option output_dir => (
    is => 'ro',
    format => 's',
    short => 'd',
    doc => 'Write the .pm files under this directory instead of printing them',
);


option from_cluster => (
    is => 'ro',
    format => 's',
    doc => 'Generate from a Kind whose CRD a live cluster already serves',
);



sub run {
    my ($self) = @_;

    my $from_cluster = $self->from_cluster;
    my $file         = $self->file;

    my $crds;
    if (defined $from_cluster && length $from_cluster) {
        $crds = $self->_crds_from_cluster($from_cluster);
    }
    elsif (defined $file && length $file) {
        croak "kube_crd2class: no such file: $file\n" unless -f $file;
        $crds = IO::K8s::CRD->load($file);
    }
    else {
        croak "kube_crd2class: no input given; pass --file/-f <crd.yaml> "
            . "or --from-cluster <Kind>\n";
    }

    binmode STDOUT, ':encoding(UTF-8)';

    my $files = $self->_render_crds($crds);

    if (defined $self->output_dir && length $self->output_dir) {
        $self->_write_files($files);
    }
    else {
        $self->_print_files($files);
    }
    return 0;
}

# The CRD hashref(s) for one Kind served by the cluster, in the shape
# IO::K8s::CRD->load returns (so _render_crds drives the same pipeline as -f):
# list the cluster's CustomResourceDefinitions through the shared api, keep the
# one whose spec.names.kind matches, and normalize it through ->load - which
# takes a CustomResourceDefinition object straight, via its TO_JSON. A Kind
# served by no CRD, or by several (same kind in different groups), dies clearly.
sub _crds_from_cluster {
    my ($self, $kind) = @_;

    my $list = $self->api->list('CustomResourceDefinition');
    my @matches = grep {
        my $names = $_->spec && $_->spec->names;
        $names && defined $names->kind && $names->kind eq $kind;
    } @{ $list->items };

    croak "kube_crd2class: no CustomResourceDefinition on the cluster serves "
        . "kind '$kind'\n" unless @matches;
    croak "kube_crd2class: kind '$kind' is served by more than one "
        . "CustomResourceDefinition (" . join(', ', map { $_->metadata->name } @matches)
        . "); nothing here can pick between them\n" if @matches > 1;

    return IO::K8s::CRD->load($matches[0]);
}

# An arrayref of [ relative_path, api_version, source ] blocks for every
# served version of every loaded CRD, in manifest order - the whole
# schema-to-DSL job delegated to IO::K8s (load/served_versions/generate/render).
sub _render_crds {
    my ($self, $crds) = @_;
    my @out;
    for my $crd (@$crds) {
        my $ns       = $self->_namespace_for($crd);
        my $versions = IO::K8s::CRD->served_versions($crd);
        # reuse_core on (D5) - a nested schema shaped like a shipped core
        # class is typed as that class rather than a per-CRD copy.
        my $classes  = IO::K8s::CRD->generate($crd, $ns, reuse_core => 1);
        for my $v (@$versions) {
            my $root = $classes->{ $v->{api_version} } or next;
            my $emitter = IO::K8s::CRD::Emitter->new(
                base => $ns . '::' . ucfirst($v->{name}),
            );
            my $rendered = $emitter->render($root);
            push @out, map { [ $_, $v->{api_version}, $rendered->{$_} ] }
                sort keys %$rendered;
        }
    }
    return \@out;
}

# The base package for one CRD: --namespace when given, otherwise
# IO::K8s::<CamelCase leading DNS label of the group>.
sub _namespace_for {
    my ($self, $crd) = @_;
    return $self->namespace if defined $self->namespace && length $self->namespace;
    my $group = $crd->{spec}{group} // '';
    my ($label) = split /\./, $group;
    $label = 'Crd' unless defined $label && length $label;
    my $camel = join '', map { ucfirst } split /-/, $label;
    return 'IO::K8s::' . $camel;
}

sub _print_files {
    my ($self, $files) = @_;
    my @blocks = @$files;
    for my $i (0 .. $#blocks) {
        my ($path, $api_version, $source) = @{ $blocks[$i] };
        print "\n" if $i;
        print '# ', ('=' x 74), "\n";
        print "# $path  ($api_version)\n";
        print '# ', ('=' x 74), "\n";
        print $source;
    }
    return;
}

sub _write_files {
    my ($self, $files) = @_;
    my $dir = path($self->output_dir);
    for my $block (@$files) {
        my ($path, undef, $source) = @$block;
        my $target = $dir->child($path);
        $target->parent->mkpath;
        $target->spew_utf8($source);
        print STDERR "wrote $target\n";
    }
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI::Crd2Class - Generate IO::K8s classes from a CustomResourceDefinition

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    use Kubernetes::REST::CLI::Crd2Class;

    my $cli = Kubernetes::REST::CLI::Crd2Class->new_with_options;
    exit $cli->run;

=head1 DESCRIPTION

L<MooX::Options>-based class that powers the L<kube_crd2class> CLI tool: the
D15 wrapper around the D10 source emitter. It reads a
C<CustomResourceDefinition> from a file and prints, for every B<served>
version, the checked-in, documented L<IO::K8s> class source that models it -
the C<k8s> DSL block plus a POD skeleton - so a cluster's CRDs can become
typed, hand-maintained Perl classes without writing them by hand (the
kopium / C<cdk8s import> path).

The schema-to-DSL work is entirely L<IO::K8s>'s: L<IO::K8s::CRD/load>,
L<IO::K8s::CRD/served_versions> and L<IO::K8s::CRD/generate> build the
classes and L<IO::K8s::CRD::Emitter/render> renders them. This class is only
the CLI hull: file in, emitter, source out.

The C<-f> path never talks to a cluster: it builds the L<api|/api> lazily
through L<Kubernetes::REST::CLI::Role::Connection>, so reading a file reads no
kubeconfig. The C</from_cluster> path uses that same C<api> to list the
cluster's C<CustomResourceDefinition>s, picks the one whose C<spec.names.kind>
matches the given Kind, and feeds its manifest through the very same emitter
pipeline as C<-f> - so the two inputs produce identical source for the same
CRD.

=head2 file

Path to a file holding one or more C<CustomResourceDefinition> manifests
(YAML, possibly multi-document, or JSON). Every served version of every CRD
in the file is turned into class source.

Short option: C<-f>

=head2 namespace

The base package the generated classes are rendered under, without the
version segment: C<IO::K8s::MyProvider> yields C<IO::K8s::MyProvider::V1::Kind>
for a served C<v1>. When omitted a default is derived from the CRD group's
leading DNS label (C<cert-manager.io> becomes C<IO::K8s::CertManager>). Per
served version the version name is appended, C<< ucfirst >>-ed the way the
D6 provider namespaces are (C<v1alpha1> becomes C<V1alpha1>).

Short option: C<-n>

=head2 output_dir

When set, each rendered class is written to
F<E<lt>output_dirE<gt>/E<lt>relative/pathE<gt>.pm> (intermediate directories
created) instead of being printed to STDOUT, and the path written is logged to
STDERR. Without it every class is printed to STDOUT, each under a banner
naming its relative path and the C<apiVersion> it models.

Short option: C<-d>

=head2 from_cluster

A Kubernetes B<Kind> (for example C<CronTab>) that a live cluster already
serves through a C<CustomResourceDefinition>. The cluster's CRDs are listed
through L</api> and the one whose C<spec.names.kind> matches is turned into
class source for every served version, exactly as L</file> would from that
CRD's manifest. Dies clearly when no CRD - or more than one - serves the Kind.

Reaching the cluster needs a kubeconfig, so this path honours C<--kubeconfig>
and C<--context> from L<Kubernetes::REST::CLI::Role::Connection>; the L</file>
path reads neither.

=head2 run

    my $exit_code = $cli->run;

Entry point called by C<bin/kube_crd2class>. Obtains one or more CRD manifests
- from L</file>, or from the cluster by Kind when L</from_cluster> is given -
and for every served version of every CRD renders the L<IO::K8s> class source
through L<IO::K8s::CRD::Emitter>, printing it to STDOUT or writing it under
L</output_dir> when that is set. Returns 0.

Dies with usage guidance when neither input is supplied, when the L</file> does
not exist, or when L</from_cluster> names a Kind the cluster does not serve
through exactly one C<CustomResourceDefinition>.

=head1 SEE ALSO

=over

=item * L<kube_crd2class> - The CLI tool built on this class

=item * L<IO::K8s::CRD> - Loads a CRD and generates one class per served version

=item * L<IO::K8s::CRD::Emitter> - Renders those classes as house-style source

=item * L<Kubernetes::REST> - The client whose CRD support this generates classes for

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
