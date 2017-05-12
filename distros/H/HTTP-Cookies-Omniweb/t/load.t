use Test::More tests => 5;

use HTTP::Cookies::Omniweb;

my %Domains = qw( .ebay.com 1 .usatoday.com 3 );

my $jar = HTTP::Cookies::Omniweb->new( File => 't/Cookies.xml' );
isa_ok( $jar, 'HTTP::Cookies::Omniweb' );

my $hash = $jar->{COOKIES};

my $domain_count = keys %$hash;
is( $domain_count, 2, 'Count of domains' );

foreach my $domain ( keys %Domains )
	{
	my $domain_hash  = $hash->{ $domain }{ '/' };
	my $count        = keys %$domain_hash;
	is( $count, $Domains{$domain}, "$domain has $count cookies" ); 	
	}

is( $hash->{'.ebay.com'}{'/'}{'lucky9'}[1], '196606', 'Cookie has right value' );
