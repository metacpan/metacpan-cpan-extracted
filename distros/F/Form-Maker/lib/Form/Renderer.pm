package Form::Renderer;

sub render {
    my ($class, $form) = @_;
    (join "", $form->start, $form->fieldset, $form->buttons, $form->end)
}

1;
