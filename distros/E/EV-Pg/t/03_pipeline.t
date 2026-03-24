use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg qw(:pipeline);
use lib 't';
use TestHelper;

require_pg;
plan tests => 18;

# Basic pipeline test
with_pg(cb => sub {
    my ($pg) = @_;
    is($pg->pipeline_status, PQ_PIPELINE_OFF, 'pipeline initially off');

    $pg->enter_pipeline;
    is($pg->pipeline_status, PQ_PIPELINE_ON, 'pipeline on after enter');

    my @results;

    $pg->query_params("select 1", [], sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : $rows->[0][0];
    });

    $pg->query_params("select 2", [], sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : $rows->[0][0];
    });

    $pg->query_params("select 3", [], sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err:$err" : $rows->[0][0];
    });

    $pg->pipeline_sync(sub {
        my ($ok, $err) = @_;
        ok($ok, 'pipeline_sync callback called with success');
        is_deeply(\@results, ['1', '2', '3'], 'pipeline: all 3 results received in order');

        $pg->exit_pipeline;
        is($pg->pipeline_status, PQ_PIPELINE_OFF, 'pipeline off after exit');
        EV::break;
    });

});

# Pipeline with error
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->enter_pipeline;

    my @results;

    $pg->query_params("select 1", [], sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err" : $rows->[0][0];
    });

    # This should fail (syntax error)
    $pg->query_params("invalid sql here", [], sub {
        my ($rows, $err) = @_;
        push @results, $err ? "err" : "ok";
    });

    $pg->query_params("select 3", [], sub {
        my ($rows, $err) = @_;
        push @results, $err ? "aborted" : $rows->[0][0];
        is($pg->pipeline_status, PQ_PIPELINE_ABORTED,
           'pipeline_status: aborted after error');
    });

    $pg->pipeline_sync(sub {
        my ($ok, $err) = @_;
        ok(1, 'sync after error pipeline');
        is($results[0], '1', 'first query succeeded before error');
        is($results[1], 'err', 'second query errored');
        is($results[2], 'aborted', 'third query aborted');

        $pg->exit_pipeline;
        EV::break;
    });

});

# Pipeline recovery: normal query works after aborted pipeline
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->enter_pipeline;
    $pg->query_params("invalid sql", [], sub {});
    $pg->query_params("select 1", [], sub {});
    $pg->pipeline_sync(sub {
        $pg->exit_pipeline;
        $pg->query("select 'recovered' as v", sub {
            my ($rows, $err) = @_;
            ok(!$err, 'pipeline recovery: query after abort succeeds');
            is($rows->[0][0], 'recovered', 'pipeline recovery: correct result');
            is($pg->pipeline_status, PQ_PIPELINE_OFF, 'pipeline recovery: pipeline off');
            EV::break;
        });
    });
});

# query() croaks in pipeline mode
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->enter_pipeline;
    eval { $pg->query("select 1", sub {}) };
    like($@, qr/not allowed in pipeline mode/, 'query() croaks in pipeline mode');
    $pg->exit_pipeline;
    EV::break;
});

# pending_count test
with_pg(cb => sub {
    my ($pg) = @_;
    is($pg->pending_count, 0, 'pending_count starts at 0');
    $pg->query("select 1", sub { EV::break });
});

# prepare + query_prepared in pipeline mode
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->enter_pipeline;

    my $prep_ok = 0;
    my $result;

    $pg->prepare('pipe_stmt', 'select $1::int * 10', sub {
        my (undef, $err) = @_;
        $prep_ok = !$err;
    });

    $pg->query_prepared('pipe_stmt', [7], sub {
        my ($rows, $err) = @_;
        $result = $err ? "err:$err" : $rows->[0][0];
    });

    $pg->pipeline_sync(sub {
        ok($prep_ok, 'pipeline: prepare succeeded');
        is($result, '70', 'pipeline: query_prepared got correct result');
        $pg->exit_pipeline;

        # verify the prepared statement persists after pipeline
        $pg->query_prepared('pipe_stmt', [3], sub {
            my ($rows, $err) = @_;
            is($rows->[0][0], '30', 'pipeline: prepared stmt usable after exit');
            EV::break;
        });
    });

});
