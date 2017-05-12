package Form::Decorator::DefaultButtons;
use Form::Button;

sub decorate {
    my ($self, $form) = @_;
    if (!@{$form->buttons}) {
        $form->add_button( Form::Button->new("submit") );
        $form->add_button( Form::Button->new("reset") );
    }
}
1;
