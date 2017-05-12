use Test::More tests => 19;

use IMAP::Client;
my $client = IMAP::Client->new;
my (%quota,@quotaresponse);

my (@searchresponse,@r_array,$r_scalar);

# Single-entry search response
@searchresponse = ("* SEARCH 1\r\n",
				   "0035 OK Completed (1 msgs in 0.000 secs)\r\n");
$r_scalar = IMAP::Client::parse_search(@searchresponse);
is($r_scalar,"1");
@r_array = IMAP::Client::parse_search(@searchresponse);
is($r_array[0],1);

# Multi-entry non-compressable search response
@searchresponse = ("* SEARCH 1 4\r\n",
				   "0035 OK Completed (1 msgs in 0.000 secs)\r\n");
$r_scalar = IMAP::Client::parse_search(@searchresponse);
is($r_scalar,"1,4");
@r_array = IMAP::Client::parse_search(@searchresponse);
is($r_array[0],1);
is($r_array[1],4);

# Multi-entry compressable search response
@searchresponse = ("* SEARCH 1 2 3 4\r\n",
				   "0035 OK Completed (1 msgs in 0.000 secs)\r\n");
$r_scalar = IMAP::Client::parse_search(@searchresponse);
is($r_scalar,"1:4");
@r_array = IMAP::Client::parse_search(@searchresponse);
is($r_array[0],1);
is($r_array[1],2);
is($r_array[2],3);
is($r_array[3],4);

# Multi-entry compressable/non-compressable mix search response
@searchresponse = ("* SEARCH 1 2 3 6 7 9\r\n",
				   "0035 OK Completed (1 msgs in 0.000 secs)\r\n");
$r_scalar = IMAP::Client::parse_search(@searchresponse);
is($r_scalar,"1:3,6:7,9");
@r_array = IMAP::Client::parse_search(@searchresponse);
is($r_array[0],1);
is($r_array[1],2);
is($r_array[2],3);
is($r_array[3],6);
is($r_array[4],7);
is($r_array[5],9);


# Search returns no matches
@searchresponse = ("* SEARCH\r\n",
				   "0035 OK Completed (1 msgs in 0.000 secs)\r\n");
$r_scalar = IMAP::Client::parse_search(@searchresponse);
is($r_scalar,undef);
@r_array = IMAP::Client::parse_search(@searchresponse);
is($r_array[0],undef);