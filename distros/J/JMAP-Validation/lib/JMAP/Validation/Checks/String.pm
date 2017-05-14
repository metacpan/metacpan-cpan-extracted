package JMAP::Validation::Checks::String;

use DateTime;
use JMAP::Validation;
use JMAP::Validation::Tests::String;
use Test2::Bundle::Extended;

# data types {{{

our $is_string = validator(sub {
  my (%params) = @_;

  return (ref($params{got}) || '') eq 'JSON::Typist::String';
});

# }}}

# restrictions {{{

our $is_string_or_null = in_set($is_string, U());

our $has_at_least_one_character = check_set(
  $is_string,
  validator(sub {
    my (%params) = @_;
    return $params{got} =~ /./;
  }),
);

our $has_at_most_256_bytes = check_set(
  $is_string,
  validator(sub {
    my (%params) = @_;
    return $params{got} !~ /\C{257}/;
  }),
);

our $has_no_leading_hash = check_set(
  $is_string,
  validator(sub {
    my (%params) = @_;
    return $params{got} !~ /^#/;
  }),
);

our $is_id = check_set(
  $is_string,
  $has_at_least_one_character,
  $has_at_most_256_bytes,
  $has_no_leading_hash,
);

our $is_array_of_ids = array {
  filter_items { grep { ! JMAP::Validation::Tests::String::is_id($_) } @_ };
  end();
};

our $is_date = validator(sub{
  my (%params) = @_;

  return unless JMAP::Validation::Tests::String::is_string($params{got});
  return unless $params{got} =~ m{^(\d\d\d\d)-(\d\d)-(\d\d)$};

  return unless eval {
    DateTime->new(
      year  => $1,
      month => $2,
      day   => $3,
    )
  };

  return 1;
});

our $is_datetime = validator(sub{
  my (%params) = @_;

  return unless JMAP::Validation::Tests::String::is_string($params{got});
  return unless $params{got} =~ m{^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z$};

  return unless eval {
    DateTime->new(
      year   => $1,
      month  => $2,
      day    => $3,
      hour   => $4,
      minute => $5,
      second => $6,
    )
  };

  return 1;
});

our $is_datetime_local = validator(sub{
  my (%params) = @_;

  return unless JMAP::Validation::Tests::String::is_string($params{got});
  return unless $params{got} =~ m{^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)$};

  return unless eval {
    DateTime->new(
      year   => $1,
      month  => $2,
      day    => $3,
      hour   => $4,
      minute => $5,
      second => $6,
    )
  };

  return 1;
});

# }}}

1;
