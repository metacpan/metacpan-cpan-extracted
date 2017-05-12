package MockReflector;
use Moose;
use namespace::autoclean;
extends 'Form::Sensible::Reflector';

sub get_field_names {
    return qw/ field1 field2 field3 /;
}

sub get_all_field_definitions {
    return (
        {
                field_class => 'Text',
                name        => 'field1',
                validation  => {
                    regex => qr/^(.+){3,}$/
                }, 
            },
            {
                field_class => 'FileSelector',
                name        => 'field2',
                validation  => {}, # wtf do we validate here?
            },
            {
                field_class => 'Text',
                name        => 'field3',
                validation  => {
                    regex => qr/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/,
                }, 
            },
    );
}

sub create_form_object {
    my ( $self, $handle, $form_options ) = @_;

    return Form::Sensible::Form->new(name => "test");
}

1;
