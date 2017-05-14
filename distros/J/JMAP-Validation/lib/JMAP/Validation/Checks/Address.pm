package JMAP::Validation::Checks::Address;

use JMAP::Validation::Checks::Boolean;
use JMAP::Validation::Checks::String;
use Test2::Bundle::Extended;

our $is_Address = hash {
  field type      => validator(sub {
    my (%params) = @_;
    return $params{got} =~ /^(?:home|work|billing|postal|other)$/;
  });

  field label     => $JMAP::Validation::Checks::String::is_string_or_null;
  field street    => $JMAP::Validation::Checks::String::is_string;
  field locality  => $JMAP::Validation::Checks::String::is_string;
  field region    => $JMAP::Validation::Checks::String::is_string;
  field postcode  => $JMAP::Validation::Checks::String::is_string;
  field country   => $JMAP::Validation::Checks::String::is_string;
  field isDefault => $JMAP::Validation::Checks::Boolean::is_boolean;
  end();
};

1;
