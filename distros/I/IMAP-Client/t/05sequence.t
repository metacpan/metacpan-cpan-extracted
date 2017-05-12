use Test::More tests => 6;

use IMAP::Client;
my $client = IMAP::Client->new;

is(IMAP::Client::sequencify(1,2,3,4,5),"1:5");
is(IMAP::Client::sequencify(1,2,4,5,6),"1:2,4:6");
is(IMAP::Client::sequencify(1,3,5,6,7),"1,3,5:7");
is(IMAP::Client::sequencify(1,3,5,7,9),"1,3,5,7,9");
is(IMAP::Client::sequencify(1,2,5,7,8),"1:2,5,7:8");
is(IMAP::Client::sequencify(3,5,2,1,4),"3,5,2,1,4");
