# -*- cperl -*-
use Test::More tests => 5;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store  { only => [qw( Mail Summary )] },
  "dbi:SQLite:dbname=t/test.db";
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("mailman-test");
Email::Store::Mail->store($data);

# We need one mail:
my @mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
is($mails[0]->message_id, '20001128211546.A29664@firedrake.org', "Correct ID");
is($mails[0]->subject, "[Templates] ttree problems - the sequel", "Correct subject");
like($mails[0]->original, qr/debug my problems/, "Correct original text");
