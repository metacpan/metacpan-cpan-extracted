package Langertha::Holmgang::Sim::Linux::Http;
# ABSTRACT: HTTP between simulated devices: curl, applications behind ports, probes at the end state

use strict;
use warnings;
use utf8;

use JSON::MaybeXS ();

our $VERSION = '0.002';


my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );

our %REASON = (
    101 => 'Switching Protocols', 200 => 'OK', 201 => 'Created', 204 => 'No Content', 301 => 'Moved Permanently',
    302 => 'Found', 304 => 'Not Modified', 307 => 'Temporary Redirect', 308 => 'Permanent Redirect',
    400 => 'Bad Request', 401 => 'Unauthorized', 403 => 'Forbidden', 404 => 'Not Found', 405 => 'Not Allowed',
    408 => 'Request Time-out', 413 => 'Request Entity Too Large', 421 => 'Misdirected Request',
    426 => 'Upgrade Required', 429 => 'Too Many Requests', 494 => 'Request Header Or Cookie Too Large',
    495 => 'SSL Certificate Error', 496 => 'No Required SSL Certificate', 500 => 'Internal Server Error',
    502 => 'Bad Gateway', 503 => 'Service Temporarily Unavailable', 504 => 'Gateway Time-out',
);

sub _linux { require Langertha::Holmgang::Sim::Linux; return 'Langertha::Holmgang::Sim::Linux' }

sub _nginx_on { my ($d) = @_; return ref $d eq 'HASH' && ref $d->{nginx} eq 'HASH' }
sub _docker_on { my ($d) = @_; return ref $d eq 'HASH' && ref $d->{docker} eq 'HASH' }


sub before {
    my ($state) = @_;
    return unless ref $state eq 'HASH';
    for my $h ( sort keys %$state ) {
        my $d = $state->{$h};
        if ( _nginx_on($d) ) { require Langertha::Holmgang::Sim::Linux::Nginx; Langertha::Holmgang::Sim::Linux::Nginx::ensure( $d, $h, $state ) }
        if ( _docker_on($d) ) { Langertha::Holmgang::Sim::Linux::_part('Docker'); Langertha::Holmgang::Sim::Linux::Docker::ensure( $d, $h, $state ) }
    }
    return;
}

