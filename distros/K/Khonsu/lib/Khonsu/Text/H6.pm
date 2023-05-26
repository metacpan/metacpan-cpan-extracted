package Khonsu::Text::H6;

use parent 'Khonsu::Text';

sub BUILD {
	my ($self, %params) = @_;
	$self->font->size($params{font_size} || 15);
	$self->font->line_height($params{line_height} || 13);
}

sub add {
	my ($self, $file, %attributes) = @_;
	$attributes{h} ||= $self->font->size;	
	$file->toc->outline($file, 'h6', %attributes) if $attributes{toc};
	return $self->SUPER::add($file, %attributes);
}

1;
