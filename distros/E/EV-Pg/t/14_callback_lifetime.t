use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper qw(with_pg require_pg $conninfo run_isolated);

require_pg;

for my $method (qw(on_connect on_error on_notify on_notice on_drain)) {
    my $pg = EV::Pg->new;
    my $original = sub {};
    my $handler = $original;
    $pg->$method($handler);
    $handler = sub {};
    is($pg->$method, $original, "$method retains the installed handler");
    undef $handler;
    is($pg->$method, $original, "$method survives clearing the caller's scalar");
    $pg->$method(undef);
    ok(!defined $pg->$method, "$method can still be cleared");
}

{
    my @seen;
    with_pg(cb => sub {
        my ($pg) = @_;
        my $cb = sub { push @seen, $_[1] // $_[0][0][0]; EV::break };
        $pg->query('select 41', $cb);
        $cb = sub { push @seen, 'replacement'; EV::break };
    });
    is_deeply(\@seen, ['41'], 'query retains the original callback');
}

{
    my @seen;
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->enter_pipeline;
        my $cb = sub { push @seen, $_[1] // $_[0][0][0] };
        $pg->query_params('select 42', [], $cb);
        undef $cb;
        my $sync = sub { push @seen, $_[1] // 'sync'; $pg->exit_pipeline; EV::break };
        $pg->pipeline_sync($sync);
        $sync = sub { push @seen, 'replacement'; EV::break };
    });
    is_deeply(\@seen, ['42', 'sync'], 'pipeline query and sync retain callbacks');
}

for my $method (qw(skip_pending finish reset)) {
    my @seen;
    with_pg(cb => sub {
        my ($pg) = @_;
        my $cb = sub { push @seen, $_[1] };
        $pg->query('select 43', $cb);
        $cb = sub { push @seen, 'replacement' };
        $pg->on_connect(sub { EV::break }) if $method eq 'reset';
        $pg->$method;
        EV::break unless $method eq 'reset';
    });
    my %errors = (skip_pending => 'skipped', finish => 'connection finished', reset => 'connection reset');
    is_deeply(\@seen, [$errors{$method}], "$method calls the original queued callback");
}

{
    my @seen;
    my $pg = EV::Pg->new(conninfo => $conninfo, on_connect => sub { EV::break });
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    my $cb = sub { push @seen, $_[1] };
    $pg->query('select 45', $cb);
    undef $cb;
    undef $pg;
    is_deeply(\@seen, ['object destroyed'], 'destruction calls the retained callback');
}

SKIP: {
    skip 'requires libpq >= 17', 2
        unless EV::Pg->can('cancel_async') && EV::Pg->lib_version >= 170000;
    for my $how (qw(complete finish)) {
        my @seen;
        with_pg(cb => sub {
            my ($pg) = @_;
            my $cb = sub { push @seen, $_[1] // $_[0]; EV::break };
            $pg->cancel_async($cb);
            $cb = sub { push @seen, 'replacement'; EV::break };
            $pg->finish if $how eq 'finish';
        });
        is_deeply(\@seen, [$how eq 'finish' ? 'connection closed' : 1],
                  "cancel_async $how retains the original callback");
    }
}

{
    my @seen;
    with_pg(cb => sub {
        my ($pg) = @_;
        $pg->enter_pipeline;
        $pg->query_params('select 1', [], sub {
            return unless $_[1];
            $pg->skip_pending;
            $pg->query_params('select 44', [], sub {
                push @seen, $_[1] // $_[0][0][0];
            });
        });
        $pg->query_params('select 2', [], sub {});
        $pg->query_params('select 3', [], sub {});
        $pg->skip_pending;
        $pg->pipeline_sync(sub { $pg->exit_pipeline; EV::break });
    });
    is_deeply(\@seen, ['44'], 'reentrant skip preserves queries queued after the inner skip');
}

{
    my ($status, $out) = run_isolated(sub {
        my ($wr) = @_;
        my (@seen, $after);
        with_pg(cb => sub {
            my ($pg) = @_;
            $pg->enter_pipeline;
            $pg->query_params('select 101', [], sub {
                push @seen, 'A:' . ($_[1] // $_[0][0][0]);
                my $t = EV::timer(0.05, 0, sub { EV::break });
                EV::run;
            });
            $pg->query_params('select 102', [], sub {
                push @seen, 'B:' . ($_[1] // $_[0][0][0]);
            });
            $pg->pipeline_sync(sub {
                push @seen, 'sync:' . ($_[1] // (ref $_[0] ? $_[0][0][0] : $_[0]));
            });
            $pg->skip_pending;
            $pg->query_params('select 46', [], sub { $after = $_[1] // $_[0][0][0] });
            $pg->pipeline_sync(sub { $pg->exit_pipeline; EV::break });
        });
        print $wr join('|', join(',', @seen), $after // '');
    }, 8);
    is($status, 'ok', 'nested cancellation finishes without a crash or spin');
    my ($seen, $after) = split /\|/, $out;
    is($seen, 'A:skipped,B:skipped,sync:skipped',
              'nested timer wait during cancellation cannot misdeliver results');
    is($after, '46', 'I/O resumes after cancellation and drains the skipped results');
}

done_testing;
