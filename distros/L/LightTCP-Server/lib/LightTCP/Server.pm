package LightTCP::Server;

use strict;
use warnings;

use IO::Socket::INET;
use IPC::Open3;
use threads;
use threads::shared;
use File::Temp;

our $VERSION = '2.00';

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;

    if (@args == 1 && ref $args[0] eq 'HASH') {
        @args = %{$args[0]};
    }

    $self->{server_addr} = '0.0.0.0:8881';
    $self->{server_name} = 'tcpsrv';
    $self->{server_type} = 'single';
    $self->{max_threads} = 10;
    $self->{server_timeout} = -1;
    $self->{server_dir} = '/var/www';
    $self->{server_etc} = '.';
    $self->{server_autostop} = 0;
    $self->{server_deny} = 0;
    $self->{server_secure} = 0;
    $self->{server_auth} = 0;
    $self->{server_keys} = [];
    $self->{runas_user} = '';
    $self->{runas_group} = '';
    $self->{server_http} = 1;
    $self->{server_perlonly} = 1;
    $self->{server_fnext} = 'html css js ico gif jpg png';
    $self->{server_cgi} = 0;
    $self->{server_cgiext} = 'cgi php';
    $self->{http_postlimit} = 0;
    $self->{func_timeout} = undef;
    $self->{func_perl} = undef;
    $self->{func_done} = undef;
    $self->{func_log} = undef;
    $self->{func_upload} = undef;
    $self->{logfn} = '';
    $self->{verbose} = 0;
    $self->{_server} = undef;
    $self->{_serverloop} = 1;
    $self->{_threads} = [];
    $self->{_log_lock} = do { my $lock :shared; \$lock; };
    $self->{upload_dir} = '/var/www/uploads';
    $self->{upload_max_size} = 10 * 1024 * 1024;
    $self->{upload_allowed_types} = [qw(
        image/jpeg image/png image/gif image/webp
        application/pdf text/plain text/csv text/html
        application/zip application/x-zip-compressed
        application/msword
        application/vnd.openxmlformats-officedocument.wordprocessingml.document
        application/vnd.ms-excel
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    )];
    $self->{rate_limit_enabled} = 0;
    $self->{rate_limit_requests} = 100;
    $self->{rate_limit_window} = 60;
    $self->{rate_limit_block_duration} = 300;
    $self->{rate_limit_whitelist} = [qw(127.0.0.1 ::1 localhost)];
    $self->{_rate_limit_lock} = do { my $lock :shared; \$lock; };
    $self->{_rate_limit_data} = {};
    $self->{_upload_lock} = do { my $lock :shared; \$lock; };

    while (@args) {
        my ($attr, $value) = splice(@args, 0, 2);
        $self->$attr($value) if $self->can($attr);
    }

    $self->_init_config();
    return $self;
}

sub server_addr {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "server_addr is required" unless defined $value && $value ne '';
        $self->{server_addr} = $value;
    }
    return $self->{server_addr};
}

sub server_name {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "server_name must be a string" if defined $value && ref $value;
        $self->{server_name} = $value;
    }
    return $self->{server_name};
}

sub server_type {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "server_type must be single, fork, or thread" unless $value =~ /^(?:single|fork|thread)$/;
        $self->{server_type} = $value;
    }
    return $self->{server_type};
}

sub max_threads {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "max_threads must be a positive integer" if defined $value && $value !~ /^\d+$/;
        $self->{max_threads} = $value;
    }
    return $self->{max_threads};
}

sub server_timeout {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "server_timeout must be >= -1" if defined $value && $value < -1;
        $self->{server_timeout} = $value;
    }
    return $self->{server_timeout};
}

sub server_dir {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_dir} = $value;
    }
    return $self->{server_dir};
}

sub server_etc {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_etc} = $value;
    }
    return $self->{server_etc};
}

sub server_autostop {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_autostop} = $value;
    }
    return $self->{server_autostop};
}

sub server_deny {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_deny} = $value;
    }
    return $self->{server_deny};
}

sub server_secure {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_secure} = $value;
    }
    return $self->{server_secure};
}

sub server_auth {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_auth} = $value;
    }
    return $self->{server_auth};
}

sub server_keys {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "server_keys must be an arrayref" if defined $value && ref $value ne 'ARRAY';
        $self->{server_keys} = $value;
    }
    return $self->{server_keys};
}

sub runas_user {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{runas_user} = $value;
    }
    return $self->{runas_user};
}

sub runas_group {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{runas_group} = $value;
    }
    return $self->{runas_group};
}

sub server_http {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_http} = $value;
    }
    return $self->{server_http};
}

sub server_perlonly {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_perlonly} = $value;
    }
    return $self->{server_perlonly};
}

sub server_fnext {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_fnext} = $value;
    }
    return $self->{server_fnext};
}

sub server_cgi {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_cgi} = $value;
    }
    return $self->{server_cgi};
}

sub server_cgiext {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{server_cgiext} = $value;
    }
    return $self->{server_cgiext};
}

sub http_postlimit {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{http_postlimit} = $value;
    }
    return $self->{http_postlimit};
}

sub func_timeout {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{func_timeout} = $value;
    }
    return $self->{func_timeout};
}

sub func_perl {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{func_perl} = $value;
    }
    return $self->{func_perl};
}

sub func_done {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{func_done} = $value;
    }
    return $self->{func_done};
}

sub func_log {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{func_log} = $value;
    }
    return $self->{func_log};
}

sub logfn {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{logfn} = $value;
    }
    return $self->{logfn};
}

sub verbose {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "verbose must be 0-3" if defined $value && ($value < 0 || $value > 3);
        $self->{verbose} = $value;
    }
    return $self->{verbose};
}

sub _server {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{_server} = $value;
    }
    return $self->{_server};
}

sub _serverloop {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{_serverloop} = $value;
    }
    return $self->{_serverloop};
}

sub _threads {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{_threads} = $value;
    }
    return $self->{_threads};
}

sub _log_lock {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{_log_lock} = $value;
    }
    return $self->{_log_lock};
}

