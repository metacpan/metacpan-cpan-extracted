use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib'; use TWK; TWK::skip_unless_available();
use EV; use EV::WebKit;
use File::Temp qw(tempdir);
use File::Spec;
use IO::Socket::INET;
use Scalar::Util ();   # weaken, for the collectability check below

# download() / on_download / on_file_chooser.
#
# Downloads are driven through download(), not by hoping a server sends
# something WebKit refuses to render: download_uri always produces a download,
# so the real signal path (download-started -> decide-destination -> finished)
# is exercised deterministically.
#
# The body is served over a real (in-process, non-blocking) HTTP socket rather
# than mock_scheme, because a download does NOT go through the custom-scheme
# handler: mock_scheme is registered on the WebContext, while downloads run on
# the NetworkSession, which has never heard of the scheme and answers "The URL
# can't be shown". (file:// URIs, unlike mock_scheme, DO download -- see 4h.)
# Same in-process EV::io server shape as t/63-proxy.t and xt/66.

my $dir = tempdir(CLEANUP => 1);

my $srv = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                Listen => 5, ReuseAddr => 1)
    or plan skip_all => "cannot bind a test server socket: $!";
my $port = $srv->sockport;
my %conns;
my @stalled;   # sockets deliberately left unanswered -- see /slow below
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
        # /slow sends HEADERS and then stops. The headers are what make WebKit
        # raise decide-destination (so the download is a real, started one that
        # on_download sees), and the missing body is what keeps it in flight
        # afterwards -- announce a megabyte, send a handful of bytes, never
        # close. @stalled holds the socket: dropping it here would close the
        # connection and turn the stall into an immediate failure.
        # The 64 KiB matters: WebKit buffers the start of a response and does not
        # raise decide-destination until it has enough, so a token handful of
        # bytes leaves the download started but never destined, and on_download
        # is never called. Blocking for this one write (the read watcher is gone
        # by now) because a short write would strand it the same way; 64 KiB
        # fits a socket buffer and WebKit is reading the other end.
        if ($buf =~ m{^\S+\s+/slow\b}) {
            $c->blocking(1);
            print $c "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\n"
                   . "Content-Disposition: attachment; filename=\"slow.bin\"\r\n"
                   . "Content-Length: 1000000\r\n\r\n" . ('S' x 65536);
            $c->flush;
            push @stalled, $c;
            return;
        }
        my $body = 'HELLO-DOWNLOAD';
        print $c "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\n"
               . "Content-Disposition: attachment; filename=\"served.bin\"\r\n"
               . "Content-Length: " . length($body) . "\r\nConnection: close\r\n\r\n$body";
        close $c;
    });
    $conns{$c} = $rw;
});
my $URL = "http://127.0.0.1:$port/served.bin";

