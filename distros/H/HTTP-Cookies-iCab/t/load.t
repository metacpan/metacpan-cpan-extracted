use Test::More tests => 8;

use_ok( 'HTTP::Cookies::iCab' );

my %Domains = qw( .cnn.com 1 .usatoday.com 3 .doubleclick.net 1 );

my $jar = HTTP::Cookies::iCab->new( File => 't/Cookies.dat' );
isa_ok( $jar, 'HTTP::Cookies::iCab' );
isa_ok( $jar, 'HTTP::Cookies' );

my $hash = $jar->{COOKIES};

my $domain_count = keys %$hash;
is( $domain_count, 3, 'Count of domains' );

foreach my $domain ( keys %Domains ) {
	my $domain_hash  = $hash->{ $domain }{ '/' };
	my $count        = keys %$domain_hash;
	is( $count, $Domains{$domain}, "$domain has $count cookies" ); 	
	}

is( 
	$hash->{'.cnn.com'}{'/'}{'CNNid'}[1], 
	'8b990c1a-20494-1039716453-329', 
	'Cookie has right value' 
	);
