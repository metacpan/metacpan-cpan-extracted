package Kubernetes::REST::CLI::Cmd::Create;
our $VERSION = '1.107';
# ABSTRACT: The create command of kube_client
use Moo;
use MooX::Options;
use MooX::Cmd;
use Encode ();


option file => (
    is => 'ro',
    format => 's',
    short => 'f',
    doc => 'File to read (- for stdin)',
    default => sub { '-' },
);


sub _source {
    my ($self) = @_;
    return $self->file eq '-' ? 'stdin' : $self->file;
}

sub _read_input {
    my ($self) = @_;

    my $input;
    if ($self->file eq '-') {
        local $/;
        $input = <STDIN>;
    } else {
        open my $fh, '<', $self->file or die "Cannot open " . $self->file . ": $!";
        local $/;
        $input = <$fh>;
        close $fh;
    }

    return defined $input ? $input : '';
}

sub _parse_manifest {
    my ($self, $api, $input) = @_;

    die "Empty manifest read from " . $self->_source . "\n"
        unless defined $input && $input =~ /\S/;

    # A JSON manifest is a JSON object, so after optional whitespace it starts
    # with a brace, while a YAML manifest starts with a key, a comment or '---'.
    # YAML is a superset of JSON and would parse both, but routing JSON to
    # inflate() leaves the path it already took completely untouched: the same
    # decoder, the same UTF-8 bytes straight in (that decoder is utf8 => 1, so
    # there is no decode step to get wrong) and JSON error messages, with a
    # character offset, for someone who wrote JSON.
    return $api->inflate($input) if $input =~ /\A\s*\{/;

    # load_yaml() parses characters, not bytes - handing it the raw bytes turns
    # every non-ASCII value into mojibake. It also treats a newline-free
    # argument as a file name, which the trailing newline keeps us out of.
    $input .= "\n" unless $input =~ /\n/;
    my $objects = $api->load_yaml(Encode::decode('UTF-8', $input));

    die "No Kubernetes manifest documents found in " . $self->_source . "\n"
        unless @$objects;

    return @$objects;
}

sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];

    my @objects = $self->_parse_manifest($root->api, $self->_read_input);
    my $multi = @objects > 1;

    for my $i (0 .. $#objects) {
        my $obj = $objects[$i];
        my $result = eval { $root->api->create($obj) };
        if (my $error = $@) {
            # A single-document manifest reports its own error unchanged; in a
            # multi-document one the caller cannot tell which document failed.
            die $error unless $multi;
            die sprintf "Document %d of %d (%s) in %s failed: %s",
                $i + 1, scalar @objects, $obj->kind, $self->_source, $error;
        }
        $root->format_output($result);
    }

    return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI::Cmd::Create - The create command of kube_client

=head1 VERSION

version 1.107

=head1 SYNOPSIS

    kube_client create -f <file>
    kube_client create -f -        # read from stdin

=head1 DESCRIPTION

Implements the C<create> command of L<Kubernetes::REST::CLI>. Reads a YAML or
JSON manifest, inflates it into typed L<IO::K8s> objects (the class of each
document is auto-detected from its C<kind> field) and creates them on the
cluster. L<MooX::Cmd> finds and loads this class, you do not use it directly.

The format is detected from the content, not from the file name, so C<-f -> is
covered as well as C<-f file.yaml>: a manifest starting with C<{> after
optional whitespace goes to L<Kubernetes::REST/inflate> as before, anything
else is parsed as YAML by L<Kubernetes::REST/load_yaml>.

Multi-document YAML (C<--->-separated) is supported and is the common case for
Kubernetes manifests. Each document is created in the order it appears in the
file - which is what makes a manifest listing a C<Namespace> before the objects
inside it work - and each created object is printed through
L<Kubernetes::REST::CLI/format_output>. With C<--output yaml> that is a
C<--->-separated stream again; with the default C<--output json> it is one JSON
document per created object. If a document fails, the documents before it have
already been created and the error names the one that failed.

=head2 file

Path of the manifest to create, C<-> for stdin. Short form: C<-f>. Defaults to
C<->.

=head2 execute

Runs the command. Called by L<MooX::Cmd> with the remaining arguments and the
command chain, whose first element is the L<Kubernetes::REST::CLI> root object.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST::CLI> - CLI base class

=item * L<Kubernetes::REST/load_yaml> - The YAML reader this command parses manifests with

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
