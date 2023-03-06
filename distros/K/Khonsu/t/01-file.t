use Khonsu;

my $khonsu = Khonsu->new(
	'test',
	page_size => 'A4',
	page_args => {
		background => '#3ff'
	}
)->add_page;

$khonsu->add_box(
	fill_colour => '#000',
	x => 20, 
	y => 20, 
	w => 100, 
	h => 100 
);


$khonsu->add_line(
	fill_colour => '#000',
	x => 140, 
	y => 20, 
	ex => 240,
	ey => 20 
);

$khonsu->add_circle(
	fill_colour => '#000',
	x => 260,
	y => 20,
	r => 50
);

$khonsu->add_pie(
	fill_colour => '#000',
	x => 380,
	y => 20,
	r => 50,
	rx => 360,
	ry => 40
);


$khonsu->add_pie(
	fill_colour => '#fff',
	x => 380,
	y => 20,
	r => 50,
	rx => 400,
	ry => 360
);

$khonsu->add_ellipse(
	fill_colour => '#000',
	x => 500,
	y => 20,
	w => 30,
	h => 50
);

$khonsu->add_text( 
	text => 'This is a test ' x 24,
	x => 20,
	y => 120,
	w => 100,
	h => 100,
);

$khonsu->add_text( 
	text => 'This is a test ' x 24,
	x => 140,
	y => 120,
	w => 100,
	h => 100,
);


$khonsu->add_text( 
	text => 'This is a test ' x 24,
	x => 260,
	y => 120,
	w => 100,
	h => 100,
);

$khonsu->add_text( 
	text => 'This is a test ' x 24,
	x => 380,
	y => 120,
	w => 100,
	h => 100,
);

$khonsu->add_h1(
	text => 'This is a test',
	x => 20,
	y => 240,
	w => 500,
);

$khonsu->add_h2(
	text => 'This is a test',
	x => 20,
	y => 270,
	w => 500,
);

$khonsu->add_h3(
	text => 'This is a test',
	x => 20,
	y => 300,
	w => 500,
);

$khonsu->add_h4(
	text => 'This is a test',
	x => 20,
	y => 325,
	w => 500,
);

$khonsu->add_h5(
	text => 'This is a test',
	x => 20,
	y => 342,
	w => 500,
);

$khonsu->add_h6(
	text => 'This is a test',
	x => 20,
	y => 358,
	w => 500,
	h => 20,
);


my @words = ('Aker', 'Anubis', 'Hapi', 'Khepri', 'Maahes', 'Thoth', 'Bastet', 'Hatmehit', 'Tefnut', 'Menhit', 'Imentet');

my $generate_text = sub {
	my $length = shift;
	return join " ", map { $words[int(rand(scalar @words))] } 1 .. $length;
};

$khonsu->add_page(
	background => '#000',
)->add_h1(
	text => $generate_text->(3),
	x => 20,
	y => 20,
	w => $khonsu->page->w - 40,
	font => {
		colour => '#fff'
	}
)->add_text(
	text => $generate_text->(2000),
	x => 20,
	y => 70,
	w => $khonsu->page->w - 40,
	h => $khonsu->page->h - 110,
	indent => 4,
	font => {
		colour => '#fff'
	},
	overflow => 1,
);

$khonsu->save();

