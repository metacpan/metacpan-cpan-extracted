use Test::More 0.96;
use File::Spec;

my $file = 't/example2.html';
my $p;

subtest 'Sanity checks' => sub {
	use_ok( "HTML::SimpleLinkExtor" );
	ok( defined &HTML::SimpleLinkExtor::absolute_links,
		"relative_links() is defined" );

	ok( -e $file, "Example file is there" );
	};

subtest 'setup' => sub {
	$p = HTML::SimpleLinkExtor->new;
	ok( ref $p, "Made parser object" );
	isa_ok( $p, 'HTML::SimpleLinkExtor' );
	can_ok( $p, 'schemes' );

	$p->parse_file( $file );
	};

subtest 'absolute links' => sub {
	my @links = $p->absolute_links;
	my $links = $p->absolute_links;

	is( scalar @links, $links, "Array and scalar context get same answer" );
	is( $links, 11, "Found the right number of links" );
	};

done_testing();
