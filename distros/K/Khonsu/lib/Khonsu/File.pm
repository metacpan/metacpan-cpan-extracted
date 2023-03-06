package Khonsu::File;

use parent 'Khonsu::Ra';

use Khonsu::Page;

sub attributes {
	my $a = shift;
	return (
		file_name => {$a->RW, $a->REQ, $a->STR},
		pdf => {$a->RW, $a->REQ, $a->OBJ},
		pages => {$a->RW, $a->REQ, $a->AR},
		page => {$a->RW, $a->OBJ},
		page_args => {$a->RW, $a->DHR},
		onsave_cbs => {$a->RW, $a->DAR},
		page_offset => {$a->RW, $a->NUM},
		$a->LINE,
		$a->BOX,
		$a->CIRCLE,
		$a->PIE,
		$a->ELLIPSE,
		$a->FONT,
		$a->TEXT,
		$a->H1,
		$a->H2,
		$a->H3,
		$a->H4,
		$a->H5,
		$a->H6
	);
}

sub add_page {
	my ($self, %args) = @_;

	my $page = $self->page(Khonsu::Page->new(
		page_size =>'A4',
		num => scalar @{$self->pages},
		%{ $self->page_args },
		%args
	))->add($self);

	push @{$self->pages}, $page;

	return $self;
}

sub add_line {
	my ($self, %args) = @_;
	$self->line->add($self, %args);
	return $self;
}

sub add_box {
	my ($self, %args) = @_;
	$self->box->add($self, %args);
	return $self;
}

sub add_circle {
	my ($self, %args) = @_;
	$self->circle->add($self, %args);
	return $self;
}

sub add_pie {
	my ($self, %args) = @_;
	$self->pie->add($self, %args);
	return $self;
}

sub add_ellipse {
	my ($self, %args) = @_;
	$self->ellipse->add($self, %args);
	return $self;
}

sub load_font {
	my ($self, %args) = @_;
	$self->font->load($self, %args);
	return $self;
}

sub add_text {
	my ($self, %args) = @_;
	$self->text->add($self, %args);
	return $self;
}

sub add_h1 {
	my ($self, %args) = @_;
	$self->h1->add($self, %args);
	return $self;
}

sub add_h2 {
	my ($self, %args) = @_;
	$self->h2->add($self, %args);
	return $self;
}

sub add_h3 {
	my ($self, %args) = @_;
	$self->h3->add($self, %args);
	return $self;
}

sub add_h4 {
	my ($self, %args) = @_;
	$self->h4->add($self, %args);
	return $self;
}

sub add_h5 {
	my ($self, %args) = @_;
	$self->h5->add($self, %args);
	return $self;
}

sub add_h6 {
	my ($self, %args) = @_;
	$self->h6->add($self, %args);
	return $self;
}

sub save {
	my ($self) = shift;
	$self->pdf->saveas();
	$self->pdf->end();
}

1;
