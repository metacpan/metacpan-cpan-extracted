package Form::Outline;
use base 'Form::Maker';

sub fill_outline {
    my ($self, $form) = @_;
    for (@{$self->fields}) {
        $form->add_fields($_);
    }
}
1;
