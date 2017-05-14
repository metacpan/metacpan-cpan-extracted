package JMAP::Validation::Checks::File;

use JMAP::Validation::Checks::Number;
use JMAP::Validation::Checks::String;
use Test2::Bundle::Extended;

our $is_File = hash {
  field blobId => $JMAP::Validation::Checks::String::is_id;
  field type   => $JMAP::Validation::Checks::String::is_string_or_null;
  field name   => $JMAP::Validation::Checks::String::is_string_or_null;
  field size   => $JMAP::Validation::Checks::Number::is_number_or_null;
  end();
};

1;
