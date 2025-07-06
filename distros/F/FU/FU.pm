package FU 1.2;
use v5.36;
use Carp 'confess', 'croak';
use IO::Socket;
use POSIX ();
use Time::HiRes 'time', 'clock_gettime', 'CLOCK_MONOTONIC';
use FU::Log 'log_write';
use FU::Util;
use FU::Validate;

my $procname;
my $scriptpath = $0;

sub import($pkg, @opt) {
    my $c = caller;
    no strict 'refs';
    *{$c.'::fu'} = \&fu;
    my $spawn;
    for (@opt) {
        if (ref $procname eq 'FU::ARG') { $procname = $_ }
        elsif ($_ eq '-procname') { $procname = bless {}, 'FU::ARG' }
        elsif ($_ eq '-spawn') { $spawn = 1; }
        else { croak "Unknown import option: '$_'" }
    }
    croak "Missing argument for -procname option" if ref $procname eq 'FU::ARG';
    _spawn() if $spawn;
}


our $REQ = {}; # Internal request-local data
our $fu = bless {}, 'FU::obj'; # App request-local data
sub fu() { $fu }

FU::Log::capture_warn(1);
FU::Log::set_fmt(sub($msg) {
    FU::Log::default_fmt($msg,
        fu->path && fu->method ? fu->method.' '.fu->path.(fu->query?'?'.fu->query:'') : '[global]',
    );
});

sub debug         { state $v = 0; $v = $_[0] if @_; $v }
sub log_slow_reqs { state $v = 0; $v = $_[0] if @_; $v }

sub mime_types() { state $v = {qw{
    7z     application/x-7z-compressed
    aac    audio/aac
    atom   application/atom+xml
    avi    video/x-msvideo
    avif   image/avif
    bin    application/octet-stream
    bmp    image/bmp
    bz2    application/x-bzip2
    css    text/css
    csv    text/csv
    gif    image/gif
    htm    text/html
    html   text/html
    ico    image/x-icon
    jpeg   image/jpeg
    jpg    image/jpeg
    js     application/javascript
    json   application/json
    jxl    image/jxl
    mjs    application/javascript
    mp3    audio/mpeg
    mp4    video/mp4
    mp4v   video/mp4
    mpg4   video/mp4
    mpg    video/mpeg
    mpeg   video/mpeg
    oga    audio/ogg
    ogg    audio/ogg
    ogv    video/ogg
    otf    font/otf
    pdf    application/pdf
    png    image/png
    rar    application/x-rar-compressed
    rss    application/rss+xml
    svg    image/svg+xml
    tar    application/x-tar
    tiff   image/tiff
    ttf    font/ttf
    txt    text/plain
    webp   image/webp
    webm   video/webm
    xhtml  text/html
    xml    application/xml
    xsd    application/xml
    xsl    application/xml
    zip    application/zip
    zst    application/zstd
}} }

# XML & JSON generally don't need a charset parameter
sub utf8_mimes { state $v = {map +($_,1), qw{
    application/javascript
    text/css
    text/html
    text/plain
}} }

sub compress_mimes { state $v = {map +($_,1), qw{
    application/atom+xml
    application/javascript
    application/json
    application/rss+xml
    application/xml
    image/svg+xml
    text/css
    text/csv
    text/html
    text/plain
}} }


