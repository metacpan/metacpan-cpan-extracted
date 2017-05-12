package LWPx::ParanoidAgent;
require LWP::UserAgent;

use vars qw(@ISA $VERSION);
@ISA = qw(LWP::UserAgent);
$VERSION = '1.12';

require HTTP::Request;
require HTTP::Response;

use HTTP::Status ();
use strict;
use Net::DNS;
use LWP::Debug ();

sub new {
    my $class = shift;
    my %opts = @_;

    my $blocked_hosts     = delete $opts{blocked_hosts}     || [];
    my $whitelisted_hosts = delete $opts{whitelisted_hosts} || [];
    my $resolver          = delete $opts{resolver};
    my $paranoid_proxy    = delete $opts{paranoid_proxy};
    $opts{timeout}      ||= 15;
 
    my $self = LWP::UserAgent->new( %opts );

    $self->{'blocked_hosts'}     = $blocked_hosts;
    $self->{'whitelisted_hosts'} = $whitelisted_hosts;
    $self->{'resolver'}          = $resolver;
    $self->{'paranoid_proxy'}    = $paranoid_proxy;

    $self = bless $self, $class;
    return $self;
}

# returns seconds remaining given a request
sub _time_remain {
    my $self = shift;
    my $req = shift;

    my $now = time();
    my $start_time = $req->{_time_begin} || $now;
    return $start_time + $self->{timeout} - $now;
}

sub _resolve {
    my ($self, $host, $request, $timeout, $depth) = @_;
    my $res = $self->resolver;
    $depth ||= 0;

    die "CNAME recursion depth limit exceeded.\n" if $depth > 10;
    die "DNS lookup resulted in bad host." if $self->_bad_host($host);

    # return the IP address if it looks like one and wasn't marked bad
    return ($host) if $host =~ /^\d+\.\d+\.\d+\.\d+$/;

    my $dns_ref = $res->bgsend($host)
        or die "No sock from bgsend";
    my $sock;

    # Net::DNS 1.03 started returning IO::Select objects instead of sockets
    if (UNIVERSAL::isa($dns_ref, "IO::Select")) {
        my $handles = [ $dns_ref->handles ];
        $sock = $handles->[0]->[0];
    }
    else {
        $sock = $dns_ref;
    }

    # wait for the socket to become readable, unless this is from our test
    # mock resolver.
    unless ($dns_ref && $dns_ref eq "MOCK") {
        my $rin = '';
        vec($rin, fileno($sock), 1) = 1;
        my $nf = select($rin, undef, undef, $self->_time_remain($request));
        die "DNS lookup timeout" unless $nf;
    }

    my $packet = $res->bgread($dns_ref)
        or die "DNS bgread failure";
    $dns_ref = $sock = undef;

    my @addr;
    my $cname;
    foreach my $rr ($packet->answer) {
        if ($rr->type eq "A") {
            die "Suspicious DNS results from A record\n" if $self->_bad_host($rr->address);
            # untaints the address:
            push @addr, join(".", ($rr->address =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/));
        } elsif ($rr->type eq "CNAME") {
            # will be checked for validity in the recursion path
            $cname = $rr->cname;
        }
    }

    return @addr if @addr;
    return () unless $cname;
    return $self->_resolve($cname, $request, $timeout, $depth + 1);
}

sub _host_list_match {
    my $self = shift;
    my $list_name = shift;
    my $host = shift;

    foreach my $rule (@{ $self->{$list_name} || [] }) {
        if (ref $rule eq "CODE") {
            return 1 if $rule->($host);
        } elsif (ref $rule) {
            # assume regexp
            return 1 if $host =~ /$rule/;
        } else {
            return 1 if $host eq $rule;
        }
    }
}

