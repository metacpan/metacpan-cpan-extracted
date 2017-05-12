package Music_Normalize_Fields;
require Normalize::Text::Normalize_Fields;
use strict;

for my $n (keys %Normalize::Text::Normalize_Fields::) {
  my $glob = $Normalize::Text::Normalize_Fields::{$n};
  next unless defined *$glob{CODE};
  *$n = \&{"Normalize::Text::Normalize_Fields::$n"};
}
