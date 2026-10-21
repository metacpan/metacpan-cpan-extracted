use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib'; use TWK; TWK::skip_unless_available();
use EV; use EV::WebKit;
use IO::Socket::INET;

# $b->status -- the HTTP status of the current document.
#
# This exists because a navigation's own (ok, err) cannot tell you: WebKit
# reports a 404 or a 500 as a perfectly successful load, since they have bodies
# and it displays them. Both come back ok=1, err=undef, which is why the first
# assertions below check exactly that -- if WebKit ever starts failing them,
# this method's reason for existing has changed and someone should notice.

my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                Listen => 5, ReuseAddr => 1)
    or plan skip_all => "cannot bind a test server socket: $!";
my $port = $srv->sockport;
my %conns;
my $accept_io = EV::io($srv, EV::READ, sub {
    my $c = $srv->accept or return;
    $c->blocking(0);
    my $buf = '';
    my $rw; $rw = EV::io($c, EV::READ, sub {
        my $n = sysread($c, my $chunk, 4096);
        if (!defined $n) { return if $!{EAGAIN} || $!{EWOULDBLOCK}; delete $conns{$c}; return }
        return delete $conns{$c} unless $n;
        $buf .= $chunk;
        return unless $buf =~ /\r?\n\r?\n/;
        delete $conns{$c};
        my ($path) = $buf =~ m{^\S+\s+(\S+)};
        $path //= '/';
        my ($code, $extra) = (200, '');
        if    ($path =~ m{/404})   { $code = 404 }
        elsif ($path =~ m{/500})   { $code = 500 }
        elsif ($path =~ m{/301})   { $code = 301; $extra = "Location: /final\r\n" }
        # /final gets a title of its own so the redirect case can prove WHERE it
        # landed, not just that the status came from the end of the chain
        my $title = $path =~ m{/final} ? 'FinalPage' : 't';
        my $body = "<html><head><title>$title</title></head><body>b</body></html>";
        print $c "HTTP/1.1 $code X\r\nContent-Type: text/html\r\n$extra"
               . "Content-Length: " . length($body) . "\r\nConnection: close\r\n\r\n$body";
        close $c;
    });
    $conns{$c} = $rw;
});

my $b = EV::WebKit->new(window => [300, 200], timeout => 15);
my %g;

# One instance, one EV::run: a queued chain, as t/42 records is necessary.
my @steps;
my $run; $run = sub { my $s = shift @steps or return EV::break; $s->() };

for my $case ([ok => 200], [404 => 404], [500 => 500], [301 => 200]) {
    my ($path, $want) = @$case;
    push @steps, sub {
        $b->go("http://127.0.0.1:$port/$path", sub {
            my ($ok, $err) = @_;
            $g{"$path.ok"}     = $ok;
            $g{"$path.err"}    = $err;
            $g{"$path.status"} = $b->status;
            $g{"$path.uri"}    = $b->uri;
            $g{"$path.title"}  = $b->title;
            $run->();
        });
    };
}
push @steps, sub {
    $b->load_html('<html><head><title>h</title></head><body>x</body></html>', sub {
        $g{'html.status'} = $b->status;
        $run->();
    });
};
push @steps, sub {
    # WebKit versions differ on whether a blocked port fails or loads an error
    # page. Neither produces an HTTP response.
    $b->go('http://127.0.0.1:1/blocked', sub {
        $g{'blocked.status'} = $b->status;
        $g{'blocked.ok'}     = $_[0];
        $g{'blocked.err'}    = $_[1];
        $run->();
    });
};

push @steps, sub {
    # A port nothing is listening on, taken and released so it is genuinely free
    # and therefore genuinely refused.
    my $s = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1);
    my $free = $s ? $s->sockport : 0;
    undef $s;
    $g{'refused.port'} = $free;
    return $run->() unless $free;
    $b->go("http://127.0.0.1:$free/refused", sub {
        $g{'refused.ok'}     = $_[0];
        $g{'refused.err'}    = $_[1];
        $g{'refused.status'} = $b->status;
        $run->();
    });
};

$run->();
TWK::run_with_timeout(60);

is($g{'ok.status'},  200, 'a 200 reports 200');
is($g{'404.status'}, 404, 'a 404 reports 404');
is($g{'500.status'}, 500, 'a 500 reports 500');

# The reason this method exists: ok/err cannot distinguish these.
is($g{'404.ok'},  1,     'a 404 still resolves as a SUCCESSFUL navigation (ok=1)');
is($g{'404.err'}, undef, '...with no error -- which is why status is needed');
is($g{'500.ok'},  1,     'a 500 likewise resolves ok=1');

# A redirect chain reports the FINAL response, not the 301.
is($g{'301.status'}, 200, 'a redirect chain reports the final status, not the 301');
# ...and uri/title follow the chain to its end too. Nothing else in t/ asserts
# where a redirect actually landed -- only that its status came from the end.
like($g{'301.uri'} // '', qr{/final$}, 'a redirect leaves uri at the final location');
is($g{'301.title'}, 'FinalPage', '...and title from the final document');

# Loads with no HTTP transaction report undef rather than 0: 0 is not a status,
# and a caller comparing numerically would read it as falsy-but-defined.
is($g{'html.status'}, undef, 'load_html has no HTTP status (undef, not 0)');
is($g{'blocked.status'}, undef, 'a blocked port has no HTTP status');
ok($g{'blocked.ok'} || ($g{'blocked.err'} // '') =~ /^load failed:/,
   'a blocked port completes with an error page or a load failure');

SKIP: {
    skip 'could not obtain a free port to be refused on', 3 unless $g{'refused.port'};
    # The distinction the POD used to get wrong: this is NOT the blocked case.
    is($g{'refused.ok'}, undef, 'a REFUSED connection resolves with ok undef');
    like($g{'refused.err'} // '', qr/load failed/,
         '...and an error, so $err is what a caller must check first');
    is($g{'refused.status'}, undef, '...with no HTTP status either');
}

# After quit the accessor must degrade, not die.
$b->quit;
is($b->status, undef, 'status is undef after quit');

done_testing;
