package Khonsu::File;

use parent 'Khonsu::Ra';

use Khonsu::Page;
use Khonsu::Page::Header;
use Khonsu::Page::Footer;

sub new {
	my ($self, %params) = @_;
	$self = $self->SUPER::new(%params);
	$self->add_page();
	if ($params{configure}) {
		$self->add_page_header(%{delete $params{configure}->{page_header}})
			if ($params{configure}->{page_header});
		$self->add_page_footer(%{delete $params{configure}->{page_footer}})
			if ($params{configure}->{page_footer});
		for my $key ( keys %{ $params{configure} }) {
			if ($self->{$key}) {
				if ($params{configure}->{$key}->{font}) {
					$self->$key->font->load($self, %{ delete $params{configure}->{$key}->{font} });
				}
				$self->$key->set_attributes(%{$params{configure}->{$key}});
			}
		}
	}
	return $self;
}


sub attributes {
	my $a = shift;
	return (
		file_name => {$a->RW, $a->REQ, $a->STR},
		pdf => {$a->RW, $a->REQ, $a->OBJ},
		pages => {$a->RW, $a->REQ, $a->DAR},
		page => {$a->RW, $a->OBJ},
		page_args => {$a->RW, $a->DHR},
		page_offset => {$a->RW, $a->NUM, default => sub { 0 }},
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
		$a->H6,
		$a->IMAGE,
		$a->TOC,
		$a->FORM,
		$a->INPUT,
		$a->SELECT,
	);
}

sub open_page {
	my ($self, $page) = @_;
	if ($self->pages) {
		$self->page($self->pages->[$page - 1]);
	}
	return $self;
}

sub set_columns {
	my ($self, $columns) = @_;
	$self->page->columns($columns);
	$self->page->column_y($self->page->y);
	return $self;
}

sub add_page {
	my ($self, %args) = @_;

	my $page = $self->page(Khonsu::Page->new(
		header => $self->page && $self->page->header ? $self->page->header->clone() : undef,
		footer => $self->page && $self->page->footer ? $self->page->footer->clone() : undef,
		columns => $self->page ? $self->page->columns : 1,
		page_size =>'A4',
		num => scalar @{$self->pages} + 1,
		%{ $self->page_args },
		%args
	))->add($self);
	splice @{$self->pages}, $page->num - 1, 0, $page;

	return $self;
}

sub remove_page_header_and_footer {
	my ($self) = @_;
	$self->remove_page_header();
	$self->remove_page_footer();
}

sub remove_page_header {
	my ($self, %args) = @_;
	$self->page->header->active(0);
	return $self;
}

sub remove_page_footer {
	my ($self, %args) = @_;
	$self->page->footer->active(0);
	return $self;
}

sub add_page_header {
	my ($self, %args) = @_;
	$self->page->header(Khonsu::Page::Header->new(
		%args
	));

	return $self;
}

sub add_page_footer {
	my ($self, %args) = @_;

	$self->page->footer(Khonsu::Page::Footer->new(
		%args
	));

	return $self;
}

sub add_toc {
	my ($self, %args) = @_;
	$self->toc->add($self, %args);
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

sub add_image {
	my ($self, %args) = @_;
	$self->image->add($self, %args);
	return $self;
}

sub add_form {
	my ($self, %args) = @_;
	$self->form->add($self, %args);
	return $self;
}

sub add_input {
	my ($self, %args) = @_;
	$self->input->add($self, %args);
	return $self;
}

sub add_select {
	my ($self, %args) = @_;
	$self->select->add($self, %args);
	return $self;
}

sub onsave {
	my ($self, $plug, $meth, %args) = @_;
	my $cbs = $self->onsave_cbs || [];
	push @{$cbs}, [$plug, $meth, \%args];
	$self->onsave_cbs($cbs);
	return $self;
}

sub handle_onsave {
	my ($self) = shift;
	if ($self->onsave_cbs) {
		for my $cb (@{$self->onsave_cbs}) {
			my ($plug, $meth, $args) = @{$cb};
			$self->$plug->$meth($self, %{$args});
		}
	}
	
	for my $page (@{$self->pages}) {
		$self->page($page);
		$page->num($page->num + ($self->page_offset || 0)) if !$page->toc;
		$page->render($self);
	}
}

sub save {
	my ($self) = shift;
	$self->handle_onsave();
	$self->pdf->saveas();
	$self->pdf->end();
}

1;
