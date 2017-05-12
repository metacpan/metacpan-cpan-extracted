#!perl -T

use Test::More tests => 32;

diag( "Testing HTTP::ProxySelector::Persistent $HTTP::ProxySelector::Persistent::VERSION, Perl $], $^X" );

BEGIN {
  use_ok( 'LWP::UserAgent' );
  use_ok( 'BerkeleyDB' );
  use_ok( 'Date::Manip' );
  use_ok( 'HTTP::ProxySelector::Persistent' );
  use_ok( 'Cwd' );
}

my $db_file = getcwd() . "/proxy_cache.bdb";
( $db_file ) = ( $db_file =~ /(.*)/s ); # untaint the cache database filename so I can delete it later
# Remove the cache database file if it is present
if (-e $db_file ) { unlink $db_file; }

# download a proxylist that contains a mix of IP and named proxy servers and verify that we parsed it correctly
ok( my $selector = HTTP::ProxySelector::Persistent->new( db_file => $db_file, sites => ['http://www.multiproxy.org/txt_anon/proxy.txt'] ), 
    "Instantiated the HTTP::ProxySelector::Persistent object for the proxylist parsing test" );
isa_ok( $selector, HTTP::ProxySelector::Persistent, "HTTP::ProxySelector::Persistent->new(): Errors: $selector" );
ok( -e $db_file, "The HTTP::ProxySelector::Persistent->new() call created a new proxy database file" );
tie my %h, "BerkeleyDB::Hash", -Filename => $db_file or die "Cannot open cache database file $db_file: $! $BerkeleyDB::Error\n";

ok( my $ua = LWP::UserAgent->new( timeout => 10 ), "Constructed the LWP::UserAgent used to check the proxies parsed by the HTTP::ProxySelector::Persistent" );
my $response = $ua->get( 'http://www.multiproxy.org/txt_anon/proxy.txt' );
ok( $response->is_success(), "Successfully downloaded the verification copy of the 1st proxylist" );
my @verification_proxies = $response->content() =~ m#(\n)#g;
is( scalar( keys( %h ) ) - 1, scalar ( @verification_proxies ), "Cache database contains the same number of proxy servers as the verification proxy list copy" );

# Unit tests: set_proxy( $ua ) method
ok( my $status = $selector->set_proxy( $ua ), "Attempt to set the proxy, capturing status in \$status" );
ok( $status, "\$selector->set_proxy( \$ua ) did not error out." );
warn $selector->error() unless $status;
ok( $result = $ua->get( "http://www.yahoo.com" ), "Manual proxy test part one: downloaded www.yahoo.com" );
ok( $result->is_success(), "The HTTP download using the proxy returned a success" );

# Force the new() call to requery the proxy lists cos the cache is too old and see if it does
my $expired_date = DateCalc( "today", "-20 minutes" );
foreach my $key ( keys( %h ) ) {
  if ( $key eq "date" ) {
    $h{"date"} = $expired_date;
  }
  else {
    delete $h{ $key };
  }
}
ok( untie %h, "Untied the hash from the BerkeleyDB" );
ok( $selector = HTTP::ProxySelector::Persistent->new( db_file => $db_file, sites => ['http://www.multiproxy.org/txt_anon/proxy.txt'] ), 
    "Instantiated the HTTP::ProxySelector::Persistent object for the expired cache test" );
tie %h, "BerkeleyDB::Hash", -Filename => $db_file or die "Cannot open cache database file $db_file: $! $BerkeleyDB::Error\n";
is( scalar( keys( %h ) ) - 1, scalar ( @verification_proxies ), "The rebuilt cache database contains the same number of proxy servers as the verification proxy list copy" );
ok( Date_Cmp( $expired_date, $h{"date"}) < 0, "The date/timestamp from the rebuilt cache database is newer than the expired date/timestamp" );
ok( untie %h, "Untied the hash from the BerkeleyDB" );

# Verify that we can extract proxy servers from oddly formatted HTML documents using nonstandard port annotation
ok( unlink $db_file, "Deleted the cache database file in preparation for the oddly formatted HTML extraction test" );
ok( $selector = HTTP::ProxySelector::Persistent->new( db_file => $db_file, sites => ['http://www.samair.ru/proxy/fresh-proxy-list.htm'] ), 
    "Instantiated the HTTP::ProxySelector::Persistent object for the oddly formatted HTML proxy list test" );
isa_ok( $selector, HTTP::ProxySelector::Persistent, "HTTP::ProxySelector::Persistent->new(): Errors: $selector" );
tie %h, "BerkeleyDB::Hash", -Filename => $db_file or die "Cannot open cache database file $db_file: $! $BerkeleyDB::Error\n";
ok( scalar( keys( %h ) ) > 1, "We successfully extracted at least one proxy server server from the oddly formatted samair.ru HTML list." );
ok( untie %h, "Untied the hash from the BerkeleyDB" );

# Download a bad proxylist (where none of the servers are valid proxies) and verify that HTTP::ProxySelector::Persistent fails to return any proxies and errors out properly
ok( unlink $db_file, "Deleted the cache database file in preparation for bad proxy server list test" );
ok( $selector = HTTP::ProxySelector::Persistent->new( db_file => $db_file, sites => ['http://trowbridge.dreamhosters.com/bad_proxies.txt'] ), 
    "Instantiated the HTTP::ProxySelector::Persistent object for the bad proxy server list test" );
isa_ok( $selector, HTTP::ProxySelector::Persistent, "HTTP::ProxySelector::Persistent->new(): Errors: $selector" );
tie %h, "BerkeleyDB::Hash", -Filename => $db_file or die "Cannot open cache database file $db_file: $! $BerkeleyDB::Error\n";
is( scalar( keys( %h ) ), 3, "We successfully extracted two proxy servers from bad_proxies.txt" );
ok( untie %h, "Untied the hash from the BerkeleyDB" );
ok( ! defined $selector->set_proxy( $ua ), "Proxy selector should error out cos the proxy tests failed for all proxies in bad_proxies.txt" );
ok( !( -e $db_file ), "The proxy selector deleted the cache database because it was empty after deleting all proxy servers that failed the test" );