# --- 1) download() writes the body to the path we asked for ---
{
    my $b = EV::WebKit->new(window => [200, 150]);
    my $dest = File::Spec->catfile($dir, 'one.bin');
    my ($got_path, $got_err);
    $b->download($URL, $dest, sub { ($got_path, $got_err) = @_; EV::break });
    TWK::run_with_timeout(20);
    $b->quit;

    is($got_err, undef, 'download: no error') or diag('err=' . ($got_err // 'undef'));
    is($got_path, $dest, 'download: callback reports the destination path');
    ok(-e $dest, 'download: the file exists');
    my $body = -e $dest ? do { open my $fh, '<', $dest or die $!; local $/; <$fh> } : '';
    is($body, 'HELLO-DOWNLOAD', 'download: the body landed on disk intact');
}

# --- 2) a page-initiated download whose handler names NO destination is
# cancelled, not written somewhere unasked. WebKit's own default would drop it
# in the user's Downloads directory behind the caller's back. ---
{
    my $b = EV::WebKit->new(window => [200, 150]);
    my ($seen_uri, $err, $calls);
    $calls = 0;
    $b->on_download(sub { $seen_uri = $_[0]->uri;
                          $_[0]->on_finish(sub { $err = $_[1]; $calls++; EV::break }) });
    $b->{view}->download_uri($URL);
    TWK::run_with_timeout(20);
    # a moment more, so a second delivery would have somewhere to land
    my $t = EV::timer(0.5, 0, sub { EV::break }); EV::run; undef $t;
    $b->quit;

    like($seen_uri // '', qr{^http://127\.0\.0\.1:}, 'on_download sees a page-initiated download');
    like($err // '', qr/no destination/, 'a download with no destination is cancelled, not written');
    # WebKit emits 'finished' as the terminal event of EVERY download, including
    # one it just cancelled -- so _finish runs twice here. Without its once-only
    # guard the caller is called twice, and the second call's (dest, undef) would
    # overwrite the cancel's reason with a phantom success.
    is($calls, 1, '...exactly once, though WebKit also emits finished after the cancel');
}

# --- 2b) ...and the verdict recorded on the wrapper is the CANCEL's, not the
# 'finished' that follows it.
#
# WebKit emits 'finished' as the terminal event of every download including one
# it just cancelled, so _finish runs a second time. Its once-only guard is what
# keeps that second run from overwriting {path}/{err} -- and a caller that
# registers on_finish LATE reads exactly those, so without the guard it is told
# the download succeeded to a destination that was never set. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    my ($kept, $native_finished);
    $b->on_download(sub { $kept = $_[0] });          # deliberately name no destination
    my $native = $b->{view}->download_uri($URL);
    # The premise this block and 2a both rest on: WebKit emits 'finished' as the
    # terminal event of every download INCLUDING one it just cancelled, so
    # _finish runs a second time and the once-only guard is what is under test.
    # Asserted rather than assumed -- if WebKit stopped emitting it, both blocks
    # would keep passing with the guard never exercised at all.
    $native->signal_connect(finished => sub { $native_finished++ }) if $native;
    # let BOTH the cancel and the trailing 'finished' land before asking
    my $t = EV::timer(3, 0, sub { EV::break }); EV::run; undef $t;

    my @got = ('never called');
    $kept->on_finish(sub { @got = @_ }) if $kept;
    my $t2 = EV::timer(1, 0, sub { EV::break }); EV::run; undef $t2;
    $b->quit;

    ok($native_finished, 'precondition: WebKit emitted finished after cancelling the download')
        or diag 'the once-only guard under test here was never exercised';
    ok($kept, 'the destination-less download reached on_download');
    like($got[1] // '', qr/no destination/,
         'a late on_finish still reports the cancel, not the finished that followed it');
    is($got[0], undef, '...and reports no path');
}

# --- 3) on_download can choose the destination from the SUGGESTED name ---
{
    my $b = EV::WebKit->new(window => [200, 150]);
    my ($suggested, $path, $err);
    $b->on_download(sub {
        my ($d) = @_;
        $suggested = $d->suggested;
        $d->save_to(File::Spec->catfile($dir, 'from-suggestion.bin'));
        $d->on_finish(sub { ($path, $err) = @_; EV::break });
    });
    $b->{view}->download_uri($URL);
    TWK::run_with_timeout(20);
    $b->quit;

    is($suggested, 'served.bin', 'on_download is told the server-suggested filename');
    is($err, undef, 'suggestion-driven download completes');
    ok($path && -e $path, 'the chosen destination exists');
}

# --- 4) quit() with a download still in flight must resolve its callback,
# not leave the caller waiting forever ---
{
    my $b = EV::WebKit->new(window => [200, 150]);
    my $err = 'never called';
    $b->download($URL, File::Spec->catfile($dir, 'x.bin'), sub { $err = $_[1] });
    $b->quit;      # immediately, before the download can finish
    is($err, 'browser closed', 'quit() resolves an in-flight download callback');
}

# --- 4b) a uri WebKit canonicalises must still reach its own callback.
#
# download() parks the destination and callback for download-started to claim.
# Keying that by the uri STRING looks obvious and is wrong: WebKit rewrites the
# uri before reporting it, so a caller's spelling and WebKit's differ for
# anything not already canonical. Every form below missed its parked entry, so
# the destination was never applied, WebKit cancelled the download as
# destination-less, and the callback was never called at all -- the download
# just silently never happened. Keyed by the WebKitDownload's identity there is
# no string to disagree about. ---
{
    my @forms = (
        ["http://127.0.0.1:$port",               'no path (WebKit appends "/")'],
        ["HTTP://127.0.0.1:$port/served.bin",    'uppercase scheme (lowercased)'],
        ["http://127.0.0.1:$port/./served.bin",  'a dot segment (collapsed)'],
        ["http://127.0.0.1:$port/served.bin?a=b c", 'a space in the query (percent-encoded)'],
    );
    my $n = 0;
    for my $f (@forms) {
        my ($uri, $why) = @$f;
        my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
        my $dest = File::Spec->catfile($dir, 'canon-' . $n++ . '.bin');
        my ($path, $err, $fired) = (undef, undef, 0);
        $b->download($uri, $dest, sub { ($path, $err) = @_; $fired = 1; EV::break });
        TWK::run_with_timeout(20);
        $b->quit;
        ok($fired, "download() calls back for a uri with $why")
            or diag("uri=$uri -- never called back at all");
        is($err, undef, "...with no error ($why)");
        is($path, $dest, "...and the destination we asked for ($why)");
    }
}

# --- 4bb) concurrent downloads stay distinct, including several of the SAME
# uri. Identity keying gives each its own entry by construction; a uri-keyed
# queue had to get the ordering right instead, and there is no ordering
# guarantee between download_uri calls and the download-started signals. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 15);
    my @want = (['/same', 'a.bin'], ['/same', 'b.bin'], ['/same', 'c.bin'],
                ['/other', 'd.bin']);
    my (%got, $left);
    $left = @want;
    for my $w (@want) {
        my ($path, $name) = @$w;
        my $dest = File::Spec->catfile($dir, "conc-$name");
        $b->download("http://127.0.0.1:$port$path", $dest, sub {
            $got{$name} = { path => $_[0], err => $_[1] };
            EV::break unless --$left;
        });
    }
    TWK::run_with_timeout(30);
    $b->quit;

    for my $w (@want) {
        my ($path, $name) = @$w;
        my $dest = File::Spec->catfile($dir, "conc-$name");
        is(($got{$name} || {})->{err}, undef, "concurrent download $name: no error");
        is(($got{$name} || {})->{path}, $dest, "...lands at its OWN destination");
    }
    # ...and each really is a separate file on disk, not one written four times
    is(scalar(grep { -e File::Spec->catfile($dir, "conc-$_->[1]") } @want), 4,
       'all four concurrent downloads produced their own file');
}

# --- 4c) a download still running when the browser closes reports 'browser
# closed' to an on_finish registered AFTERWARDS, too. Teardown flushes the
# callbacks it can see; one registered later used to route through the
# dead-gated deferral and vanish without a trace -- and had it been delivered it
# would have read (undef, undef), i.e. a successful download to nowhere. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    my $kept;
    $b->on_download(sub { $kept = $_[0]; $_[0]->save_to(File::Spec->catfile($dir, 'slow.bin')) });
    $b->{view}->download_uri("http://127.0.0.1:$port/slow");
    my $t = EV::timer(5, 0, sub { EV::break });   # let the headers land and decide-destination fire
    EV::run; undef $t;
    ok($kept, 'the stalled download reached on_download') or diag('no download object');
    $b->quit;                                     # close with it still in flight

    my @got = ('never called');
    $kept->on_finish(sub { @got = @_ }) if $kept;
    my $t2 = EV::timer(1, 0, sub { EV::break }); EV::run; undef $t2;
    is($got[1], 'browser closed', 'on_finish registered after quit() still reports browser closed');
    is($got[0], undef,            '...and reports no path, rather than a phantom success');
}

# --- 4d) a COMPLETED download must be collectable.
#
# The three signal closures connected on the WebKitDownload each capture the
# wrapper, and the wrapper holds the native as {dl}: a cycle refcounting cannot
# break, so every finished download kept both alive for the life of the process
# -- invisible in a short script and a steady leak in a long automation run.
# _finish now disconnects them. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    my (@weak, $done);
    $b->on_download(sub {
        my ($d) = @_;
        $d->save_to(File::Spec->catfile($dir, 'collect-' . scalar(@weak) . '.bin'));
        my $w = $d; Scalar::Util::weaken($w); push @weak, \$w;
        $d->on_finish(sub { EV::break if ++$done >= 3 });
    });
    $b->{view}->download_uri($URL) for 1 .. 3;
    TWK::run_with_timeout(25);
    # a couple of clean ticks, so any deferred release has run
    for (1 .. 3) { my $t = EV::timer(0.05, 0, sub { EV::break }); EV::run }
    # ANCHOR FIRST. @weak is filled only inside on_download, so without this the
    # grep below runs over an empty list, returns 0, and passes -- meaning the
    # test could not fail if the hook never fired at all. The leak direction is
    # self-detecting (a live wrapper is defined); the hook-dead direction is not.
    is(scalar @weak, 3, 'precondition: all three downloads reached on_download')
        or diag('only ' . scalar(@weak) . ' wrapper(s) were ever observed');
    is(scalar(grep { defined ${$_} } @weak), 0,
       'a finished download wrapper is collectable (no signal-closure cycle)')
        or diag('the wrapper and its WebKitDownload leak for the life of the process');
    $b->quit;
}

