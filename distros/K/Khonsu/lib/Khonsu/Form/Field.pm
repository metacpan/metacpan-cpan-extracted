package Khonsu::Form::Field;

use parent 'Khonsu::Text';

use PDF::API2::Basic::PDF::Utils;
use PDF::API2::Basic::PDF::Utils;

sub attributes {
	my $a = shift;
	return (
		$a->SUPER::attributes(),
		xo => { $a->RW, $a->OBJ },
		annotate => { $a->RW, $a->OBJ },
		name => { $a->RW, $a->STR },
	);
}

sub add {
	my ($self, $file, %args) = @_;

	my %position = $self->get_points();	

	my $field = $self->xo(
		$file->pdf->xo_form()
	);

	$self->SUPER::add($file, pad => '_', %args);

	my $annotate = $self->annotate(
		$file->page->current->annotation
	);
	$field->{OpenAction} = PDFArray($self->annotate, PDFName('XYZ'), PDFNull, PDFNull, PDFNum(0));
	$field->bbox(0, 0, 149.8, 14.4);
	$annotate->{DR} = $self->font->load();
	$annotate->{T} = PDFStr($self->name || $args{text});
	$annotate->{Subtype} = PDFName('Widget');
	$annotate->{P} = $file->page->current;
	$args{position} ||= \@pps;
	$self->configure(%args) if $self->can('configure');
	$self->set_rect($file, %args);
	$file->form->add_to_fields($file, $self->annotate);
	return $file;
}

sub set_rect {
	my ($self, $file, %args) = @_;
	my %position = $self->get_points();
	$position{y} = $file->page->h - $position{y};
	my @pos = (
		$self->end_w + 2,
		$position{y} + ($self->font->size*0.2),
		$position{w},
		$position{y} - ($self->font->size*1.4)
	);
	$self->annotate->rect(@pos);
}

1;
