package HTML::Formhandler::Role::ToJSON;

use Moose::Role;

our $VERSION = '0.002';

sub prepare_error_response {  
  return +{
    form_errors => $_[0]->form_errors,
    error_by_field => $_[0]->errors_by_name,
    fields => $_[0]->fif,
  };
}

sub prepare_valid_response {
  return +{
    fields => $_[0]->fif,
  };
}

sub TO_JSON {
  return $_[0]->is_valid ?
    $_[0]->prepare_valid_response :
      $_[0]->prepare_error_response;
}

1;

=head1 NAME

HTML::Formhandler::Role::ToJSON - Adds a basic 'TO_JSON' method 

=head1 SYNOPSIS

    package MyApp::Form::Email

    use HTML::FormHandler::Moose;

    extends 'HTML::FormHandler';
    with 'HTML::Formhandler::Role::ToJSON';

    has_field 'email' => (
      type=>'Email',
      size => 96,
      required => 1);

    has_field 'fname' => (
      type=>'Text',
      size => 96,
      required => 1);

    has_field 'lname' => (
      type=>'Text',
      size => 96,
      required => 1);

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Most Perl JSON encoders support serializing perl objects via a
'TO_JSON' method.  This can be a convenient way to have a standard
JSON data structure.  ALthough you  may find over time a need to
write a more custom data structure, this role will offer a basic
encoding for error and success states that should be suitable for say
support AJAX web forms.  It can also serve as a blueprint for your
more customized versions as your application needs evolve.

=head1 METHODS

This role creates the following methods.

=head2 TO_JSON

Returns a Hashref that can be encoded into JSON by a supporting
encoding such as L<JSON>.  This returns one of two data structures
depending on if the form state is valid or not.  If the form state
is valid it will return a Hashref like the following (examples based
on the SYNOPSIS code)


    +{
      fields => +{
        email => "jjn\@yahoo.com",
        fname => "john",
        lname => "nap"
      }
    }

So in the valid state case you get a hashref with a single key 'fields'
which itself is a key to a hashref of the normalized valid form parameters
(the values as it uses to update the model).

If it is invalid the hashref looks like this:

    +{
      error_by_field => {
        email => [
          "Email field is required"
        ],
        fname => [
          "Fname field is required"
        ],
        lname => [
          "Lname field is required"
        ]
      },
      fields => {
        email => "",
        fname => "",
        lname => ""
      },
      form_errors => []
    }

So again a hashref with three keys: 'fields', which is as it in for the valid
result state described above, 'error_by_field' which is a key to a hashref
of each form field that has an error condition (the error conditions are given
in an arrayref even if there is only one) and a third 'form_errors' which is a
key to an arrayref of any form wide errors.  Arrayrefs will be empty if there is
no related error state.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 SEE ALSO
 
L<HTML::Formhandler>. L<Moose::Role>
 
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

