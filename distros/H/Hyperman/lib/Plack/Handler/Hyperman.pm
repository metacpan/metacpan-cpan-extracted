package Plack::Handler::Hyperman;

use strict;
use warnings;
use Hyperman ();

our $VERSION = '0.16';

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

# Plack's runner passes `listen` as an arrayref of listen specs - "host:port"
# or ":port" strings (from --listen, or synthesised from --host/--port). Turn
# each into a Hyperman listener hashref; an entry that is already a hashref
# (native Hyperman per-listener config) is passed through untouched.
sub _parse_listen {
    my $spec = shift;
    return $spec if ref $spec eq 'HASH';
    die "Plack::Handler::Hyperman: UNIX socket listeners are not supported "
      . "(got '$spec')\n" if $spec =~ m{/};
    if ($spec =~ /\A(.*):(\d+)\z/) {
        return { (length $1 ? (host => $1) : ()), port => $2 + 0 };
    }
    return { port => $spec + 0 } if $spec =~ /\A\d+\z/;
    die "Plack::Handler::Hyperman: cannot parse listen spec '$spec'\n";
}

sub run {
    my ($self, $app) = @_;
    my %args = (
        app     => $app,
        workers => (defined $self->{workers}     ? $self->{workers}
                  : defined $self->{max_workers} ? $self->{max_workers}
                  : 0),                            # 0 = ncpu
        map { defined $self->{$_} ? ($_ => $self->{$_}) : () }
            qw(reuseport max_requests_per_worker shutdown_grace affinity
               idle_timeout header_timeout max_pipeline http2 redirect_https
               tls_cert tls_key tls_ca tls_verify tls_sni),
    );

    if ($self->{listen} && @{ $self->{listen} }) {
        $args{listen} = [ map { _parse_listen($_) } @{ $self->{listen} } ];
    } else {
        $args{host} = defined $self->{host} ? $self->{host} : '0.0.0.0';
        $args{port} = defined $self->{port} ? $self->{port} : 8080;
    }

    Hyperman->run(%args);
}

1;

__END__

=head1 NAME

Plack::Handler::Hyperman - Plack/PSGI adapter for the Hyperman server

=head1 SYNOPSIS

    plackup -s Hyperman --port 8080 --workers 6 app.psgi

=head1 DESCRIPTION

Lets any Plack application run on L<Hyperman>, the kqueue event-loop PSGI
server. Options: C<host>, C<port>, and C<workers> (alias C<max_workers>), plus
C<listen> for binding several listeners (for example plain :80 beside TLS :443)
in one server - see L<Hyperman/"Multiple listeners">.

=head1 SEE ALSO

L<Hyperman>, L<Plack>

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
