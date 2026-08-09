package Kubernetes::REST::CLI::Cmd::Create;
our $VERSION = '1.106';
# ABSTRACT: The create command of kube_client
use Moo;
use MooX::Options;
use MooX::Cmd;


option file => (
    is => 'ro',
    format => 's',
    short => 'f',
    doc => 'File to read (- for stdin)',
    default => sub { '-' },
);


sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];

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

    my $obj = $root->api->inflate($input);
    my $result = $root->api->create($obj);
    $root->format_output($result);
    return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::CLI::Cmd::Create - The create command of kube_client

=head1 VERSION

version 1.106

=head1 SYNOPSIS

    kube_client create -f <file>
    kube_client create -f -        # read from stdin

=head1 DESCRIPTION

Implements the C<create> command of L<Kubernetes::REST::CLI>. Reads a YAML or
JSON manifest, inflates it into a typed L<IO::K8s> object and creates it on the
cluster. L<MooX::Cmd> finds and loads this class, you do not use it directly.

=head2 file

Path of the manifest to create, C<-> for stdin. Short form: C<-f>. Defaults to
C<->.

=head2 execute

Runs the command. Called by L<MooX::Cmd> with the remaining arguments and the
command chain, whose first element is the L<Kubernetes::REST::CLI> root object.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST::CLI> - CLI base class

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
