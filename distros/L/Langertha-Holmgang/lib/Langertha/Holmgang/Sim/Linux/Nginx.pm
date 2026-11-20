package Langertha::Holmgang::Sim::Linux::Nginx;
# ABSTRACT: nginx on a simulated Linux server: checking and loading the configuration, answering requests

use strict;
use warnings;
use utf8;

use Digest::SHA ();
use JSON::MaybeXS ();

our $VERSION = '0.002';


my $JSON = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub _L { require Langertha::Holmgang::Sim::Linux; return 'Langertha::Holmgang::Sim::Linux' }
sub _ftext { _L(); return Langertha::Holmgang::Sim::Linux::_file_text(@_) }
sub _pki { require Langertha::Holmgang::Sim::Linux::Pki; return 'Langertha::Holmgang::Sim::Linux::Pki' }

our $VERSION_TEXT = 'nginx/1.22.1';

my %BUILTIN = (
    '/etc/nginx/mime.types' => "types {\n    text/html html htm shtml;\n    text/css css;\n    application/javascript js;\n    application/json json;\n    image/png png;\n    image/jpeg jpeg jpg;\n    image/svg+xml svg;\n    text/plain txt;\n}\n",
    '/etc/nginx/proxy_params' => "proxy_set_header Host \$http_host;\nproxy_set_header X-Real-IP \$remote_addr;\nproxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\nproxy_set_header X-Forwarded-Proto \$scheme;\n",
    '/etc/nginx/fastcgi_params' => "fastcgi_param QUERY_STRING \$query_string;\nfastcgi_param REQUEST_METHOD \$request_method;\n",
);

# --- Direktiven -------------------------------------------------------------------

# Kontexte: M main, E events, H http, S server, L location, I if, U upstream
my %CTX = (
    ( map { $_ => 'M' } qw( user worker_processes pid load_module worker_rlimit_nofile daemon master_process env pcre_jit
        timer_resolution worker_cpu_affinity worker_priority working_directory lock_file thread_pool events http ) ),
    ( map { $_ => 'E' } qw( worker_connections multi_accept use accept_mutex accept_mutex_delay ) ),
    ( map { $_ => 'U' } qw( keepalive least_conn ip_hash hash zone random ) ),
    ( map { $_ => 'H' } qw( upstream map types log_format limit_req_zone limit_conn_zone proxy_cache_path geo split_clients
        server_names_hash_bucket_size server_names_hash_max_size types_hash_max_size types_hash_bucket_size
        variables_hash_max_size variables_hash_bucket_size map_hash_bucket_size map_hash_max_size ) ),
    server      => 'HU',
    listen      => 'S', server_name => 'S',
    location    => 'SL', if => 'SL',
    alias       => 'L', internal => 'L', limit_except => 'L',
    proxy_pass  => 'LI',
    return      => 'SLI', rewrite => 'SLI', set => 'SLI', break => 'SLI',
    try_files   => 'SL',
    include     => 'MEHSLIU',
    error_log   => 'MHSL',
    keepalive_timeout => 'HSLU', keepalive_requests => 'HSLU',
);
my %HSL = map { $_ => 1 } qw( root index add_header add_trailer expires charset access_log error_page default_type
    server_tokens autoindex autoindex_exact_size autoindex_localtime satisfy etag if_modified_since sendfile
    tcp_nopush tcp_nodelay aio directio merge_slashes msie_padding underscores_in_headers ignore_invalid_headers
    server_name_in_redirect port_in_redirect absolute_redirect recursive_error_pages chunked_transfer_encoding
    reset_timedout_connection allow deny resolver resolver_timeout sub_filter sub_filter_once sub_filter_types
    set_real_ip_from real_ip_header real_ip_recursive log_not_found log_subrequest gunzip ssi more_set_headers gzip ssl
    error_log open_file_cache sendfile_max_chunk read_ahead disable_symlinks types_hash_max_size limit_rate auth_basic
    auth_basic_user_file auth_request postpone_output send_timeout output_buffers lingering_close userid );
my $FAMILY = qr/\A(?:proxy|ssl|gzip|fastcgi|uwsgi|scgi|grpc|limit|open_file_cache|client|keepalive|http2|lingering|auth|
    sub_filter|real_ip|send|output|postpone|resolver|large_client|server_names|types_hash|variables_hash|map_hash|
    open_log_file_cache|access_log|error_page|sendfile|read_ahead|tcp|ssi|userid|secure_link|slice|mp4|flv|
    image_filter|xslt|dav|charset|source_charset|override_charset|add_|expires)_\w+\z/x;
my %NARGS = ( listen => [ 1, 9 ], server_name => [ 1, 99 ], proxy_pass => [ 1, 1 ], root => [ 1, 1 ], alias => [ 1, 1 ],
    return => [ 1, 2 ], rewrite => [ 2, 3 ], proxy_set_header => [ 2, 2 ], add_header => [ 2, 3 ],
    client_max_body_size => [ 1, 1 ], try_files => [ 2, 99 ], include => [ 1, 1 ], location => [ 1, 2 ],
    upstream => [ 1, 1 ], allow => [ 1, 1 ], deny => [ 1, 1 ], ssl_certificate => [ 1, 1 ], ssl_certificate_key => [ 1, 1 ],
    proxy_read_timeout => [ 1, 1 ], proxy_connect_timeout => [ 1, 1 ], proxy_send_timeout => [ 1, 1 ],
    proxy_http_version => [ 1, 1 ], index => [ 1, 99 ], set => [ 2, 2 ], map => [ 2, 2 ], ssl_protocols => [ 1, 9 ],
    ssl_client_certificate => [ 1, 1 ], ssl_verify_client => [ 1, 1 ], ssl_password_file => [ 1, 1 ],
    worker_processes => [ 1, 1 ], user => [ 1, 2 ], events => [ 0, 0 ], http => [ 0, 0 ], server => [ 0, 9 ],
    types => [ 0, 0 ], internal => [ 0, 0 ], break => [ 0, 0 ], http2 => [ 0, 0 ] );
my %ONCE = map { $_ => 1 } qw( root alias proxy_pass client_max_body_size try_files ssl_certificate_key proxy_http_version
    proxy_read_timeout ssl_verify_client ssl_client_certificate index default_type autoindex );
my %BLOCK = map { $_ => 1 } qw( events http server location upstream map types if limit_except geo split_clients );

sub _known {
    my ( $n, $ctx ) = @_;
    if ( my $c = $CTX{$n} ) { return index( $c, $ctx ) >= 0 ? 1 : -1 }
    return $ctx =~ /[HSLI]/ ? 1 : -1 if $HSL{$n} || $n =~ $FAMILY;
    return 0;
}

# --- Zerlegen -------------------------------------------------------------------

