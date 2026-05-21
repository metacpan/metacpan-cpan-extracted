use strict;
use warnings;
use Test::More;
use EV;
use EV::cares qw(:status);

# is_destroyed transitions cleanly
{
    my $r = EV::cares->new;
    is($r->is_destroyed, 0, 'fresh resolver: is_destroyed == 0');
    $r->destroy;
    is($r->is_destroyed, 1, 'after destroy: is_destroyed == 1');
    $r->destroy;
    is($r->is_destroyed, 1, 'double destroy stays 1');
}

# read-only counters stay callable post-destroy
{
    my $r = EV::cares->new;
    $r->destroy;
    is($r->active_queries, 0,
        'active_queries callable after destroy (returns 0)');
    is($r->last_query_timeouts, 0,
        'last_query_timeouts callable after destroy (returns 0)');
    is($r->is_destroyed, 1,
        'is_destroyed callable after destroy');
}

# class function: lib_version remains callable independent of any instance
{
    like(EV::cares::lib_version(), qr/^\d+\.\d+\.\d+/,
        'lib_version returns dotted version');
    like(EV::cares->lib_version, qr/^\d+\.\d+\.\d+/,
        'lib_version as class method');
}

# T_TLSA / DANE constant
{
    is(EV::cares::T_TLSA(), 52, 'T_TLSA == 52 (RFC 6698)');
}

# DNSSEC type constants (RFC 4034)
{
    is(EV::cares::T_DS(),     43, 'T_DS == 43');
    is(EV::cares::T_RRSIG(),  46, 'T_RRSIG == 46');
    is(EV::cares::T_DNSKEY(), 48, 'T_DNSKEY == 48');
}

# next_timeout: -1 when no pending queries
{
    my $r = EV::cares->new;
    is($r->next_timeout, -1, 'next_timeout == -1 when idle');

    $r->destroy;
    eval { $r->next_timeout };
    like($@, qr/destroyed/, 'next_timeout croaks on destroyed resolver');
}

done_testing;
