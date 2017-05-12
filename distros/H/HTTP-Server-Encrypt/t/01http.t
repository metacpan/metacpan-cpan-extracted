use LWP::UserAgent;
use Test::More;
use HTTP::Server::Encrypt qw(http_server_start);
plan tests => 3;

my %http_conf;
$http_conf{'port'} = 1024;
$http_conf{'username'} = 'username';
$http_conf{'passwd'} = 'passwd';
$http_conf{'min_spare'} = 2;
$http_conf{'max_spare'} = 6;
$http_conf{'static_expires_secs'} = 7200;
$http_conf{'docroot'} = 'htdocs/';
$http_conf{'log_dir'} = 'no';
#$http_conf{'blowfish_key'} = $key;
#$http_conf{'blowfish_encrypt'} = 'yes';
#$http_conf{'blowfish_decrypt'} = 'yes';
#$http_conf{'ip_allow'} = \%ip_allow;
#$http_conf{'ip_deny'} = \%ip_deny;

my $parent = fork();
unless($parent)
{
    http_server_start(\%http_conf);
    exit 1;
}

my $pidfile = __FILE__ . ".pid";
for(1..9)
{
    last if -s $pidfile;
    sleep 1;
}
open my $fh,"<",$pidfile;
my $pid = <$fh>;
close $fh;

my $ua = LWP::UserAgent->new;
$ua->timeout(9);
my $url;
my $response;

$url = "http://127.0.0.1:1024/index.html";
$response = $ua->get($url);
is($response->code, 401, "Response has HTTP Base Authorization (401) status");

$ua->credentials( "127.0.0.1:1024", "Colonel Authentication System", "username", "passwd" );
$response = $ua->get($url);
is($response->code, 200, "Response has HTTP OK (2xx) status");

$url = "http://127.0.0.1:1024/page_no_found";
$response = $ua->get($url);
is($response->code, 404, "Response has HTTP Not Found (404) status");

kill TERM => $pid;
1;