# --- 4e) quit() landing between a download finishing and its deferred delivery.
#
# _finish drops the wrapper from {_downloads} immediately, and quit() cancels
# every pending _defer timer -- so a quit() in that window found nothing owed in
# either place and the callback simply vanished. The delivery is now tracked as
# an op, like every other async call here, so teardown can still flush it. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    my @got = ('NEVER CALLED');
    $b->on_download(sub {
        my ($d) = @_;
        $d->save_to(File::Spec->catfile($dir, 'race.bin'));
        $d->on_finish(sub { @got = @_ });
    });
    # quit from a handler connected AFTER the module's own, so it runs in the
    # same loop iteration as the finish that schedules the delivery
    my $quit_done = 0;
    $b->{session}->signal_connect('download-started' => sub {
        $_[1]->signal_connect(finished => sub { $b->quit; $quit_done = 1 });
    });
    $b->{view}->download_uri($URL);
    # break from a POLL timer, not from the signal handler: EV::break inside a
    # GLib dispatch frame is the documented wedge, and this test must not be the
    # thing that trips it
    my $poll = EV::timer(0.05, 0.05, sub { EV::break if $quit_done });
    my $wd   = EV::timer(15, 0, sub { EV::break });
    EV::run; undef $poll; undef $wd;
    is($got[1], 'browser closed', 'quit() racing a finished download still answers its callback')
        or diag('got: ' . join(', ', map { $_ // 'undef' } @got));
}

# --- 4f) quit() from INSIDE on_download.
#
# decide-destination calls user code synchronously (WebKit needs the answer
# before it writes anything), so it must carry the same in-dispatch guard as
# every sibling handler: without it quit() tears the native window and view down
# from inside the GLib dispatch frame -- the crash _release_natives_later exists
# to avoid -- and an EV::break there wedges the next EV::run. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    my $entered = 0;
    $b->on_download(sub {
        my ($d) = @_;
        $entered = 1;
        $d->save_to(File::Spec->catfile($dir, 'quit-inside.bin'));
        $b->quit;                       # the hazardous thing, from inside the frame
        $entered = 2;                   # ...and we survived it
    });
    $b->{view}->download_uri($URL);
    my $poll = EV::timer(0.05, 0.05, sub { EV::break if $entered == 2 });
    my $wd   = EV::timer(15, 0, sub { EV::break });
    EV::run; undef $poll; undef $wd;
    # and the loop must still be usable afterwards -- a wedge shows up here
    my $ticked = 0;
    my $t = EV::timer(0.1, 0, sub { $ticked = 1; EV::break }); EV::run; undef $t;
    # 2, not merely true: $entered is 1 before quit() and 2 after, and a Perl
    # exception from quit() inside decide-destination is caught and warned, so
    # ok($entered) passed with the second half never reached.
    is($entered, 2, 'on_download ran, and again after quit()');
    ok($ticked,  'quit() from inside on_download leaves the loop usable (no wedge, no crash)');
}

# --- 4g) save_to accepts a file:// URI, and decodes it properly.
#
# WebKitGTK 6.0 wants a plain path and stalls forever on a URI, so save_to
# strips the prefix rather than passing that trap on. Stripping and stopping
# there left the rest still URI-encoded: 'file:///tmp/a%20b' wrote a file
# literally named 'a%20b', and 'file://localhost/x' became the RELATIVE path
# 'localhost/x'. ---
{
    my $d = bless {}, 'EV::WebKit::Download';
    my @ok = (
        ['/tmp/plain',              '/tmp/plain',  'a plain path is untouched'],
        ['file:///tmp/a%20b',       '/tmp/a b',    'percent escapes are decoded'],
        ['file://localhost/tmp/x',  '/tmp/x',      'the localhost authority means this machine'],
        # hostnames are case-insensitive, and the scheme is already stripped /i
        ['file://LOCALHOST/tmp/x',  '/tmp/x',      'the localhost authority is case-insensitive'],
        ['FILE://localhost/tmp/x',  '/tmp/x',      '...as is the scheme'],
        ['file:///tmp/x',           '/tmp/x',      'an empty authority likewise'],
    );
    for my $c (@ok) {
        $d->save_to($c->[0]);
        is($d->{dest}, $c->[1], "save_to: $c->[2]");
    }
    eval { $d->save_to('file://otherhost/tmp/x') };
    like($@, qr/not a local file/, 'save_to: a file:// URI naming another host croaks');
    # %00 decodes to a NUL, which C reads as end-of-string on the other side of
    # the GI call -- so this would have written /tmp/a and reported success for
    # a path the caller never asked for
    eval { $d->save_to('file:///tmp/a%00b') };
    like($@, qr/NUL byte/, 'save_to: a percent-encoded NUL croaks rather than truncating the path');
}

# --- 4h) a destination save_to would reject must be rejected by download()
# ITSELF, at the call site.
#
# Leaving it to the save_to call inside the download-started handler meant the
# croak escaped into GLib's dispatch, which only warns. The rest of that handler
# never ran: the callback -- already taken out of the parked registry and not yet
# attached to the wrapper -- was reachable from nowhere, including quit; and
# decide-destination was never connected, so WebKit chose the destination
# itself, writing behind the caller's back. It also segfaulted. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    for my $bad ('file://somehost/tmp/f', 'file://localhost', 'file://', 'file:/tmp/x') {
        eval { $b->download($URL, $bad, sub { }) };
        like($@, qr/download: not a local file/,
             "download() rejects '$bad' at the call site");
    }
    $b->quit;
}