sub upload_dir {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "upload_dir must be a non-empty string" unless defined $value && $value ne '' && !ref $value;
        $self->{upload_dir} = $value;
    }
    return $self->{upload_dir};
}

sub upload_max_size {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "upload_max_size must be positive" if defined $value && $value <= 0;
        $self->{upload_max_size} = $value;
    }
    return $self->{upload_max_size};
}

sub upload_allowed_types {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "upload_allowed_types must be an arrayref" if defined $value && ref $value ne 'ARRAY';
        $self->{upload_allowed_types} = $value;
    }
    return $self->{upload_allowed_types};
}

sub func_upload {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{func_upload} = $value;
    }
    return $self->{func_upload};
}

sub rate_limit_enabled {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{rate_limit_enabled} = $value;
    }
    return $self->{rate_limit_enabled};
}

sub rate_limit_requests {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "rate_limit_requests must be positive" if defined $value && $value <= 0;
        $self->{rate_limit_requests} = $value;
    }
    return $self->{rate_limit_requests};
}

sub rate_limit_window {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "rate_limit_window must be positive" if defined $value && $value <= 0;
        $self->{rate_limit_window} = $value;
    }
    return $self->{rate_limit_window};
}

sub rate_limit_block_duration {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "rate_limit_block_duration must be non-negative" if defined $value && $value < 0;
        $self->{rate_limit_block_duration} = $value;
    }
    return $self->{rate_limit_block_duration};
}

sub rate_limit_whitelist {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "rate_limit_whitelist must be an arrayref" if defined $value && ref $value ne 'ARRAY';
        $self->{rate_limit_whitelist} = $value;
    }
    return $self->{rate_limit_whitelist};
}

sub _rate_limit_lock {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{_rate_limit_lock} = $value;
    }
    return $self->{_rate_limit_lock};
}

sub _rate_limit_data {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{_rate_limit_data} = $value;
    }
    return $self->{_rate_limit_data};
}

sub _upload_lock {
    my ($self, $value) = @_;
    if (@_ > 1) {
        $self->{_upload_lock} = $value;
    }
    return $self->{_upload_lock};
}

sub _init_config {
    my ($self) = @_;

    if ($self->verbose) {
        for my $attr (qw(server_addr server_name server_type max_threads server_timeout
                         server_dir server_etc server_deny server_secure server_auth
                         runas_user runas_group server_http server_perlonly server_fnext
                         server_cgi server_cgiext http_postlimit logfn verbose)) {
            $self->logit(sprintf("- %-16s = %s", $attr, $self->$attr), 2);
        }
    }
}

sub _create_server {
    my ($self) = @_;

    my $server = IO::Socket::INET->new(
        LocalAddr => $self->server_addr,
        Proto     => 'tcp',
        Listen    => SOMAXCONN,
        ReuseAddr => SO_REUSEADDR
    );

    if (!$server) {
        $self->logit("# Error: Failed to bind to " . $self->server_addr . " - $!", 0);
        return undef;
    }

    $self->_server($server);
    $self->logit("# " . $self->server_name . " Listening for requests on " . $self->server_addr, 0);
    return $server;
}

sub _set_runas {
    my ($self) = @_;

    my $user = $self->runas_user;
    my $group = $self->runas_group;

    if ($user ne '' || $group ne '') {
        if ($group ne '') {
            my $gid = getgrnam($group);
            $) = "$gid $gid" or $self->logit("# Error setting group $group: $!", 0) if $gid;
        }
        if ($user ne '') {
            my $uid = getpwnam($user);
            chown($uid, -1, $self->logfn) if $self->logfn ne '';
            $> = $uid or $self->logit("# Error setting user $user: $!", 0) if $uid;
        }
        $self->logit("# Running as user $user and group $group", 0);
    }
}

sub start {
    my ($self) = @_;

    my $server = $self->_create_server();
    return 0 unless defined $server;

    $self->_set_runas();

    $self->_serverloop(1);
    $| = 1;

    local $SIG{INT}  = sub { $self->_signal_handler() };
    local $SIG{TERM} = sub { $self->_signal_handler() };

    #$self->logit("# " . $self->server_name . " Listening for requests on " . $self->server_addr, 0);

    my $threads = $self->_threads;

    while ($self->_serverloop) {
        if ($self->server_timeout == 0) {
            my $remain = 86400 - (time() % 86400);
            $server->timeout($remain);
        } elsif ($self->server_timeout > 0) {
            $server->timeout($self->server_timeout);
        }

        my $client = $server->accept();
        if ($self->_serverloop) {
            if (!defined $client) {
                if ($! =~ /timed out/i) {
                    $self->logit("# Timeout waiting for client connection (timeout: " . $self->server_timeout . "s)");
                    if ($self->server_timeout == 0) {
                        $self->_serverloop(0);
                    } else {
                        my $func = $self->func_timeout;
                        $func->($self) if $func;
                    }
                } else {
                    $self->logit("# Error accepting client connection: $!", 0);
                }
            } elsif ($self->server_type eq 'fork') {
                my $pid = fork;
                die "fork: $!" unless defined $pid;
                if ($pid) {
                    close $client;
                } else {
                    close $server;
                    $self->_handle_client($client);
                    exit 0;
                }
            } elsif ($self->server_type eq 'thread') {
                while (scalar(@$threads) >= $self->max_threads) {
                    $threads = [ grep { $_->is_running() } @$threads ];
                    sleep 1 if scalar(@$threads) >= $self->max_threads;
                }
                my $thr = threads->create(sub { $self->_handle_client($client); threads->detach(); });
                push @$threads, $thr;
                $threads = [ grep { $_->is_running() } @$threads ];
            } else {
                $self->_handle_client($client);
            }
        } elsif (defined $client) {
            close($client);
        }
    }

    if ($self->server_type eq 'thread') {
        $self->logit("# Shutting down threads...", 0);
        for my $thr (@$threads) {
            $thr->join() if $thr->is_running();
        }
    }

    close($server);
    $self->_server(0);
    return 1;
}

