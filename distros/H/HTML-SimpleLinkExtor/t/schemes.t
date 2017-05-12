use File::Spec;
use Test::More 0.96;

my $file = 't/example2.html';

subtest 'Sanity check' => sub {
	use_ok( "HTML::SimpleLinkExtor" );
	ok( defined &HTML::SimpleLinkExtor::schemes, "schemes() is defined" );

	ok( -e $file, "Example file is there" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

subtest 'No base' => sub {
	my $p;

	subtest 'Create object' => sub {
		$p = HTML::SimpleLinkExtor->new;
		ok( ref $p, "Made parser object" );
		isa_ok( $p, 'HTML::SimpleLinkExtor' );
		can_ok( $p, 'schemes' );
		$p->parse_file( $file );
		};

	subtest 'All links' => sub {
		my @links = $p->links;

		is( scalar @links, 26, "Found the right number of links" );
		};


	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'HTTP' => sub {
		my @links = $p->schemes( 'http' );
		my $links = $p->schemes( 'http' );

		is( $links, 7, "Got the right number of HTTP links" );
		is( scalar @links, $links, "Found the right number of links" );
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'HTTPS' => sub{
		my @links = $p->schemes( 'https' );
		my $links = $p->schemes( 'https' );

		is( $links, 2, "Got the right number of HTTPS links" );
		is( scalar @links, $links, "Found the right number of links" );
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'HTTP & HTTPS' => sub {
		my @links = $p->schemes( qw(http https) );
		my $links = $p->schemes( qw(http https) );

		is( $links, 9, "Got the right number of HTTPS links" );
		is( scalar @links, $links, "Found the right number of links" );
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'FTP' => sub {
		my @links = $p->schemes( 'ftp' );
		my $links = $p->schemes( 'ftp' );

		is( $links, 1, "Got the right number of FTP links" );
		is( scalar @links, $links, "Found the right number of links" );
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'mailto' => sub {
		my @links = $p->schemes( 'mailto' );
		my $links = $p->schemes( 'mailto' );

		is( $links, 1, "Got the right number of MAILTO links" );
		is( scalar @links, $links, "Found the right number of links" );
		};
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

subtest 'HTTP base' => sub {
	my $p;

	subtest 'Create object' => sub {
		$p = HTML::SimpleLinkExtor->new( 'http://www.example.com' );
		ok( ref $p, "Made parser object" );
		isa_ok( $p, 'HTML::SimpleLinkExtor' );
		can_ok( $p, 'schemes' );

		$p->parse_file( $file );
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'HTTP' => sub {
		my @links = $p->schemes( 'http' );
		my $links = $p->schemes( 'http' );

		is( $links, 22, "Got the right number of HTTP links" );
		is( scalar @links, $links, "Found the right number of links" );
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'HTTP & HTTPS' => sub {
		my @links = $p->schemes( qw(http https) );
		my $links = $p->schemes( qw(http https) );

		is( $links, 24, "Got the right number of HTTPS links" );
		is( scalar @links, $links, "Found the right number of links" );
		};
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

subtest 'FTP base' => sub {
	my $p;

	subtest 'Create object' => sub {
		$p = HTML::SimpleLinkExtor->new( 'ftp://www.example.com' );
		ok( ref $p, "Made parser object" );
		isa_ok( $p, 'HTML::SimpleLinkExtor' );
		can_ok( $p, 'schemes' );

		$p->parse_file( $file );
		};

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	subtest 'FTP' => sub {
		my @links = $p->schemes( 'ftp' );
		my $links = $p->schemes( 'ftp' );

		is( $links, 16, "Got the right number of HTTP links" );
		is( scalar @links, $links, "Found the right number of links" );
		};
	};

done_testing();
