use strict;
use warnings;
use Test::More;
use File::Temp ();
use EV;
use EV::cares qw(:all);

# Unknown host on file-only lookup returns a non-success status
# (exact code varies: ENOTFOUND on most c-ares, ECANCELLED on some)
{
    my $tmp = File::Temp->new(SUFFIX => '.hosts');
    print $tmp "10.0.0.1 only-this-host\n";
    close $tmp;

    my $r = EV::cares->new(lookups => 'f', hosts_file => $tmp->filename);
    my @got;
    my $done;
    $r->resolve('definitely-not-in-hosts', sub { @got = @_; $done = 1 });
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    isnt($got[0], ARES_SUCCESS, 'unknown host returns non-success');
    diag "unknown-host status: $got[0] (" . EV::cares::strerror($got[0]) . ")";
}

# ARES_ECONNREFUSED / ARES_ETIMEOUT: unreachable nameserver
{
    my $r = EV::cares->new(
        servers => ['127.0.0.1:9'],   # port 9 reserved -> connection refused
        timeout => 1,
        tries   => 1,
    );
    my @got;
    my $done;
    $r->query('example.com', C_IN, T_A, sub { @got = @_; $done = 1 });
    my $t = EV::timer 5, 0, sub { $done = 1 };
    EV::run until $done;
    isnt($got[0], ARES_SUCCESS, 'unreachable server returns failure');
    ok($got[0] == ARES_ECONNREFUSED || $got[0] == ARES_ETIMEOUT,
       "got CONNREFUSED or ETIMEOUT (got $got[0]: " .
        EV::cares::strerror($got[0]) . ")");
}

# ARES_ECANCELLED: cancel while pending
{
    my $r = EV::cares->new(timeout => 5);
    my @got;
    $r->resolve('whatever.test', sub { @got = @_ });
    $r->cancel;
    my $t = EV::timer 1, 0, sub { EV::break };
    EV::run;
    is($got[0], ARES_ECANCELLED, 'cancel produces ARES_ECANCELLED');
}

# ARES_EBADNAME or ENOTFOUND: bad label-formatted name
{
    my $r = EV::cares->new(lookups => 'f', timeout => 1, tries => 1);
    my @got;
    my $done;
    # excessively long label (>63 chars) is invalid per DNS spec
    my $bad = 'x' x 100;
    $r->resolve($bad, sub { @got = @_; $done = 1 });
    my $t = EV::timer 3, 0, sub { $done = 1 };
    EV::run until $done;
    isnt($got[0], ARES_SUCCESS, 'oversize label returns failure');
}

# strerror returns a string for every documented status code
{
    for my $code (ARES_SUCCESS, ARES_ENODATA, ARES_EFORMERR, ARES_ESERVFAIL,
                  ARES_ENOTFOUND, ARES_ENOTIMP, ARES_EREFUSED, ARES_EBADQUERY,
                  ARES_EBADNAME, ARES_EBADFAMILY, ARES_EBADRESP,
                  ARES_ECONNREFUSED, ARES_ETIMEOUT, ARES_EOF, ARES_EFILE,
                  ARES_ENOMEM, ARES_EDESTRUCTION, ARES_EBADSTR, ARES_EBADFLAGS,
                  ARES_ENONAME, ARES_EBADHINTS, ARES_ENOTINITIALIZED,
                  ARES_ECANCELLED, ARES_ESERVICE, ARES_ENOSERVER) {
        my $msg = EV::cares::strerror($code);
        ok(defined $msg && length $msg, "strerror($code) returns a string");
    }
}

done_testing;
