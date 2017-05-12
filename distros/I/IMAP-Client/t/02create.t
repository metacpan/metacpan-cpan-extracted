use Test::Simple tests => 2;

use IMAP::Client;
my $client = IMAP::Client->new;
ok(defined $client);
ok($client->isa('IMAP::Client'));
