use v5.10; use strict; use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use lib 't/lib'; use TWK; TWK::skip_unless_available();
use EV; use EV::WebKit;

my $dir = tempdir(CLEANUP => 1);
my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                Listen => 5, ReuseAddr => 1) or die $!;
my $base = 'http://127.0.0.1:' . $srv->sockport;
my %connections;
my $accept = EV::io($srv, EV::READ, sub {
    my $c = $srv->accept or return;
    $c->blocking(0);
    my $fd = fileno $c;
    my $buf = '';
    $connections{$fd} = EV::io($c, EV::READ, sub {
        my $n = sysread($c, my $chunk, 4096);
        return if !defined $n && ($!{EAGAIN} || $!{EINTR});
        if (!$n) { delete $connections{$fd}; close $c; return }
        $buf .= $chunk;
        return unless $buf =~ /\r\n\r\n/;
        my ($path) = $buf =~ m{^\S+\s+(\S+)};
        my ($code, $headers) = $path eq '/entry'
            ? ('302 Found', "Location: /app/index\r\n")
            : ('200 OK', "Set-Cookie: sid=redirected; Path=/app; HttpOnly\r\n");
        my $body = $path eq '/route'
            ? q{<script>history.replaceState(null, '', '/app/route')</script>}
            : '<p>session</p>';
        print $c "HTTP/1.1 $code\r\n${headers}Content-Type: text/html\r\n"
               . 'Content-Length: ' . length($body) . "\r\nConnection: close\r\n\r\n$body";
        delete $connections{$fd};
        close $c;
    });
});

my $b = EV::WebKit->new(window => [300,200], timeout => 5);
my ($count, $err, $restore_count, $cookies);
$b->go("$base/entry", sub {
    is($_[1], undef, 'redirect completed');
    $b->save_cookies("$dir/redirect.json", sub {
        ($count, $err) = @_;
        EV::break;
    });
});
TWK::run_with_timeout(15);
is($err, undef, 'snapshot after redirect succeeded');
is($count, 1, 'default snapshot includes cookies scoped to the redirect destination');

$b->clear_cookies(sub {
    $b->load_cookies("$dir/redirect.json", sub {
        $restore_count = $_[0];
        $b->cookies("$base/app/index", sub { $cookies = $_[0]; EV::break });
    });
});
TWK::run_with_timeout(15);
is($restore_count, 1, 'redirect session restored');
is(($cookies || [])->[0]{value}, 'redirected', 'restored the saved cookie value');
$b->quit;

my $spa = EV::WebKit->new(window => [300,200], timeout => 5);
my ($spa_count, $spa_err);
$spa->go("$base/route", sub {
    is($_[1], undef, 'SPA route loaded');
    $spa->save_cookies("$dir/spa.json", sub {
        ($spa_count, $spa_err) = @_;
        EV::break;
    });
});
TWK::run_with_timeout(15);
is($spa_err, undef, 'snapshot after a same-document route change succeeded');
is($spa_count, 1, 'default snapshot includes cookies scoped to the SPA route');
$spa->quit;

my $page = EV::WebKit->new(window => [300,200], timeout => 5);
my ($page_count, $page_err);
$page->load_html('<a id=go href="' . "$base/app/page" . '">open</a>', sub {
    $page->wait_for_navigation(sub {
        is($_[1], undef, 'link navigation completed');
        $page->save_cookies("$dir/page.json", sub {
            ($page_count, $page_err) = @_;
            EV::break;
        });
    });
    $page->find('#go', sub { $_[0]->click });
});
TWK::run_with_timeout(15);
is($page_err, undef, 'default snapshot works after page-driven navigation');
is($page_count, 1, 'page-driven navigation contributes its cookies');
$page->quit;
done_testing;