sub _signal_handler {
    my ($self) = @_;
    return unless defined $self->_serverloop;
    $self->_serverloop(0);
    print STDERR "\n";
    $self->logit("# Closing server loop and setting timeout to 0", 0);
    if (defined $self->_server && $self->_server->can('timeout')) {
        $self->_server->timeout(0);
    }
}

sub _handle_client {
    my ($self, $client) = @_;

    my $clip = $client->peerhost();
    my $clport = $client->peerport();

    if ($self->rate_limit_enabled) {
        my $block_info = $self->_is_blocked($clip);
        if ($block_info) {
            $self->_send_rate_limit_response($client, $clip, $block_info);
            return;
        }

        unless ($self->_check_rate_limit($clip)) {
            $self->_block_ip($clip, $self->rate_limit_block_duration);
            $self->_send_rate_limit_response($client, $clip, {blocked => 1});
            return;
        }
    }

    my %req = (clip => $clip, clport => $clport);
    my $allow = $self->_checkhost(\%req);

    if ($allow eq 'deny') {
        close($client);
        return;
    }

    if (!($allow eq 'allow')) {
        if (!$self->_checkauth(\%req)) {
            $self->_send_unauthorized($client, $req{clip});
            return;
        }
    }

    if ($self->server_http) {
        $self->_httpparse($client, \%req);
    } else {
        my $func = $self->func_perl;
        $func->($self, $client, \%req) if $func;
    }

    close($client);
}

sub _checkhost {
    my ($self, $preq) = @_;

    return 'allow' if $self->server_deny == 0;

    my $bfn = $self->server_etc . '/' . $self->server_name . '_' . $preq->{clip};
    return 'allow' if -f "$bfn.allow" || $preq->{clip} eq '127.0.0.1';
    return 'deny' if -f "$bfn.deny";

    my $ext = $self->server_secure ? 'deny' : 'access';
    my $fn = $bfn . '.' . $ext;

    if (!-f $fn) {
        $self->logit("  TCP checkallow $fn");
        if (open(my $tfp, '>', $fn)) {
            my ($now_str, $now) = $self->_gettime();
            print $tfp "$now access\n";
            close($tfp);
            chmod(0660, $fn);
        } else {
            $self->logit("# Error creating $fn: $!");
        }
    }
    return $ext;
}

sub _checkauth {
    my ($self, $preq) = @_;

    return 1 unless $self->server_auth;

    my $client_key = '';
    $client_key = $preq->{'X-API-KEY'} if exists $preq->{'X-API-KEY'};
    (undef, $client_key) = split(/\s+/, $preq->{'AUTHORIZATION'}, 2)
        if exists $preq->{'AUTHORIZATION'} && $preq->{'AUTHORIZATION'} =~ /^Basic /i;

    if ($client_key ne '') {
        $client_key = lc($client_key);
        my %valid_keys = map { $_ => 1 } @{$self->server_keys};
        if (exists $valid_keys{$client_key}) {
            $self->logit("# Authenticated: using $client_key");
            return 1;
        }
    }

    $self->logit("# Authentication failed: No valid X-API-Key or Basic Auth", 1);
    return 0;
}

sub _send_unauthorized {
    my ($self, $client, $clip) = @_;

    my $response = "HTTP/1.1 401 Unauthorized\r\n";
    $response .= "WWW-Authenticate: Basic realm=\"Restricted Area\"\r\n";
    $response .= "Content-Type: text/plain\r\n";
    $response .= "Content-Length: 33\r\n";
    $response .= "Connection: close\r\n";
    $response .= "\r\n";
    $response .= "Error 401: Authentication required";

    print $client $response;
}

sub _httpparse {
    my ($self, $client, $preq) = @_;

    my $clip = $client->peerhost();
    my $clport = $client->peerport();
    my $request = $self->_httprequest($client);

    return if !defined $request;

    $self->logit("invalid request uri_fn=$request->{URI_FN}") if $self->server_perlonly == 0 && $request->{URI_VALID} == 0;

    if ($self->verbose >= 3) {
        for my $key (sort keys %$request) {
            $self->logit("- RECV HDR $key : $request->{$key}");
        }
    }

    $clip = $request->{'X-REAL-IP'} if exists $request->{'X-REAL-IP'};
    $clip = $request->{'X-FORWARDED-FOR'} if exists $request->{'X-FORWARDED-FOR'};
    $request->{clip} = $clip;
    $request->{clport} = $clport;

    my $allowed = $self->_checkhost($request);

    if ($allowed eq 'deny') {
        $request->{sStatus} = "403 Forbidden";
        $request->{sReturn} = "Error 403: Access denied for $clip";
        $self->logit("# Access denied: Denied by host check for $clip", 1);
        $self->_httperror($client, $request);
        return;
    }

    if ($request->{METHOD} eq '' || !defined $request->{URI_FN}) {
        $request->{sStatus} = "403 Forbidden";
        $request->{sReturn} = "Error 403: Access denied for $clip";
        $self->logit("# Access denied: Denied by host check for $clip", 1);
        return $self->_httperror($client, $request);
    }

    $self->logit("- FROM IP : $clip:$clport", 3);

    if ($self->verbose == 2) {
        $self->logit("- --------- RAW HEADER DATA:\n$request->{RAW_DATA}");
    }

    my ($stat, $len);
    my $fn = $self->server_dir . $request->{URI_FN};
    my $func = $self->func_perl;

    my $uri_fn = $request->{URI_FN} || '';

    if ($uri_fn eq '/upload' || $uri_fn eq '/upload/' || $uri_fn eq '/api/upload') {
        if ($request->{METHOD} eq 'POST' && $request->{UPLOADS}) {
            ($stat, $len) = $self->_handle_upload($client, $request);
            return;
        } elsif ($request->{METHOD} eq 'GET') {
            ($stat, $len) = $self->_send_upload_form($client);
        } else {
            ($stat, $len) = $self->_send_upload_response($client, 405, 'Method Not Allowed. Use GET to see form, POST to upload.');
        }
    } elsif ($self->server_cgi && $request->{URI_VALID} && index($self->server_cgiext, $request->{URI_EXT}) >= 0) {
        ($stat, $len) = $self->_cgiexec($client, $request);
    } elsif ($request->{URI_VALID} && -f $fn && $self->server_perlonly == 0 &&
             ($self->server_fnext eq '' || index($self->server_fnext, $request->{URI_EXT}) >= 0)) {
        ($stat, $len) = $self->_httpfn($client, $request);
    } elsif ($func) {
        ($stat, $len) = $func->($self, $client, $request);
    } else {
        ($stat, $len) = $self->_httperror($client, $request);
    }

    if ($self->logfn ne '' || $self->verbose) {
        $self->logit("$clip - $request->{METHOD} \"$request->{URI}\" $stat $len", 1);
    }

    $func = $self->func_done;
    $func->($self, $request) if $func;
}

