use strict;
use warnings;
use t::Utils;
use Test::More;
use Jonk::Client;
use Jonk::Worker;

my $dbh = t::Utils->setup;

subtest 'worker / flexible job table name' => sub {
    my $jonk = Jonk::Worker->new($dbh, {functions => [qw/MyWorker/]});
    is $jonk->{dequeue_query}, q{DELETE FROM job WHERE id = ?};
    is $jonk->{find_job_query}, q{SELECT * FROM job WHERE func IN ('MyWorker') ORDER BY id LIMIT 50};
    is $jonk->{lookup_job_query}, q{SELECT * FROM job WHERE id = ?};

    $jonk = Jonk::Worker->new($dbh, +{functions => [qw/MyWorker MyWorker2/]});
    is $jonk->{dequeue_query}, q{DELETE FROM job WHERE id = ?};
    is $jonk->{find_job_query}, q{SELECT * FROM job WHERE func IN ('MyWorker', 'MyWorker2') ORDER BY id LIMIT 50};

    $jonk = Jonk::Worker->new($dbh, +{functions => [qw/MyWorker/], table_name => 'jonk_job'});
    is $jonk->{dequeue_query}, q{DELETE FROM jonk_job WHERE id = ?};
    is $jonk->{find_job_query}, q{SELECT * FROM jonk_job WHERE func IN ('MyWorker') ORDER BY id LIMIT 50};
    is $jonk->{lookup_job_query}, q{SELECT * FROM jonk_job WHERE id = ?};

    done_testing;
};

subtest 'dequeue' => sub {
    my $client = Jonk::Client->new($dbh);

    my $job_id = $client->enqueue('MyWorker', 'arg');
    ok $job_id;

    my $jonk = Jonk::Worker->new($dbh, {functions => [qw/MyWorker/]});
    my $job = $jonk->dequeue();
    is $job->{arg}, 'arg';
    is $job->{func}, 'MyWorker';
    ok not $jonk->errstr;

    done_testing;
};

subtest 'dequeue / no job' => sub {
    my $jonk = Jonk::Worker->new($dbh, {functions => [qw/MyWorker/]});
    my $job = $jonk->dequeue();
    ok not $job;
    done_testing;
};

subtest 'dequeue / lookup specific job_id' => sub {
    my $client = Jonk::Client->new($dbh);

    my $job_id = $client->enqueue('MyWorker', 'lookup_job');
    ok $job_id;

    my $jonk = Jonk::Worker->new($dbh, {functions => [qw/MyWorker/]});
    my $job = $jonk->dequeue($job_id);
    is $job->{arg}, 'lookup_job';
    is $job->{func}, 'MyWorker';

    done_testing;
};

subtest 'error handling' => sub {
    my $jonk = Jonk::Worker->new($dbh, {table_name => 'jonk_job', functions => [qw/MyWorker/]});
    my $job = $jonk->dequeue;

    like $jonk->errstr, qr/can't get job from job queue database:/;

    done_testing;
};

t::Utils->cleanup($dbh);


subtest 'dequeue / flexible job table name' => sub {
    my $dbh = t::Utils->setup("my_job");
    my $client = Jonk::Client->new($dbh, { table_name => "my_job" });

    my $job_id = $client->enqueue('MyWorker', 'arg');
    ok $job_id;

    my $jonk = Jonk::Worker->new($dbh, { table_name => "my_job", functions => [qw/MyWorker/]});
    my $job = $jonk->dequeue();
    is $job->{arg}, 'arg';
    is $job->{func}, 'MyWorker';
    ok not $jonk->errstr;

    t::Utils->cleanup($dbh, "my_job");
    done_testing;
};

done_testing;

