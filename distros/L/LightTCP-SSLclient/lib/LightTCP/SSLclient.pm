package LightTCP::SSLclient;

use strict;
use warnings;
use IO::Socket::SSL;
use IO::Socket::INET;
use MIME::Base64 qw(encode_base64);
use URI;

our $VERSION = '1.06';

use base 'Exporter';

our @EXPORT_OK = qw(
    ECONNECT
    EREQUEST
    ERESPONSE
    ETIMEOUT
    ESSL
);

our %EXPORT_TAGS = (
    errors => [qw(ECONNECT EREQUEST ERESPONSE ETIMEOUT ESSL)],
);

use constant {
    ECONNECT  => 1,
    EREQUEST  => 2,
    ERESPONSE => 3,
    ETIMEOUT  => 4,
    ESSL      => 5,
};

sub new {
    my ($class, %opts) = @_;
    my $self = {
        timeout        => $opts{timeout} // 10,
        insecure       => $opts{insecure} // 0,
        cert           => $opts{cert} // undef,
        verbose        => $opts{verbose} // 0,
        user_agent     => $opts{user_agent} // 'LightTCP::SSLclient/'.$VERSION,
        ssl_protocols  => $opts{ssl_protocols} // ['TLSv1.2', 'TLSv1.3'],
        ssl_ciphers    => $opts{ssl_ciphers} // 'HIGH:!aNULL:!MD5:!RC4',
        keep_alive     => $opts{keep_alive} // 0,
        buffer_size    => $opts{buffer_size} // 8192,
        max_redirects  => $opts{max_redirects} // 5,
        follow_redirects => $opts{follow_redirects} // 1,
        _socket        => undef,
        _connected     => 0,
        _target_host   => undef,
        _target_port   => undef,
        _proxy         => undef,
        _proxy_auth    => undef,
        _buffer        => '',
        _redirect_count=> 0,
        _redirect_history => [],
    };
    bless $self, $class;
    return $self;
}

sub _parse_proxy_address {
    my ($proxy) = @_;

    if ($proxy =~ /^\[(.+)\]:(\d+)$/) {
        return ($1, $2);
    }

    if ($proxy =~ /^([^:]+):(\d+)$/) {
        return ($1, $2);
    }

    if ($proxy =~ /^([^:]+)$/) {
        return ($1, 8080);
    }

    return (undef, undef);
}

sub _sanitize_credentials {
    my ($str) = @_;
    return '' unless defined $str;
    $str =~ s/Basic\s+[A-Za-z0-9+\/=]+/Basic [REDACTED]/gi;
    return $str;
}

sub _read_line_from_socket {
    my ($self, $socket, $timeout, $buffer_ref) = @_;
    $$buffer_ref //= '';
    return _read_until_delimiter($self, $socket, $buffer_ref, $timeout, "\n");
}

sub _read_until_delimiter {
    my ($self, $socket, $buffer_ref, $timeout, $delim) = @_;
    my $delim_len = length($delim);

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;

        while ($$buffer_ref !~ /\Q$delim\E/) {
            my $read;
            my $res = sysread($socket, $read, $self->{buffer_size});
            if (!defined $res) {
                alarm 0;
                return undef if $!{EAGAIN} || $!{EWOULDBLOCK};
                return undef;
            }
            last if $res == 0;
            $$buffer_ref .= $read;
        }

        alarm 0;
    };
    if ($@) {
        return undef;
    }

    if ($$buffer_ref =~ /^([^\Q$delim\E]*)\Q$delim\E(.*)$/s) {
        $$buffer_ref = $2;
        return $1 . $delim;
    }
    return undef;
}

sub _read_exact_bytes {
    my ($socket, $bytes, $timeout) = @_;
    my $result = '';
    my $buf;

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;

        while (length($result) < $bytes) {
            my $read = sysread($socket, $buf, $bytes - length($result));
            last unless defined $read && $read > 0;
            $result .= $buf;
        }

        alarm 0;
    };
    if ($@) {
        return substr($result, 0, length($result));
    }
    return $result;
}