sub _httprequest {
    my ($self, $client) = @_;

    my %request = (
        QUERY_STRING   => '',
        METHOD         => '',
        CONTENT_LENGTH => 0,
        CONTENT_DATA   => '',
        RAW_DATA       => ''
    );
    $ENV{QUERY_STRING} = '';
    $ENV{REQUEST_METHOD} = '';

    $client->timeout(30);

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(30);
        while (<$client>) {
            if (!defined($_)) {
                $self->logit("# Error: Client $client->peerhost() disconnected or read failed: $!", 1);
                last;
            }
            $request{RAW_DATA} .= $_;
            s/[\r\n\s]+$//;
            print STDERR "  $_\n" if $self->verbose > 2 && $_ ne '';
            if (/\s*(\w+)\s*([^\s]+)\s*HTTP\/(\d.\d)/) {
                $ENV{REQUEST_METHOD} = uc($1);
                $request{METHOD} = $ENV{REQUEST_METHOD} || 'GET';
                $self->_httpuri(\%request, $2);
                $request{HTTP_VERSION} = $3 || '1.0';
            } elsif (/:/) {
                my ($nm, $val) = split /\s*:\s*/, $_, 2;
                $nm =~ s/^\s+//;
                $request{uc($nm)} = $val if $val ne '';
            } elsif (/^$/) {
                my $len = $request{'CONTENT-LENGTH'} || 0;
                $len = $self->http_postlimit if $self->http_postlimit && $len > $self->http_postlimit;
                $ENV{CONTENT_LENGTH} = $len;
                $request{CONTENT_LENGTH} = $len;
                if ($len > 0) {
                    my $content_type = $request{'CONTENT-TYPE'} || '';
                    if ($content_type =~ /multipart\/form-data/i) {
                        read($client, $request{CONTENT_DATA}, $len);
                        if (my $boundary = $self->_extract_boundary($content_type)) {
                            my $uploads = $self->_parse_multipart($boundary, $request{CONTENT_DATA});
                            $request{UPLOADS} = $uploads if @$uploads;
                            $request{CONTENT_DATA} = '' if $request{UPLOADS};
                        }
                    } else {
                        read($client, $request{CONTENT_DATA}, $len);
                    }
                }
                last;
            } else {
                last;
            }
        }
        alarm(0);
    };

    if ($@) {
        $self->logit("# Error: Client request timed out or failed: $@");
        $request{sStatus} = "408 Request Timeout";
        $request{sReturn} = "Error 408: Request timed out";
        $request{sContentType} = $self->_httpcontent('txt');
        $self->_reply($client, \%request);
        return undef;
    }

    return \%request;
}

sub _httpuri {
    my ($self, $preq, $uri) = @_;

    $preq->{URI} = $uri || '';
    $preq->{URI_FN} = $uri;
    $preq->{URI_PARAMS} = '';
    ($preq->{URI_FN}, $preq->{URI_PARAMS}) = split(/[?]/, $uri, 2) if index($uri, '?') > 0;
    $preq->{URI_FN} .= 'index.html' if substr($preq->{URI_FN}, -1) eq '/';
    my @flds = split(/\./, $preq->{URI_FN});
    $preq->{URI_EXT} = '';
    $preq->{URI_EXT} = pop @flds if $#flds > 0;
    $preq->{URI_VALID} = 0;
    $preq->{URI_VALID} = 1 if $#flds == 0 && $preq->{URI_EXT} ne '';
    $preq->{URI_VALID} = 0 if $preq->{URI_FN} =~ /[\\\!\$+\%<;:]/ || $preq->{URI_FN} =~ /\.\./;
    $ENV{QUERY_STRING} = $preq->{URI_PARAMS};
    $preq->{QUERY_STRING} = $preq->{URI_PARAMS};
}

sub _httpcontent {
    my ($self, $ext) = @_;

    my %MIMETYPE = (
        "txt"  => "text/plain", "html" => "text/html", "htm"  => "text/html", "css"  => "text/css",
        "jpg"  => "image/jpeg", "jpeg" => "image/jpeg", "gz"   => "application/gzip", "zip"  => "application/zip",
        "gif"  => "image/gif",  "mp3"  => "audio/mpeg", "ico"  => "image/x-icon", "xml"  => "text/xml",
        "png"  => "image/png",  "tar"  => "application/tar", "js"   => "text/javascript"
    );

    my $typ = $MIMETYPE{txt};
    $typ = $MIMETYPE{$ext} if $ext ne 'txt' && exists $MIMETYPE{$ext};
    return $typ;
}

