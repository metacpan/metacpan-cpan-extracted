use Test::More tests => 11;
use File::Slurp;
BEGIN { unlink("t/test.db"); }

# Since the test e-mails were sent during BST we need to fake that it's BST now
# Africa/Luanda is used because it doesn't have a different summertime offset
$ENV{TZ} = 'Africa/Luanda';

use Email::Store "dbi:SQLite:dbname=t/test.db";
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/date-test");
Email::Store::Mail->store($data);

# We need one mail:
my @mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
# is($mails[0]->message_id, '20001128211546.A29664@foo.org', "Correct ID");

my $date;

ok($date = $mails[0]->date );


is ($date->ymd,"2004-06-18");
is ($date->hms,"11:14:35");
is ($mails[0]->year,"2004");
is ($mails[0]->month,"6");
is ($mails[0]->day,"18");

$data = read_file("t/date-test2");
Email::Store::Mail->store($data);

@mails = Email::Store::Mail->retrieve_all;
is(@mails, 2, "now two mails");

my @searched = Email::Store::Mail->search_between(1087516800,1087603199);

is(@searched, 1, "Search only found one mail");

@searched = Email::Store::Mail->search_between(1087516800,1087689600);
is(@searched, 2, "Search found two mails");

