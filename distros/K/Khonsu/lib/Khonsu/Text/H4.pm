package Khonsu::Text::H4;

use parent 'Khonsu::Text';

sub BUILD {
	my ($self, %params) = @_;
	$self->font->size($params{font_size} || 25);
	$self->font->line_height($params{line_height} || 17);
}

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{h} ||= $self->font->size;
	$file->toc->outline($file, 'h4', %attributes) if $attributes{toc};
	return $self->SUPER::add($file, %attributes);
}

1;
