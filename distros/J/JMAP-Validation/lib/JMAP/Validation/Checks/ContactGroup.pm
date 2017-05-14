package JMAP::Validation::Checks::ContactGroup;

use JMAP::Validation;
use JMAP::Validation::Checks::String;
use JMAP::Validation::Tests::ContactGroup;
use JMAP::Validation::Tests::Object;
use JMAP::Validation::Tests::SetError;
use JMAP::Validation::Tests::String;
use JSON::Typist;
use Test2::Bundle::Extended;

# record types {{{

my $typist = JSON::Typist->new();

my %ContactGroup_checks = (
  id => $JMAP::Validation::Checks::String::is_id,

  name => check_set(
    $JMAP::Validation::Checks::String::is_string,
    $JMAP::Validation::Checks::String::has_at_least_one_character,
    $JMAP::Validation::Checks::String::has_at_most_256_bytes,
  ),

  contactIds => $JMAP::Validation::Checks::String::is_array_of_ids,
);

our $is_ContactGroup = hash {
  field id         => $ContactGroup_checks{id};
  field name       => $ContactGroup_checks{name};
  field contactIds => $ContactGroup_checks{contactIds};
  end();
};

our $is_ContactGroup_for_create = hash {
  field name       => $ContactGroup_checks{name};
  field contactIds => $ContactGroup_checks{contactIds};
  end();
};

our $is_ContactGroup_for_update = hash{
  field name       => in_set($ContactGroup_checks{name}, U());
  field contactIds => in_set($ContactGroup_checks{contactIds}, U());
  end();
};

# }}

# requests {{{

our $getContactGroups_args = hash {
  field accountId => validator(sub {
    my (%params) = @_;

    if (defined $params{got}) {
      return unless JMAP::Validation::validate(
        $params{got},
        $JMAP::Validation::Checks::String::is_string
      );
    }

    return 1;
  });

  field ids => validator(sub {
    my (%params) = @_;

    if (defined $params{got}) {
      return unless JMAP::Validation::validate(
        $params{got},
        $JMAP::Validation::Checks::String::is_array_of_ids,
      );
    }

    return 1;
  });

  end();
};

our $setContactGroups_args = hash {
  field accountId => in_set($JMAP::Validation::Checks::String::is_string_or_null, U());
  field ifInState => in_set($JMAP::Validation::Checks::String::is_string_or_null, U());

  field create => in_set(
    hash{
      all_keys validator(sub {
        my %params = @_;

        return JMAP::Validation::validate(
          $typist->apply_types($params{got}),
          $JMAP::Validation::Checks::String::is_id,
        );
      });

      all_values $is_ContactGroup_for_create;
    },
    U(),
  );

  field update => in_set(
    hash{
      all_keys validator(sub {
        my %params = @_;

        return JMAP::Validation::validate(
          $typist->apply_types($params{got}),
          $JMAP::Validation::Checks::String::is_id,
        );
      });

      all_values $is_ContactGroup_for_update;
    },
    U(),
  );

  field destroy => in_set(array { all_items $JMAP::Validation::Checks::String::is_id }, U());
  end();
};

# }}}

# response types {{{

our $is_contactGroups = hash {
  field accountId => $JMAP::Validation::Checks::String::is_id;
  field state     => $JMAP::Validation::Checks::String::is_string;

  # TODO: https://github.com/Test-More/Test2-Suite/issues/9
  # field list => array { all_items($is_ContactGroup) };

  field list => array{
    filter_items { grep { ! JMAP::Validation::Tests::ContactGroup::is_ContactGroup($_) } @_ };
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

  end();
};

our $is_contactGroupUpdates = hash {
  field accountId => $JMAP::Validation::Checks::String::is_id;
  field oldState  => $JMAP::Validation::Checks::String::is_string;
  field newState  => $JMAP::Validation::Checks::String::is_string;
  field changed   => $JMAP::Validation::Checks::String::is_array_of_ids;
  field removed   => $JMAP::Validation::Checks::String::is_array_of_ids;
  end();
};

our $is_contactGroupsSet = hash {
  field accountId => $JMAP::Validation::Checks::String::is_id;
  field oldState  => $JMAP::Validation::Checks::String::is_string_or_null;
# TODO: field newState  => $JMAP::Validation::Checks::String::is_string;

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

# TODO: end(); once newState works
};

# }}}

1;
