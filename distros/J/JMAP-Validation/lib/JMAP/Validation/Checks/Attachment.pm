package JMAP::Validation::Checks::Attachment;

use JMAP::Validation::Checks::Boolean;
use JMAP::Validation::Checks::Number;
use JMAP::Validation::Checks::String;
use Test2::Bundle::Extended;

our $is_Attachment = hash {
  field blobId   => $JMAP::Validation::Checks::String::is_string;
  field type     => $JMAP::Validation::Checks::String::is_string;
  field name     => $JMAP::Validation::Checks::String::is_string_or_null;
  field size     => $JMAP::Validation::Checks::Number::is_number;
  field cid      => $JMAP::Validation::Checks::String::is_string_or_null;
  field isInline => $JMAP::Validation::Checks::Boolean::is_boolean;
  field width    => in_set($JMAP::Validation::Checks::Number::is_number, U());
  field height   => in_set($JMAP::Validation::Checks::Number::is_number, U());
};

1;