sub _bad_host {
    my $self = shift;
    my $host = lc(shift);

    return 0 if $self->_host_list_match("whitelisted_hosts", $host);
    return 1 if $self->_host_list_match("blocked_hosts", $host);
    return 1 if
        $host =~ /^localhost$/i ||    # localhost is bad.  even though it'd be stopped in
                                      #    a later call to _bad_host with the IP address
        $host =~ /\s/i;               # any whitespace is questionable

    # Let's assume it's an IP address now, and get it into 32 bits.
    # Uf at any time something doesn't look like a number, then it's
    # probably a hostname and we've already either whitelisted or
    # blacklisted those, so we'll just say it's okay and it'll come
    # back here later when the resolver finds an IP address.
    my @parts = split(/\./, $host);
    return 0 if @parts > 4;

    # un-octal/un-hex the parts, or return if there's a non-numeric part
    my $overflow_flag = 0;
    foreach (@parts) {
        return 0 unless /^\d+$/ || /^0x[a-f\d]+$/;
        local $SIG{__WARN__} = sub { $overflow_flag = 1; };
        $_ = oct($_) if /^0/;
    }

    # a purely numeric address shouldn't overflow.
    return 1 if $overflow_flag;

    my $addr;  # network order packed IP address

    if (@parts == 1) {
        # a - 32 bits
        return 1 if
            $parts[0] > 0xffffffff;
        $addr = pack("N", $parts[0]);
    } elsif (@parts == 2) {
        # a.b - 8.24 bits
        return 1 if
            $parts[0] > 0xff ||
            $parts[1] > 0xffffff;
        $addr = pack("N", $parts[0] << 24 | $parts[1]);
    } elsif (@parts == 3) {
        # a.b.c - 8.8.16 bits
        return 1 if
            $parts[0] > 0xff ||
            $parts[1] > 0xff ||
            $parts[2] > 0xffff;
        $addr = pack("N", $parts[0] << 24 | $parts[1] << 16 | $parts[2]);
    } elsif (@parts == 4) {
        # a.b.c.d - 8.8.8.8 bits
        return 1 if
            $parts[0] > 0xff ||
            $parts[1] > 0xff ||
            $parts[2] > 0xff ||
            $parts[3] > 0xff;
        $addr = pack("N", $parts[0] << 24 | $parts[1] << 16 | $parts[2] << 8 | $parts[3]);
    } else {
        return 1;
    }

    my $haddr = unpack("N", $addr); # host order IP address
    return 1 if
        ($haddr & 0xFF000000) == 0x00000000 || # 0.0.0.0/8
        ($haddr & 0xFF000000) == 0x0A000000 || # 10.0.0.0/8
        ($haddr & 0xFF000000) == 0x7F000000 || # 127.0.0.0/8
        ($haddr & 0xFFF00000) == 0xAC100000 || # 172.16.0.0/12
        ($haddr & 0xFFFF0000) == 0xA9FE0000 || # 169.254.0.0/16
        ($haddr & 0xFFFF0000) == 0xC0A80000 || # 192.168.0.0/16
        ($haddr & 0xFFFFFF00) == 0xC0000200 || # 192.0.2.0/24  "TEST-NET" docs/example code
        ($haddr & 0xFFFFFF00) == 0xC0586300 || # 192.88.99.0/24 6to4 relay anycast addresses
         $haddr               == 0xFFFFFFFF || # 255.255.255.255
        ($haddr & 0xF0000000) == 0xE0000000;  # multicast addresses

    # as final IP address check, pass in the canonical a.b.c.d decimal form
    # to the blacklisted host check to see if matches as bad there.
    my $can_ip = join(".", map { ord } split //, $addr);
    return 1 if $self->_host_list_match("blocked_hosts", $can_ip);

    # looks like an okay IP address
    return 0;
}

sub request {
    my ($self, $req, $arg, $size, $previous) = @_;

    # walk back to the first request, and set our _time_begin to its _time_begin, or if
    # we're the first, then use current time.  used by LWPx::Protocol::http_paranoid
    my $first_res = $previous;  # previous is the previous response that invoked this request
    $first_res = $first_res->previous while $first_res && $first_res->previous;
    $req->{_time_begin} = $first_res ? $first_res->request->{_time_begin} : time();

    my $host = $req->uri->host;
    if ($self->_bad_host($host)) {
        my $err_res = HTTP::Response->new(403, "Unauthorized access to blocked host");
        $err_res->request($req);
        $err_res->header("Client-Date" => HTTP::Date::time2str(time));
        $err_res->header("Client-Warning" => "Internal response");
        $err_res->header("Content-Type" => "text/plain");
        $err_res->content("403 Unauthorized access to blocked host\n");
        return $err_res;
    }

    if (my $pp = $self->{paranoid_proxy}) {
        $req->uri("$pp?url="   . eurl($req->uri) .
                  "&timeout="  . ($self->{timeout}  + 0) .
                  "&max_size=" . ($self->{max_size} + 0));
    }

    return $self->SUPER::request($req, $arg, $size, $previous);
}

# taken from LWP::UserAgent and modified slightly.  (proxy support removed,
# and map http and https schemes to separate protocol handlers)
sub send_request
{
    my ($self, $request, $arg, $size) = @_;
    $self->_request_sanity_check($request);

    my ($method, $url) = ($request->method, $request->uri);

    local($SIG{__DIE__});  # protect against user defined die handlers

    # Check that we have a METHOD and a URL first
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "Method missing")
        unless $method;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL missing")
        unless $url;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "URL must be absolute")
        unless $url->scheme;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST,
                         "ParanoidAgent doesn't support going through proxies.  ".
                         "In that case, do your paranoia at your proxy instead.")
        if $self->_need_proxy($url);

    my $scheme = $url->scheme;
    return _new_response($request, &HTTP::Status::RC_BAD_REQUEST, "Only http and https are supported by ParanoidAgent")
        unless $scheme eq "http" || $scheme eq "https";

    LWP::Debug::trace("$method $url");

    my $protocol;

    {
      # Honor object-specific restrictions by forcing protocol objects
      #  into class LWP::Protocol::nogo.
        my $x;
        if($x       = $self->protocols_allowed) {
            if(grep lc($_) eq $scheme, @$x) {
                LWP::Debug::trace("$scheme URLs are among $self\'s allowed protocols (@$x)");
              }
            else {
                LWP::Debug::trace("$scheme URLs aren't among $self\'s allowed protocols (@$x)");
                  require LWP::Protocol::nogo;
                  $protocol = LWP::Protocol::nogo->new;
              }
        }
        elsif ($x = $self->protocols_forbidden) {
            if(grep lc($_) eq $scheme, @$x) {
                LWP::Debug::trace("$scheme URLs are among $self\'s forbidden protocols (@$x)");
                  require LWP::Protocol::nogo;
                  $protocol = LWP::Protocol::nogo->new;
              }
            else {
                LWP::Debug::trace("$scheme URLs aren't among $self\'s forbidden protocols (@$x)");
              }
        }
      # else fall thru and create the protocol object normally
    }

    unless ($protocol) {
        LWP::Protocol::implementor("${scheme}_paranoid",  "LWPx::Protocol::${scheme}_paranoid");
        eval "require LWPx::Protocol::${scheme}_paranoid;";
        if ($@) {
            $@ =~ s/ at .* line \d+.*//s;  # remove file/line number
            my $response =  _new_response($request, &HTTP::Status::RC_NOT_IMPLEMENTED, $@);
            return $response;
        }

        $protocol = eval { LWP::Protocol::create($scheme eq "http" ? "http_paranoid" : "https_paranoid", $self) };
        if ($@) {
            $@ =~ s/ at .* line \d+.*//s;  # remove file/line number
            my $response =  _new_response($request, &HTTP::Status::RC_NOT_IMPLEMENTED, $@);
            if ($scheme eq "https") {
                $response->message($response->message . " (Crypt::SSLeay not installed)");
                $response->content_type("text/plain");
                $response->content(<<EOT);
LWP will support https URLs if the Crypt::SSLeay module is installed.
More information at <http://www.linpro.no/lwp/libwww-perl/README.SSL>.
EOT
}
            return $response;
        }
    }

    # Extract fields that will be used below
    my ($timeout, $cookie_jar, $use_eval, $parse_head, $max_size) =
        @{$self}{qw(timeout cookie_jar use_eval parse_head max_size)};

    my $response;
    my $proxy = undef;
    if ($use_eval) {
        # we eval, and turn dies into responses below
        eval {
            $response = $protocol->request($request, $proxy,
                                           $arg, $size, $timeout);
        };
        my $error = $@ || $response->header( 'x-died' );
        if ($error) {
            $error =~ s/ at .* line \d+.*//s; # remove file/line number
            $response = _new_response($request,
                                      &HTTP::Status::RC_INTERNAL_SERVER_ERROR,
                                      $error);
        }
    }
    else {
        $response = $protocol->request($request, $proxy,
                                       $arg, $size, $timeout);
        # XXX: Should we die unless $response->is_success ???
    }

    $response->request($request);  # record request for reference
    $cookie_jar->extract_cookies($response) if $cookie_jar;
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    $self->run_handlers("response_done", $response) if $self->can('run_handlers');
    return $response;
}

