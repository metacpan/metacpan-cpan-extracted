package JMAP::Validation::Checks::Emailer;

use Test2::Bundle::Extended;

our $is_Emailer = hash {
  field name  => $JMAP::Validation::Checks::String::is_string;

  field email => check_set(
    $JMAP::Validation::Checks::String::is_string,
    match qr/[^@]*@[^@]*/;
  });

  end();
};

1;
