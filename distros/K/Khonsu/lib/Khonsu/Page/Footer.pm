package Khonsu::Page::Footer;

use parent 'Khonsu::Page::Header';

sub render {
	my ($self, $file) = @_;
	return unless $self->active();
	my $y = ($file->page->h - $self->h) + (($self->h / 2) - ($self->font->size / 2)); 
	my $w = $file->page->w - ($self->padding ? ( $self->padding * 2 ) : $self->padding);
	my $x = $self->padding || 0;
	if ($self->show_page_num) {
		$self->add(
			$file,
			text => $self->process_page_num_text($file),
			y => $y,
			w => $w,
			x => $x,
			h => $self->h,
			align => $self->show_page_num
		);
	}

	$self->cb->(
		$self,
		$file,
		y => $y,
		w => $w,
		x => $x,
		h => $self->h,
	) if ($self->cb);
}

1;