# blocked hostnames, compiled patterns, or subrefs
sub blocked_hosts
{
    my $self = shift;
    if (@_) {
        my @hosts = @_;
        $self->{'blocked_hosts'} = \@hosts;
        return;
    }
    return @{ $self->{'blocked_hosts'} || [] };
}

# whitelisted hostnames, compiled patterns, or subrefs
sub whitelisted_hosts
{
    my $self = shift;
    if (@_) {
        my @hosts = @_;
        $self->{'whitelisted_hosts'} = \@hosts;
        return;
    }
    return @{ $self->{'whitelisted_hosts'} || [] };
}

# get/set Net::DNS resolver object
sub resolver
{
    my $self = shift;
    if (@_) {
        $self->{'resolver'} = shift;
        require UNIVERSAL ;
        die "Not a Net::DNS::Resolver object" unless
            UNIVERSAL::isa($self->{'resolver'}, "Net::DNS::Resolver");
    }
    return $self->{'resolver'} ||= Net::DNS::Resolver->new;
}

# Taken directly from LWP::UserAgent because it was private there, and we can't depend on it
# staying there in future versions:  needed by our modified version of send_request
sub _need_proxy
{
    my($self, $url) = @_;
    $url = $HTTP::URI_CLASS->new($url) unless ref $url;

    my $scheme = $url->scheme || return;
    if (my $proxy = $self->{'proxy'}{$scheme}) {
        if ($self->{'no_proxy'} && @{ $self->{'no_proxy'} }) {
            if (my $host = eval { $url->host }) {
                for my $domain (@{ $self->{'no_proxy'} }) {
                    if ($host =~ /\Q$domain\E$/) {
                        LWP::Debug::trace("no_proxy configured");
                          return;
                      }
                }
            }
        }
        LWP::Debug::debug("Proxied to $proxy");
        return $HTTP::URI_CLASS->new($proxy);
    }
    LWP::Debug::debug('Not proxied');
    undef;
}

