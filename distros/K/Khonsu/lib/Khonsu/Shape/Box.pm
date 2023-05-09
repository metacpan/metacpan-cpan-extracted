package Khonsu::Shape::Box;

use parent 'Khonsu::Shape';

sub shape {
	my ($self, $file, $shape, %args) = @_;
	my $box = $shape->rect($args{x}, $file->page->h - ($args{y} + $args{h}), $args{w}, $args{h});
	$box->fillcolor($args{fill_colour}) unless $args{fill_colour} eq 'transparent';
	$box->fill;
}

1;
