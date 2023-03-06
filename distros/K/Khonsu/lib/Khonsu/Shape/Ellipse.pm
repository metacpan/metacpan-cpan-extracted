package Khonsu::Shape::Ellipse;

use parent 'Khonsu::Shape';

sub shape {
	my ($self, $file, $shape, %args) = @_;
	my $box = $shape->ellipse($args{x} + $args{w}, $file->page->h - ($args{y} + $args{h}), $args{w}, $args{h});
	$box->fillcolor($args{fill_colour});
	$box->fill;
}

1;
