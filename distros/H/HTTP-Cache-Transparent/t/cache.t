use strict;
use warnings;
use Test::More;
use Test::RequiresInternet ('www.example.com' => 80);

use File::Temp 'tempdir';
use LWP::Simple;
use HTTP::Cache::Transparent;

my $TMPDIR = undef;

# URL of static web content to be retrieved. 
my $url = 'http://www.example.com';

# First locate some suitable tmp-dir.  We need an absolute path.
# Will be cleaned up once test has completed.
for my $dir (tempdir( CLEANUP => 1 ))
{
  if ( open(my $fh, '>', "$dir/test-$$"))
  {
    close($fh);
    unlink("$dir/test-$$");
    $TMPDIR = $dir;
    last;
  }
}

if ( $TMPDIR )
{
  $TMPDIR =~ tr|\\|/|;
  plan tests => 8;
}
else
{
  plan skip_all => 'Cannot test without a suitable TMP Directory';
}

my $ua = LWP::UserAgent->new;

# Create cache in temporary directory with a NoUpdate time of 10 secs
HTTP::Cache::Transparent::init( { BasePath => $TMPDIR,
                                   NoUpdate => 10 } );

# Cache empty. Fetch the URL directly from the server
my $r_init   = $ua->get($url);

# Check all headers are undef
is (defined $r_init->header('X-Cached'),            '',            'x-cached header should be undef when retrieving directly from server');
is (defined $r_init->header('X-Content-Unchanged'), '', 'x-content-unchanged header should be undef when retrieving directly from server');
is (defined $r_init->header('X-No-Server-Contact'), '', 'x-no-server-contact header should be undef when retrieving directly from server');

# URL Cached and within NoUpdate time. Fetching URL again should return directly from cache
my $r_cached = $ua->get($url);

# Check all headers are set
is (defined $r_cached->header('X-Cached'),            1,            'x-cached header should be set when retrieving directly from cache');
is (defined $r_cached->header('X-Content-Unchanged'), 1, 'x-content-unchanged header should be set when retrieving directly from cache');
is (defined $r_cached->header('X-No-Server-Contact'), 1, 'x-no-server-contact header should be set when retrieving directly from cache');

# Wait for NoUpdate time to expire. 
sleep 10;

# URL Cached but outside NoUpdate time. Server should be sent conditional GET before (unchanged) content is returned from cache
my $r_server = $ua->get($url);

# Check X-Cached & X-Content-Unchanged headers are set but X-No-Server-Contact is undef
# Setting of X-Cached header apparently difficult to predict and seems to vary from ISP to ISP. Seems to interact with X-Cache header...
#is (defined $r_server->header('X-Cached'),            1,              'x-cached header should be set when retrieving from cache after HTTP 304 from server');
is (defined $r_server->header('X-Content-Unchanged'),  1,   'x-content-unchanged header should be set when retrieving from cache after HTTP 304 from server');
is (defined $r_server->header('X-No-Server-Contact'), '', 'x-no-server-contact header should be undef when retrieving from cache after HTTP 304 from server');
