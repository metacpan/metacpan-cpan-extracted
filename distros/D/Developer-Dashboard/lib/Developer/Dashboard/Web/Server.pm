package Developer::Dashboard::Web::Server;

use strict;
use warnings;

our $VERSION = '1.33';

use Capture::Tiny qw(capture);
use File::Spec;
use IO::Socket::INET;
use Plack::Runner;

use Developer::Dashboard::Web::DancerApp;
use Developer::Dashboard::Web::Server::Daemon;

# new(%args)
# Constructs the local PSGI web server wrapper.
# Input: app object plus optional host, port, worker count, and ssl flag.
# Output: Developer::Dashboard::Web::Server object.
sub new {
    my ( $class, %args ) = @_;
    my $app     = $args{app}  || die 'Missing web app';
    my $host    = defined $args{host} ? $args{host} : '0.0.0.0';
    my $port    = defined $args{port} ? $args{port} : 7890;
    my $workers = defined $args{workers} ? $args{workers} : 1;
    my $ssl     = defined $args{ssl} ? $args{ssl} ? 1 : 0 : 0;
    die 'Missing worker count' if !defined $workers || $workers eq '';
    die 'Worker count must be a positive integer' if $workers !~ /^\d+$/ || $workers < 1;

    if ($ssl) {
        generate_self_signed_cert();
    }

    return bless {
        app     => $app,
        host    => $host,
        port    => $port,
        workers => $workers + 0,
        ssl     => $ssl,
    }, $class;
}

# run()
# Starts the PSGI daemon wrapper and serves requests until the runner exits.
# Input: none.
# Output: true value when the server loop completes.
sub run {
    my ($self) = @_;

    my $daemon = $self->start_daemon;
    print "Developer Dashboard listening on ", $self->listening_url($daemon), "\n";
    return $self->serve_daemon($daemon);
}

# start_daemon()
# Reserves and validates the listen address before Starman starts.
# Input: none.
# Output: daemon descriptor object with resolved host and port.
sub start_daemon {
    my ($self) = @_;
    my $socket = IO::Socket::INET->new(
        LocalAddr => $self->{host},
        LocalPort => $self->{port},
        Proto     => 'tcp',
        ReuseAddr => 1,
        Listen    => 10,
    );
    die "Unable to start server on $self->{host}:$self->{port}: $!" if !$socket;

    my $daemon = Developer::Dashboard::Web::Server::Daemon->new(
        host => scalar( $socket->sockhost ),
        port => scalar( $socket->sockport ),
    );
    close $socket or die "Unable to close reserved listen socket: $!";
    return $daemon;
}

# listening_url($daemon)
# Builds the public listening URL for a daemon instance.
# Input: daemon descriptor object or undef.
# Output: URL string with http:// or https:// scheme based on ssl flag, or placeholder if daemon unavailable.
sub listening_url {
    my ( $self, $daemon ) = @_;
    return unless defined $daemon;
    my $scheme = $self->{ssl} ? 'https' : 'http';
    my $host = $daemon->sockhost // 'localhost';
    my $port = $daemon->sockport // 7890;
    return sprintf '%s://%s:%s/', $scheme, $host, $port;
}

# serve_daemon($daemon)
# Runs the Dancer2 PSGI app under Starman through Plack::Runner.
# Input: daemon descriptor object.
# Output: true value when the PSGI runner exits.
sub serve_daemon {
    my ( $self, $daemon ) = @_;
    my $runner = $self->_build_runner($daemon);
    my $app = $self->psgi_app;
    $runner->run($app);
    return 1;
}

# psgi_app()
# Builds the Dancer2 PSGI application with the standard security headers.
# Input: none.
# Output: PSGI application code reference.
sub psgi_app {
    my ($self) = @_;
    return Developer::Dashboard::Web::DancerApp->build_psgi_app(
        app             => $self->{app},
        default_headers => $self->_default_headers,
    );
}

