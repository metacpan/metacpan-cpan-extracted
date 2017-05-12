use strict;
use warnings;

use IO::All;
use HON::EC2::Snapshots::Monitoring qw/findLogsOfTheDay isLogOk/;

use Test::More tests => 8;


my @lines = io('t/resources/good-example.log')->slurp;
my @logs = findLogsOfTheDay(\@lines, '12-18-2015');

is(scalar(@logs), 28, 'number of lines');
like($logs[0], qr/12-18-2015/);
like($logs[scalar(@logs) - 1], qr/Backup\sdone/);
ok(isLogOk(@logs));

my @badExamples = (
  't/resources/bad-example-1.log',
  't/resources/bad-example-2.log',
);

foreach my $example (@badExamples){
  @lines = io($example)->slurp;
  @logs = findLogsOfTheDay(\@lines, '12-09-2015');
  ok(scalar(@logs) > 0);
  ok(isLogOk(@logs) == 0);
}
