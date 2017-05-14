package JMAP::Validation::Checks::ContactInformation;

use JMAP::Validation::Tests::ContactInformation;
use Test2::Bundle::Extended;

our $is_ContactInformation_emails = array {
  filter_items {
    grep { ! JMAP::Validation::Tests::ContactInformation::is_ContactInformation_email($_) } @_
  };
  end();
};

our $is_ContactInformation_phones = array {
  filter_items {
    grep { ! JMAP::Validation::Tests::ContactInformation::is_ContactInformation_phone($_) } @_
  };
  end();
};

our $is_ContactInformation_online = array {
  filter_items {
    grep { ! JMAP::Validation::Tests::ContactInformation::is_ContactInformation_online($_) } @_
  };
  end();
};

1;