sub _hex_dump {
    my ($data) = @_;
    return join('', map { sprintf('%02x', ord($_)) } split(//, $data));
}

sub connect {
    my ($self, $target_host, $target_port, $proxy, $proxy_auth) = @_;

    my $timeout = $self->{timeout};
    my $socket;

    my @debug;
    my @errors;
    push(@debug, "# === LightTCP::SSLclient::connect ===\n") if $self->{verbose};

    $self->{_target_host} = $target_host;
    $self->{_target_port} = $target_port;
    $self->{_proxy} = $proxy;
    $self->{_proxy_auth} = $proxy_auth;
    $self->{_buffer} = '';

    my %ssl_opts = (
        SSL_verifycn_scheme => 'http',
        SSL_verifycn_name   => $target_host,
        SSL_hostname        => $target_host,
        Timeout             => $timeout,
        SSL_protocols       => $self->{ssl_protocols},
        SSL_cipher_list     => $self->{ssl_ciphers},
    );

    if ($self->{insecure}) {
        $ssl_opts{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_NONE;
    } else {
        $ssl_opts{SSL_verify_mode} = IO::Socket::SSL::SSL_VERIFY_PEER;
    }

    if ($self->{cert} && -f $self->{cert}.'.key' && -f $self->{cert}.'.crt') {
        $ssl_opts{SSL_key_file}  = $self->{cert}.'.key';
        $ssl_opts{SSL_cert_file} = $self->{cert}.'.crt';
    }

    if ($self->{verbose}) {
        push(@debug, "# === ssl_opts ===\n");
        foreach my $k (sort keys %ssl_opts) {
            next if $k =~ /SSL_(key|cert)_file/;
            push(@debug, "- $k = $ssl_opts{$k}\n");
        }
    }

    if ($proxy) {
        my ($proxy_host, $proxy_port) = _parse_proxy_address($proxy);
        unless ($proxy_host && $proxy_port) {
            push(@errors, "- ERROR: Invalid proxy address format: $proxy\n");
            return (0, \@errors, \@debug, ECONNECT);
        }

        push(@debug, "# Connecting to proxy $proxy_host:$proxy_port...\n") if $self->{verbose};
        $socket = IO::Socket::INET->new(
            PeerAddr => $proxy_host,
            PeerPort => $proxy_port,
            Proto    => 'tcp',
            Timeout  => $timeout,
        );
        unless ($socket) {
            push(@errors, "- ERROR: Cannot connect to proxy: $!\n");
            return (0, \@errors, \@debug, ECONNECT);
        }

        my $connect_req = "CONNECT $target_host:$target_port HTTP/1.1\r\n";
        $connect_req   .= "Host: $target_host:$target_port\r\n";
        if ($proxy_auth) {
            my $encoded = encode_base64($proxy_auth, '');
            $connect_req .= "Proxy-Authorization: Basic $encoded\r\n";
            push(@debug, "- Proxy-Authorization: " . _sanitize_credentials("Basic $encoded") . "\n") if $self->{verbose};
        }
        $connect_req .= "\r\n";
        print $socket $connect_req;

        my $proxy_resp = _read_line_from_socket($self, $socket, $timeout, \$self->{_buffer});
        unless ($proxy_resp) {
            push(@errors, "- ERROR: Failed to read proxy response: $!\n");
            $socket->close() if $socket;
            return (0, \@errors, \@debug, ECONNECT);
        }

        unless ($proxy_resp =~ /^HTTP\/1\.[01]\s+200\b/i) {
            $socket->close() if $socket;
            push(@errors, "- ERROR: Proxy CONNECT failed:\n$proxy_resp");
            return (0, \@errors, \@debug, ECONNECT);
        }
        push(@debug, "- Proxy tunnel established.\n") if $self->{verbose};

        if (IO::Socket::SSL->start_SSL($socket, %ssl_opts)) {
            $socket->timeout($timeout);
            push(@debug, "- SSL connect established.\n") if $self->{verbose};
            $self->{_socket}    = $socket;
            $self->{_connected} = 1;
            return (1, \@errors, \@debug, 0);
        } else {
            push(@errors, "- ERROR: SSL connect failed: $SSL_ERROR\n");
            return (0, \@errors, \@debug, ESSL);
        }
    } else {
        push(@debug, "# Connecting to $target_host:$target_port...\n") if $self->{verbose};
        $socket = IO::Socket::SSL->new(
            PeerHost => $target_host,
            PeerPort => $target_port,
            %ssl_opts,
        );
        if ($socket) {
            $socket->timeout($timeout);
            push(@debug, "- Direct SSL connect established.\n") if $self->{verbose};
            $self->{_socket}    = $socket;
            $self->{_connected} = 1;
            return (1, \@errors, \@debug, 0);
        } else {
            push(@errors, "- ERROR: Direct SSL connection failed: $SSL_ERROR\n");
            return (0, \@errors, \@debug, ESSL);
        }
    }
}

sub reconnect {
    my ($self) = @_;
    return 0 unless $self->{_target_host} && $self->{_target_port};
    $self->close();
    my ($ok, $err, $dbg, $code) = $self->connect(
        $self->{_target_host},
        $self->{_target_port},
        $self->{_proxy},
        $self->{_proxy_auth},
    );
    return $ok;
}

sub request {
    my ($self, $method, $path, %opts) = @_;

    my $socket = $self->{_socket};
    my @debug;
    my @errors;

    push(@debug, "# === LightTCP::SSLclient::request ===\n") if $self->{verbose};
    push(@debug, "- Sending: $method $path HTTP/1.1\n") if $self->{verbose};

    unless ($socket) {
        push(@errors, "- ERROR: No connection established\n");
        return (0, \@errors, \@debug, EREQUEST);
    }

    my $host    = $opts{host}    // '';
    my $payload = $opts{payload} // '';
    my $ph      = $opts{headers} // {};

    my $length = defined $payload ? length($payload) : 0;

    $ph->{'Host'}         ||= $host;
    $ph->{'Accept'}       ||= '*/*';
    $ph->{'User-Agent'}   ||= $self->{user_agent};
    $ph->{'Connection'}   ||= $self->{keep_alive} ? 'keep-alive' : 'close';

    my $timeout = $self->{timeout};
    my $send_ok = 1;

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;

        unless (print $socket "$method $path HTTP/1.1\r\n") {
            push(@errors, "- ERROR: Failed to send request line: $!\n");
            $send_ok = 0;
        }

        if ($send_ok) {
            push(@debug, "# === Headers: ===\n") if $self->{verbose};
            foreach my $key (sort keys %$ph) {
                my $val = $ph->{$key} // '';
                $val =~ s/[\r\n]+//g;
                $val =~ s/^\s+|\s+$//g;
                push(@debug, "- $key: $val\n") if $self->{verbose};
                unless (print $socket "$key: $val\r\n") {
                    push(@errors, "- ERROR: Failed to send header '$key': $!\n");
                    $send_ok = 0;
                    last;
                }
            }
        }

        if ($send_ok && $length > 0) {
            unless (print $socket "Content-Length: $length\r\n") {
                push(@errors, "- ERROR: Failed to send Content-Length: $!\n");
                $send_ok = 0;
            }
        }

        if ($send_ok) {
            unless (print $socket "\r\n") {
                push(@errors, "- ERROR: Failed to send header terminator: $!\n");
                $send_ok = 0;
            }
        }

        if ($send_ok && defined $payload && $length > 0) {
            unless (print $socket $payload) {
                push(@errors, "- ERROR: Failed to send payload (connection broken): $!\n");
                $send_ok = 0;
            }
        }

        alarm 0;
    };
    if ($@) {
        push(@errors, "- ERROR: Timeout during request send\n");
        return (0, \@errors, \@debug, ETIMEOUT);
    }

    unless ($send_ok) {
        return (0, \@errors, \@debug, EREQUEST);
    }
    return (1, \@errors, \@debug, 0);
}

sub request_with_redirects {
    my ($self, $method, $path, %opts) = @_;

    $self->{_redirect_count} = 0;
    $self->{_redirect_history} = [];

    return $self->_do_request_with_redirects($method, $path, %opts);
}

sub _do_request_with_redirects {
    my ($self, $method, $path, %opts) = @_;

    my @errors;
    my @debug;
    my ($ok, $req_errors, $req_debug, $error_code) = $self->request($method, $path, %opts);
    push(@errors, @$req_errors) if $req_errors;
    push(@debug, @$req_debug) if $req_debug;
    return (undef, undef, undef, undef, \@errors, \@debug, $error_code, []) unless $ok;

    my ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code) = $self->response();
    push(@errors, @$resp_errors) if $resp_errors;
    push(@debug, @$resp_debug) if $resp_debug;
    return ($code, $state, $headers, $body, \@errors, \@debug, $resp_code, $self->{_redirect_history}) unless $code;

    if ($self->{follow_redirects} && $code >= 300 && $code < 400 && $headers && $headers->{'location'}) {
        return ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code, $self->{_redirect_history}) if $self->{_redirect_count} >= $self->{max_redirects};

        my $location = $headers->{'location'};

        push(@{$self->{_redirect_history}}, {
            from => "$method $path",
            to   => $location,
            code => $code,
        });

        $self->{_redirect_count}++;

        my ($new_method, $new_path, $new_host, $new_opts) = $self->_resolve_redirect($method, $path, $location, %opts);

        my $debug_msg = "- Following redirect ($code): $method $path -> $new_method $new_path\n";
        push(@$resp_debug, $debug_msg) if $self->{verbose};

        return $self->_do_request_with_redirects($new_method, $new_path, %$new_opts);
    }

    return ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code, $self->{_redirect_history});
}

