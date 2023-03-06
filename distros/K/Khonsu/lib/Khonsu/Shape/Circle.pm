package Khonsu::Shape::Circle;

use parent 'Khonsu::Shape';

sub shape {
	my ($self, $file, $shape, %args) = @_;
	my $circle = $shape->circle($args{x} + $args{r}, $file->page->h - ($args{y} + $args{r}), $args{r});
	$circle->fillcolor($args{fill_colour});
	$circle->fill;
}

1;
