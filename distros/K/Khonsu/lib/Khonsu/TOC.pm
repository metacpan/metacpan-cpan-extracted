package Khonsu::TOC;

use Khonsu::TOC::Outline;

use parent 'Khonsu::Text';

sub attributes {
	my $a = shift;
	return (
		$a->SUPER::attributes(),
		title => {$a->RW, $a->STR},
		title_font_args => {$a->RW, $a->HR},
		title_padding => {$a->RW, $a->NUM},
		font_args => {$a->RW, $a->HR},
		padding => {$a->RW, $a->NUM, default => sub { 0 }},
		count => {$a->RW, $a->NUM},
		toc_placeholder => {$a->RW, $a->HR},
		base_outline => {$a->RW, $a->OBJ},
		outlines => {$a->RW, $a->DAR},
		level_indent => {$a->RW, $a->NUM, default => sub { 2 }},
		levels => {$a->RW, $a->HR, default => sub {{
			h1 => 1,
			h2 => 2,
			h3 => 3,
			h4 => 4,
			h5 => 5,
			h6 => 6
		}}},
	);
}

sub add {
	my ($self, $file, %attributes) = @_;
	if (!$attributes{x}) {
		$attributes{x} = $file->page->x;
		$attributes{y} = $file->page->y;
		$attributes{h} = $file->page->remaining_height();
		$attributes{w} = $file->page->width();
	}
	$self->set_attributes(%attributes);	
	$self->toc_placeholder({
		page => $file->page,
	});
	$self->base_outline($file->pdf->outlines()->outline);
	$file->onsave('toc', 'render', %attributes);
	$file->add_page(%{$attributes{page_args} || {}});
	return $file;
}

sub outline {
	my ($self, $file, $type, %attributes) = @_;

	$self->count($self->count + 1);
		
	$attributes{title} ||= $attributes{text};
	
	delete $attributes{font};	

	my $level = $self->levels->{$type};

	my $outline = Khonsu::TOC::Outline->new(
		page => $file->page,
		level => $level,
		%attributes
	);

	if ($level == 1) {
		$outline->add($file, $self->base_outline);
		push @{ $self->outlines }, $outline;
	} else {
		$outline->indent($self->level_indent * ($level - 1));
		my $parent = $self->outlines->[-1];
		$level--;
		while ($level > 1) { 
			$parent = $parent->children->[-1];
			$level--;
		}
		$outline->add($file, $parent->outline);
		push @{$parent->children}, $outline;
	}

	return $file;
}

sub render {
	my ($self, $file, %attributes) = @_;

	$self->set_attributes(%attributes);

	my %position = $self->get_points();

	my $page = $self->toc_placeholder->{page};

	$file->open_page($self->toc_placeholder->{page}->num());

	$file->page->toc(1);
	
	if ($self->title) {
		$self->SUPER::add($file, text => $self->title, font => $self->title_font_args, %position);
		$position{y} += $self->font->size;
		$position{y} += $self->title_padding if $self->title_padding;
	}

	return unless scalar @{$self->outlines};

	my $one_toc_link = $self->outlines->[0]->font->size + $self->padding;

	$attributes{page_offset} = 0;

	my $total_height = ($self->count * $one_toc_link) - $position{h};
	if ($total_height > 0) {
		while ($total_height > 0) {
			$attributes{page_offset}++;
			$file->add_page(toc => 1, num => $self->toc_placeholder->{page}->num() + $attributes{page_offset});
			$total_height -= $file->page->h;
		}

		$file->open_page($self->toc_placeholder->{page}->num());
	}

	%attributes = (%attributes, %position);

	my $y = $attributes{y};
	my $num = $self->toc_placeholder->{page}->num();
	for my $outline (@{$self->outlines}) { 
		$outline->render(
			$file,
			%attributes,
			y => $y,
			padding => $self->padding,
			num => sub { $_[0] ? ++$num : $num }
		);
		$y = $outline->end_y + $self->padding;
		if ($y > $file->page->h - ($file->page->footer ? $file->page->footer->h : 0)) {
			$num++;
			$file->open_page($num);
			$y = $file->page->header ? $file->page->header->h : 0;
		}
	}

	$file->page_offset($attributes{page_offset});

	return $file;
}

1;
