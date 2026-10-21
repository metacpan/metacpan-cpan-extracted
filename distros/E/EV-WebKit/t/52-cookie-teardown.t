use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib'; use TWK; TWK::skip_unless_available();
use EV; use EV::WebKit;
use File::Temp qw(tempfile);

# Regression: quit() (and DESTROY) while a cookie-MANAGER op -- get_cookies
# (cookies/save_cookies) or add_cookie (set_cookie) -- is still in flight must
# not use-after-free the network session/web context in WebKit's C code. Doing
# so segfaults, reliably: quit() dropped $self's last ref to those native
# objects, WebKit finalized them, and the in-flight op's C completion then ran
# against freed memory (crash observed during the settle EV::run below). The
# fix keeps the natives alive across the op and releases them on a clean tick.
#
# A segfault crashes the whole process, so prove reports the file as failed
# (dubious/non-zero exit); reaching done_testing here IS the pass. Each op is
# fired and then quit() is called in the SAME tick, so it is guaranteed still
# in flight at teardown, with a settle run afterward (where the crash struck).

my ($fh, $jar) = tempfile(UNLINK => 1);
close $fh;

for my $op (qw/cookies set_cookie save_cookies clear_cookies/) {
    my $b = EV::WebKit->new(window => [200, 150]);
    $b->mock_scheme('m', sub { ('<html><body>hi</body></html>', 'text/html') });
    my ($settle, $nav_err, $fired);
    $b->go('m://p', sub {
        my (undef, $e) = @_;
        return do { $nav_err = $e; EV::break } if $e;
        $fired = 1;
        if    ($op eq 'cookies')      { $b->cookies('http://example.com/', sub {}) }
        elsif ($op eq 'set_cookie')   { $b->set_cookie({name=>'k',value=>'v',domain=>'example.com'}, sub {}) }
        elsif ($op eq 'save_cookies') { $b->save_cookies($jar, ['http://example.com/'], sub {}) }
        elsif ($op eq 'clear_cookies'){ $b->clear_cookies(sub {}) }
        $b->quit;                                       # tear down while the op is in flight
        $settle = EV::timer(1, 0, sub { EV::break });   # settle: where the pre-fix UAF crashed
    });
    TWK::run_with_timeout(15);
    # Assert the premise. Without this a failed navigation returned early, no op
    # was fired, quit() was never called -- and the pass() below still passed,
    # the block proving nothing at all.
    is($nav_err, undef, "$op: setup navigated") or diag $nav_err;
    ok($fired, "$op: ...and the op was fired before quit, so it WAS in flight");
    pass("$op: quit() while the op was in flight did not use-after-free / crash");
}

# Same again but via DESTROY (drop the browser, no explicit quit) mid-flight.
{
    my $settle;
    {
        my $b = EV::WebKit->new(window => [200, 150]);
        $b->mock_scheme('m', sub { ('<html><body>hi</body></html>', 'text/html') });
        my ($nav_err, $fired);
        $b->go('m://p', sub {
            my (undef, $e) = @_;
            return do { $nav_err = $e; EV::break } if $e;
            $b->cookies('http://example.com/', sub {});   # in flight
            $fired = 1;
            EV::break;
        });
        TWK::run_with_timeout(15);
        # the same premise the loop above asserts: without it a failed
        # navigation means nothing is in flight and the pass() proves nothing
        is($nav_err, undef, 'DESTROY block: setup navigated') or diag $nav_err;
        ok($fired, 'DESTROY block: ...and the cookie op was issued');
        # $b drops here (DESTROY -> quit) while the cookies() op may still be in flight
    }
    $settle = EV::timer(1.5, 0, sub { EV::break });
    EV::run;
    pass('DESTROY mid-cookie-op did not crash during the following settle run');
}

{
    require Scalar::Util;
    my $b = EV::WebKit->new(window => [200,150], timeout => 5);
    my ($weak, $fired, $err);
    {
        my $canary = bless {}, 'SnapshotCanary';
        $weak = $canary;
        Scalar::Util::weaken($weak);
        $b->save_cookies($jar, ['http://one.test/', 'http://two.test/'], sub {
            my $held = $canary;
            $fired++;
            $err = $_[1];
        });
    }
    $b->quit;
    undef $b;
    { my $settle = EV::timer(1, 0, sub { EV::break }); EV::run }
    is($fired, 1, 'snapshot callback resolved once after dropping its browser');
    is($err, 'browser closed', 'snapshot resolves as closed');
    ok(!defined $weak, 'snapshot releases callback captures after its browser is dropped');
}

done_testing;
