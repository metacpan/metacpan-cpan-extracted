use Test::More tests => 9;

use HTTP::Cookies::Chrome;
use File::Spec::Functions;

my $file = catfile( qw( test-corpus Cookies ) );

my %Domains = qw( 
	.bing.com      5 
	www.bing.com   1 
	.google.fr     2 
	.www.yahoo.com 1 
	.yahoo.com     2 
	.fr.yahoo.com  3 
	);

my $jar = HTTP::Cookies::Chrome->new( File => $file );
isa_ok( $jar, 'HTTP::Cookies::Chrome' );
ok( exists $jar->{COOKIES}, "The COOKIES key is in the jar" );

my $hash = $jar->{COOKIES};

my $domain_count = keys %$hash;
is( $domain_count, scalar keys %Domains, 'Count of domains is right' );

foreach my $domain ( keys %Domains )
	{
	my $domain_hash  = $hash->{ $domain }{ '/' };
	my $count        = keys %$domain_hash;
	is( $count, $Domains{$domain}, "$domain has $count cookies" ); 	
	}
