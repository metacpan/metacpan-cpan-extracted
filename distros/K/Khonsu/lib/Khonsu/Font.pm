package Khonsu::Font;

use parent 'Khonsu::Ra';

sub attributes {
	my $a = shift;
	return (
		colour => {$a->RW, $a->STR, default => sub { '#000' }},
		size => {$a->RW, $a->NUM, default => sub { 9 }},
		family => {$a->RW, $a->STR, default => sub { 'Times' }},
		loaded => {$a->RW, $a->DHR},
		line_height => {$a->RW, $a->NUM, default => sub { $_[0]->size }},
	);
}

sub load {
	my ($self, $file, %attributes) = @_;
	$self->set_attributes(%attributes);
	if (!$attributes{line_height} && $self->size > $self->line_height) {
		$self->line_height($self->size);
	}
	return $self->find($file, $self->family);
}

sub find {
	my ($self, $file, $family, $enc) = @_;
	my $loaded = $self->loaded;
	unless ($loaded->{$family}) {
		$loaded->{$family} = $file->pdf->corefont($family, -encoding => $enc || 'latin1');
		$self->loaded($loaded);
	}
	return $loaded->{$family};

}


1;
