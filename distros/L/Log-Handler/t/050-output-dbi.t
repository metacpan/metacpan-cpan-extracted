use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use DBI;";
    if ($@) {
        plan skip_all => "No DBI installed";
        exit(0);
    }
};

use Log::Handler::Output::DBI;
plan tests => 8;

my ($ret, $log);

$log = Log::Handler::Output::DBI->new(
    database   => "dbname",
    driver     => "mysql",
    user       => "dbuser",
    password   => "dbpass",
    host       => "127.0.0.1",
    port       => 3306,
    debug      => 0,
    table      => "messages",
    columns    => "level message",
    values     => "%level %message",
    persistent => 0,
);

ok(1, "new");

$ret = $log->{statement} eq "insert into messages (level,message) values (?,?)";
ok($ret, "checking statement");

#$ret = $log->{cstr}->[0] eq "dbi:mysql:database=dbname;host=127.0.0.1;port=3306";
$ret = $log->{cstr}->[0] eq "dbi:mysql:database=dbname;host=127.0.0.1;port=3306";
ok($ret, "checking cstr");

$ret = $log->{cstr}->[1] eq "dbuser";
ok($ret, "checking user");

$ret = $log->{cstr}->[2] eq "dbpass";
ok($ret, "checking password");

$ret = $log->{cstr}->[3]->{PrintError} == 0;
ok($ret, "checking argument PrintError");

$ret = $log->{cstr}->[3]->{AutoCommit} == 1;
ok($ret, "checking argument AutoCommit");

$log->reload(
    {
        database   => "dbname",
        driver     => "mysql",
        user       => "dbuser",
        password   => "new password",
        host       => "127.0.0.1",
        port       => 3306,
        debug      => 0,
        table      => "messages",
        columns    => "level message",
        values     => "%level %message",
        persistent => 0,
    }
);

ok($log->{password} eq "new password", "checking reload ($log->{password})");
