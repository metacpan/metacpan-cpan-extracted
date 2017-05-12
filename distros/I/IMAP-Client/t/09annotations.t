use Test::More tests => 13;

use strict;

use IMAP::Client;

my $client = IMAP::Client->new;

my @getannotation_response = ('* ANNOTATION "user.emailj" "/vendor/cmu/cyrus-imapd/lastupdate" ("value.shared" "19-Sep-2006 12:51:07 -0400" "content-type.shared" "text/plain" "size.shared" "26")'."\r\n",
'* ANNOTATION "user.emailj" "/vendor/cmu/cyrus-imapd/size" ("value.shared" "4424" "content-type.shared" "text/plain" "size.shared" "4")'."\r\n",
'* ANNOTATION "user.emailj" "/vendor/cmu/cyrus-imapd/partition" ("value.shared" "default" "content-type.shared" "text/plain" "size.shared" "7")'."\r\n",
'* ANNOTATION "user.emailj" "/vendor/cmu/cyrus-imapd/server" ("value.shared" "imapbackend.server1.com" "content-type.shared" "text/plain" "size.shared" "23")'."\r\n",
'. OK Completed'."\r\n",);

my %resp = IMAP::Client::parse_annotation(\@getannotation_response ,'user.emailj',$client);

is (scalar (keys %resp), 1);
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/size'}->{'VALUE.SHARED'}, 4424);
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/size'}->{'CONTENT-TYPE.SHARED'}, "text/plain");
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/size'}->{'SIZE.SHARED'}, 4);
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/lastupdate'}->{'VALUE.SHARED'}, '19-Sep-2006 12:51:07 -0400');
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/lastupdate'}->{'CONTENT-TYPE.SHARED'}, 'text/plain');
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/lastupdate'}->{'SIZE.SHARED'}, 26);
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/partition'}->{'VALUE.SHARED'}, 'default');
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/partition'}->{'CONTENT-TYPE.SHARED'}, 'text/plain');
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/partition'}->{'SIZE.SHARED'}, 7);
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/server'}->{'VALUE.SHARED'}, 'imapbackend.server1.com');
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/server'}->{'CONTENT-TYPE.SHARED'}, 'text/plain');
is ($resp{'user.emailj'}->{'/vendor/cmu/cyrus-imapd/server'}->{'SIZE.SHARED'}, 23);



