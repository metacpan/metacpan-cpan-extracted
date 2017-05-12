package TestForm;
use HTML::FormHandler::Moose;
use HTML::FormHandler::Types (':all');
use namespace::autoclean;

extends 'HTML::FormHandler';

with 'HTML::FormHandlerX::JQueryRemoteValidator';

#has '+skip_all_remote_validation' => (default => 1);

has '+html_prefix' => (default => 1);

has '+name' => ( default => 'TestForm' );

has_field 'id' => (type => 'Hidden');

has_field 'fname' => (
    type => 'Text',
    label => 'First name',
    required => 1,
    minlength => 2,
    required_message => 'Please enter your first name.',
);

has_field 'lname' => (
    type => 'Text',
    label => 'Last name',
    required => 1,
    minlength => 2,
    required_message => 'Please enter your last name.',
);

has_field 'email' => (
    type => 'Email',
    required => 1,
    label => 'Email',
    required_message => 'Please enter a valid email.',
);

has_field 'password' => (
    type => 'Password',
    required => 1,
    label => 'Password',
    apply => [NoSpaces, WordChars, NotAllDigits],
    ne_username => 'email',
    minlength => 8,
    required_message => 'Password must have at least 8 characters, no spaces.',
);

has_field 'password2' => (
    type => 'PasswordConf',
    password_field => 'password', # this is the default
    label => 'Confirm password',
    required => 1,
    apply => [NoSpaces, WordChars, NotAllDigits],
    minlength => 8,
    required_message => 'Please repeat the password.',
);

has_field 'submit' => (
    widget => 'Submit',
    type => 'Submit',
    label => '',
    element_class =>['btn', 'btn-primary'],
    default => 'Sign up',
);

__PACKAGE__->meta->make_immutable;
no HTML::FormHandler::Moose;

1;



