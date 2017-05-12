package Form::Renderer::Test;
use base 'Form::Renderer';

sub render {
    my ($self, $form) = @_;
    join "\n", map {
        $_->name.": ".$_->type.($_->_validation ?
            ": ".$_->_validation->{javascript} : "");
    } @{$form->fields}
}
1;
