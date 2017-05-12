use strict;
use warnings;
no warnings 'once';
use Test::More;
use JSON::Tiny 'decode_json';

my $rv = decode_json '{ "a":false, "b":true }';

ok $rv->{a}->isa('JSON::Tiny::_Bool'),
   'Decoding a "false" Boolean yields JSON::Tiny::_Bool object.';
ok $rv->{b}->isa('JSON::Tiny::_Bool'),
   'Decoding "true" Boolean yields JSON::Tiny::_Bool object.';
is ref $rv->{a}, 'JSON::Tiny::_Bool', 'ref detects JSON::Tiny::_Bool';
is ref $rv->{b}, 'JSON::Tiny::_Bool', 
  'ref detects JSON::Tiny::_Bool type (true)';

{
  local ( $JSON::Tiny::FALSE, $JSON::Tiny::TRUE ) = ( 0, 1 );
  $rv = decode_json '{"a":false, "b":true}';

  is $rv->{a}, 0, 'Overridden Boolean false yields 0';
  is $rv->{b}, 1, 'Overridden Boolean true yields 1';
  is ref $rv->{a}, '', 'Overriding Boolean false assumes correct type.';
  is ref $rv->{b}, '', 'Overriding Boolean true assumes correct type.';
}

$rv = decode_json '{"a":false, "b":true}';

is ref $rv->{b}, 'JSON::Tiny::_Bool',
   'JSON::Tiny::_Bool back after localized change to $JSON::Tiny::FALSE ' .
   'falls from scope.';
is ref $rv->{a}, 'JSON::Tiny::_Bool',
   'JSON::Tiny::_Bool back after localized change to $JSON::Tiny::TRUE ' .
   'falls from scope.';

$rv = JSON::Tiny::encode_json { a=>\0, b=>\1 };

like $rv, qr/"b":true/,  'Reference to \\1 yields true.';
like $rv, qr/"a":false/, 'Reference to \\0 yields false.';

done_testing();
