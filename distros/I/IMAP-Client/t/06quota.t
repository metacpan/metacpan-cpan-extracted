use Test::More tests => 5;

use IMAP::Client;
my $client = IMAP::Client->new;
my (%quota,@quotaresponse);


## Basic quota response
@quotaresponse = ("* QUOTA foobar (STORAGE 2 25000)\r\n",
				  "0052 OK Completed\r\n");
%quota = IMAP::Client::parse_quota('foobar',\@quotaresponse);
is($quota{STORAGE}[0],2);
is($quota{STORAGE}[1],25000);

## Basic quotaroot response
@quotaresponse = ("* QUOTAROOT foobar.test foobar\r\n",
	 			  "* QUOTA foobar (STORAGE 2 25000)\r\n",
				  "0052 OK Completed\r\n");
%quota = IMAP::Client::parse_quota('foobar.test',\@quotaresponse);
is($quota{ROOT},'foobar');
is($quota{STORAGE}[0],2);
is($quota{STORAGE}[1],25000);

## Multi-degree quota response (FIXME: NEED ACUTAL EXAMPLE TO TEST)
#@quotaresponse = ("* QUOTAROOT foobar.test foobar\r\n",
#	 			  "* QUOTA foobar (STORAGE 2 25000) (FILES 100 500000)\r\n",
#				  "0052 OK Completed\r\n");
#%quota = IMAP::Client::parse_quota('foobar.test',\@quotaresponse);
#is($quota{ROOT},'foobar');
#is($quota{STORAGE}[0],2);
#is($quota{STORAGE}[1],25000);