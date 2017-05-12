use Test::More tests => 5;

use HTTP::Cookies::Safari;

my %Domains = qw( .cnn.com 1 .usatoday.com 3 );

my $jar = HTTP::Cookies::Safari->new( File => 't/Cookies.plist' );
isa_ok( $jar, 'HTTP::Cookies::Safari' );

my $hash = $jar->{COOKIES};

my $domain_count = keys %$hash;
is( $domain_count, 2, 'Count of domains' );

foreach my $domain ( keys %Domains )
	{
	my $domain_hash  = $hash->{ $domain }{ '/' };
	my $count        = keys %$domain_hash;
	is( $count, $Domains{$domain}, "$domain has $count cookies" ); 	
	}

is( $hash->{'.cnn.com'}{'/'}{'CNNid'}[1], '18c15c9e-1045-1041996715-381', 
	'Cookie has right value' );
