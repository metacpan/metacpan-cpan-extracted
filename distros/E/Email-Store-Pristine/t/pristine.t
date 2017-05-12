# -*- cperl -*-
use Test::More tests => 11;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store { only => [qw( Mail List Pristine )] },
  "dbi:SQLite:dbname=t/test.db";
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/mailman-test");
Email::Store::Mail->store($data);

# We need one mail:
my @mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
is($mails[0]->message_id, '20001128211546.A29664@firedrake.org', "Correct ID");
like($mails[0]->message, qr/PRE_PROCESS/, "Contains the right stuff");

my @copies = $mails[0]->pristine_copies;
is(@copies, 1, "one pristine copy" );

# we're expecting the List plugin to have fiddled with the subject line
is($mails[0]->simple->header('subject'),
   'ttree problems - the sequel',
   'the mail has a munged subject' );
is($copies[0]->simple->header('subject'),
   '[Templates] ttree problems - the sequel',
  "but the pristine copy doesn't");

# to test.  getting one copy to you, one to the list - expect 1 mail
# and 2 pristine
# plug in a duplicate message
$data = read_file("t/mailman-test2");
Email::Store::Mail->store($data);

@mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
@copies = $mails[0]->pristine_copies;
is(@copies, 2, "two pristine copies" );

is($copies[0]->simple->header('subject'),
   '[Templates] ttree problems - the sequel',
  "first via list");

is($copies[1]->simple->header('subject'),
   'ttree problems - the sequel',
   "second not");
