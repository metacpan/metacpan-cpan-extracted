package Plack::Handler::Hyperman;

use strict;
use warnings;
use Hyperman ();

our $VERSION = '0.63';

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub _parse_listen {
    my $spec = shift;
    return $spec if ref $spec eq 'HASH';
    return { path => $spec } if $spec =~ m{/};        # a unix-domain socket
    if ($spec =~ /\A\[([^\]]+)\]:(\d+)\z/) {        # [::1]:8080
        return { host => $1, port => $2 + 0 };
    }
    if ($spec =~ /\A(.*):(\d+)\z/) {
        return { (length $1 ? (host => $1) : ()), port => $2 + 0 };
    }
    return { port => $spec + 0 } if $spec =~ /\A\d+\z/;
    die "Plack::Handler::Hyperman: cannot parse listen spec '$spec'\n";
}

my @PASS = qw(reuseport completion max_requests_per_worker shutdown_grace affinity
              idle_timeout header_timeout body_timeout request_timeout body_min_rate
              max_pipeline http2 http3 http3_max_conns redirect_https
              compress compress_min_length compress_level max_body
              access_log access_log_format error_log deny_capacity rate_capacity
              user group umask pid_file listen_fds proxy_protocol
              bus_slots bus_slot_size bus_groups arena_name arena_size
              distinct_clients
              tls_cert tls_key tls_ca tls_verify tls_sni);

# The spellings other servers use for the same things, so a plackup line
# written for one of them is not silently a plaintext server here.
my %ALIAS = (
    ssl_cert_file => 'tls_cert',
    ssl_key_file  => 'tls_key',
    ssl_cert      => 'tls_cert',
    ssl_key       => 'tls_key',
    ssl_ca_file   => 'tls_ca',
);

# What plackup itself hands every handler, or consumes before it does.
my %PLACK = map { $_ => 1 }
    qw(app host port socket listen listen_sock server_ready daemonize pid
       workers max_workers deny enable_ssl);

sub run {
    my ($self, $app) = @_;
    my %args = (
        app     => $app,
        workers => (defined $self->{workers}     ? $self->{workers}
                  : defined $self->{max_workers} ? $self->{max_workers}
                  : 0),                            # 0 = ncpu
        map { defined $self->{$_} ? ($_ => $self->{$_}) : () } @PASS,
    );
    for my $k (sort keys %ALIAS) {
        next unless defined $self->{$k};
        $args{ $ALIAS{$k} } = $self->{$k} unless defined $args{ $ALIAS{$k} };
    }
    # Hyperman->run croaks on an option it does not know; a handler that
    # dropped one quietly turned a typo (or --enable-ssl with no files) into
    # a server that was not what was asked for.
    my %known = (map({ $_ => 1 } @PASS), %ALIAS, %PLACK);
    for my $k (sort keys %$self) {
        next if $known{$k};
        warn "Plack::Handler::Hyperman: option '$k' is not one Hyperman takes; ignored\n";
    }
    if ($self->{enable_ssl} && !defined $args{tls_cert}) {
        die "Plack::Handler::Hyperman: --enable-ssl needs --ssl-cert-file and "
          . "--ssl-key-file (or --tls_cert and --tls_key)\n";
    }

    # `deny` wants an arrayref, and plackup hands a single --deny through as
    # a plain scalar - which run() would quietly ignore, since it only reads
    # the option when it is a reference. Normalise, so one denied address
    # works the same as several.
    if (defined $self->{deny}) {
        $args{deny} = ref $self->{deny} eq 'ARRAY'
                    ? $self->{deny} : [ $self->{deny} ];
    }

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

B<Every> other C<< Hyperman->run >> option is passed through when given
and left alone when not, so a server started by C<plackup> behaves
identically to the same options passed to C<run> directly:
C<reuseport>, C<completion>, C<max_requests_per_worker>, C<shutdown_grace>, C<affinity>,
C<idle_timeout>, C<header_timeout>, C<max_pipeline>, C<http2>, C<http3>, C<http3_max_conns>,
C<redirect_https>, C<max_body>, C<access_log>, C<deny>,
C<deny_capacity>, C<rate_capacity>, C<bus_slots>, C<bus_slot_size>,
C<bus_groups>, C<arena_name>, C<arena_size>, C<compress>, C<compress_min_length>,
C<compress_level>, and the C<tls_*> family. See L<Hyperman/run> for what
each means; the two that most often want setting have their own sections
below.

C<deny> takes an arrayref, and a single C<--deny 1.2.3.4> on a command
line arrives as a plain scalar, so one address is accepted as readily as
several.

=head2 max_body

The largest request Hyperman will buffer, headers plus body, before the
application is called. Over it, the request is answered C<413 Payload Too
Large>. The default is 16MB.

    plackup -s Hyperman --max_body 67108864     # 64MB, for large uploads
    plackup -s Hyperman --max_body 262144       # 256KB, for a JSON API

=head2 Compression

Response compression is B<off by default>, as it is under
C<< Hyperman->run >>, and is turned on per server:

    plackup -s Hyperman --compress 1
    plackup -s Hyperman --compress 1 --compress_min_length 512
    plackup -s Hyperman --compress 1 --compress_level 6

A response is compressed only if the client accepted gzip, it carries no
C<Content-Encoding> of its own, its media type is on the compressible
allowlist, and it is at least C<compress_min_length> bytes. On a Hyperman
built without zlib the option is accepted and inert. See
L<Hyperman/"Response compression"> for the full contract, including the
C<Content-Encoding: identity> opt-out and the C<ETag> rewrite.

=head1 SEE ALSO

L<Hyperman>, L<Plack>

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
