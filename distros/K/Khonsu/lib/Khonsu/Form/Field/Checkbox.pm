package Khonsu::Form::Field::Checkbox;

use parent 'Khonsu::Form::Field';

use PDF::API2::Resource::XObject::Form;
use PDF::API2::Basic::PDF::Literal;
use PDF::API2::Basic::PDF::Utils;

sub attributes {
	my $a = shift;
	return (
		$a->SUPER::attributes(),
		width => {$a->RW, $a->NUM, default => sub { 50 }}
	);
}

sub configure {
	my ($self, $file, %args) = @_;
	$self->annotate->{Type}    = PDFName( 'Annot' );
	$self->annotate->{Subtype} = PDFName( 'Widget' );
	$self->annotate->{FT}      = PDFName( 'Btn' );
	$self->annotate->{T}       = PDFStr( 'checkbox1' );
	$self->annotate->{V}       = PDFName( 'Off' );
	$self->annotate->{Rect}    = PDF::API2::Basic::PDF::Literal->new( "[100 300 200 400]" );
	$self->annotate->{H}       = PDFName( 'N' );
	$self->annotate->{AS} = PDFName('Off');
	$self->annotate->{AP}      = PDFDict();
	$self->annotate->{AP}->realise();
	$self->annotate->{AP}->{N} = PDFDict();
	$self->annotate->{AP}->{N}->realise();
}

sub set_rect {
	my ($self, $file, %args) = @_;
	my %position = $self->get_points();
	$position{y} = $file->page->h - $position{y};
	my @pos = (
		$self->end_w,
		$position{y} + ($self->font->size*0.4),
		$self->end_w + $self->width,
		$position{y} - ($self->font->size*1.2)
	);
	$self->annotate->rect(@pos);
}

1;