# Taken directly from LWP::UserAgent because it was private there, and we can't depend on it
# staying there in future versions:  needed by our modified version of send_request
sub _request_sanity_check {
    my($self, $request) = @_;
    # some sanity checking
    if (defined $request) {
        if (ref $request) {
            Carp::croak("You need a request object, not a " . ref($request) . " object")
              if ref($request) eq 'ARRAY' or ref($request) eq 'HASH' or
              !$request->can('method') or !$request->can('uri');
          }
        else {
            Carp::croak("You need a request object, not '$request'");
          }
    }
    else {
        Carp::croak("No request object passed in");
      }
}

# Taken directly from LWP::UserAgent because it was private there, and we can't depend on it
# staying there in future versions:  needed by our modified version of send_request
sub _new_response {
    my($request, $code, $message) = @_;
    my $response = HTTP::Response->new($code, $message);
    $response->request($request);
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    $response->header("Client-Warning" => "Internal response");
    $response->header("Content-Type" => "text/plain");
    $response->content("$code $message\n");
    return $response;
}

sub eurl {
    my $a = $_[0];
    $a =~ s/([^a-zA-Z0-9_\,\-.\/\\\: ])/uc sprintf("%%%02x",ord($1))/eg;
    $a =~ tr/ /+/;
    return $a;
}

1;

__END__

=head1 NAME

LWPx::ParanoidAgent - subclass of LWP::UserAgent that protects you from harm

