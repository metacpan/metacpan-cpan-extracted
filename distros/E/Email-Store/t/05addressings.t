use Test::More tests => 4;
use File::Slurp;
BEGIN { unlink("t/test.db"); }
use Email::Store "dbi:SQLite:dbname=t/test.db";
#use Email::Store "dbi:mysql:mailstore";
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/troublesome");
Email::Store::Mail->store($data);

# We need one mail:
my @mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
my $mail = $mails[0];

my @addressings = $mail->addressings(role => "To");
is(@addressings, 0, "No real addresses");
is(($mail->date - $mail->date->tzoffset)->ymd, "2002-07-12");
