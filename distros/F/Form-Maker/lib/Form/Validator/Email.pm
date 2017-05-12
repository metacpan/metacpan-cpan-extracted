package Form::Validator::Email;
use Email::Valid;
use base 'Form::Validator';

sub validate {
    my ($self, $field) = @_;
    {
        javascript =>
            '/^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/',
        perl => $Email::Valid::RFC822PAT,
    }
}

=head1 NAME

Form::Validator::Email - Canned validator for email addresses

=head1 SYNOPSIS

    $form->add_validation(username => 'Form::Validator::Email');

=head1 DESCRIPTION

Checks for a field containing a well-formed email address as specified by
RFC 822. It does not perform any detailed semantic or network-based
validity checks for the address.

=cut

1;