# ...and the handler itself still answers the caller if a destination somehow
# reaches it unapplied. Parked directly, since download() now refuses to create
# this state -- the guard exists so that a throw there can never again strand a
# callback or leave WebKit to pick the destination.
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    my ($fired, $err) = (0, undef);
    my $dl = $b->{view}->download_uri($URL);
    $b->{_dl_want}{ Scalar::Util::refaddr($dl) } = {
        dest => 'file://somehost/tmp/f', dl => $dl,
        cb   => sub { $fired = 1; $err = $_[1]; EV::break },
    };
    my $wd = EV::timer(15, 0, sub { EV::break });
    EV::run; undef $wd;
    $b->quit;
    ok($fired, 'an unapplicable parked destination still answers the caller')
        or diag('the callback was stranded');
    like($err // '', qr/not a local file/, '...with the reason it failed');
}

# --- 5) validation ---
{
    my $b = EV::WebKit->new(window => [200, 150]);
    eval { $b->download($URL, undef, sub {}) };
    like($@, qr/destination path is required/, 'download: missing destination croaks');
    eval { $b->download($URL, '/tmp/z', 'not-a-code-ref') };
    like($@, qr/code reference/, 'download: non-coderef callback croaks');
    my $e;
    $b->download('', '/tmp/z', sub { $e = $_[1]; EV::break });
    TWK::run_with_timeout(5);
    is($e, 'download: uri required', 'download: empty uri resolves with an error');
    $b->quit;
}