sub _cgiexec {
    my ($self, $client, $preq) = @_;

    $preq->{sStatus} = "400 Not Found";
    $preq->{sReturn} = "Error 400: File not found ($preq->{URI_FN})";
    $preq->{sContentType} = 'text/plain';
    $preq->{opthead} = '';
    $preq->{len} = 0;

    my $fn = $self->server_dir . $preq->{URI_FN};

    if ($preq->{URI_VALID} && -f $fn) {
        if ($fn =~ /\.\./ || index($fn, '..') >= 0) {
            $self->logit("# CGI Security: Path traversal attempt detected in $fn", 1);
            $preq->{sStatus} = "403 Forbidden";
            $preq->{sReturn} = "Error 403: Invalid CGI path";
            return $self->_reply($client, $preq);
        }

        my ($cgi_in, $cgi_out, $cgi_err);
        my $pid;

        eval {
            $pid = open3($cgi_in, $cgi_out, $cgi_err, $fn, "");
        };

        if ($@) {
            $self->logit("# Error executing CGI $fn: $@");
            $preq->{sStatus} = "500 Internal Server Error";
            $preq->{sReturn} = "Error 500: CGI execution failed ($@)";
        } else {
            if ($preq->{METHOD} =~ /POST/i) {
                print $cgi_in $preq->{CONTENT_DATA} or $self->logit("# Error sending POST data to CGI: $!");
            }
            close $cgi_in;
            my $output = do { local $/; <$cgi_out> };
            my $errors = do { local $/; <$cgi_err> };
            close $cgi_out;
            close $cgi_err;
            waitpid($pid, 0);
            my $exit_status = $? >> 8;

            if ($exit_status != 0) {
                $self->logit("# CGI $fn failed with exit status $exit_status: $errors");
                $preq->{sStatus} = "500 Internal Server Error";
                $preq->{sReturn} = "Error 500: CGI script failed ($errors)";
            } else {
                my ($header, $body) = split(/\r?\n\r?\n/, $output, 2);
                $preq->{sStatus} = '200 OK';
                $preq->{sStatus} = '302 Found' if $output =~ /^\r?Status:\s+302/;
                $preq->{sContentType} = '' if $output =~ m#^\r?Content-Type:.*?\r?\n\r?\n#mi || $preq->{sStatus} eq '302 Found';
                $preq->{opthead} = $header;
                $preq->{sReturn} = $body if length($body);
                return $self->_reply($client, $preq);
            }
        }
    }

    return $self->_reply($client, $preq);
}

sub _httpfn {
    my ($self, $client, $preq) = @_;

    my $sStatus = '';
    my $sReturn = '';
    my $opthead = '';
    my $sContentType = '';
    my $len = 0;
    my $fn = $self->server_dir . $preq->{URI_FN};

    if ($preq->{URI_VALID} && -f $fn) {
        if ($fn =~ /\.\./ || index($fn, '..') >= 0) {
            $self->logit("# Security: Path traversal attempt detected in $fn", 1);
            $sStatus = "403 Forbidden";
            $sReturn = "Error 403: Invalid path";
            $preq->{sContentType} = $self->_httpcontent('txt');
            $preq->{sStatus} = $sStatus;
            $preq->{sReturn} = $sReturn;
            $preq->{len} = length($sReturn);
            return $self->_reply($client, $preq);
        }

        my (undef, undef, undef, undef, undef, undef, undef, $size, undef, $mtime) = stat($fn);
        my $mtime_str = gmtime $mtime;
        my ($day, $mon, $dm, $tm, $yr) = ($mtime_str =~ m/(...) (...) (..) (..:..:..) (....)/);
        $opthead = "Last-Modified: $day, $dm $mon $yr $tm GMT";

        if (-r $fn) {
            if (open(my $fh, '<', $fn)) {
                binmode($fh);
                $len = $size;
                my $bytes_read = read($fh, $sReturn, $len);
                if (!defined $bytes_read) {
                    $self->logit("# Error reading file $fn: $!");
                    $sStatus = "500 Internal Server Error";
                    $sReturn = "Error 500: Failed to read file";
                } elsif ($preq->{METHOD} eq 'GET') {
                    $sStatus = "200 OK";
                } elsif ($preq->{METHOD} eq 'HEAD') {
                    $sReturn = '';
                    $sStatus = "200 OK";
                }
                close($fh);
            } else {
                $self->logit("# Error opening file $fn: $!");
                $sStatus = "500 Internal Server Error";
                $sReturn = "Error 500: Unable to open file";
            }
        } else {
            $self->logit("# Error: File $fn is not readable or accessible");
            $sStatus = "403 Forbidden";
            $sReturn = "Error 403: File access denied";
        }
    } else {
        $sStatus = "404 Not Found";
        $sReturn = "Error 404: File not found ($fn)";
    }

    $sContentType = $self->_httpcontent(lc($preq->{URI_EXT})) if $sContentType eq '';
    $preq->{sContentType} = $sContentType;
    $preq->{sStatus} = $sStatus;
    $preq->{opthead} = $opthead;
    $preq->{sReturn} = $sReturn;
    $preq->{len} = $len;

    return $self->_reply($client, $preq);
}

sub _httperror {
    my ($self, $client, $preq) = @_;

    $preq->{sContentType} = $self->_httpcontent('txt') if not exists $preq->{sContentType};
    $preq->{opthead} = '' if not exists $preq->{opthead};

    if ($preq->{sStatus} eq '') {
        $preq->{sStatus} = "400 Not Found";
        $preq->{sReturn} = "Error 400: File not found ($preq->{URI_FN})";
    }

    $preq->{len} = length($preq->{sReturn}) if not exists $preq->{len} || $preq->{len} == 0;

    return $self->_reply($client, $preq);
}

sub _reply {
    my ($self, $client, $preq) = @_;

    $preq->{sContentType} = 'text/plain' if not exists $preq->{sContentType};
    $preq->{len} = length($preq->{sReturn}) if not exists $preq->{len} || $preq->{len} == 0;

    my @aheaders = ("HTTP/1.1 $preq->{sStatus}");
    push(@aheaders, "Server: $self->{server_name}") if $self->server_name ne '';
    push(@aheaders, "Connection: close");
    push(@aheaders, "Content-Type: $preq->{sContentType}") if $preq->{sContentType} ne '';
    push(@aheaders, $preq->{opthead}) if $preq->{opthead} ne '';
    push(@aheaders, "Content-Length: $preq->{len}");

    eval {
        local $SIG{PIPE} = sub { die "Broken pipe\n" };
        print $client join("\r\n", @aheaders) . "\r\n\r\n" . $preq->{sReturn}
            or die "Write failed: $!\n";
    };

    if ($@) {
        $self->logit("# Error sending response to client $preq->{clip}: $@");
    }

    close($client);

    if ($self->verbose > 2) {
        print STDERR "# reply header:\n";
        print STDERR "  " . join("\n  ", @aheaders) . "\n";
    }

    $self->logit("status=$preq->{sStatus}  type=$preq->{sContentType}  len=$preq->{len}  $preq->{opthead}");

    my $stat = substr($preq->{sStatus}, 0, 3);
    $preq->{stat} = $stat;

    return ($stat, $preq->{len});
}

