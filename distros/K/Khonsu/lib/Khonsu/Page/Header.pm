package Khonsu::Page::Header;

use parent 'Khonsu::Text';

sub attributes {
	my ($a) = shift;
	return (
		$a->SUPER::attributes(),
		active => {$a->RW, $a->BOOL, default => sub { 1 }},
		show_page_num => {$a->RW, $a->STR},
		page_num_text => {$a->RW, $a->STR},
		padding => {$a->RW, $a->NUM},
		cb => {$a->RW, $a->CODE},  				
	);
}

sub render {
	my ($self, $file) = @_;
	return unless $self->active;
	my $y = ($self->h / 2) - ($self->font->size / 2);
	my $w = $file->page->w - ($self->padding ? ( $self->padding * 2 ) : $self->padding);
	my $x = $self->padding || 0;

	if ($self->show_page_num) {
		$self->add(
			$file,
			text => $self->process_page_num_text($file),
			y => $y,
			w => $w,
			x => $x,
			align => $self->show_page_num
		);
	}

	$self->cb->(
		$self,
		$file,
		y => $y,
		w => $w,
		x => $x,
	) if ($self->cb);
}

sub process_page_num_text {
	my ($self, $file) = @_;
	if ($self->page_num_text) {
		my $num = $file->page->num;
		(my $text = $self->page_num_text) =~ s/\{num\}/$num/g;
		return $text;
	}
	return $file->page->num;
}

sub clone {
	my ($self) = @_;
	$self = $self->SUPER::clone();
	$self->active(1);
	return $self;
}

=pod
	show_page_num => 'right',
	page_num_text => 'page {num]',
	h => 20,
	cb => sub {
		my ($self, %atts) = @_;
		$self->add_text(
			text => 'Khonsu',
			align => 'center',
			%attrs,
		);
	}
=cut

1;
