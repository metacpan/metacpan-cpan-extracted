package hint_hash_pragma;
use strictures 1;

sub import {
  my ($class, $val) = @_;
  $^H |= 0x20000;
  $^H{hint_hash_pragma} = $val;
}

1;
