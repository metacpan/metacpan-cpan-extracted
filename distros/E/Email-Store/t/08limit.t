use Test::More tests => 4;
use File::Slurp;
BEGIN { unlink("t/test.db"); }

use Email::Store { only => [ "Mail" ] }, "dbi:SQLite:dbname=t/test.db";
#use Email::Store "dbi:mysql:mailstore";
Email::Store->setup;
ok(1, "Set up");

my $data = read_file("t/troublesome");
Email::Store::Mail->store($data);

# We need one mail:
my @mails = Email::Store::Mail->retrieve_all;
is(@mails, 1, "Only one mail");
my $mail = $mails[0];


is(Email::Store::Mail->can('date'),undef,"limited");
my $var = Email::Store::Mail->can('simple');
is(ref($var),'CODE',"limited allowed");
