package Khonsu::Form;

use parent 'Khonsu::Ra';

use PDF::API2::Basic::PDF::Utils;

sub attributes {
	my $a = shift;
	return (
		form => { $a->RW, $a->OBJ },
		fields => { $a->RW, $a->AR },
	);
}

sub add {
	my ($self, $file, %args) = @_;
	return $self if $self->form;
	my $form = PDFDict();
	$form->{NeedAppearances} = PDFBool('true');
	$self->form($form);
	$file->onsave('form', 'end');
}

sub end {
	my ($self, $file) = @_;
	$self->form->{Fields} = PDFArray(@{$self->fields});
	$file->pdf->{catalog}->{AcroForm} = $self->form;
}

sub add_to_fields {
	my ($self, $file, $field) = @_;
	$self->add($file);
	my $fields = $self->fields;
	push @{$fields}, $field;
	return $self->fields($fields);

}

1;
