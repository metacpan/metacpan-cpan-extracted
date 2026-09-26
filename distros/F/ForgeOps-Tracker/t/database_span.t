use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use JSON::PP;
use Time::HiRes ();
use ForgeOps::Tracker;
use ForgeOps::Tracker::SpanBuffer;

# Stands in for the DeliveryQueue: records every trace pushed instead of delivering it.
package Fake::Queue {
    sub new { bless { pushed => [] }, shift }
    sub push { my ($self, $trace) = @_; push @{ $self->{pushed} }, $trace; return 1 }
}

sub init_tracker {
    ForgeOps::Tracker::_reset_for_testing();
    ForgeOps::Tracker::init(
        dsn                     => 'https://key@tracker.example.com/api/v1/events',
        environment             => 'production',
        enabled_environments    => { production => 1 },
        trace_capture_threshold => 0.01,
    );
}

# Runs $code inside a slow trace and returns the one trace queued, plus it as JSON.
sub traced {
    my ($code) = @_;
    init_tracker();
    my $queue = Fake::Queue->new;
    no warnings 'redefine';
    local *ForgeOps::Tracker::_span_queue = sub { $queue };
    ForgeOps::Tracker::start_trace();
    $code->();
    ForgeOps::Tracker::finish_trace('GET /orders', Time::HiRes::time, 250);
    is(scalar(@{ $queue->{pushed} }), 1, 'one trace queued');
    my $trace = $queue->{pushed}[0];
    return ($trace, JSON::PP->new->canonical->encode($trace));
}

sub span_named {
    my ($trace, $name) = @_;
    my ($span) = grep { $_->{name} eq $name } @{ $trace->{spans} };
    return $span;
}

subtest 'a database span sends its statement masked, with db.system lowercased' => sub {
    my $result;
    my ($trace, $json) = traced(sub {
        $result = ForgeOps::Tracker::span('Load orders', sub {
            ForgeOps::Tracker::record_database_span('Load user', 'SELECT name FROM users WHERE id = 9911', Time::HiRes::time, 2);
            return 'rows';
        }, kind => 'database', statement => "SELECT * FROM orders WHERE email = 'jane\@example.com' AND total > 4200",
           db_system => ' PostgreSQL ');
    });
    is($result, 'rows');

    my $orders = span_named($trace, 'Load orders');
    my $user = span_named($trace, 'Load user');
    is($orders->{kind}, 'database');
    is($orders->{data}{'db.statement'}, 'SELECT * FROM orders WHERE email = ? AND total > ?');
    is($orders->{data}{'db.system'}, 'postgresql');
    is($user->{data}{'db.statement'}, 'SELECT name FROM users WHERE id = ?');
    ok(!exists $user->{data}{'db.system'}, 'no db.system when none was given');
    is($user->{parent_span_id}, $orders->{span_id});
    unlike($json, qr/jane\@example\.com|4200|9911/, 'no literal reaches the payload');
};

subtest 'data passed alongside statement is kept' => sub {
    my ($trace) = traced(sub {
        ForgeOps::Tracker::span('Load cart', sub { 1 }, kind => 'database', statement => 'SELECT 1', data => { shard => 'eu' });
    });
    is_deeply(span_named($trace, 'Load cart')->{data}, { 'db.statement' => 'SELECT ?', shard => 'eu' });
};

subtest 'a db.statement put in data by hand is masked, and the caller hash is untouched' => sub {
    my %data = ('db.statement' => "DELETE FROM carts WHERE token = 'tok-77xq'", rows => 3);
    my ($trace, $json) = traced(sub {
        ForgeOps::Tracker::record_span('Clear cart', 'database', Time::HiRes::time, 2, \%data);
        ForgeOps::Tracker::record_span('Odd', 'database', Time::HiRes::time, 2, { 'db.statement' => [1] });
    });
    is(span_named($trace, 'Clear cart')->{data}{'db.statement'}, 'DELETE FROM carts WHERE token = ?');
    is(span_named($trace, 'Clear cart')->{data}{rows}, 3);
    ok(!exists span_named($trace, 'Odd')->{data}{'db.statement'}, 'a statement that is not a string is dropped');
    is($data{'db.statement'}, "DELETE FROM carts WHERE token = 'tok-77xq'");
    unlike($json, qr/tok-77xq/);
};

subtest 'statement and db_system are ignored on a span that is not a database span' => sub {
    my ($trace, $json) = traced(sub {
        ForgeOps::Tracker::span('Charge', sub { 1 }, statement => "SELECT 'secret-value'", db_system => 'mysql');
    });
    is_deeply(span_named($trace, 'Charge')->{data}, {});
    unlike($json, qr/secret-value/);
};

subtest 'a long statement is truncated' => sub {
    my $sql = 'SELECT ' . ('column_name, ' x 500) . 'id FROM orders';
    my $data = ForgeOps::Tracker::SpanBuffer::mask_database_data(ForgeOps::Tracker::database_span_data($sql, 'MySQL'));
    is(length $data->{'db.statement'}, 4003);
    like($data->{'db.statement'}, qr/\.\.\.\z/);
    is($data->{'db.system'}, 'mysql');
};

subtest 'database_span_data leaves out blank values' => sub {
    is_deeply(ForgeOps::Tracker::database_span_data('  ', undef), {});
    is_deeply(ForgeOps::Tracker::database_span_data(undef, ' '), {});
};

subtest 'outside a trace a database span just runs the code' => sub {
    init_tracker();
    is(ForgeOps::Tracker::span('free', sub { 7 }, kind => 'database', statement => 'SELECT 1'), 7);
    ForgeOps::Tracker::record_database_span('free', 'SELECT 1', Time::HiRes::time, 1);
    pass('record_database_span outside a trace does nothing');
};

done_testing;
