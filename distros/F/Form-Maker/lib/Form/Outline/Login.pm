package Form::Outline::Login;
use base 'Form::Outline';
use Form::Field::Text;
use Form::Field::Password;
__PACKAGE__->add_fields(
        Form::Field::Text->new({ name => "username" }),
        Form::Field::Password->new({ name => "password" }),
);
1;
