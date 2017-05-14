package JMAP::Validation::Checks::Error;

use JMAP::Validation;
use JMAP::Validation::Tests::Array;
use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::String;
use Test2::Bundle::Extended;

our $is_error = array {
  item 'error';

  item hash {
    field type => $JMAP::Validation::Checks::String::is_string;
  };

  item $JMAP::Validation::Checks::String::is_id;
};

1;
