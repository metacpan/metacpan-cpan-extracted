package Khonsu::Shape::Pie;

use parent 'Khonsu::Shape';

sub shape {
	my ($self, $file, $shape, %args) = @_;
	my $box = $shape->pie($args{x} + $args{r}, $file->page->h - ($args{y} + $args{r}), $args{r}, $args{r}, $args{rx}, $args{ry});
	$box->fillcolor($args{fill_colour});
	$box->fill;
}

1;
