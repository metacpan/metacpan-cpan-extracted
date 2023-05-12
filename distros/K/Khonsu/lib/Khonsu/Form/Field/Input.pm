package Khonsu::Form::Field::Input;

use parent 'Khonsu::Form::Field';

use PDF::API2::Basic::PDF::Literal;
use PDF::API2::Basic::PDF::Utils;

sub configure {
	my ($self) = @_;
	$self->annotate->{FT} = PDFName('Tx');
	$self->annotate->{V} = do {
		my $s = PDFStr('');
		$s->{' isutf'} = PDFBool(1);
		$s;
	};
	$self->annotate->{DA} = PDFStr('0 0 0 reg /F3 11 Tf');
	$self->annotate->{DV} = $self->annotate->{V};

	$self->annotate->{Ff} = PDFNum(393216);
}


1;
