use strict;
use warnings;
use t::Utils;
use Test::More;
use DBI;
use Jonk::Client;

my $dbh = t::Utils->setup;

subtest 'client / flexible job table name' => sub {
    my $jonk = Jonk::Client->new($dbh);
    is $jonk->{enqueue_query}, 'INSERT INTO job (func, arg, enqueue_time) VALUES (?,?,?)';

    $jonk = Jonk::Client->new($dbh, +{table_name => 'jonk_job'});
    is $jonk->{enqueue_query}, 'INSERT INTO jonk_job (func, arg, enqueue_time) VALUES (?,?,?)';

    done_testing;
};

subtest 'enqueue' => sub {
    my $jonk = Jonk::Client->new($dbh);

    my $job_id = $jonk->enqueue('MyWorker', 'arg');
    ok $job_id;

    my $sth = $dbh->prepare('SELECT * FROM job WHERE id = ?');
    $sth->execute($job_id);
    my $row = $sth->fetchrow_hashref;

    is $row->{arg}, 'arg';
    is $row->{func}, 'MyWorker';
    ok not $jonk->errstr;

    done_testing;
};

subtest 'enqueue / and enqueue_time_callback' => sub {
    my $time;
    my $jonk = Jonk::Client->new($dbh,+{enqueue_time_callback => sub {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
        $time = sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
    }});

    my $job_id = $jonk->enqueue('MyWorker', 'arg');
    ok $job_id;

    my $sth = $dbh->prepare('SELECT * FROM job WHERE id = ?');
    $sth->execute($job_id);
    my $row = $sth->fetchrow_hashref;

    is $row->{arg}, 'arg';
    is $row->{func}, 'MyWorker';
    is $row->{enqueue_time}, $time;

    done_testing;
};

subtest 'error handling' => sub {
    my $jonk = Jonk::Client->new($dbh, +{table_name => 'jonk_job'});

    my $job_id = $jonk->enqueue('MyWorker', 'arg');
    ok not $job_id;
    like $jonk->errstr, qr/can't enqueue for job queue database:/;

    done_testing;
};

t::Utils->cleanup($dbh);


subtest 'enqueue / flexible job table name' => sub {
    my $dbh = t::Utils->setup("my_job");
    my $jonk = Jonk::Client->new($dbh, +{table_name => "my_job"});

    my $job_id = $jonk->enqueue('MyWorker', 'arg');
    ok $job_id;

    my $sth = $dbh->prepare('SELECT * FROM my_job WHERE id = ?');
    $sth->execute($job_id);
    my $row = $sth->fetchrow_hashref;

    is $row->{arg}, 'arg';
    is $row->{func}, 'MyWorker';
    ok not $jonk->errstr;

    t::Utils->cleanup($dbh, "my_job");
    done_testing;
};

done_testing;

