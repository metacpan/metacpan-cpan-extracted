package Khonsu::Page;

use parent 'Khonsu::Ra';

sub attributes {
	my $a = shift;
	return (
		header => {$a->RW, $a->OBJ},
		footer => {$a->RW, $a->OBJ},
		page_size => {$a->RW, $a->REQ, $a->STR},
		background => {$a->RW, $a->STR},
		num => {$a->RW, $a->REQ, $a->NUM},
		current => {$a->RW, $a->OBJ},
		columns => {$a->RW, $a->NUM, default => sub { 1 }},
		column => {$a->RW, $a->NUM, default => sub { 1 }},
		column_y => {$a->RW, $a->NUM, default => sub {1 }},
		is_rotated => {$a->RW, $a->NUM},
		header => {$a->RW, $a->OBJ},
		footer => {$a->RW, $a->OBJ},
		toc => {$a->RW, $a->BOOL},
		padding => {$a->RW, $a->NUM},
		$a->POINTS,
		$a->BOX,
	);
}

sub add {
	my ($self, $file, %args) = @_;
	
	my $page = $args{open} ? $file->pdf->openpage($args{num} || $self->num) : $file->pdf->page($args{num} || $self->num || 0);
	$page->mediabox($self->page_size);
	$self->set_points($page->get_mediabox);

	$self->current($page);
	$self->rotate if $args{rotate};
	if ($self->background) {
		$self->box->add(
			$file,
			fill_colour => $self->background,
			$self->get_points
		);
	}

	if ($self->header) {
		$self->column_y($self->y($self->header->h));
	}

	if ($self->padding) {
		$self->x($self->padding);
	}
	return $self;
}

sub rotate {
	my ($self) = shift;
	my ($blx, $bly, $trx, $try) = $self->current->get_mediabox;
	$self->current->mediabox(
		$self->x(0),
		$self->y(0),
		$self->w($try),
		$self->h($trx),
	);
	$self->is_rotated(!$self->is_rotated);
	return $self;
}

sub render {
	my ($self, $file) = @_;
	$self->header->render($file) if $self->header;
	$self->footer->render($file) if $self->footer;

}

sub remaining_height {
	my ($self) = @_;
	return $self->h - ($self->y + ($self->footer ? $self->footer->h : 0))
}

sub width {
	my ($self) = @_;
	return ($self->w - ($self->padding * (2 + ($self->columns - 1)))) / $self->columns;
}

sub next {
	my ($self, $file) = @_;
	if ($self->column < $self->columns) {
		$self->column($self->column + 1);
		$self->x($self->x + $self->width + $self->padding);
		$self->y($self->column_y);
	} else {
		$self->column(1);
		$file->add_page();
	}
}

1;