sub logit {
    my ($self, $msg, $lvl) = @_;

    $lvl = 2 if !defined $lvl || $lvl eq '';
    return if $lvl > $self->verbose;

    lock ${ $self->_log_lock };

    my $func_log = $self->func_log;
    if ($func_log) {
        $func_log->($self, $msg, $lvl);
        return;
    }

    if ($self->logfn ne '') {
        my ($timestr) = $self->_gettime();
        $timestr =~ s/-//g;
        my $logline = substr($timestr, 2) . " $msg\n";

        my $logfn = $self->logfn;
        my $tmpfn = $logfn . '.tmp.' . $$ . '.' . time() . '.' . int(rand(1000000));

        if (open(my $tmpfp, '>', $tmpfn)) {
            print $tmpfp $logline;
            close($tmpfp);
            rename($tmpfn, $logfn) or unlink($tmpfn);
        }
    }
}

sub _gettime {
    my ($self) = @_;

    my $now = time();
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($now);
    my $tstr = sprintf "%04d-%02d-%02d %02d:%02d:%02d", 1900 + $year, $mon + 1, $mday, $hour, $min, $sec;
    return ($tstr, $now);
}

sub stop {
    my ($self) = @_;
    $self->_serverloop(0);
}

sub is_running {
    my ($self) = @_;
    return $self->_serverloop ? 1 : 0;
}

sub validate_config {
    my $pCONF = shift;

    # Support both class method and function call styles
    # If first arg is a hashref, it's the config; otherwise it's the class name
    if (ref($pCONF) ne 'HASH') {
        $pCONF = shift;
    }

    return 'server_addr is required' unless defined $pCONF && ref($pCONF) eq 'HASH';
    return 'server_addr is required' unless defined $pCONF->{server_addr} && $pCONF->{server_addr} ne '';
    if ($pCONF->{server_addr} !~ /^[0-9.]+:\d+$/) {
        return 'server_addr must be in format IP:port (e.g., 0.0.0.0:8080)';
    }

    if (!defined $pCONF->{server_type} || $pCONF->{server_type} eq '') {
        return 'server_type is required';
    }
    if ($pCONF->{server_type} ne 'single' && $pCONF->{server_type} ne 'fork' && $pCONF->{server_type} ne 'thread') {
        return 'server_type must be single, fork, or thread';
    }

    if ($pCONF->{server_type} eq 'thread' && (!defined $pCONF->{max_threads} || $pCONF->{max_threads} <= 0)) {
        return 'max_threads must be positive when server_type is thread';
    }

    if (defined $pCONF->{verbose} && ($pCONF->{verbose} < 0 || $pCONF->{verbose} > 3)) {
        return 'verbose must be between 0 and 3';
    }

    if (defined $pCONF->{http_postlimit} && $pCONF->{http_postlimit} < 0) {
        return 'http_postlimit must be >= 0';
    }

    if ($pCONF->{server_deny} && (!defined $pCONF->{server_etc} || $pCONF->{server_etc} eq '')) {
        return 'server_etc is required when server_deny is enabled';
    }

    if ($pCONF->{server_auth} && (!defined $pCONF->{server_keys} || ref($pCONF->{server_keys}) ne 'ARRAY')) {
        return 'server_keys must be an arrayref when server_auth is enabled';
    }

    return undef;
}

# ============================================================================
# File Upload Methods
# ============================================================================

