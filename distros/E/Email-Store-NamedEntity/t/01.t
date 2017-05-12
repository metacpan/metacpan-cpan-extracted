use Test::More tests => 5;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store "dbi:SQLite:dbname=t/test.db";
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/test.mail");
Email::Store::Mail->store($data);

# We need one mail:
my @mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
# is($mails[0]->message_id, '20001128211546.A29664@foo.org', "Correct ID");

my @entities;

ok(@entities = $mails[0]->named_entities );

my %ent_map = map { lc($_->thing) => $_ } @entities;

is ($ent_map{'switzerland'}->description,"place");
is ($ent_map{'tony ageh'}->description,"person");