sub _resolve_redirect {
    my ($self, $method, $path, $location, %opts) = @_;

    my $uri = URI->new($location);
    my $new_method = $method;
    my $new_path = $uri->path_query || '/';
    my $new_host = $opts{host} // '';

    if ($uri->scheme) {
        if ($uri->scheme ne 'https') {
            return ($method, $path, '', \%opts);
        }
        $new_host = $uri->host;
        $new_path = $uri->path_query || '/';
        if ($uri->port && $uri->port != 443) {
            $new_host = $uri->host . ':' . $uri->port;
        }
    } elsif ($location =~ m{^/}) {
        $new_path = $location;
    } else {
        $new_path = $self->_resolve_relative_path($path, $location);
    }

    my %new_opts = %opts;
    $new_opts{host} = $new_host;

    if ($location =~ /^HTTP\/1\.[01] (30[1278])\b/i) {
        my $code = $1;
        if ($code eq '301' || $code eq '302') {
            if ($method eq 'POST') {
                $new_method = 'GET';
                $new_opts{payload} = undef;
            }
        }
    }

    return ($new_method, $new_path, $new_host, \%new_opts);
}

sub _resolve_relative_path {
    my ($self, $current_path, $relative) = @_;

    return $relative if $relative =~ m{^/};

    $current_path =~ s{/[^/]*$}{};
    $current_path = '/' unless length $current_path;

    my $result = $current_path;
    $result .= '/' unless $result =~ m{/$};
    $result .= $relative;

    $result =~ s{[^/]+/\.\./}{}g;
    $result =~ s{/\./}{}g;
    $result =~ s{//+}{/};

    return $result;
}

sub response {
    my ($self) = @_;

    my $socket = $self->{_socket};
    my @resp_debug;
    my @resp_errors;

    push(@resp_debug, "# === LightTCP::SSLclient::response ===\n") if $self->{verbose};

    unless ($socket) {
        push(@resp_errors, "- ERROR: No connection established\n");
        return (undef, undef, undef, undef, \@resp_errors, \@resp_debug, ERESPONSE);
    }

    my $timeout = $socket->timeout // 15;

    my $headers_raw = '';
    my $buf;
    my $buf_size = $self->{buffer_size};
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;
        while (sysread($socket, $buf, $buf_size)) {
            $headers_raw .= $buf;
            last if $headers_raw =~ /\r\n\r\n|\n\n/;
        }
        alarm 0
    };
    if ($@) {
        push(@resp_errors, "- ERROR: Timeout while reading response headers\n");
        return (undef, undef, undef, undef, \@resp_errors, \@resp_debug, ETIMEOUT);
    }

    unless ($headers_raw =~ /^HTTP\/1\.[01]\s+(\d{3})\s+(.*?)\r?\n/i) {
        push(@resp_errors, "- ERROR: INVALID RESPONSE (no valid status line)\n");
        return (undef, undef, undef, undef, \@resp_errors, \@resp_debug, ERESPONSE);
    }
    my $code  = $1;
    my $state = $2;
    push(@resp_debug, "- $code $state\n") if $self->{verbose};

    my ($headers_part, $initial_body) = $headers_raw =~ /^(.*?)\r\n\r\n(.*)$/s
        ? ($1, $2)
        : ($headers_raw, '');

    my @lines = split /\r?\n/, $headers_part;
    shift @lines;

    my %hdr;
    my $current_key = '';
    for my $line (@lines) {
        if ($line =~ /^\s+(.+)/) {
            $hdr{$current_key} .= " $1" if $current_key;
        } elsif ($line =~ /^([^:]+):\s*(.*)/) {
            $current_key = lc $1;
            $hdr{$current_key} = $2;
        }
    }

    my $body = $initial_body;
    my $chunked = (lc($hdr{'transfer-encoding'} || '') eq 'chunked');
    my $content_length = $hdr{'content-length'} ? int($hdr{'content-length'}) : undef;

    if ($chunked) {
        $body = $self->_read_chunked_with_timeout($body, $timeout, \@resp_errors, \@resp_debug);
    } elsif (defined $content_length && $content_length > length($body)) {
        $body = $self->_read_exact_bytes_with_timeout($body, $content_length - length($body), $timeout, \@resp_errors, \@resp_debug);
    } else {
        $body = $self->_read_until_eof_with_timeout($body, $timeout, \@resp_errors, \@resp_debug);
    }

    return ($code, $state, \%hdr, $body, \@resp_errors, \@resp_debug, 0);
}