our $INIT_DB;
our $DB;
sub query_trace($st,@) {
    $REQ->{trace_nsql}++;
    $REQ->{trace_nsqlprep}++ if $st->prepare_time;
    $REQ->{trace_nsqldirect}++ if !defined $st->prepare_time;
    $REQ->{trace_sqlexec} += $st->exec_time;
    $REQ->{trace_sqlprep} += $st->prepare_time if $st->prepare_time;
    if (FU::debug) {
        my $t = $st->param_types;
        my $v = $st->param_values;
        my $txt = $st->get_text_params;
        push $REQ->{trace_sql}->@*, {
            query => $st->query, nrows => $st->nrows,
            exec_time => $st->exec_time, prepare_time => $st->prepare_time,
            # Store the binary value when we're in binary params mode, that way
            # we don't have to keep a reference to the original perl value and
            # we can defer & batch the conversion to text.
            params => [ map +{
                type => $t->[$_],
                !defined $v->[$_] ? (text => undef) :
                             $txt ? (text => "$v->[$_]")
                                  : (bin => $DB->perl2bin($t->[$_], $v->[$_]))
            }, 0..$#$v ],
        };
    }
}
sub _connect_db {
    $DB = ref $INIT_DB eq 'CODE' ? $INIT_DB->() : FU::Pg->connect($INIT_DB);
    $DB->query_trace(\&query_trace);
    $DB
}
sub init_db($info) {
    require FU::Pg;
    $INIT_DB = $info;
    _connect_db;
}


sub _caller_info {
    my($i, @c, @x) = (1);
    $x[0] !~ /^FU(?:$|::)/ && push @c, [ @x[0..3] ] while (@x = caller $i++);
    \@c
}

our @before_request;
our @after_request;
sub before_request :prototype(&) ($f) { push @before_request, [ $f, _caller_info ] }
sub after_request :prototype(&) ($f) { unshift @after_request, [ $f, _caller_info ] }


our %path_routes;
our %re_routes;

sub _add_route($path, $sub, $method) {
    if (ref $path eq 'REGEXP' || ref $path eq 'Regexp') {
        push $re_routes{$method}->@*, [ qr/^$path$/, $sub, _caller_info ];
    } elsif (!ref $path) {
        confess("A route has already been registered for $method $path") if $path_routes{$method}{$path};
        $path_routes{$method}{$path} = [ $sub, _caller_info ];
    } else {
        confess('Path argument in route registration must be a string or regex');
    }
}

sub get     :prototype($&) { push @_, 'GET';     &_add_route; }
sub post    :prototype($&) { push @_, 'POST';    &_add_route; }
sub delete  :prototype($&) { push @_, 'DELETE';  &_add_route; }
sub options :prototype($&) { push @_, 'OPTIONS'; &_add_route; }
sub put     :prototype($&) { push @_, 'PUT';     &_add_route; }
sub patch   :prototype($&) { push @_, 'PATCH';   &_add_route; }
sub query   :prototype($&) { push @_, 'QUERY';   &_add_route; }


sub _err_500 {
    fu->_error_page(500, '500 - Extraterrestrial Server Error', <<~_);
        Ouch! Something went wrong on the server. Perhaps a misconfiguration,
        perhaps a bug, or perhaps just a temporary issue caused by regular
        maintenance or maybe even alien interference.  Details of this error have
        been written to a log file. If the issue persists, please contact the site
        admin to let them know that they might have some fixing to do.
    _
};
my %onerr = (
    400 => sub {
        fu->_error_page(400, '400 - Bad Request', 'The server was not happy with your offer.');
    },
    404 => sub {
        fu->_error_page(404, '404 - Page Not Found', <<~_);
            Whatever it is you were looking for, this probably isn't it.
            <br><small>Unless you were looking for an error page, in which case:
            Congratulations!</small>
        _
    },
    500 => \&_err_500,
);
sub on_error :prototype($&) { $onerr{$_[0]} = $_[1] }


my($monitor_check, @monitor_paths);
sub monitor_path { push @monitor_paths, @_ }
sub monitor_check :prototype(&) { $monitor_check = $_[0] }

sub _monitor {
    return 1 if $monitor_check && $monitor_check->();

    require File::Find;
    eval {
        File::Find::find({
            wanted => sub { die if (-M) < 0 },
            no_chdir => 1
        }, grep -e, $scriptpath, values %INC, @monitor_paths);
        0
    } // 1;
}


our $debug_info = {};
sub debug_info($path, $storage=undef, $history=100) {
    $debug_info = { path => $path, storage => $storage, history => $history }
}


our $hdrname_re = qr/[!#\$\%&'\*\+-\.^_`\|~0-9a-zA-Z]{1,127}/;
our $method_re = qr/(?:HEAD|GET|POST|DELETE|OPTIONS|PUT|PATCH|QUERY)/;

# rfc7230 used as reference, though strict conformance is not a goal.
# Does not limit size of headers, so not suitable for deployment in untrusted networks.
sub _read_req_http($sock, $req) {
    local $/ = "\r\n";
    my $line = $sock->getline;
    fu->error(400, 'Client disconnect before request was read') if !defined $line;
    fu->error(400, 'Invalid request') if $line !~ /^($method_re)\s+(\S+)\s+HTTP\/1\.[01]\r\n$/;
    $req->{method} = $1;
    $req->{path} = $2 =~ s{^https?://[^/]+/}{/}r;

    while (1) {
        # Turns out header line folding has been officially deprecated, so I'm
        # going to be lazy and only support single-line headers.
        $line = $sock->getline;
        fu->error(400, 'Client disconnect before request was read') if !defined $line;
        last if $line eq "\r\n";
        fu->error(400, 'Invalid request header syntax') if $line !~ /^($hdrname_re):\s*(.+)\r\n$/;
        my($hdr, $val) = (lc $1, $2 =~ s/\s*$//r);
        if (exists $req->{hdr}{$hdr}) {
            $req->{hdr}{$hdr} .= ($hdr eq 'cookie' ? '; ' : ', ') . $val;
        } else {
            $req->{hdr}{$hdr} = $val;
        }
    }

    fu->error(400, 'Unexpected Transfer-Encoding request header') if $req->{hdr}{'transfer-encoding'};
    my $len = $req->{hdr}{'content-length'} // 0;
    fu->error(400, 'Invalid Content-Length request header') if $len !~ /^(?:0|[1-9][0-9]*)$/;

    $req->{body} = '';
    while ($len > 0) {
        my $r = $sock->read($req->{body}, $len, length $req->{body});
        fu->error(400, 'Client disconnect before request was read') if !$r;
        $len -= $r;
    }
}


sub _read_req($c) {
    if ($c->{fcgi_obj}) {
        my $r = $c->{fcgi_obj}->read_req($REQ->{hdr}, $REQ);
        # Only FUFE_ABORT is an error we can recover from, in all other
        # cases we have not properly consumed the request from the socket
        # so we'll leave the protocol in an invalid state in case we do
        # attempt to respond.
        # All other errors suggest a misconfigured web server, anyway.
        if ($r == -6) { fu->error(400, 'Client disconnect before request was read') }
        elsif ($r) {
            log_write
                 $r == -1 ? "Unexpected EOF while reading from FastCGI socket\n"
               : $r == -2 ? "I/O error while reading from FastCGI socket\n"
               : $r == -3 ? "FastCGI protocol error\n"
               : $r == -4 ? "Too long FastCGI parameter\n"
               : $r == -5 ? "Too long request body\n" : undef if $r != -7;
            delete $c->{fcgi_obj};
            fu->error(-1);
        }
        fu->error(400, 'Invalid request') if !$REQ->{method} || $REQ->{method} !~ /^$method_re$/ || !$REQ->{path};
    } else {
        _read_req_http($c->{client_sock}, $REQ);

        # Silly hack to clear ${^LAST_FH}, removes the "at <GEN#> line $n" from warn()
        open my $bullshit, '<', \"\n"; <$bullshit>;
    }

    # The HTTP reader above and the FastCGI XS reader operate on bytes.
    # Decode these into Unicode strings and check for special characters.
    eval { FU::Util::utf8_decode($_); 1} || fu->error(400, $@)
        for ($REQ->{path}, $REQ->{qs}, values $REQ->{hdr}->%*);
    fu->error(400, 'Invalid character in path') if $REQ->{path} =~ /#/; # Some bots don't correctly split off the fragment

    ($REQ->{path}, my $qs) = split /\?/, $REQ->{path}//'', 2;
    $REQ->{qs} //= $qs;
    eval { $REQ->{path} = FU::Util::uri_unescape($REQ->{path}); 1; } || fu->error(400, $@);
    fu->error(400, 'Invalid character in path') if $REQ->{path} =~ /[\r\n\t]/; # There are plenty other questionable characters, but newlines and tabs are definitely out
}


sub _is_done($e) { ref $e eq 'FU::err' && $e->[0] == 200 }

sub _log_err($e) {
    return if !$e;
    my $crit = $e isa 'FU::err' ? $e->[0] == 500 : !($e isa 'FU::Validate::err');
    return if !debug && !$crit;
    return fu->log_verbose($e) if $crit;
    log_write $e;
}

sub _do_req($c) {
    local $REQ = {
        hdr => {},
        trace_start => clock_gettime(CLOCK_MONOTONIC),
        trace_id => sprintf('%012x%06x%04x', int(time*10000) % (1<<(12*4)), $$ % (1<<(6*4)), int rand 1<<16)
    };
    local $fu = bless {}, 'FU::obj';

    $REQ->{ip} = $c->{client_sock} isa 'IO::Socket::INET' ? $c->{client_sock}->peerhost : '127.0.0.1';
    fu->reset;

    my $ok = eval {
        _read_req $c;
        $REQ->{trace_start} = clock_gettime(CLOCK_MONOTONIC);

        my $path = fu->path;
        my $method = fu->method eq 'HEAD' ? 'GET' : fu->method;

        # Intercept requests for debug_info, ensuring no website hooks get called.
        if (debug && $method eq 'GET' && $debug_info->{path} && $path eq $debug_info->{path}) {
            require FU::DebugImpl;
            FU::DebugImpl::render();
            fu->_flush($c->{fcgi_obj} || $c->{client_sock});
            fu->error(-1);
        }

        for my $h (@before_request) { $h->[0]->() }

        my $r = $path_routes{$method}{$path};
        if ($r) {
            $REQ->{trace_han} = [ $path, $r->[1] ];
            $r->[0]->();
        } else {
            for $r ($re_routes{ fu->method }->@*) {
                if($path =~ $r->[0]) {
                    $REQ->{trace_han} = [ $r->[0], $r->[2] ];
                    $r->[1]->(@{^CAPTURE});
                    fu->done;
                }
            }
            fu->notfound;
        }
        1;
    };
    return if !$ok && ref $@ eq 'FU::err' && $@->[0] == -1;
    $REQ->{trace_exn} = $ok ? undef : $@;
    my $err = $ok || _is_done($@) ? undef : $@;
    _log_err $err;

    for my $h (@after_request) {
        $ok = eval { $h->[0]->(); 1 };
        _log_err $@ if !$ok;
        $err = $@ if !$err && !$ok && !_is_done($@);
    }

    # Commit transaction, if we have one that's not done yet.
    if (!$err && $REQ->{txn} && $REQ->{txn}->status ne 'done' && !eval { $REQ->{txn}->commit; 1 }) {
        _log_err "Transaction commit failed: $@";
        $err = $@;
    }

    if ($err) {
        my($code, $msg) = $err isa 'FU::err' ? @$err : $err isa 'FU::Validate::err' ? (400, $err) : (500, $err);
        fu->reset;
        fu->status($code);
        my $ok = eval { ($onerr{$code} || $onerr{500})->($code, $msg) };
        if (!$ok && !_is_done($@)) {
            _log_err $@;
            _err_500();
        }
    }

    $REQ->{trace_end} = clock_gettime(CLOCK_MONOTONIC);
    fu->_flush($c->{fcgi_obj} || $c->{client_sock});

    if (debug && $REQ->{trace_id} && $debug_info->{history} && $debug_info->{storage}) {
        require FU::DebugImpl;
        FU::DebugImpl::save();
    }

    my $proc_ms = ($REQ->{trace_end} - $REQ->{trace_start}) * 1000;
    log_write(sprintf "%.0fms%s %s-%s %d-%s\n", $proc_ms,
        $REQ->{trace_nsql} ?
            sprintf ' (sql %.0f+%.0fms, %d/%d/%d)',
            ($REQ->{trace_sqlexec}||0)*1000, ($REQ->{trace_sqlprep}||0)*1000,
            $REQ->{trace_nsqldirect}||0, $REQ->{trace_nsqlprep}||0, $REQ->{trace_nsql} : '',
        $REQ->{status}, ($REQ->{reshdr}{'content-type'}//'-') =~ s/;.+$//r,
        length($REQ->{resbody}), substr($REQ->{reshdr}{'content-encoding'}//'r', 0, 1)
    ) if FU::debug || $proc_ms > (FU::log_slow_reqs||1e10);
}


sub _run_loop($c) {
    my $stop = 0;
    my $count = 0;
    local $SIG{HUP} = 'IGNORE';
    local $SIG{TERM} = $SIG{INT} = sub { $stop = 1 };

    my sub passclient {
        FU::Util::fdpass_send(fileno($c->{supervisor_sock}), fileno($c->{client_sock}), 'f0000')
            if $c->{supervisor_sock} && $c->{client_sock};
        exit;
    }

    my sub setstate($state) {
        $0 = sprintf "%s: %s [#%d%s]", $procname, $state, $count, $c->{max_reqs} ? "/$c->{max_reqs}" : '' if $procname;
    }

    while (!$stop) {
        setstate 'idle';

        $c->{client_sock} ||= $c->{listen_sock}->accept || next;
        $c->{fcgi_obj} ||= $c->{listen_proto} eq 'fcgi' && FU::fcgi::new(fileno $c->{client_sock}, $c->{proc});

        if ($c->{monitor} && _monitor) {
            log_write "File change detected, restarting process.\n" if debug;
            passclient;
        }

        setstate 'working';
        _do_req $c;

        $c->{client_sock} = $c->{fcgi_obj} = undef if !($c->{fcgi_obj} && $c->{fcgi_obj}->keepalive);

        $count++;
        passclient if $c->{max_reqs} && $count >= $c->{max_reqs};
    }
}


sub _supervisor($c) {
    my ($rsock, $wsock) = IO::Socket->socketpair(IO::Socket::AF_UNIX(), IO::Socket::SOCK_STREAM(), IO::Socket::PF_UNSPEC());

    my %childs; # pid => 1: spawned, 2: signalled ready
    $SIG{CHLD} = sub { $wsock->syswrite('c0000',5) };
    $SIG{HUP} = $SIG{TERM} = $SIG{INT} = sub($sig,@) {
        kill 'TERM', keys %childs;
        return if $sig eq 'HUP';
        $SIG{$sig} = undef;
        kill $sig, $$;
        exit 1;
    };

    require Fcntl;
    fcntl $c->{listen_sock}, Fcntl::F_SETFD(), 0;
    fcntl $wsock, Fcntl::F_SETFD(), 0;

    $ENV{FU_MONITOR} = $c->{monitor};
    $ENV{FU_PROC} = $c->{proc};
    $ENV{FU_MAX_REQS} = $c->{max_reqs};
    $ENV{FU_DEBUG} = debug;
    $ENV{FU_SUPERVISOR_FD} = fileno $wsock;
    $ENV{FU_LISTEN_FD} = fileno $c->{listen_sock};
    $ENV{FU_LISTEN_PROTO} = $c->{listen_proto};

    my $err = 0;
    my @client_fd;
    my $msg = '';
    while (1) {
        while ((my $pid = waitpid(-1, POSIX::WNOHANG())) > 0) {
            $err = 1 if POSIX::WIFEXITED($?) && POSIX::WEXITSTATUS($?) != 0;
            if (!$err && (!$childs{$pid} || $childs{$pid} != 2)) {
                $err = 1;
                log_write "Script exited before calling FU::run()\n";
            }
            delete $childs{$pid};
        }

        # Don't bother spawning more than 1 at a time while in error state
        my $spawn = !$err ? $c->{proc} - keys %childs : !@client_fd && (grep $_ == 1, values %childs) ? 0 : 1;
        for (1..$spawn) {
            my $client = @client_fd ? IO::Socket->new_from_fd(shift(@client_fd), 'r') : undef;
            my $pid = fork;
            die $! if !defined $pid;
            if (!$pid) { # child
                $SIG{CHLD} = $SIG{HUP} = $SIG{INT} = $SIG{TERM} = undef;
                $0 = sprintf '%s: starting', $procname if $procname;
                # In error state, wait with loading the script until we've received a request.
                # Otherwise we'll end up in an infinite spawning loop if the script doesn't start properly.
                $client = $c->{listen_sock}->accept() or die $! if !$client && $err;
                if ($client) {
                    fcntl $client, Fcntl::F_SETFD, 0;
                    $ENV{FU_CLIENT_FD} = fileno $client;
                }
                exec $^X, (map "-I$_", @INC), $scriptpath;
                exit 1;
            }
            $childs{$pid} = 1;
        }

        $0 = sprintf "%s: supervisor [%d/%d]", $procname, scalar keys %childs, $c->{proc} if $procname;

        my ($fd, $msgadd) = FU::Util::fdpass_recv(fileno($rsock), 500);
        push @client_fd, $fd if $fd;
        next if !defined $msgadd;
        $msg .= $msgadd;
        while ($msg =~ s/^(.)(....)//s) {
            my($cmd, $arg) = ($1, $2);
            next if $cmd eq 'c'; # child died
            next if $cmd eq 'f'; # child is about to exit and passed a client fd to us
            if ($cmd eq 'r') { # child ready
                my $pid = unpack 'V', $arg;
                $childs{$pid} = 2 if $childs{$pid};
                $err = 0;
            }
        }
    }
}


sub _spawn {
    state %c;
    return if keys %c && !@_; # already checked if we need to spawn

    if (!keys %c) {
        %c = (
            http => $ENV{FU_HTTP},
            fcgi => $ENV{FU_FCGI},
            proc => $ENV{FU_PROC} // 1,
            monitor => $ENV{FU_MONITOR} // 0,
            max_reqs => $ENV{FU_MAX_REQS} // 0,
            listen_proto => $ENV{FU_LISTEN_PROTO},
            listen_sock => $ENV{FU_LISTEN_FD} && IO::Socket->new_from_fd($ENV{FU_LISTEN_FD}, 'r'),
            client_sock => $ENV{FU_CLIENT_FD} && IO::Socket->new_from_fd($ENV{FU_CLIENT_FD}, 'r+'),
            supervisor_sock => $ENV{FU_SUPERVISOR_FD} && IO::Socket->new_from_fd($ENV{FU_SUPERVISOR_FD}, 'w'),
            !$ENV{FU_SUPERVISOR_FD} && @_ && defined $_[0] ? @_ : (),
        );
        debug $ENV{FU_DEBUG} if exists $ENV{FU_DEBUG};

        for (@_ ? () : @ARGV) {
            $c{http} = $1 if /^--http=(.+)$/;
            $c{fcgi} = $1 if /^--fcgi=(.+)$/;
            $c{proc} = $1 if /^--proc=([0-9]+)$/;
            $c{monitor} = 1 if /^--monitor$/;
            $c{monitor} = 0 if /^--no-monitor$/;
            $c{max_reqs} = $1 if /^--max-reqs=([0-9]+(?::[0-9]+)?)$/;
            debug 1 if /^--debug$/;
            debug 0 if /^--no-debug$/;
            $ENV{FU_LOG_FILE} = $1 if /^--log-file=(.+)$/;
        }
        FU::Log::set_file($ENV{FU_LOG_FILE}) if $ENV{FU_LOG_FILE};
    };

    # Single process, no need for a supervisor
    my $need_supervisor = !$c{supervisor_sock} && !$c{client_sock} && ($c{proc} > 1 || $c{monitor} || $c{max_reqs});
    return if !@_ && !$need_supervisor;

    if (!$c{http} && !$c{fcgi} && !$c{listen_sock}) {
        # When spawned under FastCGI, stdin is our listen socket
        local $_ = getpeername \*STDIN;
        if ($!{ENOTCONN}) {
            $c{listen_sock} = IO::Socket->new_from_fd(0, 'r');
            $c{listen_proto} = 'fcgi';
        }
    };
    $c{http} //= '127.0.0.1:3000';

    if (!$c{listen_sock}) {
        $c{listen_proto} //= $c{fcgi} ? 'fcgi' : 'http';
        my $addr = $c{$c{listen_proto}};
        $c{listen_sock} = IO::Socket->new(
            Listen => 10 * $c{proc},
            Type => IO::Socket::SOCK_STREAM(),
            $addr =~ m{^(unix:|/)(.+)$} ? do {
                my $path = ($1 eq '/' ? '/' : '').$2;
                unlink $path if -S $path;
                +(Domain => IO::Socket::AF_UNIX(), Local => $path)
            } : (
                Domain => IO::Socket::AF_INET(),
                ReuseAddr => 1,
                Proto => 'tcp',
                LocalAddr => $addr,
            )
        ) or die "Unable to create listen socket: $!\n";
        log_write "Listening on $addr\n" if debug;
    }

    if ($need_supervisor) {
        _supervisor \%c;
    } else {
        $c{supervisor_sock}->syswrite('r'.pack 'V', $$) if $c{supervisor_sock};
        $c{max_reqs} = $1 >= $2 ? $1 : $1 + int rand $2-$1 if $c{max_reqs} =~ /^([0-9]+):([0-9]+)$/;
        _run_loop \%c;
    }
}


sub run(%conf) {
    confess "FU::run() called with configuration options, but FU has already been loaded with -spawn" if keys %conf;
    # Clean up any state we may have accumulated during initialization.
    $REQ = {};
    $fu = bless {}, 'FU::obj';
    _spawn(keys %conf ? \%conf : undef);
}



package FU::obj;

use v5.36;
use Carp 'confess';

sub fu() { $FU::fu }
sub debug { FU::debug }

sub db_conn { $FU::DB || FU::_connect_db }

sub db {
    $REQ->{txn} ||= do {
        my $txn = eval { fu->db_conn->txn };
        if (!$txn) {
            # Can't start a transaction? We might be screwed, try to reconnect.
            FU::_connect_db;
            $txn = fu->db_conn->txn; # Let this error if it also fails
        }
        $txn
    };
}

sub sql { shift->db->q(@_) }
sub SQL { shift->db->Q(@_) }

sub _fmt_section($s) { $s =~ s/^\s*/  /r =~ s/\s+$//r =~ s/\n/\n  /rg }

sub log_verbose($,$msg) {
    my $r = $FU::REQ;
    return FU::Log::log_write($msg) if $r->{log_verbose}++;
    FU::Log::log_write(join "\n",
        'IP: '.($r->{ip}||'-'),
        'Headers:', (map "  $_: $r->{hdr}{$_}", sort keys $r->{hdr}->%*),
        $r->{multipart} ? ('Body (multipart):', _fmt_section join "\n", map $_->describe, $r->{multipart}->@*) :
        $r->{json} ? ('Body (JSON):', _fmt_section FU::Util::json_format($r->{json}, pretty => 1, canonical => 1)) :
        $r->{formdata} ? ('Body (formdata):', _fmt_section FU::Util::json_format($r->{formdata}, pretty => 1, canonical => 1)) :
        length $r->{body} ? do {
            my $b = substr $r->{body}, 0, 4096;
            my $trunc = length $r->{body} > 4096 ? ', truncated' : '';
            utf8::decode($b) ? ("Body (utf8$trunc):", _fmt_section($b =~ s/\r//rg =~ s/\n{4,}/\n[..]\n/rg))
                             : ("Body (hex$trunc):", _fmt_section(unpack('H*', $b) =~ s/(.{128})/$1\n/rg))
        } : (),
        'Message:', _fmt_section $msg
    );
}




# Request information methods

sub path { $FU::REQ->{path} }
sub method { $FU::REQ->{method} }
sub header($, $h) { $FU::REQ->{hdr}{ lc $h } }
sub headers { $FU::REQ->{hdr} }
sub ip { $FU::REQ->{ip} }

sub _getfield($data, @a) {
    if (@a == 1 && !ref $a[0]) {
        fu->error(400, "Expected top-level to be a hash") if ref $data ne 'HASH';
        return $data->{$a[0]};
    }
    my $schema = FU::Validate->compile(@a > 1 ? { keys => {@a} } : $a[0]);
    my $res = $schema->validate($data);
    return @a == 2 ? $res->{$a[0]} : $res;
}

sub query {
    shift;
    return $FU::REQ->{qs} if !@_;
    $FU::REQ->{qs_parsed} ||= eval { FU::Util::query_decode($FU::REQ->{qs}) } || fu->error(400, $@);
    _getfield $FU::REQ->{qs_parsed}, @_;
}

sub cookie {
    shift;
    return fu->header('cookie') if !@_;
    $FU::REQ->{cookie} ||= do {
        my %c;
        for my $c (split /; /, fu->header('cookie')||'') {
            my($n, $v) = split /=/, $c, 2;
            if (!exists $c{$n}) { $c{$n} = $v }
            elsif (ref $c{$n}) { push $c{$n}->@*, $v }
            else { $c{$n} = [ $c{$n}, $v ] }
        }
        \%c
    };
    _getfield $FU::REQ->{cookie}, @_;
}

sub json {
    shift;
    fu->error(400, "Invalid content type for json") if (fu->header('content-type')||'') !~ m{^application/json(?:;\s*charset=utf-?8)?$}i;
    return FU::Util::utf8_decode(my $x = $FU::REQ->{body}) if !@_;
    $FU::REQ->{json} ||= eval {
        FU::Util::json_parse($FU::REQ->{body}, utf8 => 1)
    } || fu->error(400, "JSON parse error: $@");
    _getfield $FU::REQ->{json}, @_;
}

sub formdata {
    shift;
    fu->error(400, "Invalid content type for form data") if (fu->header('content-type')||'') ne 'application/x-www-form-urlencoded';
    return FU::Util::utf8_decode(my $x = $FU::REQ->{body}) if !@_;
    $FU::REQ->{formdata} ||= eval {
        FU::Util::query_decode($FU::REQ->{body});
    } || fu->error(400, $@);
    _getfield $FU::REQ->{formdata}, @_;
}

sub multipart {
    require FU::MultipartFormData;
    $FU::REQ->{multipart} ||= eval {
        FU::MultipartFormData->parse(fu->header('content-type')||'', $FU::REQ->{body})
    } || fu->error(400, $@);
}





# Response generation methods

sub done { die bless [200,'Done',FU::_caller_info], 'FU::err' }
sub error($,$code,$msg=$code) { die bless [$code,$msg,FU::_caller_info], 'FU::err' }
sub denied { fu->error(403) }
sub notfound { fu->error(404) }

sub status($, $code) { $FU::REQ->{status} = $code }
sub set_body($, $data) {
    confess "Invalid undef body" if !defined $data;
    confess "Invalid attempt to set body to $data" if ref $data;
    $FU::REQ->{resbody} = $data;
}

sub reset {
    fu->status(200);
    fu->set_body('');
    $FU::REQ->{reshdr} = {
        'content-type', 'text/html',
    };
    delete $FU::REQ->{rescookie};
}


sub _validate_header($hdr, $val) {
    confess "Invalid response header '$hdr'" if $hdr !~ /^$FU::hdrname_re$/;
    confess "Invalid attempt to set response header containing a newline" if defined $val && $val =~ /[\r\n]/;
}

sub add_header($, $hdr, $val) {
    _validate_header($hdr, $val);
    $hdr = lc $hdr;
    my $h = $FU::REQ->{reshdr};
    if (!defined $h->{$hdr}) { $h->{$hdr} = $val }
    elsif (ref $h->{$hdr}) { push $h->{$hdr}->@*, $val }
    else { $h->{$hdr} = [ $h->{$hdr}, $val ] }
}

sub set_header($, $hdr, $val=undef) {
    _validate_header($hdr, $val);
    $FU::REQ->{reshdr}{ lc $hdr } = $val;
}

sub set_cookie($, $name, $val=undef, %opt) {
    confess "Invalid cookie name '$name'" if $name !~ /^$FU::hdrname_re$/;
    return delete $FU::REQ->{rescookie}{$name} if !defined $val;
    confess "Invalid cookie value: $val" if $val =~ /[\0-\x1f\x7f-\x{10ffff}\s\r\n\t",;\\]/;
    my $c = "$name=$val";
    for my ($k,$v) (%opt) {
        $k = lc $k; # attributes are case-insensitive
        if ($k eq 'domain') {
            confess "Invalid cookie domain: $v" if $v !~ $FU::Validate::re_domain;
        } elsif ($k eq 'expires') {
            confess "Cookie 'Expires' attribute should be a UNIX timestamp" if defined $v && $v !~ /^[0-9]+$/;
            $v = FU::Util::httpdate_format($v || 0);
        } elsif ($k eq 'httponly') {
            $c .= "; $k" if $v;
            next;
        } elsif ($k eq 'max-age') {
            confess "Invalid 'Max-Age' cookie attribute: $v" if $v !~ /^[0-9]+$/;
        } elsif ($k eq 'partitioned') {
            $c .= "; $k" if $v;
            next;
        } elsif ($k eq 'path') {
            confess "Invalid 'Path' cookie attribute: $v" if $v =~ /[\0-\x1f\x7f-\x{10ffff}\s\r\n\t",;\\]/;
        } elsif ($k eq 'secure') {
            $c .= "; $k" if $v;
            next;
        } elsif ($k eq 'samesite') {
            confess "Invalid 'SameSite' cookie attribute: $v" if $v !~ /^(?:Strict|Lax|None)$/;
        }
        $c .= "; $k=$v";
    }
    $FU::REQ->{rescookie}{$name} = $c;
}

sub send_json($, $data) {
    fu->set_header('content-type', 'application/json');
    fu->set_body(FU::Util::json_format($data, canonical => 1, utf8 => 1));
    fu->done;
}

sub send_file($, $root, $path) {
    # This also catches files with '..' somewhere in the middle of the name.
    # Let's just disallow that to simplify this check, I'd err on the side of
    # caution.
    return if $path =~ /\.\./;

    my $fn = "$root/$path";
    return if !-f $fn;
    my $m = (stat $fn)[9];
    return if !defined $m;

    fu->set_header('last-modified', FU::Util::httpdate_format($m));
    my $ims = fu->header('if-modified-since');
    $ims = FU::Util::httpdate_parse($ims) if $ims;
    if ($ims && $ims > $m) {
        fu->status(304);
        fu->done;
    }

    my $ctype = FU::mime_types->{$path =~ m{\.([^/\.]+)$} ? lc $1 : ''};
    {
        open my $fh, '<', $fn or confess "Unable to open '$fn': $!";
        local $/=undef;
        my $body = <$fh>;
        $ctype ||= substr($body, 0, 1024) =~ /[\x00-\x08\x0e-\x1f]/ ? 'application/octet-stream' : 'text/plain';
        fu->set_body($body);
    }
    fu->set_header('content-type', $ctype);
    fu->done;
}

sub redirect($, $code, $location) {
    state $alias = {qw/ perm 301  temp 302  tempget 303  tempsame 307  permsame 308 /};
    fu->status($alias->{$code} // $code);
    fu->set_header(location => "$location");
    fu->set_header('content-type', 'text/plain');
    fu->set_body("Redirecting to $location\n");
    fu->done;
}

sub _error_page($, $code, $title, $msg) {
    fu->reset;
    fu->status($code);
    my $body = <<~_;
      <!DOCTYPE html>
      <html>
      <head>
       <meta name="viewport" content="width=device-width, initial-scale=1">
       <style type="text/css">
        body { margin: 40px auto; max-width:700px; line-height:1.6; font-size: 18px; color:#444; padding:0 10px }
        h1 { line-height:1.2 }
       </style>
       <title>$title</title>
      </head>
      <body>
       <h1>$title</h1>
       <p>$msg</p>
      </body>
      </html>
    _
    utf8::encode($body);
    fu->set_body($body);
}

sub _finalize {
    state $hasgzip = FU::Util::gzip_lib();
    state $hasbrotli = eval { FU::Util::brotli_compress(6, ''); 1 };
    my $r = $FU::REQ;

    fu->add_header('set-cookie', $_) for $r->{rescookie} ? sort values $r->{rescookie}->%* : ();

    if ($r->{status} == 204 || $r->{status} == 304) {
        delete $r->{reshdr}{'content-length'};
        delete $r->{reshdr}{'content-encoding'};
        delete $r->{reshdr}{'content-type'};
        $r->{resbody} = '';

    } else {
        my @vary = ref $r->{reshdr}{vary} eq 'ARRAY' ? $r->{reshdr}{vary}->@* : defined $r->{reshdr}{vary} ? ($r->{reshdr}{vary}) : ();
        if (($hasgzip || $hasbrotli) && length($r->{resbody}) > 256
                && !defined $r->{reshdr}{'content-encoding'}
                && FU::compress_mimes->{$r->{reshdr}{'content-type'}}
        ) {
            push @vary, 'accept-encoding';
            if ($hasbrotli && ($r->{hdr}{'accept-encoding'}||'') =~ /\bbr\b/) {
                $r->{resbody_orig} = $r->{resbody};
                $r->{resbody} = FU::Util::brotli_compress(6, $r->{resbody});
                $r->{reshdr}{'content-encoding'} = 'br';

            } elsif ($hasgzip && ($r->{hdr}{'accept-encoding'}||'') =~ /\bgzip\b/) {
                $r->{resbody_orig} = $r->{resbody};
                $r->{resbody} = FU::Util::gzip_compress(6, $r->{resbody});
                $r->{reshdr}{'content-encoding'} = 'gzip';
            }
        }
        $r->{reshdr}{vary} = @vary ? join ', ', @vary : undef;
        $r->{reshdr}{'content-length'} = length $r->{resbody};
        $r->{resbody} = '' if (fu->method//'') eq 'HEAD';
    }

    $r->{reshdr}{'content-type'} .= '; charset=UTF-8' if FU::utf8_mimes->{ $r->{reshdr}{'content-type'}||'' };
}

sub _flush($, $sock) {
    _finalize;

    my $r = $FU::REQ;
    if ($sock isa 'FU::fcgi') {
        $sock->print('Status: ');
        $sock->print($r->{status});
        $sock->print("\r\n");
    } else {
        $sock->printf("HTTP/1.0 %d Hello\r\n", $r->{status});
        $sock->printf("date: %s\r\n", FU::Util::httpdate_format time);
        $sock->print("server: FU\r\n");
    }

    for my ($hdr, $val) ($r->{reshdr}->%*) {
        utf8::encode($hdr);
        for (!defined $val ? () : ref $val ? @$val : ($val)) {
            utf8::encode($_);
            $sock->print($hdr);
            $sock->print(': ');
            $sock->print($_);
            $sock->print("\r\n");
        }
    }
    $sock->print("\r\n");
    $sock->print($r->{resbody});
    $sock->flush;
}



package FU::err;

use overload '""' => sub { sprintf "FU exception code %d: %s", $_[0][0], $_[0][1] };


1;

__END__

=head1 NAME

FU - A Lean and Efficient Zero-Dependency Web Framework.

=head1 SYNOPSIS

  use v5.36;
  use FU -spawn;
  use FU::XMLWriter ':html5_';

  sub myhtml_($title, $body) {
      fu->set_body(html_ sub {
          head_ sub {
              title_ $title;
          };
          body_ $body;
      });
  }

  FU::get qr{/hello/(.+)}, sub($who) {
      myhtml_ "Website title", sub {
          h1_ "Hello, $who!";
      };
  };

  FU::run;

=head1 DESCRIPTION

FU is the backend web framework developed for L<VNDB.org|https://vndb.org/> and
L<Manned.org|https://manned.org/>, but is also perfectly suitable for other
projects. Besides a web framework, this distrubion also includes a bunch of
handy utility functions and modules.

=head2 Distribution Overview

This top-level C<FU> module is a web development framework. The C<FU>
distribution also includes a bunch of modules that the framework depends on or
which are otherwise useful when building web backends. These modules are
standalone and can be used independently of the framework:

=over

=item * L<FU::Util> - JSON parsing & formatting, URI encoding, etc.

=item * L<FU::Pg> - PostgreSQL client.

=item * L<FU::SQL> - Small and safe query builder.

=item * L<FU::Validate> - Input validation through a schema.

=item * L<FU::XMLWriter> - Dynamic XML generation, easy and fast.

=item * L<FU::Log> - Global logger.

=back

Note that everything in this distribution requires a moderately recent version
of Perl (5.36+), a C compiler and a 64-bit POSIXy system (not Windows, that
is). There are a few additional optional dependencies:

=over

=item * C<libpq.so> - required for L<FU::Pg>, dynamically loaded through
C<dlopen()>.

=item * C<libdeflate.so> or C<libz-ng.so> or C<libz.so> - required for
C<gzip_compress()> in L<FU::Util> and used for HTTP output compression.

=item * C<libbrotlienc.so> - required for C<brotli_compress()> in L<FU::Util>
and used for HTTP output compression.

=back


=head2 Framework Overview

C<FU> is a mostly straightforward and conventional backend web framework. It
doesn't try to be particularly innovative, but it does attempt to implement
existing ideas in a convenient, coherent and efficient way. There are a few
inherent properties of C<FU>'s design that you will want to be aware of before
digging further:

=over

=item FU is synchronous

C<FU> is an entirely synchronous framework, meaning that a single Perl process
can only handle a single request at a time. This is great in that it simplifies
the implementation, makes debugging easy and performance predictable.

The downside is that you will want to avoid long-running requests as much as
possible. Potentially slow network operations are best delegated to a
background queue. C<FU> intentionally does not support websockets, long-polling
might work but is a bad idea because you'll need to run as many processes as
there are concurrent clients, which gets wasteful very fast. If some UI latency
is acceptable, interval-based polling tends to be simpler to reason about and
more reliable. If such latency is not acceptable, you'll want to run a separate
daemon for asynchronous tasks.

=item FU is buffered

The entire request is read into memory before your code even runs, and the
generated response is buffered in full before a single byte is sent off to the
client.  This is, once again, great for simple and predictable code, but
certainly not great if you plan to transfer large files.

=back

The rest of this document is reference documentation; there's no easy
introductory cookbook-style docs yet, sorry about that.

Unless specifically mentioned otherwise, all methods and functions taking or
returning strings deal with perl Unicode strings, not raw bytes.


=head1 Framework Configuration

=over

=item use FU -procname => $name

When the C<-procname> import option is set, FU automatically updates the
process name (as displayed in L<top(1)> and L<ps(1)>, see C<$0>) with
information about the current process, prefixed with the given C<$name>.

=item FU::init_db($info)

Set database configuration. C<$info> can either be a connection string for C<<
FU::Pg->connect() >> or a subroutine that returns a L<FU::Pg> connection.  The
latter can be useful to set default parameters such as C<cache()>,
C<text_params()>, C<client_encoding>, etc.

A C<query_trace()> callback is registered after connection to collect
per-request performance metrics. If you want to register your own trace
callback, you'll want to have it call C<FU::query_trace($st)> to keep the
functionality.

The configured database is used for C<< fu->db >> and related methods; you can
of course still manage alternative database connections in your own code if you
need that, but then that won't benefit from FU's integrated transaction
handling and performance tracing.

=item FU::debug($enable)

Enable or disable debug mode. Returns the current mode when no argument is
given.

Debug mode currently enables more verbose logging and the C<debug_info>
interface below. It may influence other features in the future as well. You're
of course free to use the debug setting to enable or disable debugging features
in your own code.

=item FU::debug_info($path, $storage, $history)

Enable the built-in web interface for inspecting debug info. The interface is
accessible from your browser at the given C<$path>, which is matched against
C<< fu->path >>.

When the optional C<$storage> argument is given and set to an existing
directory, detailed request data is logged and stored in that directory, which
is then made available through the web interface. The C<$history> argument sets
the number of requests to keep, which defaults to 100.

Request logging and the web interface are only available when C<FU::debug> mode
is enabled.

B<WARNING:> This interface exposes internal and potentially sensitive
information. When this option is configured, make sure to B<ABSOLUTELY NEVER>
enable debug mode in production! Or at least set an absolutely impossible to
guess C<$path>.

=item FU::log_slow_reqs($ms)

Enable logging of requests that took longer than C<$ms> milliseconds to
process.  Can be set to 0 to disable such logging.

=item FU::mime_types

Returns a modifiable hashref that serves as a lookup table from file extension
to MIME type, used by C<< fu->send_file() >>.

=item FU::utf8_mimes

Returns a modifiable hashref listing which mime types should get a UTF-8
C<charset> parameter appended to them in the C<Content-Type> header.

=item FU::compress_mimes

Returns a modifiable hashref listing mime types for which compression makes
sense.

=item FU::monitor_path(@paths)

Add filesystem paths to be monitored for changes when running in monitor mode
(see C<--monitor> in L</"Running the Site">). When given a directory, all files
under the directory are recursively checked. The given paths do not actually
have to exist, errors are silently discarded. Relative paths are resolved to
the current working directory at the time that the paths are checked for
changes, so you may want to pass absolute paths if you ever call C<chdir()>.

You do not have to add the current script or files in C<%INC>, these are
monitored by default.

=item FU::monitor_check($sub)

Register a subroutine to be called in monitor mode. The subroutine should
return a true value to signal that something has changed and the process should
reload, false otherwise. The subroutine is called before any filesystem paths
are checked (as in C<FU::monitor_path>), so if you run any build system things
here, file modifications are properly detected and trigger a reload.

Only one subroutine can be registered at a time.  Be careful to ensure that the
subroutine returns a false value at some point, otherwise you may end up in a
restart loop.

=back


=head1 Handlers & Routing

=over

=item FU::get($path, $sub)

=item FU::post($path, $sub)

=item FU::delete($path, $sub)

=item FU::options($path, $sub)

=item FU::put($path, $sub)

=item FU::patch($path, $sub)

=item FU::query($path, $sub)

Register a route handler for the given HTTP method and C<$path>. C<$path> can
either be a string, which is matched for equality with C<< fu->path >>, or a
regex that must fully match the request path. If the regex contains capture
groups, its contents are passed to C<$sub> as arguments.

  FU::get '/', sub {
      # Here goes the code for the root path.
  };

  FU::post '/sub/path', sub {
      # POST requests to '/sub/path' go here.
  };

  FU::get qr{/hello/(.+)}, sub($name) {
      # "GET /hello/world" goes to this code, with $name='world'.
  };

It is an error to register multiple handlers for the same method and path. This
is verified for exact paths, but if you register handlers with overlapping
regexes, it's not defined which one is actually called.

=item FU::before_request($sub)

Register a callback to be run when a request has been received but before it's
being routed to the main handler function. Callbacks are run in the order that
they are registered. If C<$sub> throws an error or calls C<< fu->done >>, any
later C<before_request> callbacks are not run and no routing handler is called.

=item FU::after_request($sub)

Register a callback to be run after the routing handler has finished but before
the response is sent back to the client. Callbacks are run in reverse order
that they are registered. These callbacks are always run, even when a previous
C<before_request> or the routing handler threw an error.

=item FU::on_error($code, $sub)

Register a callback to be run when the given error code (HTTP status code) is
generated. C<$sub> is called with the error code as arguments and should
generate a suitable error page to send to the client. Only one callback can be
registered for each code, calling this function another time with the same
C<$code> overwrites a previous callback.

Internally, C<FU> can generate errors with code C<400>, C<404> and C<500>, but
C<< fu->error() >> can be used to generate other errors. If no callback exists
for a certain error code, C<500> is used as fallback.

=back

All of the above C<$sub> callbacks are allowed to throw an error. Special
handling is given to exceptions generated by C<< fu->error() >>, which are
relegated to the appropriate C<on_error> handler, and errors thrown by the
C<validate()> method of L<FU::Validate>, which result in the C<400> error
handler being run. Any other exception is passed to the C<500> error handler.


=head1 The 'fu' Object

While the C<FU::> namespace is used for global configuration and utility
functions, the C<fu> object is intended for methods that deal with request
processing (although some are useful used outside of request handlers as well).

The C<fu> object itself can be used to store request-local data. For example,
the following is a valid approach to handle user authentication:

  FU::before {
      fu->{user} = authenticate_user_from_cookie_or_something();
  };

  FU::get '/registered-users-only', sub {
      fu->denied if !fu->{user};
  };

In addition to the request information and response generation methods
described in the sections below, it has a few utility methods:

=over

=item fu->debug

Read-only alias of C<FU::debug>.

=item fu->db_conn

Returns the current database handle, as set with C<FU::init_db()>. This is
mainly useful for configuration, you generally shouldn't use this for running
queries inside a request handler, see C<< fu->db >> for that instead.

=item fu->db

Returns the database transaction for the current request. Starts a new
transaction if none is active.

Transactions initiated this way are automatically committed when the request
has successfully been processed, or rolled back if there was an error.

=item fu->sql($query, @params)

Convenient short-hand for C<< fu->db->q($query, @params) >>.

=item fu->SQL(@args)

Convenient short-hand for C<< fu->db->Q(@args) >>.

=item fu->log_verbose($message)

Write a verbose multi-line message to the log, including a full dump of
information about the request: IP, headers and (potentially reformatted and/or
truncated) body. This extra info is only written once per request, further
calls to C<log_verbose()> just go directly to L<FU::Log>'s C<log_write()>
instead.

=back

=head1 Request Information

=over

=item fu->path

The path component of the request. E.g. if the request is for
C<https://example.com/some/path?query>, this returns C</some/path>.

=item fu->method

Upper-case request method, e.g. 'POST' or 'GET'.

=item fu->header($name)

Return the request header by the given C<$name>, or undef if the requests did
not have that header. Header name matching is case-insensitive. If the request
includes multiple headers with the same name, these are merged into a single
comma-separated value.

=item fu->headers

Return a hashref with all request headers. Keys are lower-cased header names.

=item fu->ip

Return the client IP address.

=item fu->query()

Return the raw query part of the request URI, e.g.
C<https://example.com/some/path?query> this returns C<query>.

=item fu->query($name)

Parses the raw query string with C<query_decode> in L<FU::Util> and returns the
value with the given $name. Beware: an array is returned if the given key is
repeated in the query string.  Prefer to use the C<$schema>-based validation
methods below to reliably handle all sorts of query strings.

=item fu->query($name => $schema)

Parse, validate and return the query parameter identified by C<$name> with the
given L<FU::Validate> schema.

To fetch a query parameter that may have multiple values, use:

  my $arrayref = fu->query(q => {accept_scalar => 1});

  # OR:
  my $first_value = fu->query(q => {accept_array => 'first'});

  # OR:
  my $last_value = fu->query(q => {accept_array => 'last'});

=item fu->query($schema)

=item fu->query($name1 => $schema1, $name2 => $schema2, ..)

Parse, validate and return multiple query parameters.

  state $schema = FU::Validate->compile({
      keys => { a => {anybool => 1}, b => {} }
  });
  my $data = fu->query($schema);
  # $data = { a => .., b => .. }

  # Or, more concisely:
  my $data = fu->query(a => {anybool => 1}, b => {});

To fetch all query paramaters as decoded by C<query_decode()>, use:

  my $data = fu->query({type=>'any'});

=item fu->cookie(...)

Like C<< fu->query() >> but parses the C<Cookie> request header. Beware that,
exactly like with query parameters, it's possible for a cookie to have multiple
values and thus get represented as an array.

=item fu->json(...)

Like C<< fu->query() >> but parses the request body as JSON. Returns the raw
(unvalidated!) JSON Unicode string if no arguments are given. To retrieve the
decoded JSON data without performing further validation, use:

  my $data = fu->json({type=>'any'});

=item fu->formdata(...)

Like C<< fu->query() >> but returns data from the POST request body. This
method only supports form data encoded as C<application/x-www-form-urlencoded>,
which is the default for HTML C<< <form> >>s. To handle multipart form data,
use C<< fu->multipart >> instead.

=item fu->multipart

Parse the request body as C<multipart/form-data> and return an array of field
objects.  Refer to L<FU::MultipartFormData> for more information.

=back


=head1 Response Generation

=over

=item fu->done

Throw an exception to indicate that the response is "done", i.e. the current
function will return and no further handlers (if any) are run. Only works if
you're not catching the exception elsewhere, of course.

=item fu->error($code, $message)

Throw an exception with a status code. If the exception is not caught
elsewhere, this ends up in running the appropriate C<FU::on_error> handler.

C<$message> is optional and currently only used for logging.

=item fu->denied

Alias for C<< fu->error(403) >>.

=item fu->notfound

Alias for C<< fu->error(404) >>.

=item fu->reset

Reset the response to an empty state, basically undoing all effects of the
methods below.

=item fu->status($code)

Set the HTTP status code for the response. Defaults to C<200> if not set and no
error is thrown.

=item fu->add_header($name, $value)

Add a response header, can be used to add multiple headers with the same name.

=item fu->set_header($name, $value)

Add a response header or overwrite the header with a new value if it already
exists. Set C<$value> to undef to remove a previously set header.

=item fu->set_cookie($name, $value, %attributes)

Set or overwrite a cookie. Set C<$value> to undef to remove a previously set
cookie. To fully remove a cookie from the user's browser, set the cookie with
an empty value and zero C<Max-Age>:

  fu->set_cookie(my_cookie => '', 'Max-Age' => 0);

C<%attributes> can be any of the supported L<cookie
attributes|https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie>.
The C<Expires> attribute, when given, must be a UNIX timestamp. Boolean
attributes are interpreted according to Perl's idea of truthiness. For example:

  fu->set_cookie(auth => $auth_token,
      Expires => time()+30*24*3600,
      Domain => 'example.com',
      Secure => 1,
      SameSite => 'Lax'
  );

This method does not encode or escape the cookie value in any way. If you want
to set a non-ASCII value or a value containing characters that are not
permitted in the C<Set-Cookie> header, use C<uri_escape()> in L<FU::Util> or
your favorite alternative cookie-safe encoding.

=item fu->set_body($data)

Set the (raw, binary) body of the response to C<$data>. This method is not very
convenient for writing dynamic responses, so usually you'll want to use a
templating system or L<FU::XMLWriter>:

  use FU::XMLWriter ':html5_';

  fu->set_body(html_ sub {
      body_ sub {
          h1_ "Hello, world!";
      };
  });

=item fu->send_json($data)

Encode C<$data> as JSON (using C<json_format> in L<FU::Util>), set an
appropriate C<Content-Type> header and send it to the client. Calls C<<
fu->done >>.

=item fu->send_file($root, $path)

If a file identified by C<"$root/$path"> exists, set that as response and call
C<< fu->done >>. Returns normally if the file does not exist. This method is
mainly intended to serve small static files from a directory:

  FU::before_request {
      # We can set custom headers before send_file()
      fu->set_header('cache-control', 'max-age=31536000');

      # Attempt to serve files from '/static/files'
      fu->send_file('/static/files', fu->path);

      # If that fails, fall back to another directory
      fu->send_file('/more/static/files', fu->path);

      # Otherwise, continue processing the request as normal
      fu->reset;
  };

C<$path> may be an untrusted string from the client, this method prevents path
traversal attacks that go below the given C<$root>. It does follow symlinks,
though.

This method loads the entire file contents in memory and does not support range
requests, so DO NOT use it to send large files. Actual web servers are much
more efficient at serving static files.

The content-type header is determined from the file extension in C<$path>,
using the configured C<FU::mime_types>. As fallback, files that look like they
might be text get C<text/plain> and binary files are served with
C<application/octet-stream>.

This method sets an appropriate C<last-modified> header and supports
conditional requests with C<if-modified-since>.

=item fu->redirect($code, $location)

Generates a HTTP redirect response and calls C<< fu->done >>. C<$code> can be
one of the following status codes or an alias:

  Status  Alias      Semantics
  ----------------------------------------
  301     perm       Permanent, method may or may not change to GET
  302     temp       Temporary, method may or may not change to GET
  303     tempget    Temporary to GET
  307     tempsame   Temporary without changing method
  308     permsame   Permanent without changing method

=back



=head1 Running the Site

When your script is done setting L</"Framework Configuration"> and registering
L</"Handlers & Routing">, it should call C<FU::run> to actually start serving
the website:

=over

=item FU::run(%options)

In normal circumstances, this function does not return.

When FU has been loaded with the C<-spawn> flag, C<%options> are read from the
environment variables or command line arguments documented below. Otherwise,
the following corresponding options can be passed instead: I<http>, I<fcgi>,
I<proc>, I<monitor>, I<max_reqs>, I<listen_sock>.

=back

Command-line options are read only when FU has been loaded with C<-spawn>, the
environment variables are always read.

=over

=item FU_HTTP=addr

=item --http=addr

Start a local web server on the given address. I<addr> can be an C<ip:port>
combination to listen on TCP, or a path (optionally prefixed with C<unix:>) to
listen on a UNIX socket. E.g.

  ./your-script.pl --http=127.0.0.1:8000
  ./your-script.pl --http=unix:/path/to/socket

B<WARNING:> The built-in HTTP server is only intended for local development
setups, it is NOT suitable for production deployments. It has no timeouts, does
not enforce limits on request size, does not support HTTPS and will never
adequately support keep-alive. You could put it behind a reverse proxy, but it
currently also lacks provisions for extracting the client IP address from the
request headers, so that's not ideal either. Much better to use FastCGI in
combination with a proper web server for internet-facing deployments.

=item FU_FCGI=addr

=item --fcgi=addr

Like the HTTP counterpart above, but listen on a FastCGI socket instead. If
this option is set, it takes precedence over the HTTP option.

Nginx and Apache will, in their default configuration, use a separate
connection per request. If you have a more esoteric setup, you should probably
be aware of the following: this implementation does not support multiplexing or
pipelining.  It does support keepalive, but this comes with a few caveats:

=over

=item * You should not attempt to keep more connections alive than the
configured number of worker processes, otherwise new connection attempts will
stall indefinitely.

=item * When using C<--monitor> mode, the file modification check is performed
I<after> each request rather than before, so clients may get a response from
stale code.

=item * When worker processes shut down, either through C<--max-reqs> or in
response to a signal, there is a possibility that an incoming request on an
existing connection gets interrupted.

=back

=item FU_PROC=n

=item --proc=n

How many worker processes to spawn, defaults to 1.

=item FU_MONITOR=0/1

=item --monitor or --no-monitor

When enabled, worker processes will monitor for file changes and automatically
restart on changes. This is immensely useful during development, but comes at a
significant cost in performance - better not enable this in production.

=item FU_MAX_REQS=n

=item FU_MAX_REQS=min:max

=item --max-reqs=n

=item --max-reqs=min:max

Worker processes can automatically restart after handling a number of requests.
Set to 0 (the default) to disable this feature. When set as C<min:max>, the
number of requests is randomized in the given range, which is useful to avoid
restarting all worker processes around the same time.

This option can be useful when your worker processes keep accumulating memory
over time. A little pruning now and then can never hurt.

=item FU_DEBUG=0/1

=item --debug or --no-debug

Set the initial value for C<FU::debug>.

=item FU_LOG_FILE=path

=item --log-file=path

Set the initial value for C<FU::Log::set_file()>.

=item LISTEN_FD=num

=item LISTEN_PROTO=http/fcgi

Listen for incoming connections on the given file descriptor instead of
creating a new listen socket. This is mainly useful if you are using an
external process manager.

=back

When C<--monitor> or C<--max-reqs> are set or C<--proc> is larger than 1, FU
starts a supervisor process to ensure the requested number of worker processes
are running and that they are restarted when necessary. When FU has been loaded
with the C<-spawn> flag, this supervisor process runs directly from the context
of the C<use FU> statement - that is, before the rest of your script has even
loaded. This saves valuable resources: the supervisor has no need of your
website code nor does it need an active connection to your database to do its
job. Without the C<-spawn> flag, the supervisor has to run from C<FU::run>,
which is less efficient but does allow for more flexible configuration from
within your script.

When not running in supervisor mode, no separate worker processes are started
and requests are instead handled directly in the starting process.

In supervisor mode, sending C<SIGHUP> causes all worker processes to reload
their code. In both modes, C<SIGTERM> or C<SIGINT> can be used to trigger a
clean shutdown.

I<TODO:> Alternate FastCGI spawning options & server config examples.

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
