package Form::Validator::ZipCode;
use base 'Form::Validator';
sub validate {
    my ($self, $field) = @_;
    {
        javascript => '^[0-9]{5}$',
        perl => qr/^\d{5}$/
    }
}

1;
