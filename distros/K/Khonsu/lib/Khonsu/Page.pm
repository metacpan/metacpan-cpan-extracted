package Khonsu::Page;

use parent 'Khonsu::Ra';

sub attributes {
	my $a = shift;
	return (
		page_size => {$a->RW, $a->REQ, $a->STR},
		background => {$a->RW, $a->STR},
		num => {$a->RW, $a->REQ, $a->NUM},
		current => {$a->RW, $a->OBJ},
		columns => {$a->RW, $a->NUM, default => sub { 1 }},
		column => {$a->RW, $a->NUM, default => sub { 1 }},
		rows => {$a->RW, $a->NUM, default => sub { 1 }},
		row => {$a->RW, $a->NUM, default => sub { 1 }},
		is_rotated => {$a->RW, $a->NUM},
		header => {$a->RW, $a->Object},
		footer => {$a->RW, $a->Object},
		$a->POINTS,
		$a->BOX,
	);
}

sub add {
	my ($self, $file, %args) = @_;
	my $page = $args{open} ? $file->pdf->openpage($args{num}) : $file->pdf->page($args{num} || 0);
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

1;