sub _read_exact_bytes_with_timeout {
    my ($self, $initial, $remaining, $timeout, $perrs, $pdebug) = @_;
    my $body = $initial;
    my $buf;
    my $socket = $self->{_socket};
    my $buf_size = $self->{buffer_size};

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;
        while ($remaining > 0) {
            my $read = sysread($socket, $buf, ($remaining > $buf_size ? $buf_size : $remaining));
            last unless defined $read && $read > 0;
            $body .= $buf;
            $remaining -= $read;
        }
        alarm 0
    };
    if ($@) {
        push(@$perrs, "- WARNING: Timeout during Content-Length body read (incomplete body)\n");
    }
    return $body;
}

sub _read_until_eof_with_timeout {
    my ($self, $initial, $timeout, $perrs, $pdebug) = @_;
    my $body = $initial;
    my $buf;
    my $socket = $self->{_socket};
    my $buf_size = $self->{buffer_size};

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;
        while (sysread($socket, $buf, $buf_size)) {
            $body .= $buf;
        }
        alarm 0
    };
    if ($@) {
        push(@$perrs, "- WARNING: Timeout during EOF body read (connection may have stalled)\n");
    }
    return $body;
}

sub _read_chunked_with_timeout {
    my ($self, $initial, $timeout, $perrs, $pdebug) = @_;
    my $body = $initial;
    my $buf;
    my $socket = $self->{_socket};
    my $buffer = $self->{_buffer};
    my $buf_size = $self->{buffer_size};

    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $timeout;

        while (1) {
            my $chunk_line = _read_until_delimiter($self, $socket, $buffer, $timeout, "\n");
            last unless defined $chunk_line && length($chunk_line);

            $chunk_line =~ s/\r?\n$//;
            my $chunk_size = hex($chunk_line);
            push(@$pdebug, "- Chunk size: $chunk_size\n") if $self->{verbose};

            last if $chunk_size == 0;

            my $read_so_far = 0;
            while ($read_so_far < $chunk_size) {
                my $need = $chunk_size - $read_so_far;
                my $read = sysread($socket, $buf, ($need > $buf_size ? $buf_size : $need));
                unless (defined $read && $read > 0) {
                    push(@$perrs, "- WARNING: Failed to read chunk data\n");
                    last;
                }
                $body .= $buf;
                $read_so_far += $read;
            }

            my $trailing = _read_exact_bytes($socket, 2, $timeout);
            unless ($trailing eq "\r\n" || $trailing eq "\n") {
                push(@$perrs, "- WARNING: Invalid chunk trailer, expected CRLF, got: " . _hex_dump($trailing) . "\n");
            }
        }
        alarm 0
    };
    if ($@) {
        push(@$perrs, "- WARNING: Timeout during chunked transfer (incomplete body)\n");
    }
    $self->{_buffer} = $buffer;
    return $body;
}