=head1 SYNOPSIS

 require LWPx::ParanoidAgent;

 my $ua = LWPx::ParanoidAgent->new;

 # this is 10 seconds overall, from start to finish.  not just between
 # socket reads.  and it includes all redirects.  so attackers telling
 # you to download from a malicious tarpit webserver can only stall
 # you for $n seconds

 $ua->timeout(10);

 # setup extra block lists, in addition to the always-enforced blocking
 # of private IP addresses, loopbacks, and multicast addresses

 $ua->blocked_hosts(
    "foo.com",
    qr/\.internal\.company\.com$/i,
    sub { my $host = shift;  return 1 if is_bad($host); },
 );

 $ua->whitelisted_hosts(
    "brad.lj",
    qr/^192\.168\.64\.3?/,
    sub { ... },
 );

 # get/set the DNS resolver object that's used
 my $resolver = $ua->resolver;
 $ua->resolver(Net::DNS::Resolver->new(...));

 # and then just like a normal LWP::UserAgent, because it is one.
 my $response = $ua->get('http://search.cpan.org/');
 ...
 if ($response->is_success) {
     print $response->content;  # or whatever
 }
 else {
     die $response->status_line;
 }

=head1 DESCRIPTION

The C<LWPx::ParanoidAgent> is a class subclassing C<LWP::UserAgent>,
but paranoid against attackers.  It's to be used when you're fetching
a remote resource on behalf of a possibly malicious user.

This class can do whatever C<LWP::UserAgent> can (callbacks, uploads from
files, etc), except proxy support is explicitly removed, because in
that case you should do your paranoia at your proxy.

Also, the schemes are limited to http and https, which are mapped to
C<LWPx::Protocol::http_paranoid> and
C<LWPx::Protocol::https_paranoid>, respectively, which are forked
versions of the same ones without the "_paranoid".  Subclassing them
didn't look possible, as they were essentially just one huge function.

This class protects you from connecting to internal IP ranges (unless you
whitelist them), hostnames/IPs that you blacklist, remote webserver
tarpitting your process (the timeout parameter is changed to be a global
timeout over the entire process), and all combinations of redirects and
DNS tricks to otherwise tarpit and/or connect to internal resources.

=head1 CONSTRUCTOR

=over 4

=item C<new>

my $ua = LWPx::ParanoidAgent->new([ %opts ]);

In addition to any constructor options from L<LWP::UserAgent>, you may
also set C<blocked_hosts> (to an arrayref), C<whitelisted_hosts> (also
an arrayref), and C<resolver>, a Net::DNS::Resolver object.

=back

=head1 METHODS

=over 4

=item $csr->B<resolver>($net_dns_resolver)

=item $csr->B<resolver>

Get/set the L<Net::DNS::Resolver> object used to lookup hostnames.

=item $csr->B<blocked_hosts>(@host_list)

=item $csr->B<blocked_hosts>

Get/set the list of blocked hosts.  The items in @host_list may be
compiled regular expressions (with qr//), code blocks, or scalar
literals.  In any case, the thing that is match, passed in, or
compared (respectively), is all of the given hostname, given IP
address, and IP address in canonical a.b.c.d decimal notation.  So if
you want to block "1.2.3.4" and the user entered it in a mix of
network/host form in a mix of decimal/octal/hex, you need only block
"1.2.3.4" and not worry about the details.

=item $csr->B<whitelisted_hosts>(@host_list)

=item $csr->B<whitelisted_hosts>

Like blocked hosts, but matching the hosts/IPs that bypass blocking
checks.  The only difference is the IP address isn't canonicalized
before being whitelisted-matched, mostly because it doesn't make sense
for somebody to enter in a good address in a subversive way.

=back

=head1 SEE ALSO

See L<LWP::UserAgent> to see how to use this class.

http://contributing.appspot.com/lwpx-paranoidagent
http://brad.livejournal.com/2409049.html
https://github.com/collectiveintel/LWPx-ParanoidAgent
http://search.cpan.org/dist/LWPx-ParanoidAgent

=head1 ISSUES

Report issues: https://github.com/collectiveintel/LWPx-ParanoidAgent/issues

=head1 WARRANTY

This module is supplied "as-is" and comes with no warranty, expressed
or implied.  It tries to protect you from harm, but maybe it will.
Maybe it will destroy your data and your servers.  You'd better audit
it and send me bug reports.

=head1 BUGS

Maybe.  See the warranty above.

=head1 COPYRIGHT

 Copyright 2005 Brad Fitzpatrick
 Copyright 2013 Wes Young (wesyoung.me)

Lot of code from the base class, copyright 1995-2004 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
