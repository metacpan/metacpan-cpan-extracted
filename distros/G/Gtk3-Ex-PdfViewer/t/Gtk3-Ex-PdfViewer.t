use Gtk3 '-init';
use Test::More;


BEGIN { use_ok( 'Gtk3::Ex::PdfViewer' ); }
require_ok( 'Gtk3::Ex::PdfViewer' );

my $viewer = new_ok( 'Gtk3::Ex::PdfViewer' );
my $window = Gtk3::Window->new( 'toplevel' );

$window->add( $viewer->widget );
pass( 'Widget built' );

subtest 'PDF file' => sub {
	$viewer->show_file( 't/test.pdf' );
	pass( 'show_file and show_blob' );
	is( $viewer->pages, 2, 'Number of pages' );

	subtest 'Initial page' => sub {
		is( $viewer->page(), 1, 'Page number' );
		is( $viewer->page_of->get_text, '1 / 2', 'Page of' );
	};

	subtest 'Past end' => sub {
		is( $viewer->page( 999 ), 2, 'Page number' );
		is( $viewer->page_of->get_text, '2 / 2', 'Page of' );
	};

	subtest 'Before start' => sub {
		is( $viewer->page(  -1 ), 1, 'Page number' );
		is( $viewer->page_of->get_text, '1 / 2', 'Page of' );
	};
};

subtest 'Navigation' => sub {
	subtest 'Next page' => sub {
		$viewer->next->clicked();
		is( $viewer->page(), 2, 'Page number' );
		is( $viewer->page_of->get_text, '2 / 2', 'Page of' );
	};

	subtest 'Previous page' => sub {
		$viewer->previous->clicked();
		is( $viewer->page(), 1, 'Page number' );
		is( $viewer->page_of->get_text, '1 / 2', 'Page of' );
	};
};

subtest 'clear' => sub {
	$viewer->clear;
	is( $viewer->pages, 0, 'No pages' );
	subtest 'Initial page' => sub {
		is( $viewer->page(), 0, 'Page number' );
		is( $viewer->page_of->get_text, '0 / 0', 'Page of' );
	};

	subtest 'Next page' => sub {
		$viewer->next->clicked();
		is( $viewer->page(), 0, 'Page number' );
		is( $viewer->page_of->get_text, '0 / 0', 'Page of' );
	};

	subtest 'Previous page' => sub {
		$viewer->previous->clicked();
		is( $viewer->page(), 0, 'Page number' );
		is( $viewer->page_of->get_text, '0 / 0', 'Page of' );
	};
};

done_testing;