sub fingerprint_read {
    my ($self, $dir, $host, $port) = @_;
    my $file = "$dir/$host.$port";
    return '' unless -f $file;

    open my $fh, '<', $file or return '';
    my $fp = <$fh>;
    close $fh;
    chomp $fp if defined $fp;
    $fp =~ s/^\s+|\s+$//g if defined $fp;
    return $fp // '';
}

sub fingerprint_save {
    my ($self, $dir, $host, $port, $fingerprint, $save) = @_;
    my $suffix = $save ? '' : '.new';
    my $file   = "$dir/$host.$port$suffix";
    my @errors;
    my @debug;
    mkdir $dir unless -d $dir;
    open my $fh, '>', $file or do {
        push(@errors, "- WARNING: Cannot save fingerprint to \"$file\": $!\n");
        return (1, \@errors, \@debug, EREQUEST);
    };
    print $fh "$fingerprint\n";
    close $fh;
    push(@debug, "- Saved fingerprint to: $file\n") if $self->{verbose};
    if ($save) {
        unlink("$file.new") if -f "$file.new";
        return (1, \@errors, \@debug, 0);
    }
    return (1, \@errors, \@debug, 0);
}

sub DESTROY {
    my ($self) = @_;
    $self->close() if $self->{_connected};
}

sub socket {
    my ($self) = @_;
    return $self->{_socket};
}

