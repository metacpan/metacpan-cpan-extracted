package Plack::Handler::Hyperman;

use strict;
use warnings;
use Hyperman ();

our $VERSION = '0.02';

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub run {
    my ($self, $app) = @_;
    Hyperman->run(
        app     => $app,
        host    => (defined $self->{host} ? $self->{host} : '0.0.0.0'),
        port    => (defined $self->{port} ? $self->{port} : 8080),
        workers => (defined $self->{workers}     ? $self->{workers}
                  : defined $self->{max_workers} ? $self->{max_workers}
                  : 0),                            # 0 = ncpu
        map { defined $self->{$_} ? ($_ => $self->{$_}) : () }
            qw(reuseport max_requests_per_worker shutdown_grace affinity
               idle_timeout header_timeout max_pipeline http2
               tls_cert tls_key tls_ca tls_verify tls_sni),
    );
}

1;

__END__

=head1 NAME

Plack::Handler::Hyperman - Plack/PSGI adapter for the Hyperman server

=head1 SYNOPSIS

    plackup -s Hyperman --port 8080 --workers 6 app.psgi

=head1 DESCRIPTION

Lets any Plack application run on L<Hyperman>, the kqueue event-loop PSGI
server. Options: C<host>, C<port>, and C<workers> (alias C<max_workers>).

=head1 SEE ALSO

L<Hyperman>, L<Plack>

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
