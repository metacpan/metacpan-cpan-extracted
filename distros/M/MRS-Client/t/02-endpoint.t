#!perl -T

#use Test::More qw(no_plan);
use Test::More tests => 25;

BEGIN {
    use_ok ('MRS::Client');
}
diag( "Setting host and endpoints" );

#
# these tests do not need access to the network
#

# setting default endpoints
my $client = MRS::Client->new();
is ($client->search_url, $client->DEFAULT_SEARCH_ENDPOINT,   'Default search_url');
is ($client->blast_url, $client->DEFAULT_BLAST_ENDPOINT,     'Default blast_url');
is ($client->clustal_url, $client->DEFAULT_CLUSTAL_ENDPOINT, 'Default clustal_url');
is ($client->admin_url, $client->DEFAULT_ADMIN_ENDPOINT,     'Default admin_url');

# setting endpoints from environment variables
$ENV{'MRS_SEARCH_URL'}  = 'a';
$ENV{'MRS_BLAST_URL'}   = 'b';
$ENV{'MRS_CLUSTAL_URL'} = 'c';
$ENV{'MRS_ADMIN_URL'}   = 'd';
$client = MRS::Client->new();
is ($client->search_url,  'a',   'ENVAR search_url');
is ($client->blast_url,   'b',   'ENVAR blast_url');
is ($client->clustal_url, 'c',   'ENVAR clustal_url');
is ($client->admin_url,   'd',   'ENVAR admin_url');
delete $ENV{'MRS_SEARCH_URL'};
delete $ENV{'MRS_BLAST_URL'};
delete $ENV{'MRS_CLUSTAL_URL'};
delete $ENV{'MRS_ADMIN_URL'};

# mixed setting endpoints and host
$client = MRS::Client->new (search_url  => 'k',
                            blast_url   => 'l',
                            clustal_url => 'm',
                            admin_url   => 'n',
                            host        => 'myhost');
is ($client->search_url,  'k', 'new search_url and host');
is ($client->blast_url,   'l', 'new blast_url and host');
is ($client->clustal_url, 'm', 'new clustal_url and host');
is ($client->admin_url,   'n', 'new admin_url and host');

$client = MRS::Client->new (host        => 'myhostess',
                            search_url  => 'k',
                            blast_url   => 'l',
                            clustal_url => 'm',
                            admin_url   => 'n');
is ($client->search_url,  'k', 'new host and search_url');
is ($client->blast_url,   'l', 'new host and blast_url');
is ($client->clustal_url, 'm', 'new host and clustal_url');
is ($client->admin_url,   'n', 'new host and admin_url');

# replacing host by another host
$client = MRS::Client->new (host => 'myhost1');
$client->host ('myhost2');
is ($client->search_url,  'http://myhost2:18081/', 'Replacing host and search_url');
is ($client->blast_url,   'http://myhost2:18082/', 'Replacing host and blast_url');
is ($client->clustal_url, 'http://myhost2:18083/', 'Replacing host and clustal_url');
is ($client->admin_url,   'http://myhost2:18084/', 'Replacing host and admin_url');

$client = MRS::Client->new (host => 'myhostess1');
$client ->search_url  ('a priority endpoint');
$client ->blast_url   ('b priority endpoint');
$client ->clustal_url ('c priority endpoint');
$client ->admin_url   ('d priority endpoint');
$client->host ('myhostess2');
is ($client->search_url,  'a priority endpoint', 'Priority of search_url');
is ($client->blast_url,   'b priority endpoint', 'Priority of blast_url');
is ($client->clustal_url, 'c priority endpoint', 'Priority of clustal_url');
is ($client->admin_url,   'd priority endpoint', 'Priority of admin_url');