sub is_connected {
    my ($self) = @_;
    return $self->{_connected};
}

sub close {
    my ($self) = @_;
    if ($self->{_socket}) {
        $self->{_socket}->close();
        $self->{_socket}    = undef;
        $self->{_connected} = 0;
    }
    $self->{_buffer} = '';
    return 1;
}

sub set_cert {
    my ($self, $cert) = @_;
    $self->{cert} = $cert;
    return $self->{cert};
}

sub set_timeout {
    my ($self, $timeout) = @_;
    $self->{timeout} = $timeout // 10;
    $self->{_socket}->timeout($self->{timeout}) if $self->{_socket};
    return $self->{timeout};
}

sub set_insecure {
    my ($self, $insecure) = @_;
    $self->{insecure} = $insecure ? 1 : 0;
    return $self->{insecure};
}

sub set_keep_alive {
    my ($self, $keep_alive) = @_;
    $self->{keep_alive} = $keep_alive ? 1 : 0;
    return $self->{keep_alive};
}

sub get_timeout {
    my ($self) = @_;
    return $self->{timeout};
}

sub get_user_agent {
    my ($self) = @_;
    return $self->{user_agent};
}

sub is_verbose {
    my ($self) = @_;
    return $self->{verbose};
}

sub get_cert {
    my ($self) = @_;
    return $self->{cert};
}

sub get_insecure {
    my ($self) = @_;
    return $self->{insecure};
}

sub get_ssl_protocols {
    my ($self) = @_;
    return $self->{ssl_protocols};
}

sub get_ssl_ciphers {
    my ($self) = @_;
    return $self->{ssl_ciphers};
}

sub get_keep_alive {
    my ($self) = @_;
    return $self->{keep_alive};
}

sub is_keep_alive {
    my ($self) = @_;
    return $self->{keep_alive};
}

sub get_buffer_size {
    my ($self) = @_;
    return $self->{buffer_size};
}

sub set_buffer_size {
    my ($self, $size) = @_;
    $self->{buffer_size} = defined $size && $size > 0 ? $size : 8192;
    return $self->{buffer_size};
}

sub get_max_redirects {
    my ($self) = @_;
    return $self->{max_redirects};
}

sub get_follow_redirects {
    my ($self) = @_;
    return $self->{follow_redirects};
}

sub set_max_redirects {
    my ($self, $max) = @_;
    $self->{max_redirects} = $max // 5;
    return $self->{max_redirects};
}

sub set_follow_redirects {
    my ($self, $follow) = @_;
    $self->{follow_redirects} = $follow ? 1 : 0;
    return $self->{follow_redirects};
}

sub get_redirect_count {
    my ($self) = @_;
    return $self->{_redirect_count};
}

sub get_redirect_history {
    my ($self) = @_;
    return $self->{_redirect_history};
}

1;

__END__

=head1 NAME

