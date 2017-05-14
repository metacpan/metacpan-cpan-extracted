package JMAP::Validation::Checks::Contact;

use JMAP::Validation;
use JMAP::Validation::Checks::Address;
use JMAP::Validation::Checks::Boolean;
use JMAP::Validation::Checks::ContactInformation;
use JMAP::Validation::Checks::File;
use JMAP::Validation::Checks::String;
use JMAP::Validation::Tests::Contact;
use JMAP::Validation::Tests::SetError;
use JMAP::Validation::Tests::String;
use Test2::Bundle::Extended;

# record types {{{

our $is_Contact = hash {
  field id        => $JMAP::Validation::Checks::String::is_id;
  field isFlagged => $JMAP::Validation::Checks::Boolean::is_boolean;

  field avatar => validator(sub {
    my (%params) = @_;

    if (defined $params{got}) {
      return unless JMAP::Validation::validate(
        $params{got},
        $JMAP::Validation::Checks::File::is_File,
      );
    }

    return 1;
  });

  my @string_types = qw{
    prefix
    firstName
    lastName
    suffix
    nickname
    company
    department
    jobTitle
    notes
  };

  foreach my $field (@string_types) {
    field $field => $JMAP::Validation::Checks::String::is_string;
  }

  field birthday    => $JMAP::Validation::Checks::String::is_date;
  field anniversary => $JMAP::Validation::Checks::String::is_date;
  field emails      => $JMAP::Validation::Checks::ContactInformation::is_ContactInformation_emails;
  field phones      => $JMAP::Validation::Checks::ContactInformation::is_ContactInformation_phones;
  field online      => $JMAP::Validation::Checks::ContactInformation::is_ContactInformation_online;

  field addresses => array {
    filter_items { grep { ! $JMAP::Validation::Checks::Address::is_Address } @_ };
    end();
  };

  end();
};

# }}}

# response types {{{

our $is_contacts = hash {
  field accountId => $JMAP::Validation::Checks::String::is_id;
  field state     => $JMAP::Validation::Checks::String::is_string;

  # TODO: https://github.com/Test-More/Test2-Suite/issues/9
  # field list => array { all_items($is_Contact) };

  field list => array{
    filter_items { grep { ! JMAP::Validation::Tests::Contact::is_Contact($_) } @_ };
    end();
  };

  field notFound => validator(sub {
    my (%params) = @_;

    if (defined $params{got}) {
      return unless JMAP::Validation::validate(
        $params{got},
        array {
          filter_items { grep { ! JMAP::Validation::Tests::String::is_string($_) } @_ };
          end();
        },
      );
    }

    return 1;
  });
};

our $is_contactUpdates = hash {
  field accountId      => $JMAP::Validation::Checks::String::is_id;
  field oldState       => $JMAP::Validation::Checks::String::is_string;
  field newState       => $JMAP::Validation::Checks::String::is_string;
  field hasMoreUpdates => $JMAP::Validation::Checks::Boolean::is_boolean;
  field changed        => $JMAP::Validation::Checks::String::is_array_of_ids;
  field removed        => $JMAP::Validation::Checks::String::is_array_of_ids;
};

our $is_contactsSet = hash {
  field accountId => $JMAP::Validation::Checks::String::is_id;
  field oldState  => $JMAP::Validation::Checks::String::is_string_or_null;
  field newState  => $JMAP::Validation::Checks::String::is_string;

  field created  => check_set(
    hash {},
    validator(sub {
      my (%params) = @_;

      foreach my $createdId (keys %{$params{got}}) {
        return unless JMAP::Validation::Tests::Object::is_object($params{got}{$createdId});
        return unless scalar(keys %{$params{got}{$createdId}}) == 1;
        return unless JMAP::Validation::Tests::String::is_id($params{got}{$createdId}{id});
      }

      return 1;
    }),
  );

  field updated   => $JMAP::Validation::Checks::String::is_array_of_ids;
  field destroyed => $JMAP::Validation::Checks::String::is_array_of_ids;

  field notCreated => check_set(
    hash {},
    validator(sub {
      my (%params) = @_;

      foreach my $creationId (keys %{$params{got}}) {
        return unless JMAP::Validation::Tests::SetError::is_SetError_invalidProperties(
          $params{got}{$creationId}, qw{name contactIds},
        );
      }

      return 1;
    }),
  );

  field notUpdated => check_set(
    hash {},
    validator(sub {
      my (%params) = @_;

      foreach my $updatedId (keys %{$params{got}}) {
        my $is_notFound = JMAP::Validation::Tests::SetError::is_SetError_notFound(
          $params{got}{$updatedId}
        );

        my $is_invalidProperties = JMAP::Validation::Tests::SetError::is_SetError_invalidProperties(
          $params{got}{$updatedId}, qw{name contactIds},
        );

        return unless ($is_notFound or $is_invalidProperties);
      }

      return 1;
    }),
  );

  field notDestroyed => check_set(
    hash {},
    validator(sub {
      my (%params) = @_;

      foreach my $destroyedId (keys %{$params{got}}) {
        return unless JMAP::Validation::Tests::SetError::is_SetError_notFound(
          $params{got}{$destroyedId}
        );
      }

      return 1;
    }),
  );
};

# }}}

1;
