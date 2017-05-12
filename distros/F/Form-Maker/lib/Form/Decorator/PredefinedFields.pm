package Form::Decorator::PredefinedFields;
use base 'Class::Data::Inheritable';
Form::Decorator::PredefinedFields->mk_classdata(
    fields => {
        password => "Form::Field::Password"
    }
);

sub decorate {
    my ($class, $form) = @_;
    my $ff = $class->fields;
    for my $name (keys %{$form->field_hash}) {
        my $field = $form->{field_hash}->{$name};
        if (my $newclass = $ff->{$name}) {
            $form->_load_and_run($newclass);
            $field->type($newclass->type);
            $field->{type} = $field->type; # CDI is too much magic.
            bless $field, $newclass;
        }
    }
}
