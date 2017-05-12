use Graphics::Simple;

# First, three lines

line(50,50,150,150);
line(10,10,290,10);
line(10,290,290,290);

# Wait and clear the screen

stop(); clear();

# Then, a circle

color('green');
circle(50,50,25);
color('red');
arrow(10,10,100,70);

stop(); 

$w2 = new_window(400,400);
$w2->color('green');
$w2->circle(200,200,100);

for(0..300) {
	line_to($_, 50*sin($_/10) + 100);
}
line_to();

for(0..50) {
	$w2->color([$_/50,0,1-$_/50]);
	$w2->line(100, 100+4*$_, 100+4*$_, 300);
}

for my $x (30,90,150,260) {
	for my $y (40, 80, 105, 300) {
		text($x,$y,"T$x,$y");
	}
}
