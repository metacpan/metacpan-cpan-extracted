package Gepok;

use 5.010001;
use strict;
use warnings;
use Log::Any '$log';

our $VERSION = '0.28'; # VERSION

use File::HomeDir;
use HTTP::Daemon::Patch::IPv6;
use HTTP::Daemon::SSL;
use HTTP::Daemon::UNIX;
use HTTP::Date qw(time2str);
use HTTP::Status qw(status_message);
use IO::Scalar;
use IO::Select;
use IO::Socket qw(:crlf);
use Plack::Util;
use POSIX;
use Proc::Daemon::Prefork;
use Time::HiRes qw(gettimeofday);
use URI::Escape;

use Moo;

has name                   => (is => 'rw',
                               default => sub {
                                   my $name = $0;
                                   $name =~ s!.*/!!;
                                   $name;
                               });
has daemonize              => (is => 'rw', default=>sub{1});
#has sock_path              => (is => 'rw');
has pid_path               => (is => 'rw');
has scoreboard_path        => (is => 'rw');
has error_log_path         => (is => 'rw');
has access_log_path        => (is => 'rw');
has http_ports             => (is => 'rw', default => sub{[]});
has https_ports            => (is => 'rw', default => sub{[]});
has unix_sockets           => (is => 'rw', default => sub{[]});
has timeout                => (is => 'rw', default => sub{120});
has require_root           => (is => 'rw', default => sub{0});
has ssl_key_file           => (is => 'rw');
has ssl_cert_file          => (is => 'rw');
has start_servers          => (is => 'rw', default => sub{3});
has max_clients            => (is => 'rw', default=>sub{150});
has max_requests_per_child => (is => 'rw', default=>sub{1000});
has _daemon                => (is => 'rw'); # Proc::Daemon::Prefork
has _server_socks          => (is => 'rw'); # store server sockets
has _app                   => (is => 'rw'); # store PSGI app
has product_name           => (is => 'rw');
has product_version        => (is => 'rw');

has "ssl_$_" => (is => 'rw') for (qw(verify_mode verify_callback ca_path ca_file));

