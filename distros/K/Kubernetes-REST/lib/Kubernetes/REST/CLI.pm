package Kubernetes::REST::CLI;
# ABSTRACT: CLI base class for Kubernetes::REST command-line tools
our $VERSION = '1.107';
use Moo;
use MooX::Options;
use MooX::Cmd;
use JSON::MaybeXS;

with 'Kubernetes::REST::CLI::Role::Connection';


option namespace => (
    is => 'ro',
    format => 's',
    short => 'n',
    default => sub { 'default' },
    doc => 'Namespace for namespaced resources',
);


option output => (
    is => 'ro',
    format => 's',
    short => 'o',
    default => sub { 'json' },
    doc => 'Output format: json, yaml, name',
);


has json => (
    is => 'ro',
    default => sub { JSON::MaybeXS->new->pretty->canonical->utf8 },
);


sub format_output {
    my ($self, $result) = @_;
    return unless defined $result;

    my $format = $self->output;

    if ($format eq 'json') {
        my $data = ref($result) && $result->can('TO_JSON') ? $result->TO_JSON : $result;
        print $self->json->encode($data);
    } elsif ($format eq 'yaml') {
        require YAML::XS;
        my $data = ref($result) && $result->can('TO_JSON') ? $result->TO_JSON : $result;
        print YAML::XS::Dump($data);
    } elsif ($format eq 'name') {
        if (ref($result) && $result->can('items')) {
            for my $item (@{$result->items // []}) {
                my $meta = $item->metadata;
                my $ns = $meta->namespace ? $meta->namespace . '/' : '';
                print $ns, $meta->name, "\n";
            }
        } elsif (ref($result) && $result->can('metadata')) {
            my $meta = $result->metadata;
            my $ns = $meta->namespace ? $meta->namespace . '/' : '';
            print $ns, $meta->name, "\n";
        }
    } else {
        require Data::Dumper;
        print Data::Dumper::Dumper($result);
    }
}


sub execute {
    my ($self, $args, $chain) = @_;
    print "Usage: kube_client <command> [options]\n\n";
    print "Commands:\n";
    print "  get <Kind> [name]     Get resource(s)\n";
    print "  create -f <file>      Create resource from file\n";
    print "  delete <Kind> <name>  Delete resource\n";
    print "  raw <Group> <Method>  Raw API call\n";
    print "\nRun 'kube_client --help' for options.\n";
    print "See also: kube_watch <Kind> for live event streaming.\n";
    return 0;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI - CLI base class for Kubernetes::REST command-line tools

=head1 VERSION

version 1.107

=head1 SYNOPSIS

    kube_client <command> [options]

    # Get resources
    kube_client get Pod my-pod -n default
    kube_client get Deployment --output yaml

    # Create from file
    kube_client create -f deployment.yaml

    # Delete resources
    kube_client delete Pod my-pod -n default

=head1 DESCRIPTION

Base class for the C<kube_client> command-line tool. Provides common functionality for managing Kubernetes resources from the command line.

This tool uses L<Kubernetes::REST::Kubeconfig> to connect to the cluster: C<--kubeconfig> if given, otherwise the C<KUBECONFIG> environment variable, otherwise C<~/.kube/config>. A C<:>-separated list of kubeconfig files is merged the way C<kubectl> merges it, see L<Kubernetes::REST::Kubeconfig/MERGING>.

=head1 COMMANDS

=head2 get

    kube_client get <Kind> [name] [options]

Get a resource or list resources.

=over

=item B<get Pod> - List all pods in the namespace

=item B<get Pod my-pod> - Get a specific pod

=item B<--output json> (default) - JSON output

=item B<--output yaml> - YAML output

=item B<--output name> - Names only

=back

=head2 create

    kube_client create -f <file>

Create resources from a YAML or JSON manifest. Use C<-f -> to read from stdin.
The format is detected from the content, and multi-document YAML creates every
C<--->-separated document in order.

=head2 delete

    kube_client delete <Kind> <name> [options]

Delete a resource by name.

=head2 raw

    kube_client raw <Group> <Method> [key=value ...]

Make a raw call through the deprecated v0 API.

=head1 GLOBAL OPTIONS

=head2 namespace

Namespace for namespaced resources. Defaults to C<default>.

Short form: C<-n>

=head2 output

Output format. One of: C<json>, C<yaml>, C<name>.

Defaults to C<json>.

Short form: C<-o>

=head1 ATTRIBUTES

=head2 json

L<JSON::MaybeXS> encoder instance used for C<--output json>. Configured
C<pretty>, C<canonical> (stable key ordering) and C<utf8> - the C<utf8> flag
is what makes C<format_output> print UTF-8 bytes instead of characters, so
non-ASCII values survive the way to the terminal instead of triggering "Wide
character in print".

=head1 METHODS

=head2 format_output

    $cli->format_output($result);

Format and print the result according to the C<--output> option
(C<json>, C<yaml>, or C<name>). Any other value falls back to a raw dump via
L<Data::Dumper>, mainly useful for debugging.

=head2 execute

Default C<execute> method, invoked by L<MooX::Cmd> when C<kube_client> is run
without a recognized subcommand. Prints usage information to STDOUT.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API module

=item * L<Kubernetes::REST::CLI::Cmd::Get> - The get command

=item * L<Kubernetes::REST::CLI::Cmd::Create> - The create command

=item * L<Kubernetes::REST::CLI::Cmd::Delete> - The delete command

=item * L<Kubernetes::REST::CLI::Cmd::Raw> - The raw command

=item * L<Kubernetes::REST::CLI::Watch> - Watch command implementation

=item * L<Kubernetes::REST::CLI::Role::Connection> - Connection options

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
