#!perl -T

use Test::More tests => 14;

diag( "Testing HTTP::ProxySelector::Persistent $HTTP::ProxySelector::Persistent::VERSION, Perl $], $^X" );

BEGIN {
  use_ok( 'LWP::UserAgent' );
  use_ok( 'BerkeleyDB' );
  use_ok( 'HTTP::ProxySelector::Persistent' );
  use_ok( 'Cwd' );
}

my $db_file = getcwd() . "/proxy_cache.bdb";
( $db_file ) = ( $db_file =~ /(.*)/s ); # untaint the cache database filename so I can delete it later
# Remove the cache database file if it is present
if (-e $db_file ) { unlink $db_file; }

my $testsite = "http://www.google.com";
my $ua = LWP::UserAgent->new( timeout => 5, agent => "HTTP::ProxySelector::Persistent $HTTP::ProxySelector::Persistent::VERSION, Perl $], $^X" );

# download a proxylist that contains a mix of IP and dns named proxy servers and verify that we parsed it correctly
ok( my $selector = HTTP::ProxySelector::Persistent->new( db_file => $db_file, sites => ['http://www.proxy4free.com/page1.html'] ),
    "Instantiated the HTTP::ProxySelector::Persistent object for the proxylist parsing test" );
isa_ok( $selector, HTTP::ProxySelector::Persistent, "HTTP::ProxySelector::Persistent->new(): Errors: $selector" );
ok( -e $db_file, "The HTTP::ProxySelector::Persistent->new() call created a new proxy database file" );

# test proxied get with no args
ok( ! defined $selector->proxied_get()			      , "proxied_get() with no args returns undef" );
ok( $selector->error()		  			      , "proxied_get() set an error when it failed because of no url in the options" );

# test proxied get with only a url arg, default timeout and useragent
ok( my $html = $selector->proxied_get( url => $testsite )     , "proxied_get( url => \$url ) executes" );
ok( $html						      , "\$html (output of proxied_get( url => \$url ) ) is defined " );
warn $selector->error() unless $html;

# test the proxied get with the custom useragent
ok( $html = $selector->proxied_get( url => "http://whatsmyuseragent.com", ua => $ua )
							      , "proxied_get( url => \$url, ua => \$ua ) executes" );
ok( $html						      , "\$html (output of proxied_get with url and ua) is defined" );
warn $selector->error() unless $html;
like( $html, qr#Your User Agent is:.+?HTTP::ProxySelector::Persistent#is
							      , "http://whatsmyuseragent.com sees the custom useragent string" );

unlink( $db_file );