LightTCP::SSLclient - SSL/TLS HTTP client with proxy support and certificate pinning

=head1 SYNOPSIS

  use LightTCP::SSLclient;

  my $client = LightTCP::SSLclient->new(
      timeout      => 30,
      insecure     => 0,
      verbose      => 0,
      keep_alive   => 0,
      user_agent   => 'MyClient/1.0',
      ssl_protocols=> ['TLSv1.2', 'TLSv1.3'],
      ssl_ciphers  => 'HIGH:!aNULL:!MD5',
  );

  my ($ok, $errors, $debug, $error_code) = $client->connect('example.com', 443);
  return error($errors) unless $ok;

  ($ok, $errors, $debug, $error_code) = $client->request('GET', '/api/data', host => 'example.com');
  return error($errors) unless $ok;

  my ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code) = $client->response();

  $client->close();

=head1 DESCRIPTION

Object-oriented SSL/TLS HTTP client with support for HTTP CONNECT proxies,
certificate pinning, chunked transfer encoding, and keep-alive connections.

=head1 RETURN VALUES

All methods return multiple values. The standard convention is:

=head2 connect(), request()

  ($ok, $errors_ref, $debug_ref, $error_code) = $client->method(...);

=over 4

=item C<$ok>

Boolean success indicator (1 = success, 0 = failure)

=item C<$errors_ref>

Reference to array of error messages

=item C<$debug_ref>

Reference to array of debug messages (empty unless verbose mode is enabled)

=item C<$error_code>

Error type constant (0 if successful):
  - ECONNECT (1): Connection error
  - EREQUEST (2): Request error
  - ERESPONSE (3): Response error
  - ETIMEOUT (4): Timeout error
  - ESSL (5): SSL/TLS error

=back

=head2 response()

  ($code, $state, $headers_ref, $body, $errors_ref, $debug_ref, $error_code) = $client->response();

=over 4

=item C<$code>

HTTP status code (e.g., 200, 404)

=item C<$state>

HTTP status message (e.g., "OK", "Not Found")

=item C<$headers_ref>

Reference to hash of response headers (lowercase keys)

=item C<$body>

Response body as string

=item C<$errors_ref>, C<$debug_ref>, C<$error_code>

Same as above

=back

=head1 CONSTRUCTOR OPTIONS

  my $client = LightTCP::SSLclient->new(
      timeout         => 10,                     # Request timeout in seconds (default: 10)
      insecure        => 0,                      # Skip SSL verification (default: 0)
      cert            => '/path/to/client',      # Client certificate base path (optional)
      verbose         => 0,                      # Enable debug output (default: 0)
      user_agent      => 'MyClient/1.0',         # User-Agent header (default: LightTCP::SSLclient/VERSION)
      ssl_protocols   => ['TLSv1.2', 'TLSv1.3'], # Allowed SSL protocols (default: TLSv1.2, TLSv1.3)
      ssl_ciphers     => 'HIGH:!aNULL:!MD5',     # Allowed cipher suites (default: HIGH:!aNULL:!MD5:!RC4)
      keep_alive      => 0,                      # Use HTTP keep-alive (default: 0)
      buffer_size     => 8192,                   # Read buffer size (default: 8192)
      max_redirects   => 5,                      # Max redirects to follow (default: 5)
      follow_redirects=> 1,                      # Follow 3xx redirects (default: 1)
  );

=head1 METHODS

=head2 Connection Methods

=over 4

=item C<connect($host, $port, $proxy, $proxy_auth)>

Establish SSL connection to target host.

  my ($ok, $errors, $debug, $code) = $client->connect(
      'example.com',      # Target host
      443,                # Target port
      'proxy.com:8080',   # Optional HTTP proxy
      'user:pass',        # Optional proxy auth
  );

=item C<reconnect()>

Reconnect using previously used connection parameters.

  my ($ok, $errors, $debug, $code) = $client->reconnect();

=item C<close()>

Close the connection.

  $client->close();

=back

=head2 Request Methods

=over 4

=item C<request($method, $path, %options)>

Send HTTP request.

  my ($ok, $errors, $debug, $code) = $client->request(
      'GET',                    # Method
      '/api/data',              # Path
      host    => 'example.com', # Host header
      payload => $body,         # Request body (optional)
      headers => {              # Custom headers
          'X-Custom' => 'value',
      },
  );

