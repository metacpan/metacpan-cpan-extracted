package Khonsu::Shape::Line;

use parent 'Khonsu::Shape';

sub shape {
	my ($self, $file, $shape, %args) = @_;
	$shape->strokecolor($args{fill_colour});
	$shape->move($args{x}, $file->page->h - ($args{y} + 1));
	if ($args{dash}) {
		$shape->linedash(@{$args{dash}});
	} elsif ($args{type} eq 'dots') {
		$shape->linedash(1, 1);
	} elsif ($args{type} eq 'dashed') {
		$shape->linedash(5, 5);
	}
	$shape->linejoin();
	$shape->line($args{ex}, $file->page->h - ($args{ey} + 1));
	$shape->stroke;
}

1;
