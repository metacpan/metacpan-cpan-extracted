use strict;
use warnings;
use Test::More tests => 1;
use FFI::Platypus;

subtest 'C++' => sub {
  plan tests => 3;

  my $ffi = FFI::Platypus->new(lang => 'CPP');
  eval { $ffi->type('int') };
  is $@, '', 'int is an okay type';
  eval { $ffi->type('foo_t') };
  isnt $@, '', 'foo_t is not an okay type';
  note $@;
  eval { $ffi->type('sint16') };
  is $@, '', 'sint16 is an okay type';

};