=item C<response()>

Read HTTP response.

  my ($code, $state, $headers, $body, $errors, $debug, $code) = $client->response();

=item C<request_with_redirects($method, $path, %options)>

Send HTTP request and automatically follow redirects.

  my ($code, $state, $headers, $body, $errors, $debug, $resp_code, $history) = $client->request_with_redirects(
      'POST',                   # Method
      '/submit',                # Path
      host    => 'example.com', # Host header
      payload => $form_data,    # Request body
  );

Returns an 8th value C<$history> - arrayref of redirects followed:

  foreach my $redirect (@$history) {
      print "$redirect->{code}: $redirect->{from} -> $redirect->{to}\n";
  }

Redirect behavior:
  - 301/302: POST requests converted to GET, payload dropped
  - 303: Always converted to GET
  - 307/308: Method preserved (POST stays POST)

=back

=head3 Fingerprint Methods

=over 4

=item C<fingerprint_read($dir, $host, $port)>

Read saved certificate fingerprint.

  my $fp = $client->fingerprint_read($dir, $host, $port);

=item C<fingerprint_save($dir, $host, $port, $fp, $save)>

Save certificate fingerprint.

  my ($ok, $errors, $debug, $code) = $client->fingerprint_save(
      $dir, $host, $port, $fingerprint, $save
  );
  # $save = 1 to permanently save, 0 to save as .new file

=back

=head1 ACCESSOR METHODS

=over 4

=item C<socket()>

Returns the underlying socket object.

=item C<is_connected()>

Returns 1 if connected, 0 otherwise.

=item C<get_timeout()>, C<set_timeout($value)>

Get/set timeout.

=item C<get_user_agent()>, C<set_user_agent($value)>

Get/set User-Agent string.

=item C<get_insecure()>, C<set_insecure($value)>

Get/set insecure mode.

=item C<get_keep_alive()>, C<set_keep_alive($value)>

Get/set keep-alive mode.

=item C<get_cert()>, C<set_cert($value)>

Get/set client certificate path.

=item C<get_ssl_protocols()>

Get allowed SSL protocols arrayref.

=item C<get_ssl_ciphers()>

Get allowed cipher suites string.

=item C<get_buffer_size()>

Get read buffer size.

=item C<get_max_redirects()>, C<set_max_redirects($value)>

Get/set maximum number of redirects to follow (default: 5).

=item C<get_follow_redirects()>, C<set_follow_redirects($value)>

Get/set whether to follow 3xx redirects (default: 1 = yes).

=item C<get_redirect_count()>

Get the number of redirects followed in the last request.

=item C<get_redirect_history()>

Get the redirect history from the last request (arrayref of {from, to, code}).

=back

=head1 ERROR CODES

  use LightTCP::SSLclient qw(ECONNECT EREQUEST ERESPONSE ETIMEOUT ESSL);

  my ($ok, $errors, $debug, $code) = $client->connect(...);
  if (!$ok) {
      if ($code == ECONNECT) { ... }
      elsif ($code == ETIMEOUT) { ... }
      elsif ($code == ESSL) { ... }
  }

=head1 EXAMPLES

Basic GET request:

  my $client = LightTCP::SSLclient->new(timeout => 30);
  my ($ok, $errors, $debug) = $client->connect('example.com', 443);
  die "Connect failed: @$errors" unless $ok;

  ($ok, $errors, $debug) = $client->request('GET', '/');
  die "Request failed: @$errors" unless $ok;

  my ($code, $state, $headers, $body) = $client->response();
  print "Response: $code $state\n";
  print $body;

With proxy:

  my ($ok, $errors, $debug) = $client->connect(
      'api.example.com', 443,
      'proxy.corp.com:8080', 'user:pass'
  );

With certificate pinning:

  my $client = LightTCP::SSLclient->new(dir => './certs');
  my ($ok, $errors, $debug) = $client->connect('example.com', 443);

  # First connection - save fingerprint
  $client->fingerprint_save('./certs', 'example.com', 443, $fp, 1);

  # Subsequent connections will auto-verify
  $client->fingerprint_save('./certs', 'example.com', 443, $fp, 0);

=cut
