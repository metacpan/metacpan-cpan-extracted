use File::Spec;
use Test::More 'no_plan';

my $file = 't/example2.html';
my $p;

subtest 'Sanity checks' => sub {
	use_ok( "HTML::SimpleLinkExtor" );
	ok( defined &HTML::SimpleLinkExtor::relative_links,
		"relative_links() is defined" );

	ok( -e $file, "Example file is there" );
	};

subtest 'Parser' => sub {
	$p = HTML::SimpleLinkExtor->new;
	ok( ref $p, "Made parser object" );
	isa_ok( $p, 'HTML::SimpleLinkExtor' );
	can_ok( $p, 'schemes' );

	$p->parse_file( $file );
	};


subtest 'relative links' => sub {
	my @links = $p->relative_links;
	my $links = $p->relative_links;

	is( scalar @links, $links, "Found the right number of links" );
	is( $links, 15, "Found the right number of links" );
	};
