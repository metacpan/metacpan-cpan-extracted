package Khonsu::Form::Field::Select;

use parent 'Khonsu::Form::Field';

use PDF::API2::Basic::PDF::Literal;
use PDF::API2::Basic::PDF::Utils;

sub configure {
	my ($self, $file, %args) = @_;
	$self->annotate->{V} = do {
		my $s = PDFStr('');
		$s->{' isutf'} = PDFBool(1);
		$s;
	};
	$self->annotate->{DA} = PDFStr('0 0 0 reg /F3 11 Tf');
	$self->annotate->{DV} = $self->annotate->{V};
	$self->annotate->{FT} = PDFName('Ch');
	$self->annotate->{Ff} = PDFNum(393216);
	$self->annotate->{Opt} = PDFArray(map {
		PDFStr($_)
	} @{$args{options}});
}

sub set_rect {
	my ($self, $file, %args) = @_;
	my %position = $self->get_points();
	$position{y} = $file->page->h - $position{y};
	my @pos = (
		$self->end_w + 2,
		$position{y} + ($self->font->size*0.4),
		$position{w},
		$position{y} - ($self->font->size*1.2)
	);
	$self->annotate->rect(@pos);
}

1;