sub BUILD {
    my ($self) = @_;

    my $is_root = $> ? 0 : 1;
    my $log_dir = $is_root ? "/var/log" : File::HomeDir->my_home;
    my $run_dir = $is_root ? "/var/run" : File::HomeDir->my_home;

    unless ($self->error_log_path) {
        $self->error_log_path($log_dir."/".$self->name."-error.log");
    }
    unless ($self->access_log_path) {
        $self->access_log_path($log_dir."/".$self->name."-access.log");
    }
    unless ($self->pid_path) {
        $self->pid_path($run_dir."/".$self->name.".pid");
    }
    unless ($self->scoreboard_path) {
        $self->scoreboard_path($run_dir."/".$self->name.".scoreboard");
    }
    unless ($self->product_name) {
        $self->product_name(ref($self));
    }
    unless (defined $self->product_version) {
        no strict;
        $self->product_version($Gepok::VERSION // "?");
    }
    if (defined (my $vc = $self->ssl_verify_callback)) {
        $self->ssl_verify_callback($vc = sub { 0 }) if $vc eq '0';
        $self->ssl_verify_callback($vc = sub { 1 }) if $vc eq '1';
        die "ssl_verify_callback needs to be a coderef, or constant '1' or '0'" unless ref $vc eq 'CODE';
    }
    unless ($self->_daemon) {
        my $daemon = Proc::Daemon::Prefork->new(
            name                    => $self->name,
            error_log_path          => $self->error_log_path,
            access_log_path         => $self->access_log_path,
            pid_path                => $self->pid_path,
            scoreboard_path         => $self->scoreboard_path,
            daemonize               => $self->daemonize,
            prefork                 => $self->start_servers,
            max_children            => $self->max_clients,
            after_init              => sub { $self->_after_init },
            main_loop               => sub { $self->_main_loop },
            require_root            => $self->require_root,
            # currently auto reloading is turned off
        );
        $self->_daemon($daemon);
    }
}

sub run {
    my ($self, $app) = @_;
    $self->_app($app);
    $self->_daemon->run;
}

# alias for run()
sub start {
    my $self = shift;
    $self->run(@_);
}

sub stop {
    my ($self) = @_;
    $self->_daemon->kill_running;
}

sub restart {
    my ($self) = @_;
    $self->_daemon->kill_running;
    $self->_daemon->run;
}

sub is_running {
    my ($self) = @_;
    my $pid = $self->_daemon->check_pidfile;
    $pid ? 1:0;
}

sub _after_init {
    my ($self) = @_;

    my @server_socks;
    my @server_sock_infos;
    my $ary;

    $ary = $self->unix_sockets;
    if (defined($ary) && ref($ary) ne 'ARRAY') { $ary = [split /\s*,\s*/,$ary] }
    for my $path (@$ary) {
        my %args;
        $args{Timeout} = $self->timeout;
        $args{Local}   = $path;
        $log->infof("Binding to Unix socket %s (http) ...", $path);
        my $sock = HTTP::Daemon::UNIX->new(%args);
        die "Unable to bind to Unix socket $path: $@" unless $sock;
        push @server_socks, $sock;
        push @server_sock_infos, "$path (unix)";
    }

    $ary = $self->http_ports;
    if (defined($ary) && ref($ary) ne 'ARRAY') { $ary = [split /\s*,\s*/,$ary] }
    for my $port (@$ary) {
        my %args;
        $args{Reuse}   = 1;
        $args{Timeout} = $self->timeout;
        if ($port =~ /^(?:0\.0\.0\.0|\*)?:?(\d+)$/) {
            $args{LocalPort} = $1;
        } elsif ($port =~ /^([^:]+):(\d+)$/) {
            $args{LocalHost} = $1;
            $args{LocalPort} = $2;
        } else {
            die "Invalid http_port syntax `$port`, please specify ".
                ":N or 1.2.3.4:N";
        }
        $log->infof("Binding to TCP socket %s (http) ...", $port);
        my $sock = HTTP::Daemon->new(%args);
        die "Unable to bind to TCP socket $port" unless $sock;
        push @server_socks, $sock;
        push @server_sock_infos, "$port (tcp)";
    }

    $ary = $self->https_ports;
    if (defined($ary) && ref($ary) ne 'ARRAY') { $ary = [split /\s*,\s*/,$ary] }
    for my $port (@$ary) {
        my %args;
        $args{Reuse}   = 1;

        # temporarily not passing Timeout param because this does make
        # request/packet larger than 2k hangs
        #$args{Timeout} = $self->timeout; # can hang with larger POST?

        $args{SSL_key_file}  = $self->ssl_key_file;
        $args{SSL_cert_file} = $self->ssl_cert_file;

        for (qw(verify_mode verify_callback ca_path ca_file)) {
            my $meth = "ssl_$_";
            my $val  = $self->$meth;
            $args{"SSL_$_"} = $val if defined $val;
        }

        if ($port =~ /^(?:0\.0\.0\.0)?:?(\d+)$/) {
            $args{LocalPort} = $1;
        } elsif ($port =~ /^(\d+\.\d+\.\d+\.\d+):(\d+)$/) {
            $args{LocalHost} = $1;
            $args{LocalPort} = $2;
        } else {
            die "Invalid http_port syntax `$port`, please specify ".
                ":N or 1.2.3.4:N";
        }

        $log->infof("Binding to TCP socket %s (https) ...", $port);
        my $sock = HTTP::Daemon::SSL->new(%args);
        die "Unable to bind to TCP socket $port, common cause include ".
            "port taken or missing server key/cert file" unless $sock;
        push @server_socks, $sock;
        push @server_sock_infos, "$port (tcp, https)";
    }

    die "Please specify at least one HTTP/HTTPS/Unix socket port"
        unless @server_socks;

    $self->_server_socks(\@server_socks);
    warn "Will be binding to ".join(", ", @server_sock_infos)."\n";
    $self->before_prefork();
}

sub before_prefork {}

sub _main_loop {
    my ($self) = @_;
    if ($self->_daemon->{parent_pid} == $$) {
        $log->info("Entering main loop");
    } else {
        $log->info("Child process started (PID $$)");
    }
    $self->_daemon->update_scoreboard({child_start_time=>time()});

    my $sel = IO::Select->new(@{ $self->_server_socks });

    for (my $i=1; $i<=$self->max_requests_per_child; $i++) {
        $self->_daemon->set_label("listening");
        my @ready = $sel->can_read();
        for my $s (@ready) {
            my $sock = $s->accept();
            # sock can be undef
            next unless $sock;
            $self->{_connect_time} = [gettimeofday];
            $self->_set_label_serving($sock);
            while (1) {
                $self->_daemon->update_scoreboard({
                    req_start_time => time(),
                    num_reqs => $i,
                    state => "R",
                });
                $self->{_start_req_time} = [gettimeofday];
                my $req = $sock->get_request;
                $self->{_finish_req_time} = [gettimeofday];
                last unless $req;
                $self->{_client_proto} =
                    $sock->proto_ge("1.1") ? "HTTP/1.1" : "HTTP/1.0";
                $self->_daemon->update_scoreboard({state => "W"});
                my $res = $self->_handle_psgi($req, $sock);
                $self->access_log($req, $res, $sock);
            }
            $self->_daemon->update_scoreboard({state => "_"});
        }
    }
}

# taken from Starman, with modifications. turn PSGI response into actual HTTP
# response and send it to client.
sub _finalize_response {
    my($self, $env, $res, $sock) = @_;

    if ($env->{'psgix.harakiri.commit'}) {
        $self->{_client_keepalive} = 0;
        $self->{_client_harakiri}  = 1;
    }

    my $server_proto = $env->{SERVER_PROTOCOL};
    my $client_proto = $self->{_client_proto};
    my $status       = $res->[0];
    my $message      = status_message($status);
    $self->{_res_status} = $status;

    # generate HTTP status + response headers

    my(@headers, %headers);
    push @headers, "$server_proto $status $message";
    push @headers, "Server: ".
            $self->product_name."/".$self->product_version;
    while (my ($k, $v) = splice @{$res->[1]}, 0, 2) {
        push @headers, "$k: $v";
        $headers{lc $k} = $v;
    }

    if (!$headers{date}) {
        push @headers, "Date: " . time2str(time());
    }

    my $keepalive;
    if ($env->{HTTP_CONNECTION}) {
        $keepalive = $env->{HTTP_CONNECTION} =~ /alive/i ? 1:0;
    }
    # default is keep-alive for HTTP/1.1, but close for HTTP/1.0
    $keepalive //= ($client_proto eq 'HTTP/1.1' ? 1:0);
    # normally HTTP::Daemon prints this, but we're not sending response using
    # HTTP::Daemon
    push @headers, "Connection: ".($keepalive ? "Keep-Alive" : "Close");

    my $chunked;
    my $cl = $headers{'content-length'};
    if ($client_proto eq 'HTTP/1.1') {
        if ($status =~ /^[123]/ && $status != 304 && (!defined($cl) || $cl)) {
            $chunked = 1;
        }
        if (my $te = $headers{'transfer-encoding'}) {
            $chunked = $te eq 'chunked';
        }
    } else {
        # "A server MUST NOT send transfer-codings to an HTTP/1.0 client."
        $chunked = 0;
    }
    push @headers, "Transfer-Encoding: chunked" if $chunked;
    $self->{_chunked} = $chunked;

    #warn "chunked=$chunked, keep-alive=$keepalive, client_proto=$client_proto";

    if ($client_proto le 'HTTP/1.0' && $keepalive && !defined($cl)) {
        # if HTTP/1.0 client requests keep-alive (like Wget), we need
        # Content-Length so client knows when response ends.

        # produce body first so we can calculate content-length
        $self->_finalize_body($env, $res, $sock, 1);
        push @headers, "Content-Length: ".$self->{_res_content_length};
        syswrite $sock, join($CRLF, @headers, '') . $CRLF; # print header
        syswrite $sock, $_ for @{$self->{_body}}; # print body
    } else {
        # print headers + body normally

        syswrite $sock, join($CRLF, @headers, '') . $CRLF; # print header
        $self->_finalize_body($env, $res, $sock);
    }
}

# either print body to $sock, or store it in $self-> (for HTTP/1.0 Keep-Alive
# clients)
sub _finalize_body {
    my ($self, $env, $res, $sock, $save) = @_;
    my $cl = 0;
    $self->{_body} = [] if $save;
    if (defined $res->[2]) {
        Plack::Util::foreach(
            $res->[2],
            sub {
                my $buffer = $_[0];
                my $len = length $buffer;
                $cl += $len;
                if ($self->{_chunked}) {
                    return unless $len;
                    $buffer = sprintf("%x", $len) . $CRLF . $buffer . $CRLF;
                }
                $self->_write_sock($sock, $save, $buffer);
            });
        $self->_write_sock($sock, $save, "0$CRLF$CRLF") if $self->{_chunked};
    } else {
        return Plack::Util::inline_object(
            write => sub {
                my $buffer = $_[0];
                my $len = length $buffer;
                $cl += $len;
                if ($self->{_chunked}) {
                    return unless $len;
                    $buffer = sprintf("%x", $len) . $CRLF . $buffer . $CRLF;
                }
                $self->_write_sock($sock, $save, $buffer);
            },
            # poll_cb => sub { ... },
            close => sub {
                $self->_write_sock($sock, $save, "0$CRLF$CRLF")
                    if $self->{_chunked};
            }
        );
    }
    $self->{_res_content_length} = $cl;
}

sub _write_sock {
    my ($self, $sock, $save, $buffer) = @_;
    if ($save) {
        push @{$self->{_body}}, $buffer;
    } else {
        # large $buffer might need to be written in several steps, especially in
        # SSL sockets which might have smaller buffer size (like 16k)
        my $tot_written = 0;
        while (1) {
            my $written = syswrite $sock, $buffer, length($buffer)-$tot_written,
                $tot_written;
            # XXX what to do on error, i.e. $written is undef?
            $tot_written += $written;
            last unless $tot_written < length($buffer);
        }
    }
}

# run PSGI app, send PSGI response to client as HTTP response, and return it
sub _handle_psgi {
    my ($self, $req, $sock) = @_;

    my $env = $self->_prepare_env($req, $sock);

    # cache first before socket closes
    $self->{_sock_peerhost} = $env->{REMOTE_ADDR};

    my $res = Plack::Util::run_app($self->_app, $env);

    # trap i/o error when sending response
    eval {
        if (ref($res) eq 'CODE') {
            $res->(sub { $self->_finalize_response($env, $_[0], $sock) });
        } else {
            $self->_finalize_response($env, $res, $sock);
        }
    };

    $res;
}

# prepare PSGI env
sub _prepare_env {
    my ($self, $req, $sock) = @_;

    my $httpd   = ${*$sock}{httpd_daemon};
    my $is_unix = $httpd->isa('HTTP::Daemon::UNIX');
    my $is_ssl  = $httpd->isa('HTTP::Daemon::SSL');
    my $uri = $req->uri->as_string;
    my ($qs, $pi);
    if ($uri =~ /(.*)\?(.*)/) {
        $pi = $1;
        $qs = $2;
    } else {
        $pi = $uri;
        $qs = "";
    }
    $pi = uri_unescape($pi);

    #warn "uri=$uri, qs=$qs\n";
    my $env = {
        REQUEST_METHOD  => $req->method,
        SCRIPT_NAME     => '',
        PATH_INFO       => $pi,
        REQUEST_URI     => $uri,
        QUERY_STRING    => $qs,
        SERVER_PORT     => $is_unix ? 0 : $httpd->sockport,
        SERVER_NAME     => $is_unix ? $httpd->hostpath : $httpd->sockhost,
        SERVER_PROTOCOL => 'HTTP/1.1',
        REMOTE_ADDR     => $is_unix ? '127.0.0.1' : $sock->peerhost,

        'psgi.version'         => [ 1, 1 ],
        'psgi.input'           => IO::Scalar->new(\($req->{_content})),
        'psgi.errors'          => *STDERR,
        'psgi.url_scheme'      => $is_ssl ? 'https' : 'http',
        'psgi.run_once'        => Plack::Util::FALSE,
        'psgi.multithread'     => Plack::Util::FALSE,
        'psgi.multiprocess'    => Plack::Util::TRUE,
        'psgi.streaming'       => Plack::Util::TRUE,
        'psgi.nonblocking'     => Plack::Util::FALSE,
        'psgix.input.buffered' => Plack::Util::TRUE,
        'psgix.io'             => $sock,
        'psgix.input.buffered' => Plack::Util::TRUE,
        'psgix.harakiri'       => Plack::Util::TRUE,

        # additional/server-specific
        'gepok'                     => 1,
        'gepok.connect_time'        => $self->{_connect_time},
        'gepok.start_request_time'  => $self->{_start_req_time},
        'gepok.finish_request_time' => $self->{_finish_req_time},
        'gepok.client_protocol'     => $self->{_client_proto},
        'gepok.socket'              => $sock,
        'gepok.httpd_socket'        => $httpd,
    };
    $env->{HTTPS} = 'on' if $is_ssl;
    if ($is_unix) {
        $env->{'gepok.unix_socket'} = 1;
    } else {
        #
    }

    # HTTP_ vars
    my $rh = $req->headers;
    for my $hn ($rh->header_field_names) {
        my $key = uc($hn); $key =~ s/[^A-Z0-9]/_/g;
        $key = "HTTP_$key" unless $key =~ /\A(?:CONTENT_(?:TYPE|LENGTH))\z/;
        $env->{$key} = join(", ", $rh->header($hn));
    }

    $env;
}

sub _set_label_serving {
    my ($self, $sock) = @_;
    # sock can be undef when client timed out
    return unless $sock;

    my $httpd = ${*$sock}{httpd_daemon};
    my $is_unix = $httpd->isa('HTTP::Daemon::UNIX');

    if ($is_unix) {
        my $sock_path = $httpd->hostpath;
        my ($pid, $uid, $gid) = $httpd->peercred;
        $log->trace("Unix socket info: path=$sock_path, ".
                        "pid=$pid, uid=$uid, gid=$gid");
        $self->_daemon->set_label("serving unix (pid=$pid, uid=$uid, ".
                                      "path=$sock_path)");
    } else {
        my $is_ssl = $httpd->isa('HTTP::Daemon::SSL') ? 1:0;
        my $server_port = $sock->sockport;
        my $remote_ip   = $sock->peerhost // "127.0.0.1";
        my $remote_port = $sock->peerport;
        if ($log->is_trace) {
            $log->trace(join("",
                             "TCP socket info: https=$is_ssl, ",
                             "server_port=$server_port, ",
                             "remote_ip=$remote_ip, ",
                             "remote_port=$remote_port"));
        }
        $self->_daemon->set_label("serving TCP :$server_port (https=$is_ssl, ".
                                      "remote=$remote_ip:$remote_port)");
    }
}

sub __escape {
    my $s = shift;
    $s =~ s/\n/\\n/g;
    $s;
}

sub __escape_quote {
    my $s = shift;
    $s =~ s/\n/\\n/g;
    $s =~ s/"/\\"/g;
    $s;
}

sub access_log {
    my ($self, $req, $sock) = @_;
    return unless $self->access_log_path;

    my $reqh = $req->headers;
    if ($log->is_trace) {
        $log->tracef("\$self->{_sock_peerhost}=%s, (gmtime(\$self->{_finish_req_time}))[0]=%s, \$req->method=%s, \$req->uri->as_string=%s, \$self->{_res_status}=%s, \$self->{res_content_length}=%s, ".
                         "\$reqh->header('referer')=%s, \$reqh->header('user-agent')=%s",
                     $self->{_sock_peerhost},
                     (gmtime($self->{_finish_req_time}))[0],
                     $req->method,
                     $req->uri->as_string,
                     $self->{_res_status},
                     $self->{_res_content_length},
                     scalar($reqh->header("referer")),
                     scalar($reqh->header("user-agent")),
                 );
    }
    my $logline = sprintf(
        "%s - %s [%s] \"%s %s\" %d %s \"%s\" \"%s\"\n",
        $self->{_sock_peerhost} // "-",
        "-", # XXX auth user
        POSIX::strftime("%d/%b/%Y:%H:%M:%S +0000",
                        gmtime($self->{_finish_req_time}[0])),
        $req->method,
        __escape_quote($req->uri->as_string),
        $self->{_res_status} // 0,
        $self->{_res_content_length} // "-",
        scalar($reqh->header("referer")) // "-",
        scalar($reqh->header("user-agent")) // "-",
    );
    #$log->tracef("logline=%s", $logline);
    if ($self->daemonize) {
        syswrite($self->_daemon->{_access_log}, $logline);
    } elsif (!defined($ENV{PLACK_ENV})) {
        warn $logline;
    }
}

1;

# ABSTRACT: PSGI server with built-in HTTPS support, Unix sockets, preforking

__END__

=pod

=encoding UTF-8

=head1 NAME

Gepok - PSGI server with built-in HTTPS support, Unix sockets, preforking

=head1 VERSION

This document describes version 0.28 of Gepok (from Perl distribution Gepok), released on 2014-12-11.

=head1 SYNOPSIS

To run with plackup:

 % plackup -s Gepok --daemonize

To run standalone:

 #!/usr/bin/perl
 use Gepok;
 my $d = Gepok->new(
     http_ports     => [8081, ':8082', '127.0.0.1:8083'], # default none
     https_ports    => [8084, '0.0.0.0:8085'],            # default none
     unix_sockets   => ['/var/run/gepok.sock','/tmp/gepok.sock'], # default none
     #ssl_key_file  => '/path/to/key.pem', # required if https_ports specified
     #ssl_cert_file => '/path/to/crt.pem', # required if https_ports specified
     #max_requests_per_child => 100,       # default is 1000
     #start_servers          => 0,         # default is 3, 0 means don't prefork
     #daemonize => 0,       # default is 1, 0 = don't go into background
 );
 $d->run($psgi_app);

=head1 DESCRIPTION

Gepok is a PSGI server implementation. Its features are:

=over 4

=item * HTTPS support out-of-the-box

This is the primary (if not the only) reason why I wrote Gepok, and why it uses
HTTP::Daemon::* family (because there is HTTP::Daemon::SSL). I needed a
pure-Perl standalone webserver with SSL support builtin. Other Perl servers
usually recommend running behind Nginx or some other external HTTPS proxy.

=item * Preforking

Good performance and reliability.

=item * Multiple interface and Unix socket

=item * Runs on Unix platform

=back

Gepok can run under B<plackup>, or standalone.

=head1 PSGI ENVIRONMENT

Gepok adds the following server-specific keys in the PSGI environment passed to
application/middleware:

=over 4

=item * gepok.connect_time => ARRAY

A 2-element arrayref (produced by Time::HiRes' gettimeofday()), clocked at
connect time.

=item * gepok.finish_request_time => ARRAY

A 2-element arrayref (produced by Time::HiRes' gettimeofday()), clocked right
after Gepok has received the complete request from client.

=item * gepok.client_protocol => STR

HTTP protocol version sent by client, e.g. "HTTP/1.0" or "HTTP/1.1". This can be
used to avoid sending HTTP/1.1 response to HTTP/1.0 or older clients.

=item * gepok.socket => OBJ

Raw HTTP::Daemon::ClientConn socket. Can be used to get information about
socket, e.g. peerport(), etc. Should not be used to read/write data (use PSGI
way for that, e.g. $env->{'psgi.input'}, returning PSGI response, etc).

=item * gepok.httpd_socket => OBJ

Raw HTTP::Daemon socket. Can be used to get information about socket, e.g.
peercred() (for UNIX sockets), etc. Should not be used to return HTTP response
directly (use PSGI way for that).

=item * gepok.unix_socket => BOOL

A boolean value which is set to true if client connects via Unix socket. (Note,
you can get Unix socket path from $env->{SERVER_NAME} or
$env->{'gepok.socket'}).

=back

=head1 ATTRIBUTES

=head2 name => STR (default is basename of $0)

Name of server, for display in process table ('ps ax').

=head2 daemonize => BOOL (default 1)

Whether to daemonize (go into background).

=head2 http_ports => ARRAY OF STR (default [])

One or more HTTP ports to listen to. Default is none. Each port can be in the
form of N, ":N", "0.0.0.0:N" (all means the same thing, to bind to all
interfaces) or "1.2.3.4:N" (to bind to a specific network interface).

A string is also accepted, it will be split (delimiter ,) beforehand.

=head2 https_ports => ARRAY OF STR (default [])

Just like http_ports, but for specifying ports for HTTPS.

=head2 unix_sockets => ARRAY OF STR (default [])

Location of Unix sockets. Default is none, which means not listening to Unix
socket. Each element should be an absolute path.

A string is also accepted, it will be split (delimiter ,) beforehand.

You must at least specify one port (either http, https, unix_socket) or Gepok
will refuse to run.

=head2 timeout => BOOL (default 120)

Socket timeout. Will be passed as Timeout option to HTTP::Daemon's constructor
(which will be passed to IO::Socket).

=head2 require_root => BOOL (default 0)

Whether to require running as root.

Passed to Proc::Daemon::Prefork's constructor.

=head2 pid_path => STR (default /var/run/<name>.pid or ~/<name>.pid)

Location of PID file.

=head2 scoreboard_path => STR (default /var/run/<name>.scoreboard or ~/<name>.scoreboard)

Location of scoreboard file (used for communication between parent and child
processes). If you disable this, autoadjusting number of children won't work
(number of children will be kept at 'start_servers').

=head2 error_log_path => STR (default /var/log/<name>-error.log or ~/<name>-error.log)

Location of error log. Default is /var/log/<name>-error.log. It will be opened
in append mode.

=head2 access_log_path => STR (default /var/log/<name>-access.log or ~/<name>-access.log)

Location of access log. It will be opened in append mode.

Default format of access log is the Apache combined format. Override
access_log() method if you wan't to customize this.

If Gepok is run Under plackup, by default it will not write an access log file
(unless you specify this attribute) since plackup already writes an access log.

=head2 ssl_key_file => STR

Path to SSL key file, to be passed to HTTP::Daemon::SSL. If you specify one or
more HTTPS ports, you need to supply this.

=head2 ssl_cert_file => STR

Path to SSL cert file, to be passed to HTTP::Daemon::SSL. If you specify one or
more HTTPS ports, you need to supply this.

=head2 ssl_verify_mode => INT

Level of verification for SSL client certificates, to be passed to
HTTP::Daemon::SSL. This is optional.

=head2 ssl_verify_callback => CODEREF

Custom verifier for SSL client certificates, to be passed to HTTP::Daemon::SSL.
This is optional.

=head2 ssl_ca_file => STR

Path for file containing certificates of reputable authorties for certificate
verification. This is optional.

=head2 ssl_ca_path => STR

According to L<IO::Socket::SSL> this is only of interest if you are
"unusually friendly with the OpenSSL documentation". This is optional.

=head2 start_servers => INT (default 3)

Number of children to fork at the start of run. If you set this to 0, the server
becomes a nonforking one.

Tip: You can set start_servers to 0 and 'daemonize' to false for debugging.

=head2 max_clients => INT (default 150)

Maximum number of children processes to maintain. If server is busy, number of
children will be increased from the original 'start_servers' up until this
value.

=head2 max_requests_per_child => INT (default 1000)

Number of requests each child will serve until it exists.

=head2 product_name => STR

Used in 'Server' HTTP response header (<product_name>/<version>). Defaults to
class name, e.g. "Gepok".

=head2 product_version => STR

Used in 'Server' HTTP response header (<product_name>/<version>). Defaults to
$VERSION package variable.

=head1 METHODS

=for Pod::Coverage BUILD

=head2 new(%args)

Create a new instance of server. %args can be used to set attributes.

=head2 $gepok->run($app)

Start/run server and run the PSGI application $app.

=head2 $gepok->start($app)

Alias for run().

=head2 $gepok->stop()

Stop running server.

=head2 $gepok->restart()

Restart server.

=head2 $gepok->is_running() => BOOL

Check whether server is running.

=head2 $gepok->before_prefork()

This is a hook provided for subclasses to do something before the daemon is
preforking. For example, you can preload Perl modules here so that each child
doesn't have to load modules separately (= inefficient).

=head2 $gepok->access_log($req, $res, $sock)

The default implementation uses the Apache combined format. Override if you want
custom format. $res is HTTP::Request object, $res is PSGI response, $sock is the
raw socket.

=head1 FAQ

=head2 Why the name Gepok?

Gepok is an Indonesian word, meaning bundle/bunch. This class bundles one or
several HTTP::Daemon::* objects to create a stand-alone web server.

=head2 Why use Gepok?

The main feature for Gepok is builtin HTTPS support, which means you do not have
to setup a separate front-end HTTPS proxy for serving content over HTTPS. This
is convenient, especially for development. Builtin HTTPS support also makes some
things easier to, e.g. check client certificates you can use the
B<ssl_verify_callback> options. Your PSGI application also has direct access to
the raw socket (C<< $env->{'gepok.socket'} >>).

However, for heavy traffic use, you might want to check out more battle-tested
solution like L<Perlbal>.

There are now other PSGI servers that support HTTPS, see the SEE ALSO section.

I personally developed Gepok for two reasons: HTTPS support and listening on
Unix sockets.

=head2 Performance notes?

Thanks to preforking, Gepok has adequate performance and reliability handling
multiple clients. But Gepok is not yet performance-tuned, or very
performance-oriented to begin with. For convenience Gepok is based on
HTTP::Daemon, which is also not too performance-oriented. For each HTTP request,
HTTP::Daemon constructs an L<HTTP::Request> object, which copies request body
into a scalar (and, for PSGI, needs to be re-presented as a stream using
L<IO::Scalar>). Creating other objects like L<URI> and L<HTTP::Headers> are also
involved. Gepok also creates file-based scoreboard, which might or might not be
a bottleneck.

Casual benchmarking on my PC shows that Gepok is about 3-4x slower than
L<Starman> for "hello world" PSGI.

I am using Gepok primarily with L<Perinci::Access::HTTP::Server> for serving
remote API requests, in which HTTPS support is required.

=head2 "Bad arg length for Socket::inet_ntoa, length is 16, should be 4" error

At the time of this writing, L<HTTP::Daemon> (6.01) might throw this error
message when receiving request. For patches/solutions to overcome this problem,
see: https://rt.cpan.org/Ticket/Display.html?id=71395

=head1 CREDITS

Some code portion taken from Starman.

=head1 SEE ALSO

L<PSGI> and L<Plack>.

HTTP server classes used: L<HTTP::Daemon>, L<HTTP::Daemon::SSL>,
L<HTTP::Daemon::UNIX>.

L<Perlbal>.

Other PSGI servers that support Unix sockets: L<Starman>.

Other PSGI servers that support HTTPS out of the box:

=over

=item * L<Plack::Handler::AnyEvent::HTTPD>

As of Aug 2012 still needs a patch to allow SSL, see
https://github.com/miyagawa/Plack-Handler-AnyEvent-HTTPD/pull/2#issuecomment-7046948

=back

Note that any PSGI server can be used if you setup a front-end HTTPS proxy/load
balancer.

Please drop me a message if you think other PSGI servers need to be mentioned.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Gepok>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Gepok>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Gepok>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
