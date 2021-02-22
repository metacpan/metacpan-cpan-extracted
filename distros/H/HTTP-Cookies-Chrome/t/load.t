use Test::More;

use HTTP::Cookies::Chrome;
use File::Spec::Functions;

my $file = catfile( qw( test-corpus cookies.db ) );

my %Domains = qw(
	.google.com        12
	.youtube.com        2
	accounts.google.com 4
	ogs.google.com      1
	www.google.com      1
	);

my $password = '1fFTtVFyMq/J03CMJvPLDg==';

my $jar = HTTP::Cookies::Chrome->new(
	chrome_safe_storage_password => $password,
	file => $file
	);
isa_ok( $jar, 'HTTP::Cookies::Chrome' );
ok( exists $jar->{COOKIES}, "The COOKIES key is in the jar" );

my $hash = $jar->{COOKIES};

my $domain_count = keys %$hash;
is( $domain_count, scalar keys %Domains, 'Count of domains is right' );

foreach my $domain ( keys %Domains ) {
	my $domain_hash  = $hash->{ $domain }{ '/' };
	my $count        = keys %$domain_hash;
	is( $count, $Domains{$domain}, "$domain has $count cookies" );
	}

done_testing();
