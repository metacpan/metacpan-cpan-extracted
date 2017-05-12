use strict;
use Test::More tests => 3;

use DBI;
use File::Temp qw(tempdir);
use Log::Dispatch::DBI;

my $temp = tempdir(CLEANUP => 1);
my $dbh = DBI->connect("dbi:CSV:f_dir=$temp") or die $DBI::errstr;
$dbh->do(<<'SQL');
CREATE TABLE log (
    level VARCHAR(9) NOT NULL,
    message text NOT NULL
)
SQL
    ;

{
    my $log = Log::Dispatch::DBI->new(
	name => 'dbi',
	min_level => 'info',
	dbh => $dbh,
    );
    ok $log->log(level => 'emergency', message => 'something BAD happened');
}

{
    my $sth = $dbh->prepare('SELECT * FROM log');
    $sth->execute;

    while (my $data = $sth->fetchrow_arrayref) {
	is $data->[0], 'emergency', 'level';
	is $data->[1], 'something BAD happened', 'message';
    }
}