sub _send_upload_form {
    my ($self, $client) = @_;

    my $max_mb = $self->upload_max_size / (1024 * 1024);
    my $allowed_types = join(', ', @{$self->upload_allowed_types});

    my $html = <<"HTML";
<!DOCTYPE html>
<html>
<head>
    <title>File Upload</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .error { color: red; margin: 10px 0; }
        button { background: #4CAF50; color: white; padding: 10px 20px; border: none; cursor: pointer; }
        button:hover { background: #45a049; }
    </style>
</head>
<body>
    <h1>File Upload</h1>
    <div class="info">
        <strong>Maximum file size:</strong> ${max_mb}MB<br>
        <strong>Allowed types:</strong> $allowed_types
    </div>
    <form action="/upload" method="POST" enctype="multipart/form-data">
        <p><input type="file" name="file" required></p>
        <p><button type="submit">Upload File</button></p>
    </form>
</body>
</html>
HTML

    my $len = length($html);

    my @headers = (
        "HTTP/1.1 200 OK",
        "Server: " . $self->server_name,
        "Content-Type: text/html; charset=utf-8",
        "Content-Length: $len",
        "Connection: close",
    );

    print $client join("\r\n", @headers) . "\r\n\r\n" . $html;
    close($client);

    return (200, $len);
}

sub _handle_upload {
    my ($self, $client, $request) = @_;

    my @upload_results;
    my $clip = $request->{clip} || 'unknown';

    if (!$request->{UPLOADS} || @{$request->{UPLOADS}} == 0) {
        $self->logit("# Upload request from $clip with no files", 1);
        return $self->_send_upload_response($client, 400, 'No files uploaded');
    }

    for my $upload (@{$request->{UPLOADS}}) {
        my $filename = $upload->{filename} || 'unnamed';
        my $size = $upload->{size} || 0;
        my $mime_type = $upload->{mime_type} || 'application/octet-stream';

        $self->logit("# Processing upload: $filename ($size bytes, $mime_type) from $clip", 2);

        my ($success, $message, $saved_path) = $self->_save_upload_file(
            $filename,
            $upload->{data},
            $mime_type,
        );

        if ($success) {
            $self->logit("# Upload success: $filename -> $saved_path", 1);
            push @upload_results, {
                filename    => $filename,
                size        => $size,
                mime_type   => $mime_type,
                saved_path  => $saved_path,
                success     => 1,
            };
        } else {
            $self->logit("# Upload failed: $filename - $message", 1);
            push @upload_results, {
                filename    => $filename,
                size        => $size,
                mime_type   => $mime_type,
                success     => 0,
                error       => $message,
            };
        }
    }

    my $func = $self->func_upload;
    if ($func) {
        my ($status, $body) = $func->($self, \@upload_results);
        return $self->_send_upload_response($client, $status, $body);
    }

    my $success_count = scalar grep { $_->{success} } @upload_results;
    my $total_count = scalar @upload_results;

    if ($success_count == $total_count) {
        return $self->_send_upload_response($client, 201, "All $success_count file(s) uploaded successfully");
    } elsif ($success_count > 0) {
        return $self->_send_upload_response($client, 207, "$success_count of $total_count files uploaded");
    } else {
        return $self->_send_upload_response($client, 400, "No files uploaded successfully");
    }
}

sub _extract_boundary {
    my ($self, $content_type) = @_;

    return undef unless defined $content_type && $content_type ne '';

    if ($content_type =~ /boundary=(.+)$/i) {
        my $boundary = $1;
        $boundary =~ s/^["']+|["']+$//g;
        return $boundary;
    }

    return undef;
}

sub _parse_multipart {
    my ($self, $content_type, $body) = @_;

    my @uploads;

    my $boundary;
    if ($content_type =~ /boundary=(.+)$/i) {
        $boundary = $1;
        $boundary =~ s/^["']|["']$//g;
    } else {
        $self->logit("# No boundary found in Content-Type: $content_type", 1);
        return \@uploads;
    }

    my $delimiter = "--$boundary";
    my $end_delimiter = "$boundary--";

    my $part_start = 0;
    my $part_end = index($body, $delimiter, $part_start);

    while ($part_end > 0) {
        my $part = substr($body, $part_start, $part_end - $part_start);
        $part =~ s/^\r?\n//;

        if ($part ne $end_delimiter && $part ne '') {
            my ($headers, $data) = $self->_split_part_headers($part);
            if ($headers && $data ne '') {
                my $disposition = $headers->{'Content-Disposition'} || '';
                if ($disposition =~ /filename="([^"]+)"/) {
                    my $filename = $1;
                    my $safe_name = $self->_sanitize_filename($filename);
                    my $mime_type = $headers->{'Content-Type'} || 'application/octet-stream';

                    push @uploads, {
                        filename    => $safe_name,
                        data        => $data,
                        mime_type   => $mime_type,
                        size        => length($data),
                    };
                }
            }
        }

        $part_start = $part_end + length($delimiter) + 2;
        last if $part_start >= length($body);
        $part_end = index($body, $delimiter, $part_start);
    }

    return \@uploads;
}

sub _split_part_headers {
    my ($self, $part) = @_;

    my ($header_section, $body) = $part =~ /^((?:[^\r\n]+\r?\n)*)\r?\n(.*)$/s;

    return (undef, $part) unless defined $header_section && defined $body;

    my %headers;
    for my $line (split /\r?\n/, $header_section) {
        if ($line =~ /^([^:]+):\s*(.+)$/) {
            $headers{$1} = $2;
        }
    }

    return (\%headers, $body);
}

sub _save_upload_file {
    my ($self, $filename, $data, $mime_type) = @_;

    my $max_size = $self->upload_max_size;
    if (length($data) > $max_size) {
        return (0, "File exceeds maximum size of " . ($max_size / 1024 / 1024) . "MB");
    }

    unless ($self->_validate_upload_type($mime_type)) {
        return (0, "File type not allowed: $mime_type");
    }

    my $upload_dir = $self->upload_dir;
    unless (-d $upload_dir) {
        mkdir($upload_dir, 0755) or return (0, "Cannot create upload directory: $!");
    }

    my $safe_name = $self->_sanitize_filename($filename);
    my $target_path = "$upload_dir/$safe_name";

    lock ${ $self->_upload_lock };

    my $temp_fd = File::Temp->new(
        DIR     => $upload_dir,
        SUFFIX  => '.tmp',
        UNLINK  => 0,
    );
    print $temp_fd $data;
    close($temp_fd);

    if (rename($temp_fd, $target_path)) {
        chmod(0644, $target_path);
        $self->logit("# Saved upload: $target_path (" . length($data) . " bytes)", 2);
        return (1, $target_path, $target_path);
    } else {
        unlink($temp_fd);
        return (0, "Failed to save file: $!");
    }
}

sub _sanitize_filename {
    my ($self, $filename) = @_;

    return 'unnamed_file' unless defined $filename && $filename ne '';

    $filename =~ s/^["']+|["']+$//g;

    $filename =~ s/\.\.//g;
    $filename =~ s/[\\\/]+//g;

    $filename =~ s/[^\w\.\-]/_/g;

    $filename =~ s/^\s+|\s+$//g;

    $filename = 'unnamed_file' if $filename =~ /^\.+$/;
    $filename = 'unnamed_file' if $filename eq '';

    my ($base, $ext) = $filename =~ /^(.+?)(\.[^.]+)?$/;
    $base = 'file' if $base eq '';
    $filename = defined $ext ? "$base$ext" : $base;

    return $filename;
}

sub _validate_upload_type {
    my ($self, $mime_type) = @_;

    return 1 unless defined $mime_type && $mime_type ne '';

    my $allowed = $self->upload_allowed_types;
    return 1 unless @$allowed;

    $mime_type = lc($mime_type);
    for my $allowed_type (@$allowed) {
        return 1 if lc($allowed_type) eq $mime_type;
    }

    $self->logit("# Rejected upload type: $mime_type", 1);
    return 0;
}

sub _send_upload_response {
    my ($self, $client, $status, $body) = @_;

    my $status_text = $status eq '201' ? 'Created' :
                      $status eq '400' ? 'Bad Request' :
                      $status eq '207' ? 'Multi-Status' : 'Response';

    my $len = length($body);

    my @headers = (
        "HTTP/1.1 $status $status_text",
        "Server: " . $self->server_name,
        "Content-Type: text/plain",
        "Content-Length: $len",
        "Connection: close",
    );

    print $client join("\r\n", @headers) . "\r\n\r\n" . $body;
    close($client);

    return ($status, $len);
}

# ============================================================================
# Rate Limiting Methods
# ============================================================================

sub _check_rate_limit {
    my ($self, $ip) = @_;

    my $whitelist = $self->rate_limit_whitelist;
    for my $_ip (@$whitelist) {
        return 1 if $ip eq $_ip;
    }

    my $lock = $self->_rate_limit_lock;
    lock($$lock);

    my $data = $self->_rate_limit_data;

    my $now = time();
    my $window = $self->rate_limit_window;
    my $max_requests = $self->rate_limit_requests;

    my $ip_data = $data->{$ip} //= { count => 0, first_request => $now };

    if ($now - $ip_data->{first_request} > $window) {
        $ip_data->{count} = 0;
        $ip_data->{first_request} = $now;
    }

    $ip_data->{count}++;
    $self->logit("# Rate limit check for $ip: $ip_data->{count}/$max_requests", 3) if $self->verbose >= 3;

    return $ip_data->{count} <= $max_requests;
}

sub _is_blocked {
    my ($self, $ip) = @_;

    my $lock = $self->_rate_limit_lock;
    lock($$lock);

    my $data = $self->_rate_limit_data;

    return undef unless exists $data->{"blocked:$ip"};

    my $block_info = $data->{"blocked:$ip"};
    my $now = time();

    if ($now > $block_info->{until}) {
        delete $data->{"blocked:$ip"};
        $self->logit("# Rate limit expired for $ip", 2);
        return undef;
    }

    return $block_info;
}

sub _block_ip {
    my ($self, $ip, $duration) = @_;

    my $lock = $self->_rate_limit_lock;
    lock($$lock);

    my $data = $self->_rate_limit_data;

    $data->{"blocked:$ip"} = {
        until    => time() + $duration,
        reason   => 'rate_limit_exceeded',
        requests => $self->rate_limit_requests,
        window   => $self->rate_limit_window,
    };

    $self->logit("# Blocked IP $ip for ${duration}s (rate limit exceeded)", 1);
}

sub _send_rate_limit_response {
    my ($self, $client, $ip, $block_info) = @_;

    my $remaining = $block_info ? 0 : $self->rate_limit_requests;
    my $limit = $self->rate_limit_requests;
    my $reset = $block_info ? $block_info->{until} - time() : $self->rate_limit_window;
    my $retry_after = $block_info ? $block_info->{until} - time() : 1;

    my $body = $block_info
        ? "Error 429 Too Many Requests\nIP $ip has been temporarily blocked due to rate limit exceeded. Retry after $retry_after seconds.\n"
        : "Error 429 Too Many Requests\nRate limit exceeded. Please slow down.\n";

    my $len = length($body);

    my @headers = (
        "HTTP/1.1 429 Too Many Requests",
        "Server: " . $self->server_name,
        "Content-Type: text/plain",
        "Content-Length: $len",
        "Connection: close",
        "X-RateLimit-Limit: $limit",
        "X-RateLimit-Remaining: $remaining",
        "X-RateLimit-Reset: $reset",
        "Retry-After: $retry_after",
    );

    print $client join("\r\n", @headers) . "\r\n\r\n" . $body;
    close($client);

    $self->logit("# Sent rate limit response to $ip (blocked: " . ($block_info ? 'yes' : 'warning') . ")", 1);
}

# ============================================================================

1;

=pod

=head1 NAME

LightTCP::Server - A configurable TCP server with HTTP, CGI, and threading support (Pure Perl OOP)

=head1 SYNOPSIS

    use LightTCP::Server;

    # Basic OOP usage
    my $server = LightTCP::Server->new(
        server_addr => '0.0.0.0:8080',
        server_name => 'MyServer',
        verbose     => 1,
    );
    $server->start();

    # With custom request handler
    my $server = LightTCP::Server->new(
        server_addr => '127.0.0.1:8881',
        server_type => 'thread',
        max_threads => 5,
        func_perl   => sub {
            my ($self, $client, $preq) = @_;
            print $client "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nHello!";
            return (200, 6);
        },
    );
    $server->start();

=head1 DESCRIPTION

C<LightTCP::Server> is a Perl module that implements a flexible TCP server using pure Perl OOP.
It handles HTTP requests, serves static files, executes CGI scripts, and supports
custom logic via callbacks. Features single-threaded, forked, or threaded operation.

=head1 ATTRIBUTES

=over 4

=item C<server_addr> (default: '0.0.0.0:8881')

IP address and port to listen on.

=item C<server_type> (default: 'single')

Execution mode: C<'single'>, C<'fork'>, or C<'thread'>.

=item C<max_threads> (default: 10)

Maximum concurrent threads for threaded mode.

=item C<verbose> (default: 0)

Verbosity level 0-3.

=item C<server_auth> (default: 0)

Enable authentication.

=item C<server_keys>

Arrayref of valid authentication keys.

=item C<func_perl>

Coderef for custom request handling.

=back

=head1 METHODS

=over 4

=item C<new(%config)>

Create a new server instance.

=item C<start()>

Start the server and block until shutdown.

=item C<stop()>

Stop the server gracefully.

=item C<logit($msg, $lvl)>

Log a message at the given level.

=item C<is_running()>

Returns true if server is running.

=item C<validate_config(\%config)>

Class method to validate configuration. Returns undef on success, error message on failure.

=back

=head1 EXAMPLES

See L<examples/demo.pl> for a complete example.

=head1 DATE

Last updated: January 2026

=cut
