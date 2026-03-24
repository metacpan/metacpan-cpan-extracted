use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg qw(:transaction);
use lib 't';
use TestHelper;

require_pg;
plan tests => 32;

# escape_literal
with_pg(cb => sub {
    my ($pg) = @_;
    my $escaped = $pg->escape_literal("hello'world");
    like($escaped, qr/'hello''world'/, 'escape_literal quotes correctly');
    EV::break;
});

# escape_identifier
with_pg(cb => sub {
    my ($pg) = @_;
    my $escaped = $pg->escape_identifier("my table");
    like($escaped, qr/"my table"/, 'escape_identifier quotes correctly');
    EV::break;
});

# parameter_status
with_pg(cb => sub {
    my ($pg) = @_;
    my $encoding = $pg->parameter_status('server_encoding');
    ok(defined $encoding, 'parameter_status returns a value');
    EV::break;
});

# transaction_status
with_pg(cb => sub {
    my ($pg) = @_;
    is($pg->transaction_status, PQTRANS_IDLE, 'transaction_status idle when connected');
    EV::break;
});

# error callback on syntax error
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("invalid sql", sub {
        my ($data, $err) = @_;
        ok($err, 'syntax error: got error string');
        ok(!defined $data, 'syntax error: data is undef');
        EV::break;
    });
});

# reset
with_pg(cb => sub {
    my ($pg) = @_;
    ok($pg->is_connected, 'connected before reset');
    $pg->on_connect(sub {
        ok($pg->is_connected, 'reconnected after reset');
        EV::break;
    });
    $pg->reset;
});

# double finish
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->finish;
    ok(!$pg->is_connected, 'not connected after finish');
    $pg->finish;
    ok(1, 'double finish did not crash');
    EV::break;
});

# skip_pending
with_pg(cb => sub {
    my ($pg) = @_;
    my $skipped = 0;
    $pg->query("select pg_sleep(10)", sub {
        my ($data, $err) = @_;
        $skipped = 1;
        like($err, qr/skipped/, 'skipped query: error says skipped');
    });
    ok($pg->pending_count > 0, 'pending_count > 0 after send');
    $pg->skip_pending;
    is($pg->pending_count, 0, 'pending_count 0 after skip');
    EV::break;
});

# DESTROY during callback
{
    my $survived = 0;
    my $pg2;
    $pg2 = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub {
            $pg2->query("select 1", sub {
                if (!$survived) {
                    undef $pg2;
                    $survived = 1;
                }
                EV::break;
            });
        },
        on_error => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    ok($survived, 'DESTROY during callback did not crash');
}

# query before connect croaks
{
    my $pg3 = EV::Pg->new(on_error => sub {});
    eval { $pg3->query("select 1", sub {}) };
    like($@, qr/not connected/, 'query before connect croaks');
}

# query_params before connect croaks
{
    my $pg3 = EV::Pg->new(on_error => sub {});
    eval { $pg3->query_params("select 1", [], sub {}) };
    like($@, qr/not connected/, 'query_params before connect croaks');
}

# query after finish croaks
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->finish;
    eval { $pg->query("select 1", sub {}) };
    like($@, qr/not connected/, 'query after finish croaks');
    EV::break;
});

# finish with pending callbacks delivers errors
with_pg(cb => sub {
    my ($pg) = @_;
    my $got_err;
    $pg->query("select pg_sleep(10)", sub {
        my ($data, $err) = @_;
        $got_err = $err;
    });
    $pg->finish;
    ok($got_err, 'finish with pending: callback got error');
    like($got_err, qr/connection finished/, 'finish with pending: correct error message');
    EV::break;
});

# re-enqueue during finish: pipeline mode allows re-enqueue, second drain catches it
{
    my $pg;
    my ($orig_err, $requeued_err);
    $pg = EV::Pg->new(
        conninfo => $conninfo,
        on_connect => sub {
            $pg->enter_pipeline;
            $pg->query_params("select pg_sleep(10)", [], sub {
                my ($data, $err) = @_;
                $orig_err = $err;
                # re-enqueue in pipeline — PQsendQueryParams works here
                $pg->query_params("select 1", [], sub {
                    my ($data2, $err2) = @_;
                    $requeued_err = $err2;
                });
            });
            $pg->pipeline_sync(sub {});
            $pg->finish;
            EV::break;
        },
        on_error => sub { diag "Error: $_[0]"; EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    like($orig_err, qr/connection finished/, 're-enqueue finish: orig cb got error');
    like($requeued_err, qr/connection finished/, 're-enqueue finish: re-enqueued cb got error');
}

# non-CODE callback croaks
with_pg(cb => sub {
    my ($pg) = @_;
    eval { $pg->query("select 1", "not_a_coderef") };
    like($@, qr/CODE reference/, 'non-CODE callback croaks');
    EV::break;
});

# reset before any connect croaks
{
    my $pg = EV::Pg->new(on_error => sub {});
    eval { $pg->reset };
    like($@, qr/no previous connection/, 'reset without prior connect croaks');
}

# connect while already connected croaks
with_pg(cb => sub {
    my ($pg) = @_;
    eval { $pg->connect($conninfo) };
    like($@, qr/already connected/, 'connect while connected croaks');
    EV::break;
});

# query_params with >16 params (exercises heap allocation path)
with_pg(cb => sub {
    my ($pg) = @_;
    my @params = (1..20);
    my $placeholders = join(', ', map { "\$$_\::int" } 1..20);
    $pg->query_params("select $placeholders", \@params, sub {
        my ($rows, $err) = @_;
        ok(!$err, 'query_params >16 params: no error');
        is($rows->[0][19], '20', 'query_params >16 params: last param correct');
        EV::break;
    });
});

# escape functions croak when not connected
{
    my $pg = EV::Pg->new(on_error => sub {});
    eval { $pg->escape_literal("test") };
    like($@, qr/not connected/, 'escape_literal when disconnected croaks');
    eval { $pg->escape_identifier("test") };
    like($@, qr/not connected/, 'escape_identifier when disconnected croaks');
    eval { $pg->cancel };
    like($@, qr/not connected/, 'cancel when disconnected croaks');
}

# handler_accessor rejects non-CODE non-undef
with_pg(cb => sub {
    my ($pg) = @_;
    eval { $pg->on_connect("not_a_coderef") };
    like($@, qr/CODE reference/, 'on_connect with non-CODE croaks');
    EV::break;
});

# set_client_encoding with pending queries croaks
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("select pg_sleep(10)", sub {});
    eval { $pg->set_client_encoding('UTF8') };
    like($@, qr/pending queries/, 'set_client_encoding with pending croaks');
    $pg->finish;
    EV::break;
});

# new() warns on unknown arguments
{
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $pg = EV::Pg->new(on_error => sub {}, bogus_arg => 1);
    like($w[0], qr/unknown argument.*bogus_arg/, 'new() warns on unknown args');
}
