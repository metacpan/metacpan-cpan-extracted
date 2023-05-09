use Test::More;

use Khonsu;

my $khonsu = Khonsu->new(
	'test',
	page_size => 'A4',
	page_args => {
		padding => 20,
		background => '#3ff'
	},
	configure => {
		page_header => {
			padding => 20,
			show_page_num => 'right',
			page_num_text => 'page {num}',
			h => 20,
			cb => sub {
				my ($self, $file, %atts) = @_;
				$self->add(
					$file,
					text => 'Khonsu',
					align => 'center',
					%attrs,
				);
			}
		},
		page_footer => {
			padding => 20,
			show_page_num => 'left',
			page_num_text => 'page {num}',
			h => 20,
			cb => sub {
				my ($self, $file, %atts) = @_;
				$self->add(
					$file,
					text => 'Khonsu',
					align => 'center',
					%attrs,
				);
			}
		},
		toc => {
			title => 'Table of contents',
			title_font_args => {
				size => 50,
			},
			title_padding => 10,
			font_args => {
				size => 20,
			},
			padding => 5,
		},
		h1 => {
			font => { colour => '#0EE' }
		}
	}
);

$khonsu->remove_page_header_and_footer(1)->add_image(
	image => 't/test.png',
	x => 20,
	y => 20,
	w => $khonsu->page->w - 40,
	h => $khonsu->page->h - 40,
)->add_page;

$khonsu->add_toc();

$khonsu->add_h1(
	text => 'A Title',
	toc => 1
);

$khonsu->add_text( 
	text => 'This is a test ' x 204,
);

$khonsu->add_image(
	image => 't/test.png',
	align => 'center',
	w => 300,
	h => 300
);

$khonsu->add_text( 
	text => 'This is a test ' x 204,
);

$khonsu->add_text( 
	text => 'This is a test ' x 234,
);

$khonsu->add_text( 
	text => 'This is a test ' x 2004,
);

$khonsu->add_h2(
	text => 'A simple form',
	toc => 1,
);

$khonsu->add_input(
	text => 'Name:'
);

$khonsu->add_select(
	text => 'Colour:',
	options => [qw/red yellow green/]
);

$khonsu->save();

ok(1);

done_testing();

