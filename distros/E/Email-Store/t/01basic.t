use Test::More tests => 20;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store "dbi:SQLite:dbname=t/test.db";
#use Email::Store "dbi:mysql:mailstore";
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/mailman-test");
Email::Store::Mail->store($data);

# We need one mail:
my @mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
is($mails[0]->message_id, '20001128211546.A29664@firedrake.org', "Correct ID");
like($mails[0]->message, qr/PRE_PROCESS/, "Contains the right stuff");

my $simple = $mails[0]->simple;
isa_ok($simple, "Email::Simple");
is($simple, $mails[0]->simple, "Email::Simple objects should be singleton");

# Subject munged correctly
is($simple->header("Subject"), "ttree problems - the sequel", "Subject had relevant bits removed");

# And one list:
my @lists = Email::Store::List->retrieve_all;
is(@lists, 1, "Only one list");
my $list = shift @lists;
is ($list->name, "templates", "Good name");
is ($list->posting_address, 'templates@template-toolkit.org', "Good address");

# List should have one post:
is($list->posts, 1, "One post");
# And the post should belong to a list!
is(($mails[0]->lists)[0], $list, "Belongs to correct list");

# Now I expect there to be two entities in the world
my @entities = Email::Store::Entity->retrieve_all;
is(@entities, 2, "Two people in our universe");
for (@entities) {
    my @addressings = $_->addressings;
    is (@addressings, 1, "One addressing each");
    is ($addressings[0]->mail, $mails[0], "Referring to the right mail");
}

# Dates:
my $date;
ok($date = $mails[0]->date );
is (($date - $date->tzoffset)->ymd,"2000-11-28");                               
is (($date - $date->tzoffset)->hms,"21:15:46");                                 
