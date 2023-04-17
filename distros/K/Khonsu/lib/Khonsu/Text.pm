package Khonsu::Text;

use parent 'Khonsu::Ra';

sub attributes {
	my $a = shift;
	return (
		text => {$a->RW, $a->STR},
		overflow => {$a->RW, $a->BOOL},
		indent => {$a->RW, $a->NUM, default => sub { 0 }},
		pad => {$a->RW, $a->STR},
		pad_end => {$a->RW, $a->STR},
		align => {$a->RW, $a->STR, default => sub { 'left' }},
		$a->FONT,
		$a->POINTS
	);
}

sub add {
	my ($self, $file, %attributes) = @_;

	my $font = $self->font->load($file, %{ delete $attributes{font} || {} });
	
	$self->set_attributes(%attributes);

	my $size = $self->font->size;
	
	my $text = $file->page->current->text;
	
	$text->font($font, $size);
	
	$text->fillcolor($self->font->colour);

	my (%pos) = (
		l => $self->font->line_height,
		$self->get_points()
	);

	my $ypos = $file->page->h - ($pos{y} + $pos{l});

	my $max_height = $ypos - $pos{h};

	my $xpos = $pos{x};

	my $indent = $self->indent;
	
	my @paragraphs = split /\n/, $self->text;
	
	my $space = $text->advancewidth(" ");

	my @words = split / /, shift @paragraphs;

	if ($indent) {
		unshift @words, map { " " } 0 .. $indent;
	}

	while ($ypos > $max_height && @words) {
		my $word = shift @words;
		my ($width, @line) = ($text->advancewidth($word), ());
		while ($width <= $pos{w} && $word) {
			$width += $space;
			push @line, $word;
			$word = shift @words;
			$width += $text->advancewidth($word);
		}
		if ($word) {
			unshift @words, $word if (scalar @words);
		} elsif ($self->pad) {
			my $pad_width = $text->advancewidth($self->pad);
			my $pad_end_width = $self->pad_end ? $text->advancewidth($self->pad_end) : 0;
			my $left = int(($pos{w} - ($width + $pad_end_width)) / $pad_width);
			push @line, $self->pad x $left if $left;
			push @line, $self->pad_end if $self->pad_end;
			$width = $pos{w};
		}

		my $align = $self->align;
		if ($align eq 'center') {
			$xpos = $xpos + ((($pos{w} - $width) / 2) -  ($width / 2));
		} elsif ($align eq 'right') {
			$xpos = $xpos + ($pos{w} - $width);
		}

		$text->translate($xpos, $ypos);
		$text->text(join(" ", @line));
		$ypos -= $pos{l};
	}

	if (!$self->overflow && scalar @words) {
		die "Too many words to fit the max height: $pos{h} and width: $pos{w} overflow:" . join " ", @words;
	}

	return $file;
}

1;