# --- 6) file upload: on_file_chooser drives <input type=file>, which cannot be
# populated from JavaScript at all ---
{
    my $upload = File::Spec->catfile($dir, 'upload.txt');
    open my $fh, '>', $upload or die $!; print {$fh} 'PAYLOAD'; close $fh;

    my $b = EV::WebKit->new(window => [300, 200]);
    my ($mimes, $multi, $chose);
    $b->on_file_chooser(sub {
        my ($fc) = @_;
        $mimes = join ',', $fc->mime_types;
        $multi = $fc->multiple;
        $fc->select($upload);
        $chose = 1;
    });
    my %g;
    # WebKit applies the selection ASYNCHRONOUSLY: reading files.length in the
    # click callback still shows 0, and it becomes 1 a tick later. So poll to a
    # deadline rather than reading once (which would be a guaranteed-flaky
    # assertion) or sleeping a magic interval (which would be slow AND flaky).
    my $poll; my $deadline = time + 10;
    $poll = sub {
        $b->script('const f = document.getElementById("f");'
                 . 'return JSON.stringify({ n: f.files.length,'
                 . ' name: f.files[0] ? f.files[0].name : null,'
                 . ' size: f.files[0] ? f.files[0].size : null })',
            sub {
                my ($json) = @_;
                $g{r} = $json;
                return EV::break if ($json // '') =~ /"n":[1-9]/ || time > $deadline;
                my $t; $t = EV::timer(0.05, 0, sub { undef $t; $poll->() });
            });
    };
    $b->load_html('<input type=file id=f accept="text/plain">', sub {
        $b->find('#f', sub { $_[0]->click(sub { $poll->() }) });
    });
    TWK::run_with_timeout(20);
    $b->quit;

    ok($chose, 'on_file_chooser was invoked by a real <input type=file> click');
    like($mimes // '', qr{text/plain}, 'the chooser reports the accept= mime types');
    is($multi, 0, 'a single-file input reports multiple=0');
    require Cpanel::JSON::XS;
    my $r = eval { Cpanel::JSON::XS::decode_json($g{r} // '{}') } || {};
    is($r->{n}, 1, 'the input received exactly one file');
    is($r->{name}, 'upload.txt', 'the page sees the file name we selected');
    # a real size proves the page can actually READ it, not just see a name
    is($r->{size}, 7, 'and its real size -- the file is genuinely readable by the page');
}

# --- 6a) FileChooser::selected reports what is already on the input.
# Documented and never called, so a `sub selected { () }` passed the suite. Two
# clicks: the first selects, the second sees the selection. ---
{
    my $upload = File::Spec->catfile($dir, 'again.txt');
    open my $fh, '>', $upload or die $!; print {$fh} 'X'; close $fh;

    my $b = EV::WebKit->new(window => [300, 200], timeout => 15);
    my ($round, @first, @second) = (0);
    $b->on_file_chooser(sub {
        my ($fc) = @_;
        $round++;
        if ($round == 1) { @first = $fc->selected; $fc->select($upload); return }
        @second = $fc->selected;
        $fc->cancel;
    });
    my $el;
    $b->load_html('<input type=file id=f>', sub {
        $b->find('#f', sub {
            $el = $_[0];
            $el->click(sub {
                # the selection is applied a tick later -- poll for it, then
                # click again so the second chooser can report it
                my $poll; my $deadline = time + 10;
                $poll = sub {
                    $b->script('return String(document.getElementById("f").files.length)', sub {
                        my ($n) = @_;
                        if (($n // '0') ne '0' || time > $deadline) {
                            return $el->click(sub { my $t; $t = EV::timer(0.5, 0, sub { undef $t; EV::break }) });
                        }
                        my $t; $t = EV::timer(0.05, 0, sub { undef $t; $poll->() });
                    });
                };
                $poll->();
            });
        });
    });
    TWK::run_with_timeout(25);
    $b->quit;

    is($round, 2, 'precondition: the chooser opened twice') or diag "opened $round time(s)";
    is(scalar @first, 0, 'selected is empty before anything was chosen');
    is(scalar @second, 1, 'selected reports the file chosen on the first round')
        or diag explain \@second;
    like($second[0] // '', qr/again\.txt$/, '...by its path');
}

# --- 6b) an on_file_chooser that decides NOTHING leaves the page usable.
#
# The handler cancels an undecided request rather than leaving it outstanding.
# Note honestly what this does NOT cover: whether the cancel happens is not
# observable from the page on this engine -- measured, an unanswered request and
# a cancelled one behave identically, including a second click still reaching the
# handler. So the cancel stays as a defensive release of the native request, and
# what is pinned here is the part that IS observable: the click completes and no
# file is selected. ---
{
    my $b = EV::WebKit->new(window => [300, 200], timeout => 10);
    my ($entered, $clicked) = (0, 0);
    $b->on_file_chooser(sub { $entered = 1; return });    # neither select nor cancel
    my $files = 'never-read';
    $b->load_html('<input type=file id=f>', sub {
        $b->find('#f', sub {
            $_[0]->click(sub {
                $clicked = 1;
                $b->script('return String(document.getElementById("f").files.length)',
                           sub { $files = $_[0]; EV::break });
            });
        });
    });
    TWK::run_with_timeout(20);
    $b->quit;
    ok($entered, 'on_file_chooser ran');
    ok($clicked, '...the click completed rather than hanging on an unanswered chooser');
    is($files, '0', '...and no file was selected');
}

# --- 6c) download() on an already-closed browser still answers its caller.
# That path is only ever reached when the browser IS dead, so a dead-gated
# deferral there would drop the callback every single time. ---
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 10);
    $b->quit;
    my @got = ('never called');
    $b->download($URL, File::Spec->catfile($dir, 'after-quit.bin'), sub { @got = @_; EV::break });
    my $t = EV::timer(3, 0, sub { EV::break }); EV::run; undef $t;
    is($got[1], 'browser closed', 'download() after quit reports browser closed')
        or diag('got: ' . join(', ', map { $_ // 'undef' } @got));
}

# --- 7) file-chooser validation ---
{
    my $b = EV::WebKit->new(window => [300, 200]);
    my $upload = File::Spec->catfile($dir, 'upload.txt');
    my ($e_missing, $e_multi);
    $b->on_file_chooser(sub {
        my ($fc) = @_;
        eval { $fc->select(File::Spec->catfile($dir, 'no-such-file')) };
        $e_missing = $@;
        eval { $fc->select($upload, $upload) };
        $e_multi = $@;
        $fc->cancel;
    });
    $b->load_html('<input type=file id=f>', sub {
        $b->find('#f', sub { $_[0]->click(sub { EV::break }) });
    });
    TWK::run_with_timeout(20);
    $b->quit;
    like($e_missing // '', qr/no such file/,     'select() rejects a path that does not exist');
    like($e_multi   // '', qr/single file only/, 'select() rejects several files on a single-file input');
}

# --- 6) the Download accessors: destination/received/progress, and cancel ---
# All four are documented and none was ever called, so a Download that returned
# constants for them passed the whole suite. cancel is the one with a real
# silent path: its contract is that on_finish then reports the cancellation.
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 15);
    my $dest = File::Spec->catfile($dir, 'six.bin');
    my ($dl, $path, $err);
    $b->on_download(sub {
        $dl = $_[0];
        $dl->save_to($dest);
        $dl->on_finish(sub { ($path, $err) = @_; EV::break });
    });
    $b->{view}->download_uri($URL);
    TWK::run_with_timeout(20);

    is($err, undef, 'the download completed') or diag $err;
    is($path, $dest, 'on_finish reports the path');
    is($dl && $dl->destination, $dest, 'destination is what save_to chose');
    is($dl && $dl->received, length('HELLO-DOWNLOAD'), 'received counts the bytes that arrived');
    cmp_ok($dl->progress, '>', 0, 'progress advanced past zero') if $dl;
    $b->quit;
}

# cancel: a download stalled mid-body, aborted by hand
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 15);
    my $dest = File::Spec->catfile($dir, 'seven.bin');
    my ($dl, $path, $err, $before);
    $b->on_download(sub {
        $dl = $_[0];
        $dl->save_to($dest);
        $dl->on_finish(sub { ($path, $err) = @_; EV::break });
        # cancel once some of the body has actually arrived, so this is a real
        # abort of a live transfer rather than a race with the start
        my $t; $t = EV::timer(1.5, 0, sub { undef $t; $before = $dl->received; $dl->cancel });
        $b->{_test_cancel_timer} = $t;
    });
    $b->{view}->download_uri("http://127.0.0.1:$port/slow");
    TWK::run_with_timeout(25);

    cmp_ok($before // 0, '>', 0, 'precondition: bytes had arrived before the cancel');
    ok(defined $err, 'cancel: on_finish reports the cancellation') or diag 'no error was reported';
    is($path, undef, 'cancel: and reports no path');
    $b->quit;
}

# --- 4h) file:// DOES download.
#
# The POD used to say it produced no download at all. It does: the file is
# copied and a missing one comes back as an ordinary error. Pinned because the
# claim is load-bearing for anyone deciding what a control-socket client is
# allowed to ask for -- download('file:///etc/passwd', $out) reads any file the
# process can, which page JavaScript cannot.
{
    my $b = EV::WebKit->new(window => [200, 150], timeout => 15);
    my $srcf = File::Spec->catfile($dir, 'local-src.txt');
    my $dest = File::Spec->catfile($dir, 'local-out.txt');
    open my $w, '>', $srcf or die $!; print $w "hello-from-file\n"; close $w;

    my ($path, $err, $done) = (undef, undef, 0);
    $b->download("file://$srcf", $dest, sub { ($path, $err) = @_; $done = 1; EV::break });
    TWK::run_with_timeout(25);
    ok($done, 'file:// download completes') or diag 'no callback at all';
    is($err, undef, '...without an error') or diag $err;
    is($path, $dest, '...reporting the destination path');
    ok(-e $dest && -s $dest == 16, '...and the bytes really landed')
        or diag('exists=' . (-e $dest ? 1 : 0) . ' size=' . (-e $dest ? -s $dest : 'n/a'));

    my ($mpath, $merr, $mdone) = (undef, undef, 0);
    $b->download("file://$dir/no-such-file-here", File::Spec->catfile($dir, 'nope.txt'),
                 sub { ($mpath, $merr) = @_; $mdone = 1; EV::break });
    TWK::run_with_timeout(25);
    ok($mdone, 'a missing file:// source still answers') or diag 'no callback at all';
    ok(defined $merr, '...with an error rather than success') or diag 'no error reported';
    is($mpath, undef, '...and no path');
    $b->quit;
}

# save_to had neither an unknown-key sweep nor a pairs-up check: `overwrit => 1` silently left
# overwrite OFF, and an odd list warned "Odd number of elements in hash
# assignment" from inside WebKit.pm.
{
    my $b = EV::WebKit->new(window => [200, 150], ephemeral => 1, timeout => 10);
    my $dl;
    $b->on_download(sub { $dl = $_[0] });
    $b->{view}->download_uri("http://127.0.0.1:$port/one");
    my $wd = EV::timer(6, 0, sub { EV::break });
    EV::run; undef $wd;
    # Anchored: without this the whole save_to sweep vanishes silently if the
    # download never arrives, and the file still passes green.
    ok($dl, 'premise: a download object to test save_to on')
        or diag('download-started never fired -- the sweep below measures nothing');
  SKIP: {
        skip 'no download object to test save_to on', 5 unless $dl;
        my @w; local $SIG{__WARN__} = sub { push @w, $_[0] };
        ok(!eval { $dl->save_to(File::Spec->catfile($dir, 's.bin'), overwrit => 1); 1 },
           'save_to croaks on a typo\'d option rather than silently leaving it off');
        like($@, qr/unknown option\(s\): overwrit/, '...naming it');
        ok(!eval { $dl->save_to(File::Spec->catfile($dir, 's.bin'), 'overwrite'); 1 },
           'save_to croaks on an odd option list');
        like($@, qr/name => value pairs/, '...saying what is wrong');
        is(scalar(@w), 0, '...without warning from inside the module first');
    }
    $b->quit;
}

# A RELATIVE destination used to wedge the download outright.
# webkit_download_set_destination has a g_path_is_absolute precondition: handed
# a relative path it emits only a C-level CRITICAL, sets nothing, and -- since
# decide-destination has already answered "handled" -- WebKit waits forever for
# a destination that never arrives. download() is deliberately exempt from the
# per-op timeout, so nothing bounded it: the callback never fired at all, until
# quit() flushed it as 'browser closed'. `save_to('out.bin')` in on_download,
# or a plain download($uri, 'out.bin'), is an entirely ordinary thing to write.
{
    require Cwd;
    my $rd  = tempdir(CLEANUP => 1);
    my $srcf = File::Spec->catfile($rd, 'src.txt');
    open my $w, '>', $srcf or die $!; print $w "hello-relative\n"; close $w;

    my $back = Cwd::getcwd();
    chdir $rd or die "chdir $rd: $!";
    my $rb = EV::WebKit->new(window => [200,150], ephemeral => 1, timeout => 10);
    my ($p, $e, $done) = (undef, undef, 0);
    $rb->download("file://$srcf", 'rel-out.bin', sub { ($p, $e) = @_; $done = 1; EV::break });
    my $wd = EV::timer(20, 0, sub { EV::break });
    EV::run; undef $wd;
    my $landed = -s File::Spec->catfile($rd, 'rel-out.bin');
    $rb->quit;
    chdir $back or die "chdir back: $!";

    ok($done, 'a relative download destination answers at all')
        or diag('no callback -- the download wedged waiting for a destination');
    is($e, undef, '...without an error') or diag $e;
    ok($landed, '...and the bytes landed, resolved against the cwd');
    like($p // '', qr{^/}, '...with the callback reporting the absolute path');
}

{
    my ($download, $ready, $err);
    my $b = EV::WebKit->new(window => [200,150], timeout => 5);
    $b->on_download(sub {
        $download = $_[0];
        $download->save_to("$dir/dropped.bin");
        $download->on_finish(sub { $err = $_[1] });
        $ready = EV::timer(0, 0, sub { undef $ready; EV::break });
    });
    $b->{view}->download_uri("http://127.0.0.1:$port/slow");
    TWK::run_with_timeout(15);
    ok($download, 'a download is still in flight before dropping the browser');
    Scalar::Util::weaken(my $weak = $b);
    undef $b;
    ok(!defined $weak, 'holding an in-flight download does not keep its browser alive');
    is($err, 'browser closed', 'dropping the browser resolves the active download');
    $weak->quit if $weak;
}

done_testing;
