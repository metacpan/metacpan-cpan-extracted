use lib qw(t/lib);
use Test::More;
use TestUtils;

my %Domains = qw(
	.google.com        12
	.youtube.com        2
	accounts.google.com 4
	ogs.google.com      1
	www.google.com      1
	);

sanity_subtest();

my $jar;
subtest 'new jar' => sub {
	$jar = new_jar();
	isa_ok( $jar, class() );
	ok( exists $jar->{COOKIES}, "The COOKIES key is in the jar" );
	};

subtest 'domain counts' => sub {
	my $hash = $jar->{COOKIES};

	my $domain_count = keys %$hash;
	is( $domain_count, scalar keys %Domains, 'Count of domains is right' );

	foreach my $domain ( keys %Domains ) {
		my $domain_hash  = $hash->{ $domain }{ '/' };
		my $count        = keys %$domain_hash;
		is( $count, $Domains{$domain}, "$domain has $count cookies" );
		}
	};

done_testing();
