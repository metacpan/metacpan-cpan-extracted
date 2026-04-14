package IPC::Manager::Service::Echo;
use strict;
use warnings;

our $VERSION = '0.000019';

use Object::HashBase qw{
    <name
    <orig_io
    <ipcm_info
    <redirect

    use_posix_exit
    intercept_errors
    watch_pids
};

use Role::Tiny::With;

sub pid     { $_[0]->{pid} }
sub set_pid { $_[0]->{pid} = $_[1] }

sub handle_request {
    my ($self, $req, $msg) = @_;
    return "echo: $req->{request}";
}

with 'IPC::Manager::Role::Service';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Service::Echo - Service that echoes back request content

=head1 DESCRIPTION

A lightweight service that echoes every request back to the caller.  For
each incoming request the response is the string C<"echo: "> followed by the
request payload.

This is useful for smoke-testing IPC connectivity, verifying that the
C<exec> service code path works, and as a minimal example of a custom
service class that composes L<IPC::Manager::Role::Service>.

=head1 SYNOPSIS

    use IPC::Manager qw/ipcm_service/;

    # In-process (forked) echo service
    my $handle = ipcm_service('echo', class => 'IPC::Manager::Service::Echo');

    my $resp = $handle->sync_request(echo => "hello");
    # $resp->{response} is "echo: hello"

    $handle = undef;    # shuts down the service

    # Via exec (fresh interpreter)
    my $handle = ipcm_service(
        'echo',
        class => 'IPC::Manager::Service::Echo',
        exec  => { cmd => [] },
    );

=head1 METHODS

=over 4

=item $response = $svc->handle_request($req, $msg)

Returns C<"echo: $req-E<gt>{request}">.

=back

See L<IPC::Manager::Role::Service> for inherited methods.

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
