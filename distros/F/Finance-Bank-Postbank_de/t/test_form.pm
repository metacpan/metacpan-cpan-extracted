sub form_ok {
  my ($mech, $name, @fields) = @_;
  my $result = 1;

  my $form;

  if( ! $name) {
    my $testname = "Form with fields '@fields' exists";
    # Find a matching form
    my $form = $mech->form_with_fields( @fields );
    if( ! $form ) {
      diag $mech->content;
      diag "Form with fields @fields does not exist";
      diag $_->dump for @forms;
      return ok(0,$testname);
    };

  } else {
    my $testname = "Form '$name' matches description";

    my @forms = $mech->forms();
    if (scalar(grep({    ($_->attr('name')||"") eq $name 
                      or ($_->attr('id')  ||"") eq $name } @forms)) != 1) {
      diag $mech->content;
      diag "Form $name doesn't exist";
      diag $_->dump for @forms;
      return ok(0,$testname);
    };
    $mech->form_name($name);
  };

  # Check that the expected form fields are available :
  my $field;
  for $field (@fields) {
    if (! defined $mech->current_form->find_input($field)) {
      undef $result;
      diag "Form field '$field' was not found in '$name'";
    };
  };
  
  diag $mech->current_form->dump
    unless $result;
  return ok($result, $testname);
};

1;
