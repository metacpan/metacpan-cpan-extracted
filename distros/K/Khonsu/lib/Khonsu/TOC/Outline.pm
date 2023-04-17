package Khonsu::TOC::Outline;

use parent 'Khonsu::Text';

sub attributes {
	my $a = shift;
	return (
		$a->SUPER::attributes(),
		page => {$a->RW, $a->OBJ},
		outline => {$a->RW, $a->OBJ},
		outline_position => {$a->RW, $a->DHR},
		end_y => {$a->RW, $a->NUM},
		level => {$a->RW, $a->NUM},
		children => {$a->RW, $a->DAR},
	);
}

sub add {
	my ($self, $file, $outline, %attributes) = @_;
	$self->set_attributes(%attributes);	
	my %position = $self->get_points();
	$position{y} = $file->page->h - $position{y};
	$self->outline_position(\%position);
	$outline = $outline->outline()->open()
		->title($self->text)
		->dest($self->page->current, '-xyz' => [$position{x}, $position{y}, 0]);
	$self->outline($outline);
	return $file;
}

sub render {
	my ($self, $file, %attributes) = @_;
	$self->set_attributes(
		pad => '.',
		pad_end => $self->page->num + $attributes{page_offset},
		%attributes
	);
	$self->SUPER::add($file);	
	my %position = $self->get_points();
	my $outline_position = $self->outline_position;
	$attributes{y} = $position{y} + $self->font->size;
	$position{y} = $file->page->h - $position{y};
	my $annotation = $file->page->current->annotation()->rect(
		$position{x}, $position{y}, $position{w}, $position{y} - $self->font->size
	)->link($self->page->current, '-xyz' => [$outline_position->{x}, $outline_position->{y}, 0]);
	my $y = $attributes{y};
	my $num = $attributes{num};
	for (@{$self->children}) {
		$y += $attributes{padding};
		if ($y > $file->page->h - ($file->page->footer ? $file->page->footer->h : 0)) {
			$file->open_page($num->(1));
			$y = $file->page->header ? $file->page->header->h : 0;
		}
		$_->render($file, %attributes, y => $y);
		$y = $_->end_y;
	}
	$self->end_y($y);
}

1;