# _build_runner($daemon)
# Configures the Plack runner to serve the dashboard PSGI app via Starman.
# Includes SSL configuration (--ssl-key and --ssl-cert) when ssl flag is enabled.
# Input: daemon descriptor object.
# Output: Plack::Runner object.
sub _build_runner {
    my ( $self, $daemon ) = @_;
    my $runner = Plack::Runner->new;
    my @options = (
        '--server', 'Starman',
        '--host',   $daemon->sockhost,
        '--port',   $daemon->sockport,
        '--env',    'deployment',
        '--workers', $self->{workers},
    );

    if ( $self->{ssl} ) {
        my ( $cert, $key ) = get_ssl_cert_paths();
        push @options, '--ssl',      1;
        push @options, '--ssl-key',  $key;
        push @options, '--ssl-cert', $cert;
    }

    $runner->parse_options(@options);
    return $runner;
}

# _default_headers()
# Returns the security and cache headers applied to every browser response.
# Input: none.
# Output: hash reference of header names to values.
sub _default_headers {
    return {
        'X-Frame-Options'         => 'DENY',
        'X-Content-Type-Options'  => 'nosniff',
        'Referrer-Policy'         => 'no-referrer',
        'Cache-Control'           => 'no-store',
        'Content-Security-Policy' => q{default-src 'self' 'unsafe-inline' data:; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'},
    };
}

# generate_self_signed_cert()
# Generates or reuses a self-signed certificate for HTTPS.
# Creates ~/.developer-dashboard/certs/ if it does not exist.
# Reuses existing certificates if already present.
# Input: none.
# Output: path to certificate file, or dies on error.
sub generate_self_signed_cert {
    my $home = $ENV{HOME} || die 'Missing HOME environment variable';
    my $cert_dir = File::Spec->catdir($home, '.developer-dashboard', 'certs');
    my $cert_file = File::Spec->catfile($cert_dir, 'server.crt');
    my $key_file  = File::Spec->catfile($cert_dir, 'server.key');

    return $cert_file if -f $cert_file && -f $key_file;

    if (!-d $cert_dir) {
        require File::Path;
        File::Path::make_path($cert_dir) or die "Unable to create cert directory $cert_dir: $!";
    }

    my @cmd = (
        'openssl', 'req', '-new', '-x509', '-days', '365',
        '-nodes',
        '-out', $cert_file,
        '-keyout', $key_file,
        '-subj', '/C=US/ST=Local/L=Local/O=Developer Dashboard/CN=localhost'
    );

    my ($stdout, $stderr, $exit) = capture {
        system(@cmd);
    };
    die "Failed to generate SSL certificate: $stderr" if $exit != 0;
    die "Certificate file not created" if !-f $cert_file;
    die "Key file not created" if !-f $key_file;

    return $cert_file;
}

# get_ssl_cert_paths()
# Returns the paths to the self-signed certificate and key files.
# Input: none.
# Output: list of (cert_path, key_path) or dies if files do not exist.
sub get_ssl_cert_paths {
    my $home = $ENV{HOME} || die 'Missing HOME environment variable';
    my $cert_dir = File::Spec->catdir($home, '.developer-dashboard', 'certs');
    my $cert_file = File::Spec->catfile($cert_dir, 'server.crt');
    my $key_file  = File::Spec->catfile($cert_dir, 'server.key');

    die "Certificate file not found: $cert_file" if !-f $cert_file;
    die "Key file not found: $key_file" if !-f $key_file;

    return ($cert_file, $key_file);
}

1;

__END__

=head1 NAME

Developer::Dashboard::Web::Server - PSGI server bridge for Developer Dashboard

=head1 SYNOPSIS

  my $server = Developer::Dashboard::Web::Server->new(app => $app);
  $server->run;

=head1 DESCRIPTION

This module reserves the local listen address, builds the Dancer2 PSGI app,
and runs it under Starman through Plack::Runner.

=head1 METHODS

=head2 new, run, start_daemon, listening_url, serve_daemon, psgi_app, _build_runner, _default_headers, generate_self_signed_cert, get_ssl_cert_paths

Construct and run the local PSGI web server with optional SSL/HTTPS support.

When C<ssl => 1> is passed to new(), generates self-signed certificates in C<~/.developer-dashboard/certs/> and configures Starman for HTTPS. The listening_url() method returns https:// when SSL is enabled.

=head1 SSL SUPPORT

Pass C<ssl => 1> to the new() constructor to enable HTTPS:

  my $server = Developer::Dashboard::Web::Server->new(
      app => $app,
      ssl => 1,
  );
  $server->run;

Self-signed certificates are generated automatically in C<~/.developer-dashboard/certs/> and reused on subsequent runs.

=cut
