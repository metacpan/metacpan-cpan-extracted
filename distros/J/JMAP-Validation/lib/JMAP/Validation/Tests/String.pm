package JMAP::Validation::Tests::String;

use strict;
use warnings;

use DateTime;
use Encode;
use JMAP::Validation::Tests::Array;

 # data types {{{

sub is_string {
  my ($value) = @_;

  return (ref($value) || '') eq 'JSON::Typist::String';
}

# }}}

# restrictions {{{

sub has_at_least_one_character {
  my ($value) = @_;

  return length($value) >= 1;
}

sub has_at_most_256_bytes {
  my ($value) = @_;

  return length(Encode::encode_utf8($value)) <= 256;
}

sub has_no_leading_hash {
  my ($value) = @_;

  return $value !~ /^#/;
}

sub is_id {
  my ($value) = @_;

  return
       is_string($value)
    && has_at_least_one_character($value)
    && has_at_most_256_bytes($value)
    && has_no_leading_hash($value);
}

sub is_array_of_ids {
  my ($value) = @_;

  return unless JMAP::Validation::Tests::Array::is_array($value);

  foreach my $id (@{$value}) {
    return unless is_id($id);
  }

  return 1;
}

sub is_date {
  my ($value) = @_;

  return is_string($value);
  return unless $value =~ m{^(\d\d\d\d)-(\d\d)-(\d\d)$};

  return unless eval {
    DateTime->new(
      year  => $1,
      month => $2,
      day   => $3,
    )
  };

  return 1;
}

# }}}

1;