sub _tokens {
    my ( $text, $file ) = @_;
    my @t;
    my $line = 1;
    pos($text) = 0;
    while ( pos($text) < length $text ) {
        if    ( $text =~ /\G\n/gc )      { $line++ }
        elsif ( $text =~ /\G[ \t\r]+/gc ) { }
        elsif ( $text =~ /\G#[^\n]*/gc ) { }
        elsif ( $text =~ /\G([{};])/gc ) { push @t, { op => $1, line => $line } }
        elsif ( $text =~ /\G"((?:[^"\\]|\\.)*)"/gcs || $text =~ /\G'((?:[^'\\]|\\.)*)'/gcs ) {
            my $v = $1;
            $line += () = $v =~ /\n/g;
            $v =~ s/\\(["'\\nrt])/{ n => "\n", r => "\r", t => "\t" }->{$1} \/\/ $1/ge;
            push @t, { w => $v, line => $line, q => 1 };
        }
        elsif ( $text =~ /\G((?:[^\s{};"'\\]|\\.)+)/gc ) { push @t, { w => $1, line => $line } }
        elsif ( $text =~ /\G["']/gc ) { die { msg => 'unexpected end of file, expecting ";" or "}"', file => $file, line => $line } }
        else { pos($text)++ }
    }
    return ( \@t, $line );
}

# Datei -> Liste von Direktiven { name, args, file, line, block }
# Wie nginx: jede Direktive wird beim Lesen geprueft (bekannt, Kontext,
# Anzahl der Argumente) — der erste Fehler in Dateireihenfolge zaehlt.
sub _block_ctx {
    my ( $n, $ctx ) = @_;
    return 'T' if $n =~ /\A(?:types|map|geo|split_clients)\z/;
    return { events => 'E', http => 'H', server => 'S', location => 'L', limit_except => 'L', if => 'I', upstream => 'U' }->{$n} // $ctx;
}

sub _stream_check {
    my ( $d, $ctx, $block ) = @_;
    return if $ctx eq 'T' || $d->{name} eq 'include';
    my $n = $d->{name};
    my $k = _known( $n, $ctx );
    _err( $d, "unknown directive \"$n\"" ) unless $k;
    _err( $d, "\"$n\" directive is not allowed here" ) if $k < 0;
    _err( $d, "directive \"$n\" has no opening \"{\"" ) if $BLOCK{$n} && !$block && !( $n eq 'server' && $ctx eq 'U' );
    _err( $d, "\"$n\" directive is not allowed here" ) if $block && !$BLOCK{$n};
    _nargs($d) unless $n eq 'server' && $ctx eq 'U';
}

sub _parse_file {
    my ( $p, $file, $ctx0 ) = @_;
    $ctx0 //= 'M';
    my @ctx = ($ctx0);
    my $text = $p->{read}->($file);
    die { msg => "open() \"$file\" failed (2: No such file or directory)", %{ $p->{at} || {} } } unless defined $text;
    $p->{conf_files}{$file} = $text;
    my ( $t, $last ) = _tokens( $text, $file );
    my @stack = ( [] );
    my @open;
    my @cur;
    for my $tok (@$t) {
        if ( defined $tok->{w} ) { push @cur, $tok; next }
        if ( $tok->{op} eq ';' || $tok->{op} eq '{' ) {
            die { msg => "unexpected \"$tok->{op}\"", file => $file, line => $tok->{line} } unless @cur;
            my ( $n, @a ) = @cur;
            my $d = { name => $n->{w}, args => [ map { $_->{w} } @a ], file => $file, line => $n->{line} };
            @cur = ();
            _stream_check( $d, $ctx[-1], $tok->{op} eq '{' );
            if ( $tok->{op} eq '{' ) {
                $d->{block} = [];
                push @{ $stack[-1] }, $d;
                push @stack, $d->{block};
                push @open, $d;
                push @ctx, _block_ctx( $d->{name}, $ctx[-1] );
            }
            else { push @{ $stack[-1] }, $d }
            next;
        }
        # }
        if (@cur) { die { msg => 'unexpected "}"', file => $file, line => $tok->{line} } }
        die { msg => 'unexpected "}"', file => $file, line => $tok->{line} } unless @open;
        pop @stack;
        pop @open;
        pop @ctx;
    }
    die { msg => 'unexpected end of file, expecting ";" or "}"', file => $file, line => $last } if @cur;
    die { msg => 'unexpected end of file, expecting "}"', file => $file, line => $last } if @open;
    return $stack[0];
}

sub _glob_re { my ($g) = @_; ( my $r = quotemeta $g ) =~ s/\\\*/[^\/]*/g; $r =~ s/\\\?/[^\/]/g; return qr/\A$r\z/ }

# include aufloesen (rekursiv), Kontext pruefen
sub _expand {
    my ( $p, $list, $ctx ) = @_;
    my @out;
    for my $d (@$list) {
        if ( $d->{name} eq 'include' ) {
            _nargs($d);
            my $pat = $d->{args}[0];
            $pat = "/etc/nginx/$pat" unless $pat =~ m{\A/};
            my @files;
            if ( $pat =~ /[*?\[]/ ) { @files = $p->{glob}->($pat) }
            else { @files = ($pat) }
            for my $f (@files) {
                local $p->{at} = { file => $d->{file}, line => $d->{line} };
                die { msg => 'include depth', file => $d->{file}, line => $d->{line} } if ++$p->{depth} > 50;
                push @out, @{ _expand( $p, _parse_file( $p, $f, $ctx ), $ctx ) };
            }
            next;
        }
        push @out, $d;
        if ( $d->{block} && $d->{name} ne 'types' && $d->{name} ne 'map' && $d->{name} ne 'geo' ) {
            my $inner = $d->{name} eq 'events' ? 'E' : $d->{name} eq 'http' ? 'H' : $d->{name} eq 'server' ? ( $ctx eq 'U' ? 'X' : 'S' )
                : $d->{name} eq 'location' || $d->{name} eq 'limit_except' ? 'L' : $d->{name} eq 'if' ? 'I' : $d->{name} eq 'upstream' ? 'U' : $ctx;
            $d->{block} = _expand( $p, $d->{block}, $inner );
        }
        elsif ( $d->{block} ) {
            my @x;
            for my $e ( @{ $d->{block} } ) {
                if ( $e->{name} eq 'include' ) {
                    my $f = $e->{args}[0];
                    $f = "/etc/nginx/$f" unless $f =~ m{\A/};
                    push @x, @{ _parse_file( $p, $f, 'T' ) };
                }
                else { push @x, $e }
            }
            $d->{block} = \@x;
        }
    }
    return \@out;
}

sub _err { my ( $d, $msg ) = @_; die { msg => $msg, file => $d->{file}, line => $d->{line} } }

sub _nargs {
    my ($d) = @_;
    my $r = $NARGS{ $d->{name} } or return;
    my $n = @{ $d->{args} };
    _err( $d, "invalid number of arguments in \"$d->{name}\" directive" ) if $n < $r->[0] || $n > $r->[1];
}

# Pruefen: Kontext, Argumente, Werte, Doppelte
sub _check {
    my ( $p, $list, $ctx ) = @_;
    my %seen;
    for my $d (@$list) {
        my $n = $d->{name};
        my $k = $ctx eq 'X' ? 1 : _known( $n, $ctx );
        $k = 1 if $ctx eq 'U' && $n eq 'server';
        _err( $d, "unknown directive \"$n\"" ) unless $k;
        _err( $d, "\"$n\" directive is not allowed here" ) if $k < 0;
        _err( $d, "directive \"$n\" has no opening \"{\"" ) if $BLOCK{$n} && !$d->{block} && !( $n eq 'server' && $ctx eq 'U' );
        _err( $d, "\"$n\" directive is not allowed here" ) if $d->{block} && !$BLOCK{$n};
        _nargs($d) unless $n eq 'server' && $ctx eq 'U';
        _err( $d, "\"$n\" directive is duplicate" ) if $ONCE{$n} && $seen{$n}++;
        _check_value( $p, $d, $ctx );
        next unless $d->{block};
        next if $n eq 'types' || $n eq 'map' || $n eq 'geo' || $n eq 'split_clients';
        my $inner = $n eq 'events' ? 'E' : $n eq 'http' ? 'H' : $n eq 'server' ? 'S' : $n eq 'upstream' ? 'U'
            : $n eq 'if' ? 'I' : 'L';
        _check( $p, $d->{block}, $inner );
    }
}

sub _size {
    my ($v) = @_;
    my ( $n, $u ) = ( $v // '' ) =~ /\A(\d+)([kKmMgG]?)\z/ or return undef;
    return $n * { '' => 1, k => 1024, m => 1024**2, g => 1024**3 }->{ lc $u };
}

sub _secs {
    my ($v) = @_;
    my ( $n, $u ) = ( $v // '' ) =~ /\A(\d+)(ms|s|m|h|d)?\z/ or return undef;
    return $n * { '' => 1, s => 1, ms => 0.001, m => 60, h => 3600, d => 86400 }->{ $u // '' };
}

my %LISTEN_PARAM = map { $_ => 1 } qw( ssl default_server default http2 proxy_protocol reuseport deferred bind spdy quic );

sub _check_value {
    my ( $p, $d, $ctx ) = @_;
    my ( $n, @a ) = ( $d->{name}, @{ $d->{args} } );
    if ( $n eq 'listen' ) {
        for my $x ( @a[ 1 .. $#a ] ) {
            next if $LISTEN_PARAM{$x} || $x =~ /\A(?:backlog|rcvbuf|sndbuf|ipv6only|so_keepalive|fastopen|accept_filter|setfib)=/;
            _err( $d, "invalid parameter \"$x\"" );
        }
        _err( $d, "invalid port in \"$a[0]\" of the \"listen\" directive" )
            unless $a[0] =~ /\A\d{1,5}\z|\A(?:\[[^\]]+\]|[\w.*-]+):\d{1,5}\z|\A[A-Za-z][\w.-]*\z|\Aunix:/;
    }
    elsif ( $n eq 'client_max_body_size' ) { _err( $d, '"client_max_body_size" directive invalid value' ) unless defined _size( $a[0] ) }
    elsif ( $n =~ /_timeout\z/ && $n ne 'keepalive_timeout' ) { _err( $d, "\"$n\" directive invalid value" ) unless defined _secs( $a[0] ) }
    elsif ( $n eq 'proxy_http_version' ) { _err( $d, "invalid value \"$a[0]\" in \"$n\" directive, it must be \"1.0\" or \"1.1\"" ) unless $a[0] =~ /\A1\.[01]\z/ }
    elsif ( $n eq 'ssl_protocols' ) {
        for (@a) { _err( $d, "invalid value \"$_\" in \"ssl_protocols\" directive" ) unless /\A(?:SSLv2|SSLv3|TLSv1|TLSv1\.1|TLSv1\.2|TLSv1\.3)\z/ }
    }
    elsif ( $n eq 'ssl_verify_client' ) { _err( $d, "invalid value \"$a[0]\" in \"ssl_verify_client\" directive, it must be \"on\", \"off\", \"optional\" or \"optional_no_ca\"" ) unless $a[0] =~ /\A(?:on|off|optional|optional_no_ca)\z/ }
    elsif ( $n eq 'add_header' ) { _err( $d, "invalid parameter \"$a[2]\"" ) if @a == 3 && $a[2] ne 'always' }
    elsif ( $n eq 'return' ) {
        _err( $d, "invalid return code \"$a[0]\"" ) unless $a[0] =~ /\A\d{3}\z/ || ( @a == 1 && $a[0] =~ m{\A(?:https?://|\$scheme)} );
    }
    elsif ( $n eq 'rewrite' ) {
        _err( $d, "invalid parameter \"$a[2]\"" ) if @a == 3 && $a[2] !~ /\A(?:last|break|redirect|permanent)\z/;
        _regex( $d, $a[0], 0 );
    }
    elsif ( $n eq 'location' ) {
        my ( $mod, $uri ) = _loc_args($d);
        _err( $d, "invalid location modifier \"$a[0]\"" ) unless defined $mod;
        _regex( $d, $uri, $mod eq '~*' ) if $mod =~ /~/ && $mod ne '^~';
    }
    elsif ( $n eq 'allow' || $n eq 'deny' ) {
        _err( $d, "invalid parameter \"$a[0]\"" ) unless $a[0] eq 'all' || $a[0] =~ m{\A\d+\.\d+\.\d+\.\d+(?:/\d{1,2})?\z} || $a[0] =~ /:/;
    }
    return;
}

sub _regex {
    my ( $d, $re, $ci ) = @_;
    my $q = eval { $ci ? qr/$re/i : qr/$re/ };
    _err( $d, "pcre2_compile() failed: missing closing parenthesis in \"$re\"" ) unless $q;
    return $q;
}

sub _loc_args {
    my ($d) = @_;
    my @a = @{ $d->{args} };
    return ( @a == 2 ? ( $a[0] =~ /\A(?:=|~|~\*|\^~)\z/ ? @a : ( undef, $a[1] ) ) : () ) if @a == 2;
    my $x = $a[0];
    return ( '@', $x ) if $x =~ /\A\@/;
    return ( $1, $2 ) if $x =~ /\A(~\*|\^~|~|=)(.+)\z/s;
    return ( '', $x );
}

# --- Modell -------------------------------------------------------------------------


sub parse {
    my (%o) = @_;
    my $conf = $o{conf} // '/etc/nginx/nginx.conf';
    my $p = { read => $o{reader}, glob => $o{glob}, conf_files => {}, depth => 0 };
    my $cfg = eval {
        my $top = _expand( $p, _parse_file( $p, $conf ), 'M' );
        _check( $p, $top, 'M' );
        _model( $p, $top, \%o );
    };
    if ( my $e = $@ ) {
        my $msg = ref $e eq 'HASH' ? $e->{msg} . ( $e->{file} ? " in $e->{file}:$e->{line}" : '' ) : "$e";
        $msg =~ s/\s+\z//;
        return { error => $msg, conf_files => $p->{conf_files}, files => $p->{files} || {} };
    }
    $cfg->{conf} = $conf;
    $cfg->{conf_files} = $p->{conf_files};
    $cfg->{files} = { %{ $p->{conf_files} }, %{ $p->{files} || {} } };
    return $cfg;
}

sub _model {
    my ( $p, $top, $o ) = @_;
    my ($http) = grep { $_->{name} eq 'http' } @$top;
    my $hd = $http ? $http->{block} : [];
    my %cfg = ( http => [ grep { $_->{name} ne 'server' && $_->{name} ne 'upstream' && $_->{name} ne 'map' } @$hd ],
        servers => [], upstreams => {}, maps => {}, warnings => [] );
    for my $u ( grep { $_->{name} eq 'upstream' } @$hd ) {
        my @s;
        for my $s ( grep { $_->{name} eq 'server' } @{ $u->{block} } ) {
            my ( $addr, @f ) = @{ $s->{args} };
            _err( $s, 'invalid number of arguments in "server" directive' ) unless defined $addr;
            push @s, { addr => $addr =~ /:\d+\z/ ? $addr : "$addr:80", backup => ( grep { $_ eq 'backup' } @f ) ? 1 : 0,
                down => ( grep { $_ eq 'down' } @f ) ? 1 : 0, d => $s };
        }
        _err( $u, "no servers are inside upstream" ) unless @s;
        $cfg{upstreams}{ $u->{args}[0] } = \@s;
    }
    for my $m ( grep { $_->{name} eq 'map' } @$hd ) {
        my ( $src, $var ) = @{ $m->{args} };
        $var =~ s/\A\$//;
        $cfg{maps}{$var} = { src => $src, rules => [ map { [ $_->{name}, $_->{args}[0] // '' ] } @{ $m->{block} } ] };
    }
    my %listen_default;
    my %names;
    for my $s ( grep { $_->{name} eq 'server' } @$hd ) {
        my $srv = { d => $s, dirs => $s->{block}, listens => [], names => [], locations => _locations( $s->{block} ) };
        for my $l ( grep { $_->{name} eq 'listen' } @{ $s->{block} } ) {
            my ( $a, @f ) = @{ $l->{args} };
            next if $a =~ /\A\[/ || $a =~ /\Aunix:/;    # IPv6, Unix-Sockets: nicht nachgebildet
            my ( $ip, $port ) = $a =~ /\A(.+):(\d+)\z/ ? ( $1, $2 ) : $a =~ /\A\d+\z/ ? ( '0.0.0.0', $a ) : ( $a, 80 );
            $ip = '0.0.0.0' if $ip eq '*';
            $ip = '127.0.0.1' if $ip eq 'localhost';
            my $def = ( grep { $_ eq 'default_server' || $_ eq 'default' } @f ) ? 1 : 0;
            my $ssl = ( grep { $_ eq 'ssl' } @f ) ? 1 : 0;
            if ( $def && $listen_default{"$ip:$port"}++ ) { _err( $l, "a duplicate default server for $ip:$port" ) }
            push @{ $srv->{listens} }, { ip => $ip, port => 0 + $port, default => $def, ssl => $ssl };
        }
        push @{ $srv->{listens} }, { ip => '0.0.0.0', port => 80, default => 0, ssl => 0 } unless grep { $_->{name} eq 'listen' } @{ $s->{block} };
        $srv->{names} = [ map { lc } map { @{ $_->{args} } } grep { $_->{name} eq 'server_name' } @{ $s->{block} } ];
        for my $n ( @{ $srv->{names} } ) {
            for my $l ( @{ $srv->{listens} } ) {
                push @{ $cfg{warnings} }, "conflicting server name \"$n\" on $l->{ip}:$l->{port}, ignored"
                    if length $n && $n ne '_' && $names{"$n $l->{ip}:$l->{port}"}++;
            }
        }
        push @{ $cfg{servers} }, $srv;
    }
    # Sockets: ssl gilt fuer alle Server des Sockets
    my %ssl;
    for my $srv ( @{ $cfg{servers} } ) { $ssl{"$_->{ip}:$_->{port}"} ||= $_->{ssl} for @{ $srv->{listens} } }
    $cfg{ssl_sockets} = \%ssl;
    # Pruefungen, die das Modell brauchen
    my $cat = $o->{state} ? _pki()->can('catalog')->( $o->{state} ) : { certs => {}, keys => {} };
    for my $srv ( @{ $cfg{servers} } ) {
        _check_server( $p, \%cfg, $srv, $o, $cat );
    }
    return \%cfg;
}

sub _locations {
    my ($list) = @_;
    my @l;
    for my $d ( grep { $_->{name} eq 'location' } @$list ) {
        my ( $mod, $uri ) = _loc_args($d);
        my $loc = { mod => $mod, uri => $uri, d => $d, dirs => $d->{block}, children => _locations( $d->{block} ) };
        $loc->{re} = $mod eq '~*' ? qr/$uri/i : qr/$uri/ if $mod eq '~' || $mod eq '~*';
        _err( $d, "duplicate location \"$uri\"" ) if grep { $_->{mod} eq $mod && $_->{uri} eq $uri } @l;
        push @l, $loc;
    }
    return \@l;
}

my %VARS = map { $_ => 1 } qw( host http_host scheme request_uri uri args query_string is_args remote_addr
    proxy_add_x_forwarded_for server_name server_port server_addr request_method proxy_host proxy_port document_root
    request_filename binary_remote_addr ssl_client_verify ssl_protocol ssl_server_name request remote_port
    https server_protocol content_length content_type realpath_root nginx_version time_iso8601 msec status
    request_id hostname connection request_time upstream_addr ssl_client_s_dn ssl_cipher body_bytes_sent );

sub _check_vars {
    my ( $cfg, $d, $setvars ) = @_;
    for my $a ( @{ $d->{args} } ) {
        while ( $a =~ /\$\{?([A-Za-z_]\w*)\}?/g ) {
            my $v = $1;
            next if $VARS{$v} || $cfg->{maps}{$v} || $setvars->{$v} || $v =~ /\A(?:http|arg|cookie|sent_http|upstream_http|sent_trailer)_/;
            _err( $d, "unknown \"$v\" variable" );
        }
    }
}

sub _walk { my ( $list, $cb, @up ) = @_; for my $d (@$list) { $cb->( $d, @up ); _walk( $d->{block}, $cb, @up, $d ) if $d->{block} && $d->{name} ne 'map' && $d->{name} ne 'types' } }

sub _check_server {
    my ( $p, $cfg, $srv, $o, $cat ) = @_;
    my %set = map { ( $_->{args}[0] // '' ) =~ /\A\$(\w+)/ ? ( $1 => 1 ) : () } grep { $_->{name} eq 'set' } map { _all($_) } $srv->{d};
    _walk( $srv->{dirs}, sub {
        my ( $d, @up ) = @_;
        _check_vars( $cfg, $d, \%set ) if $d->{name} =~ /\A(?:proxy_pass|proxy_set_header|add_header|return|rewrite|try_files|set|root|alias)\z/;
        if ( $d->{name} eq 'proxy_pass' ) {
            my $url = $d->{args}[0];
            my ( $sch, $host, $port, $uri ) = $url =~ m{\A(https?)://([^/:]+)(?::(\d+))?(/.*)?\z} or _err( $d, "invalid URL prefix in \"$url\"" );
            my ($loc) = grep { $_->{name} eq 'location' } reverse @up;
            my $in_if = grep { $_->{name} eq 'if' } @up;
            if ( defined $uri && $url !~ /\$/ && ( $in_if || $loc && ( _loc_args($loc) )[0] =~ /\A(?:~|~\*|\@)\z/ ) ) {
                _err( $d, '"proxy_pass" cannot have URI part in location given by regular expression, or inside named location, or inside "if" statement, or inside "limit_except" block' );
            }
            if ( $host !~ /\$/ && !( !defined $port && $cfg->{upstreams}{$host} ) && $host !~ /\A\d+\.\d+\.\d+\.\d+\z/ && $host ne 'localhost' ) {
                my ($ip) = $o->{dev} ? _L()->can('_resolve')->( $o->{dev}, $host ) : ();
                _err( $d, "host not found in upstream \"$host" . ( defined $port ? ":$port" : '' ) . "\"" ) unless defined $ip;
            }
        }
    } );
    for my $u ( values %{ $cfg->{upstreams} } ) {
        for my $s (@$u) {
            my ($h) = $s->{addr} =~ /\A(.+):\d+\z/;
            next if $h =~ /\A\d+\.\d+\.\d+\.\d+\z/ || $h eq 'localhost' || $s->{checked}++;
            my ($ip) = $o->{dev} ? _L()->can('_resolve')->( $o->{dev}, $h ) : ();
            _err( $s->{d}, "host not found in upstream \"$s->{addr}\"" ) unless defined $ip;
        }
    }
    # TLS: Zertifikat und Schluessel laden
    return unless grep { $_->{ssl} || $cfg->{ssl_sockets}{"$_->{ip}:$_->{port}"} } @{ $srv->{listens} };
    my $cert = _eff1( $cfg, [ $srv->{dirs} ], 'ssl_certificate' );
    my $key  = _eff1( $cfg, [ $srv->{dirs} ], 'ssl_certificate_key' );
    my ($ld) = grep { $_->{name} eq 'listen' && grep { $_ eq 'ssl' } @{ $_->{args} } } @{ $srv->{dirs} };
    $ld //= $srv->{d};
    _err( $ld, 'no "ssl_certificate" is defined for the "listen ... ssl" directive' ) unless $cert;
    _err( $ld, 'no "ssl_certificate_key" is defined for certificate "' . $cert->{args}[0] . '"' ) unless $key;
    my $read = sub { my ($f) = @_; my $t = $p->{read}->($f); $p->{files}{$f} = $t if defined $t; return $t };
    my $cf = $cert->{args}[0];
    my $ct = $read->($cf);
    die { msg => "cannot load certificate \"$cf\": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen($cf, r) error:10000080:BIO routines::no such file)" }
        unless defined $ct;
    my @chain = map { $_->{id} } grep { $_->{kind} eq 'cert' && $cat->{certs}{ $_->{id} } } _pki()->can('blocks')->($ct);
    die { msg => "cannot load certificate \"$cf\": PEM_read_bio_X509_AUX() failed (SSL: error:0480006C:PEM routines::no start line:Expecting: TRUSTED CERTIFICATE)" } unless @chain;
    my $kf = $key->{args}[0];
    my $kt = $read->($kf);
    die { msg => "cannot load certificate key \"$kf\": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen($kf, r) error:10000080:BIO routines::no such file)" }
        unless defined $kt;
    my ($kb) = grep { $_->{kind} eq 'key' || $_->{kind} eq 'enckey' } _pki()->can('blocks')->($kt);
    die { msg => "cannot load certificate key \"$kf\": PEM_read_bio_PrivateKey() failed (SSL: error:1E08010C:DECODER routines::unsupported:No supported data to decode.)" }
        unless $kb && $cat->{keys}{ $kb->{id} };
    if ( $kb->{kind} eq 'enckey' ) {
        my $pf = _eff1( $cfg, [ $srv->{dirs} ], 'ssl_password_file' );
        my $want = $cat->{keys}{ $kb->{id} }{passphrase} // '';
        my $pt = $pf ? $read->( $pf->{args}[0] ) : undef;
        die { msg => "open() \"$pf->{args}[0]\" failed (2: No such file or directory)", file => $pf->{file}, line => $pf->{line} } if $pf && !defined $pt;
        die { msg => "cannot load certificate key \"$kf\": PEM_read_bio_PrivateKey() failed (SSL: error:1400006B:UI routines::processing error:while reading strings error:0480006D:PEM routines::problems getting password error:07880109:common libcrypto routines::interrupted or cancelled)" }
            unless defined $pt && grep { $_ eq $want } split /\n/, $pt;
    }
    my $leaf = $cat->{certs}{ $chain[0] };
    die { msg => "SSL_CTX_use_PrivateKey(\"$kf\") failed (SSL: error:05800074:x509 certificate routines::key values mismatch)" }
        unless ( $leaf->{key} // '' ) eq $kb->{id};
    $srv->{tls} = { chain => \@chain, key => $kb->{id} };
    if ( my $cc = _eff1( $cfg, [ $srv->{dirs} ], 'ssl_client_certificate' ) ) {
        my $t = $read->( $cc->{args}[0] );
        die { msg => "SSL_CTX_load_verify_locations(\"$cc->{args}[0]\") failed (SSL: error:80000002:system library::No such file or directory)" } unless defined $t;
        $srv->{tls}{client_ca} = [ map { $_->{id} } grep { $_->{kind} eq 'cert' } _pki()->can('blocks')->($t) ];
    }
    my $vc = _eff1( $cfg, [ $srv->{dirs} ], 'ssl_verify_client' );
    if ( $vc && $vc->{args}[0] =~ /\A(?:on|optional)\z/ && !$srv->{tls}{client_ca} ) {
        _err( $vc, 'no ssl_client_certificate for ssl_verify_client' );
    }
    return;
}

sub _all { my ($d) = @_; return ( $d, map { _all($_) } @{ $d->{block} || [] } ) }

# wirksame Direktive (eine): innerste Ebene zuerst; Ebenen = Listen von Direktiven
sub _eff1 {
    my ( $cfg, $levels, $name ) = @_;
    for my $l ( reverse( $cfg->{http}, @$levels ) ) {
        my ($d) = grep { $_->{name} eq $name } @$l;
        return $d if $d;
    }
    return undef;
}

# wirksame Liste (proxy_set_header, add_header, allow/deny): die innerste Ebene, die eine hat
sub _effn {
    my ( $cfg, $levels, @names ) = @_;
    my %n = map { $_ => 1 } @names;
    for my $l ( reverse( $cfg->{http}, @$levels ) ) {
        my @d = grep { $n{ $_->{name} } } @$l;
        return @d if @d;
    }
    return ();
}

# --- Laden ----------------------------------------------------------------------------

sub _live_reader {
    my ( $dev, $over ) = @_;
    return sub {
        my ($f) = @_;
        return $over->{$f} if $over && exists $over->{$f};
        my $t = _ftext( $dev, $f );
        return $t // $BUILTIN{$f};
    };
}

sub _live_glob {
    my ( $dev, $over ) = @_;
    return sub {
        my $re = _glob_re( $_[0] );
        my %p = map { $_ => 1 } keys %{ $dev->{files} || {} }, keys %{ $over || {} };
        return sort grep { $_ =~ $re && !( $over && exists $over->{$_} && !defined $over->{$_} ) } keys %p;
    };
}

sub _load {
    my ( $dev, $state, $over ) = @_;
    my $ng = $dev->{nginx};
    return parse( reader => _live_reader( $dev, $over ), glob => _live_glob( $dev, $over ), conf => $ng->{conf}, state => $state, dev => $dev );
}

sub _commit {
    my ( $dev, $cfg ) = @_;
    my $new = { conf => $cfg->{conf}, files => $cfg->{files} };
    my $old = $dev->{nginx}{loaded};
    $dev->{nginx}{loaded} = $new unless $old && $JSON->encode($old) eq $JSON->encode($new);
    return;
}

sub _state { my ($ctx) = @_; return $ctx && $ctx->{state} ? $ctx->{state} : {} }


sub ensure {
    my ( $dev, $host, $state ) = @_;
    my $ng = $dev->{nginx};
    return if $ng->{loaded};
    return unless ( ( $dev->{services} || {} )->{nginx} || {} )->{active};
    my $cfg = _load( $dev, $state, $ng->{initial} );
    if ( $cfg->{error} ) { $ng->{loaded} = { error => $cfg->{error} }; return }
    _commit( $dev, $cfg );
    return;
}


sub service {
    my ( $dev, $verb, $ctx ) = @_;
    my $cfg = _load( $dev, _state($ctx) );
    return "nginx: [emerg] $cfg->{error}\nnginx: configuration file " . ( $dev->{nginx}{conf} // '/etc/nginx/nginx.conf' ) . ' test failed'
        if $cfg->{error};
    _commit( $dev, $cfg );
    return undef;
}


sub nginx {
    my ( $dev, $av, $ctx ) = @_;
    my @a = @$av;
    my ( %f, $sig );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-s' ) { $sig = shift @a // return ( 'nginx: option "-s" requires parameter', 0 ) }
        elsif ( $x eq '-c' ) { $dev->{nginx}{conf_override} = shift @a; $f{c} = 1 }
        elsif ( $x eq '-g' ) { shift @a }
        elsif ( $x eq '-p' ) { shift @a }
        elsif ( $x =~ /\A-([tTqvV]+)\z/ ) { $f{$_} = 1 for split //, $1 }
        else { return ( "nginx: invalid option: \"" . substr( $x, 1 ) . "\"", 0 ) }
    }
    my $conf = delete( $dev->{nginx}{conf_override} ) // $dev->{nginx}{conf} // '/etc/nginx/nginx.conf';
    return ( "nginx version: $VERSION_TEXT", 1 ) if $f{v};
    return ( "nginx version: $VERSION_TEXT\nbuilt with OpenSSL 3.0.11 19 Sep 2023 (running with OpenSSL 3.0.15 3 Sep 2024)\nTLS SNI support enabled\nconfigure arguments: --with-cc-opt='-g -O2' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_sub_module", 1 )
        if $f{V};
    my $state = _state($ctx);
    my $svc = ( $dev->{services} || {} )->{nginx};
    if ( $f{t} || $f{T} ) {
        my $cfg = parse( reader => _live_reader($dev), glob => _live_glob($dev), conf => $conf, state => $state, dev => $dev );
        if ( $cfg->{error} ) { return ( "nginx: [emerg] $cfg->{error}\nnginx: configuration file $conf test failed", 0 ) }
        my @l = map {"nginx: [warn] $_"} @{ $cfg->{warnings} };
        push @l, "nginx: the configuration file $conf syntax is ok", "nginx: configuration file $conf test is successful" unless $f{q};
        if ( $f{T} ) {
            for my $file ( sort { $a eq $conf ? -1 : $b eq $conf ? 1 : 0 } keys %{ $cfg->{conf_files} } ) {
                push @l, "# configuration file $file:", $cfg->{conf_files}{$file} =~ s/\n\z//r, '';
            }
        }
        return ( join( "\n", @l ), 1 );
    }
    if ( defined $sig ) {
        return ( "nginx: invalid option: \"-s $sig\"", 0 ) unless $sig =~ /\A(?:reload|stop|quit|reopen)\z/;
        my $cfg = parse( reader => _live_reader($dev), glob => _live_glob($dev), conf => $conf, state => $state, dev => $dev );
        return ( "nginx: [emerg] $cfg->{error}", 0 ) if $cfg->{error};
        return ( 'nginx: [error] invalid PID number "" in "/run/nginx.pid"', 0 ) unless $svc && $svc->{active};
        if ( $sig eq 'reload' ) { _commit( $dev, $cfg ); return ( join( "\n", map {"nginx: [warn] $_"} @{ $cfg->{warnings} } ), 1 ) }
        if ( $sig eq 'stop' || $sig eq 'quit' ) {
            $svc->{restarts} = ( $svc->{restarts} // 0 ) + 1;
            $svc->{active} = JSON::MaybeXS::false();
        }
        return ( '', 1 );
    }
    # nginx ohne Argument: starten
    my $cfg = parse( reader => _live_reader($dev), glob => _live_glob($dev), conf => $conf, state => $state, dev => $dev );
    return ( "nginx: [emerg] $cfg->{error}", 0 ) if $cfg->{error};
    if ( $svc && $svc->{active} ) {
        return ( "nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)\nnginx: [emerg] still could not bind()", 0 );
    }
    $dev->{services}{nginx} //= {};
    $dev->{services}{nginx}{active} = JSON::MaybeXS::true();
    $dev->{services}{nginx}{failed} = JSON::MaybeXS::false() if $dev->{services}{nginx}{failed};
    _commit( $dev, $cfg );
    return ( '', 1 );
}

# --- Anfragen ---------------------------------------------------------------------------

my %CACHE;

sub _model_of {
    my ( $dev, $state ) = @_;
    my $l = $dev->{nginx}{loaded} or return undef;
    return undef if $l->{error};
    my $key = Digest::SHA::sha1_hex( $JSON->encode( [ $l, _pki()->can('catalog')->($state) ] ) );
    %CACHE = () if keys %CACHE > 200;
    return $CACHE{$key} //= do {
        my $files = $l->{files} || {};
        my $cfg = parse( reader => sub { exists $files->{ $_[0] } ? $files->{ $_[0] } : undef },
            glob => sub { my $re = _glob_re( $_[0] ); sort grep { $_ =~ $re } keys %$files }, conf => $l->{conf}, state => $state, dev => $dev );
        $cfg->{error} ? undef : $cfg;
    };
}

my %REASON = ( 400 => 'Bad Request', 403 => 'Forbidden', 404 => 'Not Found', 405 => 'Not Allowed', 413 => 'Request Entity Too Large',
    500 => 'Internal Server Error', 502 => 'Bad Gateway', 503 => 'Service Temporarily Unavailable', 504 => 'Gateway Time-out',
    301 => 'Moved Permanently', 302 => 'Found', 303 => 'See Other', 307 => 'Temporary Redirect', 308 => 'Permanent Redirect',
    401 => 'Authorization Required', 429 => 'Too Many Requests', 444 => '' );

sub _page {
    my ( $code, $tokens, $extra ) = @_;
    my $t = "$code " . ( $REASON{$code} // '' );
    my $sig = $tokens ? $VERSION_TEXT : 'nginx';
    return "<html>\r\n<head><title>" . ( $extra ? "$code $extra" : $t ) . "</title></head>\r\n<body>\r\n<center><h1>$t</h1></center>\r\n"
        . ( $extra ? "<center>$extra</center>\r\n" : '' ) . "<hr><center>$sig</center>\r\n</body>\r\n</html>\r\n";
}

sub _name_match {
    my ( $servers, $name ) = @_;
    return undef unless defined $name && length $name;
    for my $s (@$servers) { return $s if grep { $_ eq $name } @{ $s->{names} } }
    my ( $best, $bl );
    for my $s (@$servers) {
        for my $n ( @{ $s->{names} } ) {
            if ( $n =~ /\A\*\.(.+)\z/ || $n =~ /\A\.(.+)\z/ ) {
                my $d = $1;
                if ( ( $name =~ /\.\Q$d\E\z/ || ( $n =~ /\A\./ && $name eq $d ) ) && ( !$bl || length $d > $bl ) ) { ( $best, $bl ) = ( $s, length $d ) }
            }
        }
    }
    return $best if $best;
    for my $s (@$servers) {
        for my $n ( @{ $s->{names} } ) {
            next unless $n =~ /\A(.+)\.\*\z/;
            return $s if $name =~ /\A\Q$1\E\./;
        }
    }
    for my $s (@$servers) {
        for my $n ( @{ $s->{names} } ) {
            next unless $n =~ /\A~(.+)\z/;
            my $re = $1;
            return $s if eval { $name =~ /$re/ };
        }
    }
    return undef;
}


sub serve {
    my ( $state, $to, $req, $from, $depth ) = @_;
    my $dev = $state->{$to};
    return undef unless ( ( $dev->{services} || {} )->{nginx} || {} )->{active};
    my $cfg = _model_of( $dev, $state ) or return undef;
    my $local = defined $from && $from eq $to;
    require Langertha::Holmgang::Sim::Linux::Http;
    my ( @exact, @wild );
    for my $s ( @{ $cfg->{servers} } ) {
        for my $l ( @{ $s->{listens} } ) {
            next unless $l->{port} == $req->{port};
            if ( $l->{ip} eq '0.0.0.0' ) { push @wild, [ $s, $l ] }
            elsif ( $l->{ip} eq $req->{ip} || ( $l->{ip} =~ /\A127\./ && $req->{ip} =~ /\A127\./ ) ) { push @exact, [ $s, $l ] if $local || $l->{ip} !~ /\A127\./ }
        }
    }
    my @group = @exact ? @exact : @wild;
    return undef unless @group;
    my $sock = "$group[0][1]{ip}:$req->{port}";
    my $ssl = $cfg->{ssl_sockets}{$sock};
    my %seen;
    my @servers = grep { !$seen{"$_"}++ } map { $_->[0] } @group;
    my ($def) = map { $_->[0] } grep { $_->[1]{default} } @group;
    $def //= $servers[0];
    my $tokens = !grep { $_->{args}[0] eq 'off' } grep { $_->{name} eq 'server_tokens' } @{ $cfg->{http} };
    my %base = ( server => $tokens ? $VERSION_TEXT : 'nginx' );
    my $html = sub { my ( $code, $extra ) = @_; return { %base, status => $code, headers => [ [ 'Content-Type', 'text/html' ] ], body => _page( $code, $tokens, $extra ) } };
    if ( $ssl && $req->{scheme} eq 'http' ) { return $html->( 400, 'The plain HTTP request was sent to HTTPS port' ) }
    if ( !$ssl && $req->{scheme} eq 'https' ) { return { %base, status => 400 } }    # kein TLS: der Client meldet den Fehler
    my ( $host_hdr ) = ( $req->{headers}{host} // '' );
    ( my $hname = lc $host_hdr ) =~ s/:\d+\z//;
    my $tls;
    my $tsrv;
    if ($ssl) {
        my $sni = $req->{sni} // ( $req->{host} =~ /\A[\d.]+\z/ ? undef : $req->{host} );
        $tsrv = _name_match( \@servers, defined $sni ? lc $sni : undef ) // $def;
        my $t = $tsrv->{tls} || {};
        my @prot = map { @{ $_->{args} } } grep {defined} _eff1( $cfg, [ $tsrv->{dirs} ], 'ssl_protocols' );
        @prot = qw( TLSv1.2 TLSv1.3 ) unless @prot;
        my %p = map { $_ => 1 } @prot;
        if ( defined $req->{tls_version} && !$p{ $req->{tls_version} } ) {
            return { error => '(35) OpenSSL/3.0.15: error:0A00042E:SSL routines::tlsv1 alert protocol version', code => 35 };
        }
        my $proto = $req->{tls_version} // ( $p{'TLSv1.3'} ? 'TLSv1.3' : $p{'TLSv1.2'} ? 'TLSv1.2' : $p{'TLSv1.1'} ? 'TLSv1.1' : 'TLSv1' );
        $tls = { chain => $t->{chain} || [], protocol => $proto, sni => $sni, ( $t->{client_ca} ? ( client_ca => $t->{client_ca} ) : () ) };
        $tls->{lines} = [ _pki()->can('tls_lines')->( $state, $tls ) ];
    }
    my $srv = _name_match( \@servers, $hname ) // $def;
    my %ctx = ( cfg => $cfg, srv => $srv, req => $req, state => $state, to => $to, from => $from, depth => $depth // 0,
        dev => $dev, tokens => $tokens, html => $html, ssl => $ssl, sock => $sock );
    # Client-Zertifikat
    if ( $ssl && $tsrv->{tls} && $tsrv->{tls}{client_ca} ) {
        my $vc = _eff1( $cfg, [ $tsrv->{dirs} ], 'ssl_verify_client' );
        my $mode = $vc ? $vc->{args}[0] : 'off';
        my $st = 'NONE';
        if ( defined $req->{cert} ) {
            my $fd = $state->{$from} || {};
            my $ct = _ftext( $fd, $req->{cert} ) // '';
            my @ids = map { $_->{id} } grep { $_->{kind} eq 'cert' } _pki()->can('blocks')->($ct);
            my $cat = _pki()->can('catalog')->($state);
            $st = @ids && !_pki()->can('verify_chain')->( $cat, $ids[0], [ @ids[ 1 .. $#ids ] ], $tsrv->{tls}{client_ca} ) ? 'SUCCESS' : 'FAILED';
        }
        $ctx{ssl_client_verify} = $st;
        if ( $mode eq 'on' ) {
            my $r = $st eq 'NONE' ? $html->( 400, 'No required SSL certificate was sent' ) : $st eq 'FAILED' ? $html->( 400, 'The SSL certificate error' ) : undef;
            if ($r) { $r->{tls} = $tls; return $r }
        }
    }
    my $res = _handle( \%ctx );
    $res->{server} //= $base{server};
    if ( $ssl && !defined $res->{error} ) { $res->{tls} = $tls; $res->{cert} = $tls->{chain}[0]; $res->{protocol} = $tls->{protocol} }
    $res->{tls_lines} = $tls->{lines} if $ssl;
    return $res;
}

# Variablen
sub _var {
    my ( $c, $v ) = @_;
    my $r = $c->{req};
    my %h = %{ $c->{out_headers} || {} };
    my $host = lc( $r->{headers}{host} // '' );
    $host =~ s/:\d+\z//;
    my $uri = $c->{uri};
    return $c->{cap}[$v] // '' if $v =~ /\A\d\z/;
    return $c->{set}{$v} if $c->{set} && exists $c->{set}{$v};
    if ( my $m = $c->{cfg}{maps}{$v} ) {
        my $src = _interp( $c, $m->{src} );
        my $def = '';
        for my $rule ( @{ $m->{rules} } ) {
            my ( $k, $val ) = @$rule;
            if ( $k eq 'default' ) { $def = $val; next }
            if ( $k =~ /\A~(\*)?(.*)\z/s ) { my ( $ci, $re ) = ( $1, $2 ); return $val if eval { $ci ? $src =~ /$re/i : $src =~ /$re/ } ; next }
            $k = '' if $k eq "''" || $k eq '""';
            return $val if $src eq $k;
        }
        return $def;
    }
    my %v = (
        host => length $host ? $host : ( $c->{srv}{names}[0] // '' ), http_host => $r->{headers}{host} // '',
        scheme => $r->{scheme}, request_uri => $r->{path}, uri => $uri, args => $c->{args} // '',
        query_string => $c->{args} // '', is_args => length( $c->{args} // '' ) ? '?' : '',
        remote_addr => $r->{client_ip} // '127.0.0.1', server_name => $c->{srv}{names}[0] // '', server_port => $r->{port},
        server_addr => $r->{ip}, request_method => $r->{method}, proxy_host => $c->{proxy_host} // '',
        proxy_port => $c->{proxy_port} // '', document_root => $c->{root} // '', request_filename => ( $c->{root} // '' ) . $uri,
        https => $r->{scheme} eq 'https' ? 'on' : '', ssl_client_verify => $c->{ssl_client_verify} // 'NONE',
        ssl_server_name => $r->{sni} // $host, server_protocol => 'HTTP/1.1', binary_remote_addr => $r->{client_ip} // '',
        request => "$r->{method} $r->{path} HTTP/1.1", nginx_version => '1.22.1', hostname => $c->{to},
    );
    $v{proxy_add_x_forwarded_for} = defined $r->{headers}{'x-forwarded-for'} ? "$r->{headers}{'x-forwarded-for'}, $v{remote_addr}" : $v{remote_addr};
    return $v{$v} if exists $v{$v};
    if ( $v =~ /\Ahttp_(\w+)\z/ ) { ( my $n = lc $1 ) =~ tr/_/-/; return $r->{headers}{$n} // '' }
    if ( $v =~ /\Aarg_(\w+)\z/ ) { my $n = $1; return ( $c->{args} // '' ) =~ /(?:\A|&)\Q$n\E=([^&]*)/ ? $1 : '' }
    if ( $v =~ /\Acookie_(\w+)\z/ ) { my $n = $1; return ( $r->{headers}{cookie} // '' ) =~ /(?:\A|;\s*)\Q$n\E=([^;]*)/ ? $1 : '' }
    return '';
}

sub _interp {
    my ( $c, $s ) = @_;
    $s =~ s/\$(?:\{(\w+)\}|(\d|[A-Za-z_]\w*))/_var( $c, $1 \/\/ $2 )/ge;
    return $s;
}

sub _cond {
    my ( $c, @a ) = @_;
    my $e = join ' ', @a;
    $e =~ s/\A\(\s*//;
    $e =~ s/\s*\)\z//;
    if ( $e =~ /\A(\$\S+)\s*(=|!=|~\*|~|!~\*|!~)\s*(.*)\z/s ) {
        my ( $l, $op, $r ) = ( _interp( $c, $1 ), $2, $3 );
        $r =~ s/\A(["'])(.*)\1\z/$2/s;
        return $l eq _interp( $c, $r ) if $op eq '=';
        return $l ne _interp( $c, $r ) if $op eq '!=';
        my $m = $op =~ /\*/ ? $l =~ /$r/i : $l =~ /$r/;
        $c->{cap} = [ $&, map { substr( $l, $-[$_], $+[$_] - $-[$_] ) } 1 .. $#- ] if $m && $op !~ /!/;
        return $op =~ /!/ ? !$m : $m;
    }
    if ( $e =~ /\A(!?)-([fde])\s+(\S+)\z/ ) {
        my ( $neg, $t, $p ) = ( $1, $2, _interp( $c, $3 ) );
        my $x = $t eq 'd' ? _L()->can('_is_dir')->( $c->{dev}, $p ) : defined _ftext( $c->{dev}, $p );
        return $neg ? !$x : $x;
    }
    if ( $e =~ /\A(\$\S+)\z/ ) { my $v = _interp( $c, $1 ); return length $v && $v ne '0' }
    return 0;
}

# Rewrite-Phase: ( 'res', $res ) | ( 'last' ) | ( 'break' ) | ()
sub _rewrite_phase {
    my ( $c, $dirs ) = @_;
    my $changed;
    for my $d (@$dirs) {
        my $n = $d->{name};
        if ( $n eq 'return' ) { return ( 'res', _return( $c, @{ $d->{args} } ) ) }
        if ( $n eq 'set' ) { ( my $v = $d->{args}[0] ) =~ s/\A\$//; $c->{set}{$v} = _interp( $c, $d->{args}[1] ); next }
        if ( $n eq 'break' ) { return ('break') }
        if ( $n eq 'if' ) {
            next unless _cond( $c, @{ $d->{args} } );
            $c->{if_dirs} = $d->{block};
            my @r = _rewrite_phase( $c, $d->{block} );
            return @r if @r;
            next;
        }
        if ( $n eq 'rewrite' ) {
            my ( $re, $rep, $flag ) = @{ $d->{args} };
            my @m = $c->{uri} =~ /$re/ or next;
            $c->{cap} = [ $&, map { defined $-[$_] ? substr( $c->{uri}, $-[$_], $+[$_] - $-[$_] ) : '' } 1 .. $#- ];
            my $no_args = $rep =~ s/\?\z//;
            my $new = _interp( $c, $rep );
            if ( $new =~ /\?/ ) { ( $new, my $a ) = split /\?/, $new, 2; $c->{args} = length( $c->{args} // '' ) && !$no_args ? "$a&$c->{args}" : $a }
            elsif ($no_args) { $c->{args} = '' }
            my $redir = ( $flag // '' ) =~ /\A(?:redirect|permanent)\z/ || $new =~ m{\Ahttps?://};
            if ($redir) {
                my $code = ( $flag // '' ) eq 'permanent' ? 301 : 302;
                my $loc = $new =~ m{\Ahttps?://} ? $new : "$c->{req}{scheme}://" . _var( $c, 'host' ) . _port_part($c) . $new;
                $loc .= '?' . $c->{args} if length( $c->{args} // '' );
                return ( 'res', { status => $code, headers => [ [ 'Content-Type', 'text/html' ], [ 'Location', $loc ] ], body => _page( $code, $c->{tokens} ) } );
            }
            $c->{uri} = $new;
            $c->{rewritten} = 1;
            return ('last') if ( $flag // '' ) eq 'last';
            return ('break') if ( $flag // '' ) eq 'break';
            $changed = 1;
        }
    }
    return $changed ? ('last') : ();
}

sub _port_part { my ($c) = @_; my $p = $c->{req}{port}; return ( $c->{req}{scheme} eq 'https' && $p == 443 || $c->{req}{scheme} eq 'http' && $p == 80 ) ? '' : ":$p" }

sub _return {
    my ( $c, $code, $text ) = @_;
    if ( $code !~ /\A\d+\z/ ) { ( $code, $text ) = ( 302, $code ) }
    return { error => '(52) Empty reply from server', code => 52 } if $code == 444;
    if ( $code =~ /\A30[12378]\z/ ) {
        my $loc = _interp( $c, $text // '' );
        $loc = "$c->{req}{scheme}://" . _var( $c, 'host' ) . _port_part($c) . $loc if $loc =~ m{\A/};
        return { status => 0 + $code, headers => [ [ 'Content-Type', 'text/html' ], [ 'Location', $loc ] ], body => _page( $code, $c->{tokens} ) };
    }
    return { status => 0 + $code, headers => [ [ 'Content-Type', 'text/plain' ] ], body => _interp( $c, $text ) } if defined $text;
    return { status => 0 + $code, headers => [ [ 'Content-Type', 'text/html' ] ], body => _page( $code, $c->{tokens} ) };
}

# Location-Suche (verschachtelt): ( location, [ kette ] )
sub _find_loc {
    my ( $locs, $uri ) = @_;
    my ($ex) = grep { $_->{mod} eq '=' && $_->{uri} eq $uri } @$locs;
    return ( $ex, [$ex] ) if $ex;
    my ($best) = sort { length $b->{uri} <=> length $a->{uri} }
        grep { ( $_->{mod} eq '' || $_->{mod} eq '^~' ) && substr( $uri, 0, length $_->{uri} ) eq $_->{uri} } @$locs;
    if ( $best && @{ $best->{children} } ) {
        my ( $in, $chain ) = _find_loc( $best->{children}, $uri );
        return ( $in, [ $best, @$chain ] ) if $in;
    }
    return ( $best, [$best] ) if $best && $best->{mod} eq '^~';
    for my $l ( grep { $_->{re} } @$locs ) {
        if ( my @m = $uri =~ $l->{re} ) {
            if ( @{ $l->{children} } ) { my ( $in, $chain ) = _find_loc( $l->{children}, $uri ); return ( $in, [ $l, @$chain ] ) if $in }
            return ( $l, [$l] );
        }
    }
    return $best ? ( $best, [$best] ) : ();
}

sub _in_cidr {
    my ( $ip, $c ) = @_;
    return 1 if $c eq 'all';
    $c .= '/32' unless $c =~ m{/};
    return _L()->can('_in')->( $ip, $c );
}

sub _handle {
    my ($c) = @_;
    my $cfg = $c->{cfg};
    my $srv = $c->{srv};
    my $r = $c->{req};
    ( $c->{uri}, $c->{args} ) = split /\?/, $r->{path}, 2;
    $c->{args} //= '';
    my @sr = _rewrite_phase( $c, $srv->{dirs} );
    return _finish( $c, $sr[1], [] ) if @sr && $sr[0] eq 'res';
    my ( $loc, $chain );
    my $named;
    for my $round ( 1 .. 11 ) {
        return _finish( $c, $c->{html}->(500), [] ) if $round == 11;
        if ($named) { ($loc) = grep { $_->{mod} eq '@' && $_->{uri} eq $named } @{ $srv->{locations} }; $chain = [$loc]; undef $named }
        else { ( $loc, $chain ) = _find_loc( $srv->{locations}, $c->{uri} ) }
        $c->{loc} = $loc;
        $c->{if_dirs} = undef;
        my @lv = ( $srv->{dirs}, map { $_->{dirs} } grep {defined} @{ $chain || [] } );
        $c->{levels} = \@lv;
        if ($loc) {
            my @rr = _rewrite_phase( $c, $loc->{dirs} );
            return _finish( $c, $rr[1], \@lv ) if @rr && $rr[0] eq 'res';
            next if @rr && $rr[0] eq 'last';
        }
        # Zugriff
        my @ad = _effn( $cfg, \@lv, 'allow', 'deny' );
        for my $d (@ad) {
            next unless _in_cidr( $r->{client_ip} // '127.0.0.1', $d->{args}[0] );
            return _finish( $c, $c->{html}->(403), \@lv ) if $d->{name} eq 'deny';
            last;
        }
        my $mx = _eff1( $cfg, \@lv, 'client_max_body_size' );
        my $limit = $mx ? _size( $mx->{args}[0] ) : 1024 * 1024;
        return _finish( $c, $c->{html}->(413), \@lv ) if $limit && ( $r->{body_size} // 0 ) > $limit;
        my @pp_levels = ( @lv, $c->{if_dirs} ? $c->{if_dirs} : () );
        my ($pp) = grep { $_->{name} eq 'proxy_pass' } map {@$_} grep {defined} ( $loc ? $loc->{dirs} : undef ), $c->{if_dirs};
        return _finish( $c, _proxy( $c, $pp, \@pp_levels ), \@pp_levels ) if $pp;
        my ( $res, $next ) = _static( $c, \@lv );
        if ( !defined $next && $res && !$c->{error_paged} && ( my $ep = _error_page( $c, \@lv, $res->{status} ) ) ) {
            ( $next, $c->{status_override} ) = @$ep;
            $c->{error_paged} = 1;
        }
        if ( defined $next ) {
            if ( $next =~ /\A\@/ ) { $named = $next }
            else { ( $c->{uri}, my $a ) = split /\?/, $next, 2; $c->{args} = $a if defined $a }
            next;
        }
        $res->{status} = $c->{status_override} if $c->{status_override} && ( $res->{status} // 200 ) == 200;
        return _finish( $c, $res, \@lv );
    }
}

# error_page CODE … [=ANTWORT] URI: ( uri, status ) oder undef
sub _error_page {
    my ( $c, $lv, $status ) = @_;
    for my $d ( _effn( $c->{cfg}, $lv, 'error_page' ) ) {
        my @a = @{ $d->{args} };
        my $uri = pop @a;
        my ($resp) = map { /\A=(\d*)\z/ ? $1 : () } @a;
        next unless grep { /\A\d{3}\z/ && $_ == ( $status // 0 ) } @a;
        return [ $uri, defined $resp ? ( length $resp ? $resp : 200 ) : $status ];
    }
    return undef;
}

my %ADD_OK = map { $_ => 1 } qw( 200 201 204 206 301 302 303 304 307 308 );

sub _finish {
    my ( $c, $res, $levels ) = @_;
    return $res if defined $res->{error};
    my @h = @{ $res->{headers} || [] };
    for my $d ( _effn( $c->{cfg}, $levels, 'add_header' ) ) {
        my ( $n, $v, $always ) = @{ $d->{args} };
        next unless $always || $ADD_OK{ $res->{status} // 200 };
        my $val = _interp( $c, $v );
        push @h, [ $n, $val ] if length $val;
    }
    $res->{headers} = \@h;
    return $res;
}

my %TYPE = ( html => 'text/html', htm => 'text/html', css => 'text/css', js => 'application/javascript', json => 'application/json',
    png => 'image/png', jpg => 'image/jpeg', jpeg => 'image/jpeg', svg => 'image/svg+xml', txt => 'text/plain', ico => 'image/x-icon' );

sub _is_file {
    my ( $dev, $p ) = @_;
    return 0 if $p =~ m{/\z};
    return defined _ftext( $dev, $p ) && !_L()->can('_is_dir')->( $dev, $p ) ? 1 : 0;
}

# statische Dateien: ( antwort ) oder ( undef, neue_uri ) fuer interne Umleitung
sub _static {
    my ( $c, $lv ) = @_;
    my $cfg = $c->{cfg};
    my $dev = $c->{dev};
    my $loc = $c->{loc};
    my $al = $loc ? ( grep { $_->{name} eq 'alias' } @{ $loc->{dirs} } )[0] : undef;
    my $rd = _eff1( $cfg, $lv, 'root' );
    my $root = $rd ? _interp( $c, $rd->{args}[0] ) : '/usr/share/nginx/html';
    $root = "/usr/share/nginx/$root" unless $root =~ m{\A/};
    $c->{root} = $root;
    my $map = sub {
        my ($u) = @_;
        if ($al) {
            my $a = _interp( $c, $al->{args}[0] );
            my $pre = $loc->{mod} eq '' || $loc->{mod} eq '^~' ? $loc->{uri} : '';
            return $a . substr( $u, length $pre ) if length $pre && substr( $u, 0, length $pre ) eq $pre;
            return $a;
        }
        return $root . $u;
    };
    my $id = _eff1( $cfg, $lv, 'index' );
    my @index = $id ? @{ $id->{args} } : ('index.html');
    my $serve = sub {
        my ($path) = @_;
        my ($ext) = $path =~ /\.(\w+)\z/;
        my $dt = _eff1( $cfg, $lv, 'default_type' );
        return { status => 200, headers => [ [ 'Content-Type', $TYPE{ lc( $ext // '' ) } // ( $dt ? $dt->{args}[0] : 'application/octet-stream' ) ] ],
            body => _ftext( $dev, $path ) // '', file => $path };
    };
    my $tf = $loc ? ( grep { $_->{name} eq 'try_files' } @{ $loc->{dirs} } )[0] : undef;
    $tf //= ( grep { $_->{name} eq 'try_files' } @{ $c->{srv}{dirs} } )[0] unless $loc;
    if ($tf) {
        my @a = @{ $tf->{args} };
        my $last = pop @a;
        for my $x (@a) {
            my $u = _interp( $c, $x );
            if ( $u =~ m{/\z} ) {
                my $d = $map->($u);
                for my $i (@index) { return $serve->("$d$i") if _is_file( $dev, "$d$i" ) }
                next;
            }
            my $p = $map->($u);
            return $serve->($p) if _is_file( $dev, $p );
        }
        return ( $c->{html}->( 0 + $1 ) ) if $last =~ /\A=(\d{3})\z/;
        return ( undef, $last ) if $last =~ /\A\@/;
        return ( undef, _interp( $c, $last ) );
    }
    my $u = $c->{uri};
    if ( $u =~ m{/\z} ) {
        my $d = $map->($u);
        for my $i (@index) {
            return $serve->("$d$i") if _is_file( $dev, "$d$i" );
        }
        return $c->{html}->( _L()->can('_is_dir')->( $dev, $d ) ? 403 : 404 );
    }
    my $p = $map->($u);
    return $serve->($p) if _is_file( $dev, $p );
    if ( _L()->can('_is_dir')->( $dev, $p ) ) {
        my $loc2 = "$c->{req}{scheme}://" . _var( $c, 'host' ) . _port_part($c) . "$u/";
        return { status => 301, headers => [ [ 'Content-Type', 'text/html' ], [ 'Location', $loc2 ] ], body => _page( 301, $c->{tokens} ) };
    }
    return $c->{html}->(404);
}

sub _proxy {
    my ( $c, $pp, $lv ) = @_;
    my $cfg = $c->{cfg};
    my $r = $c->{req};
    my $url = _interp( $c, $pp->{args}[0] );
    my ( $sch, $host, $port, $upart ) = $url =~ m{\A(https?)://([^/:]+)(?::(\d+))?(/.*)?\z} or return $c->{html}->(500);
    my $ups = !defined $port && $cfg->{upstreams}{$host};
    $c->{proxy_host} = $ups ? $host : $host . ( defined $port ? ":$port" : '' );
    $c->{proxy_port} = $port // ( $sch eq 'https' ? 443 : 80 );
    my $loc = $c->{loc};
    my $args = length( $c->{args} // '' ) ? "?$c->{args}" : '';
    my $out_uri;
    if ( defined $upart && !$c->{rewritten} && $loc && ( $loc->{mod} eq '' || $loc->{mod} eq '^~' || $loc->{mod} eq '=' ) ) {
        my $rest = substr( $c->{uri}, length $loc->{uri} );
        $rest = '' if $loc->{mod} eq '=';
        $out_uri = $upart . $rest . $args;
    }
    elsif ( $c->{rewritten} || defined $upart ) { $out_uri = $c->{uri} . $args }
    else { $out_uri = $r->{path} }
    # Kopfzeilen an das Backend
    my %h = %{ $r->{headers} || {} };
    delete @h{qw( host connection upgrade keep-alive te proxy-connection )};
    my @set = ( [ 'Host', '$proxy_host' ], [ 'Connection', 'close' ] );
    push @set, map { [ $_->{args}[0], $_->{args}[1] ] } _effn( $cfg, $lv, 'proxy_set_header' );
    for my $s (@set) {
        my $v = _interp( $c, $s->[1] );
        if ( length $v ) { $h{ lc $s->[0] } = $v } else { delete $h{ lc $s->[0] } }
    }
    my $hv = _eff1( $cfg, $lv, 'proxy_http_version' );
    delete $h{upgrade} unless $hv && $hv->{args}[0] eq '1.1';
    my $rt = _eff1( $cfg, $lv, 'proxy_read_timeout' );
    my $timeout = $rt ? _secs( $rt->{args}[0] ) : 60;
    my @cand = $ups
        ? ( ( map { $_->{addr} } grep { !$_->{down} && !$_->{backup} } @$ups ), ( map { $_->{addr} } grep { !$_->{down} && $_->{backup} } @$ups ) )
        : ( $host . ( defined $port ? ":$port" : '' ) );
    return $c->{html}->(502) if $c->{depth} > 6;
    my $timed_out;
    for my $addr (@cand) {
        my $res = Langertha::Holmgang::Sim::Linux::Http::request( $c->{state}, $c->{to},
            { url => "$sch://$addr$out_uri", method => $r->{method}, headers => {%h}, insecure => 1,
              ( defined $r->{body_size} ? ( body_size => $r->{body_size} ) : () ) }, $c->{depth} + 1 );
        if ( defined $res->{error} ) { next }
        if ( ( $res->{delay} // 0 ) > $timeout ) { $timed_out = 1; next }
        my %out = %$res;
        delete @out{qw( tls tls_lines server )};
        $out{headers} = [ grep { lc( $_->[0] ) ne 'server' } @{ $res->{headers} || [] } ];
        return \%out;
    }
    my $e = $c->{html}->( $timed_out ? 504 : 502 );
    $e->{delay} = $timeout if $timed_out;
    return $e;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Nginx - nginx on a simulated Linux server: checking and loading the configuration, answering requests

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator (nginx -t, systemctl reload nginx) and from Sim::Http (curl)
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Nginx::nginx( $dev, [ '-t' ], $ctx );
  my $err = Langertha::Holmgang::Sim::Linux::Nginx::service( $dev, 'reload', $ctx );   # undef = loaded
  my $res = Langertha::Holmgang::Sim::Linux::Nginx::serve( $state, 'web1', \%req, 'client1', 0 );

=head1 DESCRIPTION

nginx 1.22 (Debian 12) as state of a Linux device (cai-platform F<docs/entwurf-evals.md>
§3.3). The configuration lives in the device's files (F</etc/nginx/nginx.conf>
with C<include>, links in F<sites-enabled> as C<files: { link: … }>). The service
is called C<nginx>. Under C<nginx>:

  nginx:
    conf: /etc/nginx/nginx.conf      # optional
    initial: { <path>: "<text>" }    # optional: what was loaded at start when the
                                     # file has changed since (untested); null =
                                     # the file did not exist then
    loaded: { conf, files: { <path>: "<text>" } }   # by the simulator: the loaded configuration

B<Loaded is what applied at the last start, restart or reload> (including
certificates and keys); a changed file only takes effect after that. A
reload with a broken configuration fails, nginx keeps running with the old one;
a restart with a broken configuration leaves nginx stopped.

B<Check> like C<nginx -t>: syntax (C<;>, braces), unknown directives,
context (C<is not allowed here>), number of arguments, duplicate directives and
locations, C<listen> parameters, duplicate C<default_server>, upstream names
(C<host not found in upstream>), C<proxy_pass> with URI in regex locations,
unknown variables, certificate and key (L<Langertha::Holmgang::Sim::Linux::Pki>:
loadable, matching, encrypted only with C<ssl_password_file>), warning on
duplicate server name.

B<Requests> (L</serve>): socket from C<listen> (address, port, C<ssl>,
C<default_server>), server by C<server_name> (exact, C<*.> wildcard,
regex, otherwise default server), certificate by SNI, C<ssl_protocols>,
C<ssl_verify_client> with C<ssl_client_certificate>; locations as in nginx (C<=>,
longest prefix, C<^~>, regex in order, nested, C<@name>);
C<rewrite> (last, break, redirect, permanent), C<return> (also 444), C<if> with
simple conditions, C<set>, C<map>; C<allow>/C<deny>, C<client_max_body_size>;
C<proxy_pass> (URI part replaces the location's prefix, C<upstream> with
C<backup>/C<down>, next server on error or timeout, 502/504),
C<proxy_set_header> (default C<Host $proxy_host>, C<Connection close>),
C<proxy_http_version> (WebSocket needs 1.1), C<proxy_read_timeout>;
C<add_header> (only 2xx/3xx without C<always>); C<root>/C<alias>/C<index>/C<try_files>
with the device's files. As in nginx, C<proxy_set_header>,
C<add_header> and C<allow>/C<deny> on one level replace B<all> of those of the higher level.

Built in (unless present as a file): F</etc/nginx/mime.types>,
F</etc/nginx/proxy_params>, F</etc/nginx/fastcgi_params>.

=head2 parse

  my $cfg = parse( reader => sub { $text_or_undef }, glob => sub { @paths }, conf => '/etc/nginx/nginx.conf',
      state => $state, dev => $dev );
  # { ok => 1, servers, upstreams, maps, http, files, conf_files, warnings } or { error => "…" }

=head2 ensure

Captures the loaded configuration on the first command (running service:
the files, or C<nginx.initial>).

=head2 service

C<systemctl start|restart|reload nginx>: loads the configuration; returns
C<undef> or nginx's message.

=head2 nginx

The command C<nginx> (C<-t>, C<-T>, C<-q>, C<-s reload|stop|quit|reopen>,
C<-v>, C<-V>, C<-c file>, without arguments: start).

=head2 serve

nginx's answer to a request (see L<Langertha::Holmgang::Sim::Linux::Http/request>),
or C<undef> when no running nginx listens on the address and port.

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
