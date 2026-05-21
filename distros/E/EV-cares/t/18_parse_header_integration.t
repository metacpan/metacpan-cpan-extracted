use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:all);

# Integration test: issue a real raw query() and run parse_header on the
# returned buffer.  Verifies the header parser agrees with what c-ares
# hands us for a file-based lookup (no network required).

{
    my $r = EV::cares->new(lookups => 'f');
    my $status;
    my $buf;
    $r->query('localhost', C_IN, T_A, sub {
        ($status, $buf) = @_;
    });
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until defined $status;

    SKIP: {
        skip "file-based query for localhost didn't yield a response buffer", 6
            if $status != ARES_SUCCESS || !defined $buf;
        ok(length $buf >= 12, "response is at least a DNS header (got @{[length $buf]} bytes)");
        my $h = EV::cares::parse_header($buf);
        is($h->{qr},     1, 'QR bit set (this is a response)');
        is($h->{rcode},  0, 'RCODE NOERROR on success');
        cmp_ok($h->{qdcount}, '>=', 1, 'qdcount >= 1 (we asked something)');
        cmp_ok($h->{ancount}, '>=', 1, 'ancount >= 1 (we got at least one answer)');
        # ID is whatever c-ares used; just sanity-check the range
        cmp_ok($h->{id}, '>=', 0, 'id is non-negative');
        cmp_ok($h->{id}, '<=', 0xffff, 'id fits in 16 bits');
    }
}

# parse_header on a known-failing query result.  We don't assert RCODE
# because c-ares may synthesize different statuses across platforms; the
# point is to exercise the integration path with a real buffer.
{
    my $r = EV::cares->new(lookups => 'f');
    my ($status, $buf);
    $r->query('utterly-impossible-name.invalid', C_IN, T_A, sub {
        ($status, $buf) = @_;
    });
    my $t = EV::timer 5, 0, sub { EV::break };
    EV::run until defined $status;

    SKIP: {
        skip 'no response buffer for negative lookup', 1
            unless defined $buf && length $buf >= 12;
        my $h = EV::cares::parse_header($buf);
        ok(exists $h->{rcode}, 'parse_header still works on error responses');
    }
}

done_testing;
