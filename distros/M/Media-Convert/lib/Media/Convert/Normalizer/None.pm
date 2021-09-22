package Media::Convert::Normalizer::None;

use Media::Convert::Normalizer;
use Moose;
use File::Copy;

extends 'Media::Convert::Normalizer';

sub run {
	my $self = shift;
	if ($self->input->url ne $self->output->url) {
		copy($self->input->url, $self->output->url);
	}
}
