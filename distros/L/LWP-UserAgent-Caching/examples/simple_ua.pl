use LWP::UserAgent::Caching;
use CHI;

# use LWP::ConsoleLogger::Everywhere;

my $chi_cache = CHI->new(
    driver          => 'File',
    root_dir        => '/tmp/LWP_UserAgent_Caching',
    file_extension  => '.cache',
);

my $chi_cache_meta = CHI->new(
    driver          => 'File',
    root_dir        => '/tmp/LWP_UserAgent_Caching',
    file_extension  => '.cache',
    l1_cache        => {
        driver          => 'Memory',
        global          => 1,
        max_size        => 1024*1024
    }
);

my $ua = LWP::UserAgent::Caching->new(
    http_caching => {
        cache           => $chi_cache,
    #   cache_meta      => $chi_cache_meta,
        request_directives => "no-transform, add-on-top=true, max-stale", # uhm ... no-transform ???
    },
);

$ua->default_header('X-Module' => __PACKAGE__ );
$ua->default_header('Cache-Control' => 'unknown' );

$HTTP::Caching::DEBUG = 1;

my $method  = shift;
my $url     = shift;

if ($method =~ /^GET$/i ) {
print "\n#####\n";
print "\nGETTING\n";
print "\n#####\n";

    my $resp = $ua->get($url, 'Cache-Control' => 'min-fresh=30' );
    print $resp->headers->as_string;
    print "\n";
    print $resp->request()->headers()->as_string;
}