sub after {
    my ($state) = @_;
    return unless ref $state eq 'HASH';
    for my $h ( sort keys %$state ) {
        my $d = $state->{$h};
        next unless ref $d eq 'HASH' && ref $d->{probes} eq 'HASH';
        for my $n ( sort keys %{ $d->{probes} } ) {
            my $p = $d->{probes}{$n};
            next unless ref $p eq 'HASH' && defined $p->{url};
            my $res = request( $state, $h, {
                url     => $p->{url},
                method  => $p->{method} // 'GET',
                headers => { map { lc($_) => $p->{headers}{$_} } keys %{ $p->{headers} || {} } },
                map { exists $p->{$_} ? ( $_ => $p->{$_} ) : () } qw( insecure resolve cacert cert key body_size max_time follow tls_version sni ),
            } );
            my %r = ( status => $res->{status} // 0 );
            $r{error} = $res->{error} if defined $res->{error};
            for my $k (qw( body cert protocol )) { $r{$k} = $res->{$k} if defined $res->{$k} }
            $r{headers} = { map { lc( $_->[0] ) => $_->[1] } @{ $res->{headers} || [] } } if $res->{headers};
            $r{location} = $r{headers}{location} if $r{headers} && defined $r{headers}{location};
            $r{backend} = $res->{backend} if $res->{backend};
            $r{redirects} = $res->{redirects} if $res->{redirects};
            $p->{result} = \%r;
        }
    }
    return;
}

# --- Adressen ---------------------------------------------------------------------


# Adressen eines Geraets (ohne Laenge)
sub addresses {
    my ($d) = @_;
    my @a = ('127.0.0.1');
    for my $if ( values %{ $d->{interfaces} || {} } ) { push @a, map { s{/.*}{}r } @{ $if->{addr} || [] } }
    return @a;
}


# Name -> ( geraet, ip ) vom fragenden Geraet aus; () wenn unbekannt
sub resolve {
    my ( $state, $from, $name, $override ) = @_;
    my $d = $state->{$from};
    my $ip;
    if ( $name =~ /\A\d+\.\d+\.\d+\.\d+\z/ ) { $ip = $name }
    elsif ( defined $override ) { $ip = $override }
    elsif ( $name eq 'localhost' ) { $ip = '127.0.0.1' }
    else {
        ($ip) = _linux()->can('_resolve')->( $d, $name ) if ref $d eq 'HASH';
        if ( !defined $ip ) {
            # Rueckfall: der Name eines Geraets im Zustand (bzw. sein hostname)
            my ($h) = grep { $_ eq $name || ( ref $state->{$_} eq 'HASH' && ( $state->{$_}{hostname} // '' ) eq $name ) } sort keys %$state;
            return () unless defined $h;
            my @a = grep { $_ ne '127.0.0.1' } addresses( $state->{$h} );
            return ( $h, $a[0] // '127.0.0.1' );
        }
    }
    return ( $from, $ip ) if $ip =~ /\A127\./;
    for my $h ( sort keys %$state ) {
        next unless ref $state->{$h} eq 'HASH';
        return ( $h, $ip ) if grep { $_ eq $ip } addresses( $state->{$h} );
    }
    return ( undef, $ip );
}

# --- Anfrage --------------------------------------------------------------------



sub parse_url {
    my ($u) = @_;
    $u = "http://$u" unless $u =~ m{\A[a-z]+://}i;
    my ( $scheme, $host, $port, $path ) = $u =~ m{\A([a-z]+)://(\[[^\]]+\]|[^/:?#]+)(?::(\d+))?([^#]*)}i or return;
    $scheme = lc $scheme;
    $path = '/' . $path if $path !~ m{\A/};
    return { scheme => $scheme, host => lc $host, port => $port // ( $scheme eq 'https' ? 443 : 80 ), path => $path };
}

sub request {
    my ( $state, $from, $req, $depth ) = @_;
    $depth //= 0;
    my $u = parse_url( $req->{url} // '' ) or return { error => "(3) URL using bad/illegal format or missing URL", code => 3 };
    return { error => "(1) Protocol \"$u->{scheme}\" not supported", code => 1 } unless $u->{scheme} =~ /\Ahttps?\z/;
    my %r = ( %$req, %$u );
    $r{method} = uc( $r{method} // 'GET' );
    $r{headers} = { %{ $req->{headers} || {} } };
    $r{headers}{host} //= $u->{host} . ( $u->{port} == ( $u->{scheme} eq 'https' ? 443 : 80 ) ? '' : ":$u->{port}" );
    my $override;
    for my $rv ( ref $req->{resolve} ? @{ $req->{resolve} } : grep {defined} $req->{resolve} ) {
        my ( $n, $p, $ip ) = split /:/, $rv, 3;
        $override = $ip if defined $ip && lc($n) eq $u->{host} && $p == $u->{port};
    }
    my ( $to, $ip ) = resolve( $state, $from, $u->{host}, $override );
    return { error => "(6) Could not resolve host: $u->{host}", code => 6 } unless defined $ip;
    $r{ip} = $ip;
    $r{client_ip} //= $to && $to eq $from ? '127.0.0.1' : _source_ip( $state->{$from}, $ip );
    my $refused = { error => "(7) Failed to connect to $u->{host} port $u->{port} after 0 ms: Couldn't connect to server", code => 7 };
    return $refused unless defined $to;
    my $dev = $state->{$to};
    my $res;
    if ( _nginx_on($dev) ) {
        require Langertha::Holmgang::Sim::Linux::Nginx;
        $res = Langertha::Holmgang::Sim::Linux::Nginx::serve( $state, $to, \%r, $from, $depth );
    }
    if ( !$res && _docker_on($dev) ) {
        Langertha::Holmgang::Sim::Linux::_part('Docker');
        $res = Langertha::Holmgang::Sim::Linux::Docker::serve( $state, $to, \%r, $from, $depth );
    }
    $res //= app_serve( $state, $to, \%r, $from );
    return $refused unless $res;
    return $res if defined $res->{error};
    # TLS: der Client prueft, was der Server vorzeigt
    if ( $u->{scheme} eq 'https' ) {
        if ( !$res->{tls} ) {
            return { error => '(35) OpenSSL/3.0.15: error:0A00010B:SSL routines::wrong version number', code => 35 };
        }
        if ( !$req->{insecure} ) {
            require Langertha::Holmgang::Sim::Linux::Pki;
            if ( my $bad = Langertha::Holmgang::Sim::Linux::Pki::client_verify( $state, $from, $res->{tls}, \%r ) ) {
                return { error => $bad->[1], code => $bad->[0], tls_lines => $res->{tls}{lines} };
            }
        }
    }
    my $max = $req->{max_time};
    if ( defined $max && ( $res->{delay} // 0 ) > $max ) {
        return { error => sprintf( '(28) Operation timed out after %d milliseconds with 0 bytes received', $max * 1000 + 1 ), code => 28 };
    }
    if ( $req->{follow} && ( $res->{status} // 0 ) =~ /\A30[1278]\z/ ) {
        my ($loc) = map { $_->[1] } grep { lc( $_->[0] ) eq 'location' } @{ $res->{headers} || [] };
        if ( defined $loc ) {
            my $n = ( $req->{_redirects} // 0 ) + 1;
            return { error => "(47) Maximum (50) redirects followed", code => 47, redirects => $n - 1 } if $n > 50;
            my $next = $loc =~ m{\A[a-z]+://}i ? $loc : "$u->{scheme}://$u->{host}" . ( $loc =~ m{\A/} ? $loc : "/$loc" );
            my %h = %{ $req->{headers} || {} };
            delete $h{host};
            my $r2 = request( $state, $from, { %$req, url => $next, headers => \%h, _redirects => $n }, $depth );
            $r2->{redirects} //= $n;
            return $r2;
        }
    }
    return $res;
}

sub _source_ip {
    my ( $d, $to ) = @_;
    my @a = grep { $_ ne '127.0.0.1' } addresses($d);
    for my $if ( values %{ $d->{interfaces} || {} } ) {
        for my $c ( @{ $if->{addr} || [] } ) {
            my ( $ip, $len ) = split m{/}, $c;
            return $ip if defined $len && _linux()->can('_in')->( $to, "$ip/$len" );
        }
    }
    return $a[0] // '127.0.0.1';
}

# --- Anwendungen (http) -----------------------------------------------------------


# Passt ein Lauscher "ip:port" | "port" auf ( ip, port )? 127.* nur vom Geraet selbst.
sub listens {
    my ( $key, $ip, $port, $local ) = @_;
    my ( $lip, $lport ) = $key =~ /\A(?:(.+):)?(\d+)\z/ or return 0;
    return 0 unless $lport == $port;
    $lip //= '0.0.0.0';
    $lip = '0.0.0.0' if $lip eq '*' || $lip eq '';
    return 1 if $lip eq '0.0.0.0';
    return 0 if $lip =~ /\A127\./ && !$local;
    return $lip eq $ip || ( $lip =~ /\A127\./ && $ip =~ /\A127\./ ) ? 1 : 0;
}


sub app_serve {
    my ( $state, $to, $req, $from ) = @_;
    my $dev = $state->{$to};
    my $apps = ref $dev->{http} eq 'HASH' ? $dev->{http} : return undef;
    my $local = defined $from && $from eq $to;
    my ($key) = grep { listens( $_, $req->{ip}, $req->{port}, $local ) } sort keys %$apps or return undef;
    my $app = $apps->{$key};
    if ( defined $app->{service} ) {
        my $svc = ( $dev->{services} || {} )->{ $app->{service} };
        return undef unless $svc && $svc->{active};
    }
    return respond( $app, $req, "$to $key" );
}


sub respond {
    my ( $app, $req, $name ) = @_;
    my $path = $req->{path} // '/';
    ( my $bare = $path ) =~ s/\?.*//;
    my %h = %{ $req->{headers} || {} };
    my $fill = sub {
        my ($t) = @_;
        return $t unless defined $t && !ref $t;
        my $host = $h{host} // '';
        $host =~ s/:\d+\z//;
        $t =~ s/\{host\}/$host/g;
        $t =~ s/\{path\}/$path/g;
        $t =~ s/\{header:([\w-]+)\}/$h{lc $1} \/\/ ''/ge;
        return $t;
    };
    my $backend = { app => $name, path => $path, host => $h{host},
        headers => { map { $_ => $h{$_} } grep { $_ ne 'host' && $_ ne 'user-agent' && $_ ne 'accept' } sort keys %h } };
    my $mk = sub {
        my ($s) = @_;
        my @hd = map { [ $_, $fill->( $s->{headers}{$_} ) ] } sort keys %{ $s->{headers} || {} };
        my $body = $s->{echo}
            ? $JSON->encode( { method => $req->{method}, path => $path, headers => { %h } } ) . "\n"
            : $fill->( $s->{body} // '' );
        return { status => $s->{status} // 200, headers => \@hd, body => $body, backend => $backend,
            delay => $s->{delay} // $app->{delay} // 0 };
    };
    for my $c ( @{ $app->{require} || [] } ) {
        my $v = $h{ lc( $c->{header} // '' ) };
        my $ok = defined $v;
        $ok &&= $v eq $c->{equals} if $ok && defined $c->{equals};
        $ok &&= $v =~ /$c->{regex}/ if $ok && defined $c->{regex};
        $ok = !defined $v if exists $c->{absent};
        return $mk->($c) unless $ok;
    }
    my ($route) = sort { length $b->{path} <=> length $a->{path} }
        grep { substr( $bare, 0, length $_->{path} ) eq $_->{path} } @{ $app->{routes} || [ { path => '/' } ] };
    return $mk->( $route || { status => 404, body => "Not Found\n" } );
}

# --- curl ---------------------------------------------------------------------------


my %CURL_FLAG = map { $_ => 1 } qw( -s --silent -S --show-error -f --fail --fail-with-body -k --insecure -I --head
    -i --include -v --verbose -L --location -4 -6 --http1.1 --http1.0 --http2 --compressed -N --no-buffer -g --globoff
    --no-progress-meter -q --ipv4 --ipv6 --tlsv1.2 --tlsv1.3 --ssl-no-revoke );
my %CURL_ARG = map { $_ => 1 } qw( -o --output -w --write-out -H --header -X --request -d --data --data-binary
    --data-raw --data-urlencode -F --form --resolve --cacert --capath --cert --key -m --max-time --connect-timeout
    -u --user -A --user-agent -e --referer -b --cookie -c --cookie-jar --max-redirs -T --upload-file --interface
    --retry --retry-delay --cert-type --key-type --pass --url --tls-max --ciphers );

sub curl {
    my ( $dev, $av, $ctx ) = @_;
    my $state = $ctx->{state} || { $ctx->{host} => $dev };
    my $from  = $ctx->{host};
    my ( %f, @hdr, @res, $url, $out_file, $wfmt, $method, $body );
    my @a = @$av;
    while (@a) {
        my $x = shift @a;
        if ( $x =~ /\A-([a-zA-Z]{2,})\z/ ) {    # -sSfL, -sSo datei
            my @c     = split //, $1;
            my $takes = $CURL_ARG{"-$c[-1]"} ? pop @c : undef;
            return ( "curl: option $x: is unknown\ncurl: try 'curl --help' or 'curl --manual' for more information", 0 )
                if grep { !$CURL_FLAG{"-$_"} } @c;
            $f{"-$_"} = 1 for @c;
            unshift @a, "-$takes" if defined $takes;
            next;
        }
        if ( $x =~ /\A(--[\w.-]+)=(.*)\z/s && $CURL_ARG{$1} ) { unshift @a, $1, $2; next }
        if ( $CURL_FLAG{$x} ) { $f{$x} = 1; next }
        if ( $CURL_ARG{$x} ) {
            my $v = shift @a;
            return ( "curl: option $x: requires parameter\ncurl: try 'curl --help' or 'curl --manual' for more information", 0 ) unless defined $v;
            if    ( $x eq '-o' || $x eq '--output' ) { $out_file = $v }
            elsif ( $x eq '-w' || $x eq '--write-out' ) { $wfmt = $v }
            elsif ( $x eq '-H' || $x eq '--header' ) { push @hdr, $v }
            elsif ( $x eq '-X' || $x eq '--request' ) { $method = $v }
            elsif ( $x =~ /\A(?:-d|--data(?:-binary|-raw|-urlencode)?|-F|--form|-T|--upload-file)\z/ ) {
                my $len = length $v;
                if ( $v =~ /\@(\S+)\z/ || $x eq '-T' || $x eq '--upload-file' ) {
                    my $p = $x =~ /\A(?:-T|--upload-file)\z/ ? $v : $1;
                    my $L = _linux();
                    my $e = $L->can('_file_entry')->( $dev, $p ) or return ( "curl: (26) Failed to open/read local data from file/application", 0 );
                    $len = $L->can('_file_size')->($e);
                }
                $body = ( $body // 0 ) + $len;
                $method //= $x =~ /\A(?:-T|--upload-file)\z/ ? 'PUT' : 'POST';
            }
            elsif ( $x eq '--resolve' ) { push @res, $v }
            elsif ( $x eq '-m' || $x eq '--max-time' ) { $f{max_time} = $v }
            elsif ( $x eq '-u' || $x eq '--user' ) { push @hdr, 'Authorization: Basic ' . _b64($v) }
            elsif ( $x eq '-A' || $x eq '--user-agent' ) { push @hdr, "User-Agent: $v" }
            elsif ( $x eq '--url' ) { $url = $v }
            else { $f{$x} = $v }
            next;
        }
        return ( "curl: option $x: is unknown\ncurl: try 'curl --help' or 'curl --manual' for more information", 0 ) if $x =~ /\A-/;
        $url //= $x;
    }
    return ( "curl: no URL specified!\ncurl: try 'curl --help' or 'curl --manual' for more information", 0 ) unless defined $url;
    my $silent = $f{'-s'} || $f{'--silent'};
    my $show   = $f{'-S'} || $f{'--show-error'};
    my $head   = $f{'-I'} || $f{'--head'};
    my %h = ( 'user-agent' => 'curl/7.88.1', accept => '*/*' );
    for (@hdr) { my ( $k, $v ) = /\A([^:]+):\s*(.*)\z/ or next; $h{ lc $k } = $v }
    my $u = parse_url($url) // {};
    $h{host} //= $u->{host} . ( ( $u->{port} // 80 ) == ( ( $u->{scheme} // '' ) eq 'https' ? 443 : 80 ) ? '' : ":$u->{port}" ) if $u->{host};
    my $req = {
        url => $url, method => $method // ( $head ? 'HEAD' : 'GET' ), headers => \%h,
        resolve => \@res, insecure => $f{'-k'} || $f{'--insecure'}, follow => $f{'-L'} || $f{'--location'},
        ( defined $body ? ( body_size => $body ) : () ),
        map { defined $f{"--$_"} ? ( $_ => $f{"--$_"} ) : () } qw( cacert cert key ),
    };
    $req->{max_time} = $f{max_time} if defined $f{max_time} && $f{max_time} =~ /\A\d+(?:\.\d+)?\z/;
    my $res = request( $state, $from, $req );
    my @v;    # -v
    my $verbose = $f{'-v'} || $f{'--verbose'};
    if ($verbose) {
        my ( undef, $ip ) = $u->{host} ? resolve( $state, $from, $u->{host} ) : ();
        if ( defined $ip ) {
            push @v, "*   Trying $ip:$u->{port}...";
            push @v, "* Connected to $u->{host} ($ip) port $u->{port} (#0)" unless ( $res->{code} // 0 ) == 7;
        }
        push @v, @{ $res->{tls_lines} || [] } if $u->{scheme} && $u->{scheme} eq 'https';
    }
    my $code = $res->{code};
    if ( !defined $code && ( $f{'-f'} || $f{'--fail'} ) && ( $res->{status} // 0 ) >= 400 ) { $code = 22 }
    my @out;
    if ( defined $res->{error} ) {
        push @out, @v;
        push @out, "* $res->{error}" if $verbose;
        push @out, "curl: $res->{error}" if !$silent || $show;
        push @out, 'More details here: https://curl.se/docs/sslcerts.html', '',
            'curl failed to verify the legitimacy of the server and therefore could not',
            'establish a secure connection to it. To learn more about this situation and',
            'how to fix it, please visit the web page mentioned above.'
            if ( $res->{code} // 0 ) == 60 && ( !$silent || $show );
        push @out, _wout( $wfmt, { http_code => '000' }, $url ) if defined $wfmt;
        return ( join( "\n", @out ), 0 );
    }
    my $status = $res->{status} // 200;
    my @hl = ( "HTTP/1.1 $status " . ( $REASON{$status} // '' ), _resp_headers($res) );
    if ($verbose) {
        push @v, "> $req->{method} " . ( $u->{path} // '/' ) . ' HTTP/1.1', "> Host: " . ( $h{host} // '' ),
            ( map { '> ' . _hname($_) . ": $h{$_}" } grep { exists $h{$_} } 'user-agent', 'accept',
                grep { !/\A(?:host|user-agent|accept)\z/ } sort keys %h ), '>';
        push @v, ( map {"< $_"} @hl ), '<';
    }
    if ( $code && $code == 22 ) {
        push @out, @v;
        push @out, "curl: (22) The requested URL returned error: $status" if !$silent || $show;
        push @out, _wout( $wfmt, { http_code => $status }, $url ) if defined $wfmt;
        return ( join( "\n", @out ), 0 );
    }
    push @out, @v;
    my $show_body = !$head;
    if ( $head || $f{'-i'} || $f{'--include'} ) { push @out, @hl, '' }
    my $b = $res->{body} // '';
    if ( defined $out_file ) {
        if ( $out_file ne '/dev/null' && $out_file ne '-' ) { my ( $e, $ok ) = _linux()->can('_write_path')->( $dev, $out_file, $b, 0, $ctx ); return ( $e, 0 ) unless $ok }
        $show_body = 0 unless $out_file eq '-';
    }
    if ($show_body) { ( my $t = $b ) =~ s/\n\z//; push @out, $t if length $t }
    if ( defined $wfmt ) {
        my ($loc) = map { $_->[1] } grep { lc( $_->[0] ) eq 'location' } @{ $res->{headers} || [] };
        my $w = _wout( $wfmt, { http_code => $status, redirect_url => $loc // '', ssl_verify_result => 0 }, $url );
        if ( @out && !$verbose && $show_body ) { $out[-1] .= $w } else { push @out, $w }
    }
    pop @out while @out && $out[-1] eq '' && $head;
    return ( join( "\n", @out ), 1 );
}

sub _resp_headers {
    my ($res) = @_;
    my @h = ( 'Server: ' . ( $res->{server} // 'nginx' ) ) x !!$res->{server};
    push @h, map {"$_->[0]: $_->[1]"} @{ $res->{headers} || [] };
    return @h;
}

sub _hname { my ($n) = @_; return join '-', map {ucfirst} split /-/, $n }

sub _wout {
    my ( $fmt, $v, $url ) = @_;
    $fmt =~ s/\\n/\n/g;
    $fmt =~ s/%\{url_effective\}/$url/g;
    $fmt =~ s/%\{time_total\}/0.012000/g;
    $fmt =~ s/%\{(\w+)\}/$v->{$1} \/\/ ''/ge;
    $fmt =~ s/\n\z//;
    return $fmt;
}

sub _b64 { require MIME::Base64; return MIME::Base64::encode_base64( $_[0], '' ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Http - HTTP between simulated devices: curl, applications behind ports, probes at the end state

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Http::curl( $dev, \@argv, $ctx );

  # request from a device (also for proxies such as nginx)
  my $res = Langertha::Holmgang::Sim::Linux::Http::request( $state, 'client1',
      { method => 'GET', url => 'https://shop.example.com/api/items' } );

  # before/after every command (Sim::Linux): capture the services' state, recompute probes
  Langertha::Holmgang::Sim::Linux::Http::before($state);
  Langertha::Holmgang::Sim::Linux::Http::after($state);

=head1 DESCRIPTION

The seam between devices that speak HTTP (cai-platform F<docs/entwurf-evals.md> §3.3).
A request goes to the device that owns the target address (name through
F</etc/hosts> and the nameservers of the asking device, then the device's
name in the state), and there to whoever listens on the port:

=over

=item * B<nginx> (L<Langertha::Holmgang::Sim::Linux::Nginx>, state C<nginx>) with
the configuration loaded last;

=item * B<containers> (L<Langertha::Holmgang::Sim::Linux::Docker>, state
C<docker>) with published ports;

=item * B<applications> under the device's C<http>:

  http:
    "127.0.0.1:3000":            # address:port; "0.0.0.0:3000" or "3000" = all addresses
      service: shop              # alive only while this service runs
      delay: 2                   # seconds per response (timeouts)
      require:                   # conditions on the request; the first one violated answers
        - { header: host, regex: '^shop\.example\.com$', status: 404, body: "unknown host" }
        - { header: x-forwarded-proto, equals: https, status: 301,
            headers: { Location: "https://{host}{path}" } }
      routes:                    # longest matching prefix of the path
        - { path: /api/, status: 200, body: '{"ok":true}', headers: { Content-Type: application/json } }
        - { path: /, status: 200, body: "<h1>Shop</h1>", echo: false, delay: 90 }

C<{host}>, C<{path}> and C<{header:name}> are substituted in responses;
C<echo: true> answers with method, path and headers as JSON.

=back

A port nobody listens on refuses like a real host (curl: "(7)
Failed to connect"). Whether a certificate is valid is checked by the client
(L<Langertha::Holmgang::Sim::Linux::Pki/client_verify>).

B<Probes> (C<probes> of a device) are requests recomputed after every
command; their result is in the state, so rules check the end state of the
services, not the configuration files:

  probes:
    shop-api:
      url: https://shop.example.com/api/v1/items
      headers: { Cookie: "a=b" }          # optional; method, insecure, resolve, cacert,
                                          # cert, key, body_size (bytes), max_time, follow
      result:                             # by the simulator: status, error, location,
                                          # headers, body, backend { app, path, host, headers },
                                          # cert, protocol

=head2 before

Before a command: simulators with a lazy initial state (loaded nginx
configuration, running containers) capture it before anything changes.

=head2 after

After a command: recompute all probes of all devices.

=head2 addresses

  my @ips = addresses($device);

The IPv4 addresses of a device (without prefix length), C<127.0.0.1> first.

=head2 resolve

  my ( $target, $ip ) = resolve( $state, $from, $name, $override );

Name to device and address as seen from the asking device (F</etc/hosts>,
nameservers, then device name); empty when unknown.

=head2 request

  my $res = request( $state, $from, \%request, $depth );

Request: C<url>, C<method>, C<headers> (names lower case), C<insecure>, C<resolve>
(C<name:port:ip>), C<cacert>, C<cert>, C<key>, C<body_size>, C<max_time>,
C<follow>, C<client_ip> (otherwise the asking device's address towards the target).
Response: C<status>, C<headers> (C<< [ [name, value], … ] >>), C<body>, C<error>
(curl's text, e.g. C<(7) Failed to connect …>), C<code> (curl's exit
status), C<backend>, C<cert>, C<protocol>, C<tls_lines>, C<ms>.

=head2 parse_url

  my $u = parse_url('https://shop.example.com/api');   # { scheme, host, port, path }

=head2 listens

  my $yes = listens( '127.0.0.1:3000', $ip, $port, $local );

Does a listener (C<address:port> or C<port>) match address and port?
C<127.*> only from the device itself.

=head2 app_serve

Response of an application under C<http> of the target device, or C<undef> when
nobody listens there (or its service is stopped).

=head2 respond

  my $res = respond( $spec, $req, $name );

Response from a description as under C<http> (containers too).

=head2 curl

C<curl> on a device: C<-s>, C<-S>, C<-f>, C<-k>, C<-I>, C<-i>, C<-v>,
C<-L>, C<-o file>, C<-w format> (C<%{http_code}>, C<%{redirect_url}>,
C<%{url_effective}>, C<%{ssl_verify_result}>, C<%{time_total}>), C<-H>,
C<-X>, C<-d>/C<--data*>/C<-F> (size of the body, also C<@file>),
C<--resolve>, C<--cacert>, C<--cert>, C<--key>, C<-m>/C<--max-time>,
C<--connect-timeout>, C<-u>, C<-A>, C<--http1.1>/C<--http2> (no effect).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
